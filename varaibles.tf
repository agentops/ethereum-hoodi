variable "consensus_client_image" {
  description = "The Docker image for the consensus client (Lighthouse)."
  type        = string
  default     = "sigp/lighthouse:latest"

}

variable "execution_client_image" {
  description = "The Docker image for the execution client (Nethermind)."
  type        = string
  default     = "nethermind/nethermind:latest"

}

variable "checkpoint_sync_url" {
  description = "The checkpoint sync URL for the consensus client."
  type        = string
  default     = "https://beaconstate-hoodi.chainsafe.io"

}

variable "network_name" {
  description = "The Ethereum network name."
  type        = string
  default     = "hoodi"

}

variable "grafana_image" {
  description = "The Docker image for Grafana."
  type        = string
  default     = "grafana/grafana:latest"
}

variable "prometheus_image" {
  description = "The Docker image for Prometheus."
  type        = string
  default     = "prom/prometheus"
}
/*
variable "pushgateway_image" {
  description = "The Docker image for Prometheus Pushgateway."
  type        = string
  default     = "prom/pushgateway:latest"
}
*/
variable "consensus_data_dir" {
  description = "The data directory for the consensus client."
  type        = string
  default     = "/var/lib/lighthouse"

}

variable "execution_data_dir" {
  description = "The data directory for the execution client."
  type        = string
  default     = "/nethermind/data"

}