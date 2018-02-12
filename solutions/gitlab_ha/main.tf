module "gitlab" {
  source = "../../modules/gitlab"
  name   = "${var.name}"
  vpc_id = "${var.vpc_id}"
  public_vswitchs_ids = "${var.public_vswitchs_ids}"
  private_vswitchs_ids = "${var.private_vswitchs_ids}"
  ssh_password = "${var.ssh_password}"
  db_password = "${var.db_password}"
  redis_connect = "${var.redis_connect}"
  redis_password = "${var.redis_password}"
  nas_mount_points = "${var.nas_mount_points}"
}