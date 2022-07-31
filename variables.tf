variable "nginx_load_balancer_ip" {
  default = ""
}

variable "letsencrypt_issuer_name" {
  default = "letsencrypt"
}

variable "letsencrypt_admin_email" {
  type = string
}

variable "nginx_customer_headers" {
  description = "Custom nginx headers for each request"
  type        = map(string)
  default     = {
    "X-Country-Code" : "$geoip2_data_country_code"
    "X-City-Name" : "$geoip2_data_city_name"
  }
}

variable "nginx_namespace" {
  default = "ingress-nginx"
}

variable "cert_manager_namespace" {
  default = "cert-manager"
}