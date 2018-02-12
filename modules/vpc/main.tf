data "alicloud_zones" "default" {
  "available_instance_type"= "ecs.n4.large"
  "available_disk_category"= "cloud_ssd"
}

resource "alicloud_vpc" "default" {
  name        = "${var.name}"
  cidr_block  = "${var.cidr}"
}

resource "alicloud_nat_gateway" "nat_gateway" {
  vpc_id          = "${alicloud_vpc.default.id}"
  specification   = "Small"

  depends_on = ["alicloud_vswitch.public"]
}

resource "alicloud_eip" "default" {
  bandwidth = "5"
  count     = "${var.az_count}"
}

resource "alicloud_eip_association" "default" {
  allocation_id = "${element(alicloud_eip.default.*.id, count.index)}"
  instance_id   = "${alicloud_nat_gateway.nat_gateway.id}"
  count         = "${var.az_count}"
}

resource "alicloud_snat_entry" "default" {
  snat_table_id     = "${alicloud_nat_gateway.nat_gateway.snat_table_ids}"
  source_vswitch_id = "${element(alicloud_vswitch.public.*.id, count.index)}"
  snat_ip           = "${element(alicloud_eip.default.*.ip_address, count.index)}"
  count             = "${var.az_count}"
}

resource "alicloud_security_group" "web" {
  name   = "web-sg"
  vpc_id = "${alicloud_vpc.default.id}"
}

resource "alicloud_security_group" "ssh" {
  name   = "ssh-sg"
  vpc_id = "${alicloud_vpc.default.id}"
}

resource "alicloud_security_group_rule" "allow_http_access" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = "${alicloud_security_group.web.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_ssh_access" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.ssh.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_vswitch" "public" {
  name              = "${var.name}_public_${count.index}"
  vpc_id            = "${alicloud_vpc.default.id}"
  cidr_block        = "${cidrsubnet(var.cidr, 8, count.index)}"
  availability_zone = "${lookup(data.alicloud_zones.default.zones[count.index], "id")}"
  count             = "${var.az_count}"
}

resource "alicloud_vswitch" "private" {
  name              = "${var.name}_private_${count.index}"
  vpc_id            = "${alicloud_vpc.default.id}"
  cidr_block        = "${cidrsubnet(var.cidr, 8, count.index + 2)}"
  availability_zone = "${lookup(data.alicloud_zones.default.zones[count.index], "id")}"
  count             = "${var.az_count}"
}