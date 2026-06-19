# K9s Cheat Sheet

A quick reference for navigating your EKS cluster with K9s on Windows.

## Launch

```powershell
# In a normal pwsh / Windows Terminal window (NOT the "PowerShell Extension" pane)
k9s
```

If `k9s` is not found in the current shell, use the full path or open a new terminal:

```powershell
C:\Users\Owner\AppData\Local\Microsoft\WinGet\Packages\Derailed.k9s_Microsoft.Winget.Source_8wekyb3d8bbwe\k9s.exe
```

Useful launch flags:

```powershell
k9s --context <context-name>   # start in a specific cluster context
k9s -n amazon-cloudwatch       # start in a specific namespace
k9s --readonly                 # safe view-only mode (no edits/deletes)
```

## Core Concept

K9s works through a command bar. Press `:` then type a resource name and press `Enter`.

```text
:ns        ->  namespaces
:po        ->  pods
:deploy    ->  deployments
:svc       ->  services
:sa        ->  service accounts
:no        ->  nodes
:ev        ->  events
:cm        ->  config maps
:secret    ->  secrets
:ing       ->  ingresses
:rs        ->  replica sets
:ds        ->  daemon sets
:sts       ->  stateful sets
:job       ->  jobs
:cj        ->  cron jobs
:pvc       ->  persistent volume claims
:crd       ->  custom resource definitions
```

## Navigation

| Key | Action |
|-----|--------|
| `:` | Open command bar |
| `Enter` | Drill into selected resource |
| `Esc` | Go back / cancel |
| `Tab` | Move between panels |
| arrow keys / `j` `k` | Move down / up |
| `/` | Filter the current list |
| `q` or `Ctrl+c` | Quit K9s |
| `?` | Help / keybindings |
| `0` | Show all namespaces |

## Working With a Pod

Select a pod, then:

| Key | Action |
|-----|--------|
| `Enter` | Show containers in the pod |
| `l` | View logs |
| `p` | View previous container logs (after a crash) |
| `d` | Describe the resource |
| `e` | Edit the resource (YAML) |
| `y` | View the full YAML |
| `s` | Shell into the container |
| `Ctrl+k` | Kill the pod (delete) |
| `Esc` | Back to the list |

### Logs view shortcuts

| Key | Action |
|-----|--------|
| `0` | Show all log lines |
| `1`..`9` | Tail last N minutes |
| `f` | Toggle full screen |
| `w` | Toggle line wrap |
| `Esc` | Exit logs |

## Switching Namespace / Context

```text
:ns            ->  pick a namespace, press Enter to scope to it
:ctx           ->  switch Kubernetes context (cluster)
```

## Troubleshooting Flow (CloudWatch Agent Example)

1. Press `:`, type `ns`, press `Enter`.
2. Select `amazon-cloudwatch`, press `Enter`.
3. Press `:`, type `po`, press `Enter`.
4. Select the `cloudwatch-agent` pod.
5. Press `p` to view previous (crashed) container logs.
6. Press `d` to describe and read the events at the bottom.
7. Press `e` (or `:sa`) to inspect the service account and its IAM role annotation.

## Common Filters

While viewing a list, press `/` then type:

```text
/cloudwatch      ->  filter resources containing "cloudwatch"
/Running         ->  filter by status
/!Running        ->  inverse filter (NOT Running)
```

## Safety Tips

- Use `--readonly` when you only want to inspect, to avoid accidental deletes.
- `Ctrl+k` deletes the selected resource. Confirm before pressing it.
- If keystrokes don't register, click inside the terminal to focus it, or
  run K9s in Windows Terminal instead of the VS Code "PowerShell Extension" pane.

## Equivalent kubectl Commands

If K9s misbehaves, these give the same information:

```powershell
kubectl get ns
kubectl get pods -n amazon-cloudwatch
kubectl describe pod -n amazon-cloudwatch <pod-name>
kubectl logs -n amazon-cloudwatch <pod-name> -c otc-container --previous
kubectl get sa -n amazon-cloudwatch cloudwatch-agent -o yaml
kubectl config get-contexts
```
