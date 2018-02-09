# Deploy Gitlab HA on Alibaba Cloud with Terraform

At Alibaba Cloud, we use Terraform to provide fast demos to our customers.
I truly believe that the infrasture-as-code is the quick way to leverage a public cloud provider services. Instead of clicking on the Web Console UI, the logic of the infrasture-as-code allows us to define more accuratly each used services, automate the entire infrastructure and version it with a versionning control (git).

## High-level design

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
## Managed services (manual setup)
### ApsaraDB for Redis

Add a whitelist group ips with 192.168.1.0/24,192.168.2.0/24

Then you can get the Connection Address (host) on the instance information page (ex: r-gs5e52f3dd2aa6f4.redis.singapore.rds.aliyuncs.com)

### NAS

* Create a file system
* Add one mount point to each public Vswitch (ex: 7aa7048405-enk90.ap-southeast-1.nas.aliyuncs.com and 7aa7048405-txk20.ap-southeast-1.nas.aliyuncs.com)