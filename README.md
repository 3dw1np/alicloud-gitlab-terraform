# Deploy Gitlab HA on Alibaba Cloud with Terraform

At Alibaba Cloud, we use Terraform to provide fast demos to our customers.
I truly believe that the infrasture-as-code is the quick way to leverage a public cloud provider services. Instead of clicking on the Web Console UI, the logic of the infrasture-as-code allows us to define more accuratly each used services, automate the entire infrastructure and version it with a versionning control (git).

## High-level design
![HLD](https://raw.githubusercontent.com/3dw1np/alicloud-gitlab-terraform/master/HLD.png)

## Export environment variables
We provide the Alicloud credentials with envrionments variables. In this tutorial, we are going to use the Singapore Region (ap-southeast-1).
 
```
root@alicloud:~$ export ALICLOUD_ACCESS_KEY="anaccesskey"
root@alicloud:~$ export ALICLOUD_SECRET_KEY="asecretkey"
root@alicloud:~$ export ALICLOUD_REGION="ap-southeast-1"
```

If you don't have an access key for your Alicloud account yet, just follow this [tutorial](https://www.alibabacloud.com/help/doc-detail/28955.htm).

## Install Terraform
To install Terraform, download the appropriate package for your OS. The download contains an executable file that you can add in your global PATH.

Verify your PATH configuration by typing the terraform

```
root@alicloud:~$ terraform
Usage: terraform [--version] [--help] <command> [args]
```

## Setup Alicloud terraform provider (> v1.7.1)
The official repository for Alicloud terraform provider is [https://github.com/alibaba/terraform-provider]() 

* Download a compiled binary from https://github.com/alibaba/terraform-provider/releases.
* Create a custom plugin directory named **terraform.d/plugins/darwin_amd64**.
* Move the binary inside this custom plugin directory.
* Create **test.tf** file for the plan and provide inside:

```
# Configure the Alicloud Provider
provider "alicloud" {}
```

* Initialize the working directory but Terraform will not download the alicloud provider plugin from internet, because we provide a newest version locally.

```
terraform init
```

## Deployment steps
### Base vpc
```bash
terraform init solutions/base_vpc
terraform plan|apply \
  -var-file=parameters/base_vpc.tfvars \
  -state=states/base_vpc.tfstate \
  solutions/base_vpc
```

### Managed services (manual setup)
The managed services must be in the same region / VPC.

#### ApsaraDB for Redis

* Create a new instance (Standard or Cluster mode) named **'gitlab&#95;ha&#95;redis'**
* Select a private Vswitch where to bootstrap the instance
* Keep in mind the password set
* Replace the default whitelist group ips with **192.168.0.0/24,192.168.1.0/24** (corresponding to the public Vswitchs CIDR)
* Then you can get the Connection Address (host) on the instance information page (ex:  r-gs5fa531c02cbc74.redis.singapore.rds.aliyuncs.com)

#### NAS

* Create a new file system
* Rename the NAS into **'gitlab&#95;ha&#95;nas'** 
* Add one mount point to each public Vswitch (ex: 7c9b6481b5-uwy77.ap-southeast-1.nas.aliyuncs.com and 7c9b6481b5-uwy77.ap-southeast-1.nas.aliyuncs.com)
* Use the default permission group (allow all)

### Gitlab HA application
```bash
terraform init solutions/gitlab_ha
terraform plan|apply \
  -var-file=parameters/gitlab_ha.tfvars \
  -state=states/gitlab_ha.tfstate \
  solutions/gitlab_ha
```

## Issues
If you have any issues related to gitlab-ctl reconfigure (step: gitlab::database_migrations), please create the db manually by following the [help doc of RDS](https://www.alibabacloud.com/help/doc-detail/26156.htm).