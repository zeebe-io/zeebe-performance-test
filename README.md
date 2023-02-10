## Initial Setup

The cluster should have chaos mesh installed:
```shell
helm list -A -f chaos
```

If not, you can install it:

```shell
helm upgrade --install chaos-mesh \
    chaos-mesh/chaos-mesh --version 2.5.1 \
    --namespace=chaos-mesh --create-namespace \
    --set dashboard.securityMode=false \
    --set chaosDaemon.runtime=containerd \
    --set chaosDaemon.socketPath=/var/run/containerd/containerd.sock
```

Accessing chaos mesh:

```
kubectl -n chaos-mesh port-forward svc/chaos-dashboard 2333
```

## Running experiments

### Locally using nix

Enter the nix develop environment:
```shell
nix develop
```

Run the script:
```shell
BENCHMARK_NAME=os-perf-test ./run.sh
```

This will take a moment but eventually the script will print out some measurements before and after running the chaos-mesh experiment.

### Locally without nix

Make sure that you have all dependencies installed:
- gcloud
- kubectl
- helm
- jq

and run the script: 
```shell
BENCHMARK_NAME=os-perf-test ./run.sh
```

### Using GitHub Actions

Trigger the `measure` workflow with a benchmark name.

## Adding experiments

Access the chaos mesh UI, use the experiment designer and save the yaml file in `experiments/`. 
Replace namespaces and the like with enviroment variables. These will be substituted before the experiment is deployed.
