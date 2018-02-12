output "vpc_id" {
  value = "${alicloud_vpc.default.id}"
}

# output "public_subnets" {
#   value = ["${alicloud_vswitch.public.*.id}"]
# }

# output "private_subnets" {
#   value = ["${alicloud_vswitch.private.*.id}"]
# }