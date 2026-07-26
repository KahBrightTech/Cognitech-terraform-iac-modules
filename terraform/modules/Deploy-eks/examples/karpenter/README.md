# Karpenter for EKS

This example deploys an EKS cluster with a minimal static node group (just enough to run the Karpenter controller pod) and enables Karpenter to provision every other node dynamically, based on actual pending pod requirements.

## Overview

Karpenter watches for unschedulable pods and launches right-sized EC2 instances directly (no Auto Scaling Group in the loop), consolidating/terminating underutilized nodes as workloads shrink. It replaces Cluster Autoscaler - **enable one or the other, not both** (`eks_addons.enable_karpenter` and `eks_addons.enable_cluster_autoscaler` are mutually exclusive; the module will fail `terraform plan` if both are `true`, since they'd both try to manage EC2 capacity for the same pending pods).

Unlike Cluster Autoscaler, Karpenter needs more than a Helm release:

- A **node IAM role** that trusts `ec2.amazonaws.com` (not the OIDC provider like every other addon's role in this module) - the instances Karpenter launches assume this.
- An **EC2_LINUX EKS access entry** for that role, so nodes Karpenter launches can actually join the cluster.
- An **SQS queue + 4 EventBridge rules** so Karpenter can react to spot interruption, instance rebalance, instance state-change, and AWS health events.
- The `NodePool`/`EC2NodeClass` custom resources that tell Karpenter what to launch. These aren't applied by Terraform (their CRDs don't exist until the Helm release has actually run, which makes them awkward with `kubernetes_manifest` in the same apply) - instead you author them as a plain YAML file and the module reads + placeholder-substitutes it into an output.

## Keeping controller pods off Karpenter nodes

The module hardcodes a `workload-type = system` label/toleration pair onto
every controller-type Deployment it manages (coredns, csi driver
controllers, load balancer controller, karpenter itself, cluster-autoscaler,
external-dns, kube-prometheus-stack, metrics-server, privateca-issuer) - see
`local.controller_scheduling` in `main.tf`. DaemonSets the module manages
(vpc-cni, kube-proxy, csi driver node plugins, pod-identity-agent,
secrets-store-csi-driver-provider-aws, fluent-bit) only pick up the
toleration via `local.daemonset_scheduling`, never the nodeSelector, since
they must keep running on every node - including Karpenter ones. This isn't
configurable per-environment; it's baked into the module.

For this to actually repel application pods onto Karpenter nodes, your
static "system" node group needs the matching label and taint:

```hcl
labels = { "workload-type" = "system" }
taints = [
  { key = "workload-type", value = "system", effect = "NO_SCHEDULE" } # AWS API spelling, not Kubernetes' "NoSchedule"
]
```

Leave your `NodePool`/`EC2NodeClass` untainted (as in
`karpenter-nodepool.yaml`) so Karpenter-launched nodes accept any pod with no
special toleration required - this is what makes application workloads land
there by default, with zero changes needed on the application side.

## Prerequisites

1. An EKS cluster (this example creates one) with a small static node group for the controller pod
2. Three files in this folder: `karpenter-controller-policy.json`, `karpenter-node-trust-policy.json`, and `karpenter-nodepool.yaml`
3. Subnet IDs and a VPC already provisioned (see the `subnets`/`vpc` modules elsewhere in this repo)

## Setup

1. **Edit `karpenter-controller-policy.json`**: replace every `${CLUSTER_NAME}` with your actual cluster name. `[[account_number]]` and `[[region]]` are filled in automatically by the module (same mechanism used by every other IAM policy file in this repo) - only `${CLUSTER_NAME}` needs a manual edit, since that substitution isn't one of the ones the module supports.

2. **Edit `karpenter-nodepool.yaml`**: this is a plain Kubernetes YAML file - write your `EC2NodeClass`/`NodePool` however you'd normally write them. The module substitutes these placeholders automatically: `[[account_number]]`, `[[account_name]]`, `[[account_name_abr]]`, `[[region]]`, `[[region_prefix]]`, `[[cluster_name]]`, `[[node_role_name]]`, `[[node_role_arn]]`. Adjust AMI family, subnet/security-group selectors, instance requirements, limits, and disruption settings directly in the file.

   `subnetSelectorTerms`/`securityGroupSelectorTerms` only match what's actually tagged that way in your account - if nothing matches, Karpenter can't launch any nodes. This example matches both by `Name` tag, built from `[[account_name]]`/`[[region_prefix]]` so the same file deploys cleanly in any account without editing literal strings: subnets via `Name: "[[account_name]]-[[region_prefix]]-*-sbnt*-public-*"`, and the security group via `Name: "[[account_name]]-[[region_prefix]]-*eks-nodes*"` (adjust the wildcard to match your actual SG naming - this assumes a dedicated node security group with `eks-nodes` in the name, rather than relying on EKS's auto-tagged cluster security group). If your naming differs, adjust the pattern or switch to explicit `id:` entries instead.

3. **Edit `terragrunt.hcl`**: fill in your real `subnet_ids`, `role_arn`, `oidc_thumbprint`, and admin role ARN.

4. **Deploy**:
   ```bash
   terragrunt apply
   ```

5. **Apply the NodePool/EC2NodeClass** once the Karpenter controller pod is running:
   ```bash
   aws eks update-kubeconfig --name my-cluster --region us-east-1
   terragrunt output -raw karpenter_manifests_yaml | kubectl apply -f -
   ```
   Re-run this any time you edit `karpenter-nodepool.yaml` - the substituted output changes, but Terraform won't re-apply it for you.

## Configuration Reference

```hcl
eks_addons = {
  enable_karpenter = true

  karpenter = {
    chart_version           = "1.1.1"
    controller_role_key     = "karpenter_controller" # references iam_roles below
    node_role_key           = "karpenter_node"        # references iam_roles below
    interruption_queue_name = "my-cluster"
    nodepool_manifest_file  = "${get_terragrunt_dir()}/karpenter-nodepool.yaml"
  }
}
```

And on the system node group itself (see "Keeping controller pods off
Karpenter nodes" above - the label/taint here must match what the module
hardcodes for controller pods):

```hcl
eks_node_groups = [
  {
    key = "system"
    labels = { "workload-type" = "system" }
    taints = [
      { key = "workload-type", value = "system", effect = "NO_SCHEDULE" } # AWS API spelling
    ]
    # ...desired_size, instance_types, etc.
  }
]
```

Both IAM roles are created the same way every other addon's role is in this module - via `iam_roles` entries referenced by key:

```hcl
iam_roles = [
  {
    key                       = "karpenter_controller"
    name                      = "karpenter-controller-role"
    service_account_name      = "karpenter"
    service_account_namespace = "kube-system"
    policy = {
      name   = "karpenter-controller-policy"
      policy = "${get_terragrunt_dir()}/karpenter-controller-policy.json"
    }
  },
  {
    key                   = "karpenter_node"
    name                  = "karpenter-node-role"
    assume_role_policy    = "${get_terragrunt_dir()}/karpenter-node-trust-policy.json" # overrides the default OIDC trust policy
    create_custom_policy  = false
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
  }
]
```

The node role doesn't need a custom policy (`create_custom_policy = false`), just the standard EKS worker managed policies plus SSM (handy for `aws ssm start-session` node access without SSH).

## Verification

```bash
# Controller pod running?
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter

# Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -f

# NodePool/EC2NodeClass applied?
kubectl get nodepools,ec2nodeclasses

# Node role able to join the cluster?
terragrunt output karpenter_node_access_entry
```

## Testing

Scale up:
```bash
kubectl create deployment karpenter-test --image=nginx --replicas=20 \
  --requests=cpu=500m
kubectl get nodes -w   # new nodes should appear within ~30-60s
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -f
```

Scale down (consolidation):
```bash
kubectl delete deployment karpenter-test
# with consolidate_after = "1m", nodes should start terminating shortly after
kubectl get nodes -w
```

## Troubleshooting

**Nodes never launch**
- Check controller logs for IAM errors first - a missing action in `karpenter-controller-policy.json` is the most common cause.
- Confirm `karpenter_node_access_entry` in the outputs shows the node role - if the access entry wasn't created, new nodes can launch but can never register with the API server.
- Double check `${CLUSTER_NAME}` was actually replaced in the policy file - a literal `${CLUSTER_NAME}` in the JSON is invalid ARN syntax and IAM will reject the policy at apply time.

**Nodes launch but never go Ready**
- Usually a networking issue - verify `subnet_ids` in `eks_addons.karpenter` are subnets that can actually reach the cluster endpoint, and that the security group (defaults to the cluster SG) allows node-to-control-plane traffic.

**Spot interruptions aren't handled gracefully**
- Verify the SQS queue name matches what's in `karpenter_interruption_queue_name` output, and that all 4 EventBridge rules (`terraform state list | grep karpenter_interruption`) exist and target that queue.

## Additional Resources

- [Karpenter Documentation](https://karpenter.sh/)
- [Karpenter NodePool API Reference](https://karpenter.sh/docs/concepts/nodepools/)
- [Karpenter EC2NodeClass API Reference](https://karpenter.sh/docs/concepts/nodeclasses/)
- [AWS Karpenter Getting Started Guide](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/)
