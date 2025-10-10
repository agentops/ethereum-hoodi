# Ethereum Node Deployment 
Ethereum(Hoodi Testnet) infrastructure setup with Terraform. With terraform we deploy the nethermind execution client alogside the lighthouse consensus client, using containers. Also Prometheus and Grafana for metrics gathering and visualization.


## Nethermind client
Default docker image is the nethermind/nethermind:latest image. You can use what version of the image youd prefer as documented on the nethermind documentation page linked here [Docs](https://docs.nethermind.io/). Also rely on the docs to enable functionality as needed, especially for metrics exposure.

## Consensus Client

Uses the sigp/lighthouse docker image. The consensus client is setup to do a checkpoint sync, which doesnt sync the entire hoodi testnet immediately.


## Monitoring

Prometheus is also setup to gather metrics from the execution client and is chosen as the datasource in grafana.