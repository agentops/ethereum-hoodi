provider "docker" {

}
provider "random" {

}

resource "random_bytes" "jwt_secret" {
  length = 32
}
resource "local_file" "jwt_secret_file" {
  content  = random_bytes.jwt_secret.hex
  filename = "/tmp/jwtsecret"

}

locals {
  config_data = {
    global = {
      scrape_interval     = "15s"
      evaluation_interval = "15s"
    }
    scrape_configs = [
      {
        job_name     = "nethermind"
        honor_labels = true
        static_configs = [
          {
            targets = ["${docker_container.execution_client.network_data[0].ip_address}:9093"]
            labels = {
              group = "local"
            }
          }
        ]
      }
    ]
  }
  yaml_config = yamlencode(local.config_data)

}

resource "local_file" "prom_config" {
  content  = local.yaml_config
  filename = "prometheus.yml"
}

/** * Pull Docker images for Nethermind and Lighthouse
 */
resource "docker_image" "nethermind" {
  name         = var.execution_client_image
  keep_locally = false
}

resource "docker_image" "consensus_client" {
  name         = var.consensus_client_image
  keep_locally = false

}

resource "docker_image" "prometheus" {
  name         = var.prometheus_image
  keep_locally = false
}

resource "docker_image" "grafana" {
  name         = var.grafana_image
  keep_locally = false

}

/** * Docker container for Nethermind execution client
 */
resource "docker_container" "execution_client" {
  depends_on = [local_file.jwt_secret_file ]
  image      = docker_image.nethermind.name
  mounts {
    target    = "/nethermind/jwtsecret"
    source    = local_file.jwt_secret_file.filename
    type      = "bind"
    read_only = true
  }
  name = "nethermind_execution_client"
  ports {
    internal = 30303
    external = 30303
    protocol = "tcp"
  }
  ports {
    internal = 8545
    external = 8545
    protocol = "tcp"
  }
  ports {
    internal = 8551
    external = 8551
    protocol = "tcp"
  }
  ports {
    internal = 9093
    external = 9093
    protocol = "tcp"
  }
  env = [
    "NETHERMIND_CONFIG=${var.network_name}",
    "NETHERMIND_JSONRPCCONFIG_ENABLED=true",
    "NETHERMIND_JSONRPCCONFIG_HOST=0.0.0.0",
    "NETHERMIND_JSONRPCCONFIG_PORT=8545",
    "NETHERMIND_JSONRPCCONFIG_ENGINEHOST=0.0.0.0",
    "NETHERMIND_JSONRPCCONFIG_ENGINEPORT=8551",
    "NETHERMIND_HEALTHCHECKSCONFIG_ENABLED=true",
    "NETHERMIND_SYNCCONFIG_SNAPSYNC=true",
    "NETHERMIND_METRICSCONFIG_ENABLED=true",
    "NETHERMIND_METRICSCONFIG_MONITORINGGROUP=local",
    "NETHERMIND_METRICSCONFIG_MONITORINGJOB=nethermind",
    "NETHERMIND_METRICSCONFIG_EXPOSEPORT=9093",
    "NETHERMIND_JSONRPCCONFIG_JWTSECRETFILE=/nethermind/jwtsecret"
  ]

}

/** * Docker container for Lighthouse consensus client
 */
resource "docker_container" "consensus_client" {
  name  = "lighthouse_consensus_client"
  image = docker_image.consensus_client.name
  ports {
    internal = 9000
    external = 9000
    protocol = "tcp"
  }
  ports {
    internal = 5052
    external = 5052
    protocol = "tcp"
  }
  ports {
    internal = 9000
    external = 9000
    protocol = "udp"
  }

  mounts {
    target    = "/lighthouse/jwtsecret"
    source    = local_file.jwt_secret_file.filename
    type      = "bind"
    read_only = true
  }

  depends_on = [random_bytes.jwt_secret, docker_container.execution_client]
  command = [
    "lighthouse",
    "bn",
    "--network",
    "hoodi",
    "--http",
    "--http-address",
    "0.0.0.0",
    "--datadir",
    "${var.consensus_data_dir}",
    "--execution-endpoint",
    "http://${docker_container.execution_client.network_data[0].ip_address}:8551",
    "--checkpoint-sync-url",
    "${var.checkpoint_sync_url}",
    "--disable-deposit-contract-sync",
    "--execution-jwt",
    "/lighthouse/jwtsecret"
  ]
}


/* Prometheus Container*/
resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.name
  ports {
    internal = 9090
    external = 9090
    protocol = "tcp"
  }
  mounts {
    target = "/etc/prometheus/prometheus.yml"
    source = "${path.cwd}/${local_file.prom_config.filename}"
    type   = "bind"
  }
  depends_on = [local_file.prom_config]
}

resource "docker_container" "grafana" {
  name = "grafana"
  image = var.grafana_image
    ports {
    internal = 3000
    external = 3030
    protocol = "tcp"
    }
    env = [
      "GF_SECURITY_ADMIN_PASSWORD=admin",
      "GF_USERS_ALLOW_SIGN_UP=false"
    ]
  depends_on = [docker_container.prometheus]
}


output "docker_container_ip" {
  value = docker_container.execution_client.network_data[0].ip_address

}
