resource "kubernetes_config_map" "custom-headers" {
  metadata {
    name      = "custom-headers"
    namespace = "ingress-nginx"
  }

  data       = var.nginx_customer_headers
  depends_on = [
    helm_release.nginx
  ]
}

resource "helm_release" "nginx" {
  name             = "nginx"
  chart            = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  namespace        = var.nginx_namespace
  create_namespace = true
  values           = [
    yamlencode({
      controller : {
        autoscaling : {
          enabled : false
        }
        config : {
          use-geoip2 : "false"
          log-format-escape-json : "true"
          proxy-set-headers : "true"
          log-format-upstream : "{proxyUpstreamName\": \"$proxy_upstream_name\", \"proxyUpstreamAddr\": \"$upstream_addr\", \"requestMethod\": \"$request_method\", \"requestUrl\": \"$host$uri?$args\", \"status\": $status, \"requestSize\": \"$request_length\", \"responseSize\": \"$upstream_response_length\", \"userAgent\": \"$http_user_agent\", \"remoteIp\": \"$remote_addr\", \"serverIp\": \"$remote_addr\", \"referer\": \"$http_referer\", \"latency\": \"$upstream_response_time\"}"
        }
        service : {
          externalTrafficPolicy : "Local"
          loadBalancerIP : var.nginx_load_balancer_ip
        }
      }
    })
  ]
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  namespace        = var.cert_manager_namespace
  create_namespace = true

  set {
    name  = "installCRDs"
    value = true
  }
}

resource "kubernetes_manifest" "cluster-issuer" {
  depends_on = [
    helm_release.cert-manager
  ]
  count    = var.create_cluster_issuer ? 1 : 0
  manifest = {
    apiVersion : "cert-manager.io/v1"
    kind : "ClusterIssuer"
    metadata = {
      name =  var.letsencrypt_issuer_name
    },
    spec = {
      "acme" = {
        "email"               = var.letsencrypt_admin_email
        "privateKeySecretRef" = {
          "name" = var.letsencrypt_issuer_name
        }
        "server"  = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            http01 = {
              "ingress" = {
                "class" = "nginx"
              }
            }
          },
        ]
      }
    }
  }
}
