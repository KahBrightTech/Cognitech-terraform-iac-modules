# Node Scheduling: System vs. Karpenter/Autoscaled Nodes

This module pins cluster-critical controllers to a tainted "system" node group and
leaves everything else free to run on whatever untainted worker capacity you provision
(Karpenter-managed nodes, a Cluster Autoscaler-managed node group, or both). This is
implemented in `main.tf` via three locals:

- `system_node_selector` - `{ "workload-type" = "system" }`, matched against the label
  you put on your system node group's `eks_node_groups` entry.
- `system_tolerations` - tolerates `workload-type=system:NoSchedule` with `operator = "Equal"`.
  Combined with `system_node_selector`, this pins a Deployment/StatefulSet to the system
  node group specifically.
- `all_workload_node_tolerations` - tolerates `workload-type:NoSchedule` with
  `operator = "Exists"` (matches any value), and no nodeSelector. This lets a DaemonSet
  run on every node - system nodes included - without restricting it to only the system
  node group.

The system node group itself must carry both the label and the taint (see
`examples/karpenter/terragrunt.hcl` for a working example); application workloads get no
toleration for this taint at all, so the scheduler places them only on untainted nodes.

## Component Scheduling Reference

| Component | System node selector | System toleration | Runs on Karpenter/untainted nodes |
|---|---|---|---|
| VPC CNI | No | All-node toleration | Yes |
| kube-proxy | No | All-node toleration | Yes |
| CoreDNS | Yes | Yes | No |
| Pod Identity Agent | No | All-node toleration | Yes |
| EBS CSI controller | Yes | Yes | No |
| EBS CSI node | No | All-node toleration | Yes |
| EFS CSI controller | Yes | Yes | No |
| EFS CSI node | No | All-node toleration | Yes |
| FSx CSI controller | Yes | Yes | No |
| FSx CSI node | No | All-node toleration | Yes |
| Private CA Issuer | Yes | Yes | No |
| Secrets Store provider | No | All-node toleration | Yes |
| AWS Load Balancer Controller | Yes | Yes | No |
| Cluster Autoscaler | Yes | Yes | No |
| Karpenter controller | Yes | Yes | No |
| ExternalDNS | Yes | Yes | No |
| Metrics Server | Yes | Yes | No |
| CloudWatch node agent | No | All-node toleration | Yes |
| Fluent Bit | No | All-node toleration | Yes |
| Grafana | Yes | Yes | No |
| Prometheus | Yes | Yes | No |
| Prometheus Operator | Yes | Yes | No |
| Prometheus node exporter | No | All-node toleration | Yes |
| Alertmanager | Yes | Yes | No |

### Reading the table

- **System node selector = Yes** means the component's `configuration_values`/Helm
  `values` set `nodeSelector = local.system_node_selector`, restricting it to nodes
  labeled `workload-type: system`.
- **System toleration = Yes** means it also carries `tolerations = local.system_tolerations`
  (the `Equal`/`system` toleration), which is what actually lets it schedule on the
  tainted system nodes - the label alone only narrows where it *can* go, the taint is what
  would otherwise block it there.
- **All-node toleration** means it uses `local.all_workload_node_tolerations` instead
  (the `Exists` toleration, no nodeSelector) - it tolerates the system taint but isn't
  restricted to system nodes, so it schedules everywhere, which is required for anything
  that runs as a DaemonSet.
- **Runs on Karpenter/untainted nodes** reflects the net effect: components pinned to the
  system node group never land on Karpenter (or other untainted) nodes; DaemonSets and
  the CSI/agent "node" components do, because they either have no nodeSelector or are
  specifically designed to run everywhere.

### Two-part components

EBS, EFS, and FSx CSI drivers each deploy two separate workloads from a single addon:
a **controller** Deployment (pinned to system nodes, since it only talks to the AWS API)
and a **node** DaemonSet (must run on every node to handle the actual mount/unmount on
whichever host a pod lands on). Both halves are configured in the same
`configuration_values` block, e.g.:

```terraform
configuration_values = jsonencode({
  controller = { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }
  node       = { tolerations = local.all_workload_node_tolerations }
})
```

### Karpenter is not required for this scheme to work

Nothing here depends on Karpenter specifically - it depends on there being untainted
worker capacity somewhere. That capacity can come from Karpenter (see
`examples/karpenter/`) or from a second, untainted `eks_node_groups` entry managed by
Cluster Autoscaler (see `examples/cluster-autoscaler/`). `enable_karpenter` and
`enable_cluster_autoscaler` are mutually exclusive (enforced by a validation rule in
`variables.tf`), since both would otherwise try to manage the same EC2 capacity.
