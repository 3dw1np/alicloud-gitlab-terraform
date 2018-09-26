

resource "alicloud_security_group" "web" {
  name   = "${var.name}_web_sg"
  vpc_id = "${var.vpc_id}"
}

resource "alicloud_security_group" "ssh" {
  name   = "${var.name}_ssh_sg"
  vpc_id = "${var.vpc_id}"
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

resource "alicloud_slb" "web" {
  name                 = "${var.name}_web_slb"
  internet             = true
  internet_charge_type = "paybytraffic"
}

resource "alicloud_slb_listener" "http" {
  load_balancer_id          = "${alicloud_slb.web.id}"
  backend_port              = 80
  frontend_port             = 80
  bandwidth                 = 10
  protocol                  = "http"
  health_check_connect_port = 80
  health_check_http_code    = "http_2xx,http_3xx"
  sticky_session            = "on"
  sticky_session_type       = "insert"
  cookie                    = "alicloud_${var.name}"
  cookie_timeout            = 86400
}

resource "alicloud_slb_attachment" "default" {
  load_balancer_id = "${alicloud_slb.web.id}"
  instance_ids     = ["${alicloud_instance.web.*.id}"]
}

resource "alicloud_instance" "bastion" {
  instance_name              = "bastion_srv"
  instance_type              = "ecs.n4.large"
  system_disk_category       = "cloud_ssd"
  system_disk_size           = 50
  image_id                   = "ubuntu_14_0405_64_20G_alibase_20170824.vhd"

  vswitch_id                 = "${element(var.public_vswitchs_ids, 0)}"
  internet_max_bandwidth_out = 1 // Not allocate public IP for VPC instance

  security_groups            = ["${alicloud_security_group.ssh.id}"]
  password                   = "${var.ssh_password}"
}

resource "alicloud_instance" "web" {
  instance_name              = "${var.name}_web_srv_${count.index}"
  instance_type              = "ecs.n4.large"
  system_disk_category       = "cloud_ssd"
  system_disk_size           = 50
  image_id                   = "ubuntu_14_0405_64_20G_alibase_20170824.vhd"
  count                      = 2

  vswitch_id                 = "${element(var.public_vswitchs_ids, count.index)}"
  internet_max_bandwidth_out = 0 // Not allocate public IP for VPC instance

  security_groups            = ["${alicloud_security_group.web.id}", "${alicloud_security_group.ssh.id}"]
  user_data                  = "${element(data.template_file.user_data.*.rendered, count.index)}"
  password                   = "${var.ssh_password}"

  depends_on                 = ["alicloud_db_instance.default", "alicloud_db_account.account"]
}

resource "alicloud_db_instance" "default" {
    instance_name         = "${var.name}-db-srv"
    engine                = "PostgreSQL"
    engine_version        = "9.4"
    instance_type         = "rds.pg.s2.large"
    instance_storage      = "10"

    vswitch_id            = "${element(var.private_vswitchs_ids, 0)}"
    security_ips          = ["192.168.1.0/24", "192.168.2.0/24"]
}

resource "alicloud_db_account" "account" {
  instance_id = "${alicloud_db_instance.default.id}"
  name        = "gitlab"
  password    = "${var.db_password}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/tpl/user_data.sh")}"

  vars {
    INSTANCE_INDEX  = "${count.index}"
    WEB_URL         = "http://${alicloud_slb.web.address}"
    DB_CONNECT      = "${alicloud_db_instance.default.connection_string}"
    DB_PASSWORD     = "${var.db_password}"
    REDIS_CONNECT   = "${var.redis_connect}"
    REDIS_PASSWORD  = "${var.redis_password}"
    NAS_MOUNT_POINT = "${element(var.nas_mount_points, count.index)}"
  }
}