output "vpc_id" {
  value = "${alicloud_vpc.default.id}"
}

output "public_vswitchs_ids" {
  value = ["${alicloud_vswitch.public.*.id}"]
}

output "private_vswitchs_ids" {
  value = ["${alicloud_vswitch.private.*.id}"]
}