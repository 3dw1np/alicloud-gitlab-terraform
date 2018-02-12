output "slb_web_public_ip" {
  value = "${alicloud_slb.web.address}"
}

output "db_connections" {
  value = "${alicloud_db_instance.default.connection_string}"
}