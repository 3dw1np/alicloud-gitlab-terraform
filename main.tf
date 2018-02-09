# Configure the Alicloud Provider
provider "alicloud" {}

# Init varaibles
variable "ssh_password" {}
variable "db_password" {}
variable "redis_connect" {
  default = "r-gs5e52f3dd2aa6f4.redis.singapore.rds.aliyuncs.com"
}
variable "redis_password" {}

variable "nas_mount_points" {
  default = ["7aa7048405-enk90.ap-southeast-1.nas.aliyuncs.com", "7aa7048405-txk20.ap-southeast-1.nas.aliyuncs.com"]
}

resource "alicloud_vpc" "default" {
  name        = "shared-services"
  cidr_block  = "192.168.0.0/16"
}

resource "alicloud_nat_gateway" "nat_gateway" {
  vpc_id          = "${alicloud_vpc.default.id}"
  specification   = "Small"

  depends_on = [
    "alicloud_vswitch.public_a",
    "alicloud_vswitch.public_b",
  ]
}

# resource "alicloud_eip" "eip_a" {
#   bandwidth = "5"
# }

# resource "alicloud_eip" "eip_b" {
#   bandwidth = "5"
# }

# resource "alicloud_eip_association" "eip_asso_a" {
#   allocation_id = "${alicloud_eip.eip_a.id}"
#   instance_id   = "${alicloud_nat_gateway.nat_gateway.id}"
# }

# resource "alicloud_eip_association" "eip_asso_b" {
#   allocation_id = "${alicloud_eip.eip_b.id}"
#   instance_id   = "${alicloud_nat_gateway.nat_gateway.id}"
# }

# resource "alicloud_snat_entry" "snat_a" {
#   snat_table_id     = "${alicloud_nat_gateway.nat_gateway.snat_table_ids}"
#   source_vswitch_id = "${alicloud_vswitch.public_a.id}"
#   snat_ip           = "${alicloud_eip.eip_a.ip_address}"
# }

# resource "alicloud_snat_entry" "snat_b" {
#   snat_table_id     = "${alicloud_nat_gateway.nat_gateway.snat_table_ids}"
#   source_vswitch_id = "${alicloud_vswitch.public_b.id}"
#   snat_ip           = "${alicloud_eip.eip_b.ip_address}"
# }

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

resource "alicloud_vswitch" "public_a" {
  name              = "public_a"
  vpc_id            = "${alicloud_vpc.default.id}"
  cidr_block        = "192.168.1.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "alicloud_vswitch" "public_b" {
  name              = "public_b"
  vpc_id            = "${alicloud_vpc.default.id}"
  cidr_block        = "192.168.2.0/24"
  availability_zone = "ap-southeast-1b"
}

resource "alicloud_vswitch" "private_a" {
  name              = "private_a"
  vpc_id            = "${alicloud_vpc.default.id}"
  cidr_block        = "192.168.3.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "alicloud_vswitch" "private_b" {
  name              = "private_b"
  vpc_id            = "${alicloud_vpc.default.id}"
  cidr_block        = "192.168.4.0/24"
  availability_zone = "ap-southeast-1b"
}

resource "alicloud_slb" "web" {
  name                 = "web-slb"
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
  cookie                    = "gitlab_alicloud"
  cookie_timeout            = 86400
}

resource "alicloud_slb_attachment" "default" {
  load_balancer_id = "${alicloud_slb.web.id}"
  instance_ids     = ["${alicloud_instance.web_a.id}", "${alicloud_instance.web_b.id}"]
}

resource "alicloud_instance" "bastion" {
  instance_name              = "bastion-srv"
  instance_type              = "ecs.n4.large"
  system_disk_category       = "cloud_ssd"
  system_disk_size           = 50
  image_id                   = "ubuntu_16_0402_64_20G_alibase_20171227.vhd"

  vswitch_id                 = "${alicloud_vswitch.public_a.id}"
  internet_max_bandwidth_out = 1 // Not allocate public IP for VPC instance

  security_groups            = ["${alicloud_security_group.ssh.id}"]
  //TODO: remove this
  password                   = "${var.ssh_password}"
}

resource "alicloud_instance" "web_a" {
  instance_name              = "gitlab-web-srv"
  instance_type              = "ecs.n4.large"
  system_disk_category       = "cloud_ssd"
  system_disk_size           = 50
  image_id                   = "ubuntu_16_0402_64_20G_alibase_20171227.vhd"

  vswitch_id                 = "${alicloud_vswitch.public_a.id}"
  internet_max_bandwidth_out = 0 // Not allocate public IP for VPC instance

  security_groups            = ["${alicloud_security_group.web.id}", "${alicloud_security_group.ssh.id}"]
  user_data                  = "${data.template_file.user_data_b.rendered}"
  //TODO: remove this
  password                   = "${var.ssh_password}"
}

resource "alicloud_instance" "web_b" {
  instance_name              = "gitlab-web-srv"
  instance_type              = "ecs.n4.large"
  system_disk_category       = "cloud_ssd"
  system_disk_size           = 50
  image_id                   = "ubuntu_16_0402_64_20G_alibase_20171227.vhd"

  vswitch_id                 = "${alicloud_vswitch.public_b.id}"
  internet_max_bandwidth_out = 0 // Not allocate public IP for VPC instance

  security_groups            = ["${alicloud_security_group.web.id}", "${alicloud_security_group.ssh.id}"]
  user_data                  = "${data.template_file.user_data_a.rendered}"
  //TODO: remove this
  password                   = "${var.ssh_password}"
}

resource "alicloud_db_instance" "default" {
    instance_name         = "gitlab-db-srv"
    engine                = "PostgreSQL"
    engine_version        = "9.4"
    instance_type         = "rds.pg.s2.large"
    instance_storage      = "10"

    vswitch_id            = "${alicloud_vswitch.private_a.id}"
    security_ips          = ["192.168.1.0/24", "192.168.2.0/24"]
}

resource "alicloud_db_account" "account" {
  instance_id = "${alicloud_db_instance.default.id}"
  name        = "gitlab"
  password    = "${var.db_password}"
}

data "template_file" "user_data_a" {
  template = "${file("user_data.sh")}"

  vars {
    WEB_URL         = "http://${alicloud_slb.web.address}"
    DB_CONNECT      = "${alicloud_db_instance.default.connection_string}"
    DB_PASSWORD     = "${var.db_password}"
    REDIS_CONNECT   = "${var.redis_connect}"
    REDIS_PASSWORD  = "${var.redis_password}"
    NAS_MOUNT_POINT = "${var.nas_mount_points[0]}"
  }
}

data "template_file" "user_data_b" {
  template = "${file("user_data.sh")}"

  vars {
    WEB_URL         = "http://${alicloud_slb.web.address}"
    DB_CONNECT      = "${alicloud_db_instance.default.connection_string}"
    DB_PASSWORD     = "${var.db_password}"
    REDIS_CONNECT   = "${var.redis_connect}"
    REDIS_PASSWORD  = "${var.redis_password}"
    NAS_MOUNT_POINT = "${var.nas_mount_points[1]}"
  }
}

output "slb_web_public_ip" {
  value = "${alicloud_slb.web.address}"
}

output "db_connections" {
  value = "${alicloud_db_instance.default.connection_string}"
}