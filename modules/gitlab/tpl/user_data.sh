#!/bin/bash

echo "Start installation / setup of Gitlab Application ..." >> /var/log/bootstrap.log 2>&1
cd /tmp
curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh >> /var/log/bootstrap.log 2>&1
bash /tmp/script.deb.sh >> /var/log/bootstrap.log 2>&1

apt-get update >> /var/log/bootstrap.log 2>&1
apt-get -y install openssh-server nfs-common gitlab-ce >> /var/log/bootstrap.log 2>&1

mkdir /gitlab-data
mkdir -p /gitlab-data/home/.ssh /gitlab-data/uploads /gitlab-data/shared /gitlab-data/builds /gitlab-data/git-data
mount -t nfs4 ${NAS_MOUNT_POINT}:/ /gitlab-data >> /var/log/bootstrap.log 2>&1
echo "${NAS_MOUNT_POINT}:/ /gitlab-data nfs4 defaults,soft,rsize=1048576,wsize=1048576,noatime,nobootwait,lookupcache=positive 0 2" >> /etc/fstab

touch /gitlab-data/home/.ssh/authorized_keys
chmod -R git:git /gitlab-data/home/.ssh/

cat << EOF > /etc/gitlab/gitlab.rb
external_url 'http://127.0.0.1'

git_data_dirs({"default" => {"path": "/gitlab-data/git-data"}})
user['home'] = '/gitlab-data/home'
gitlab_rails['uploads_directory'] = '/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/gitlab-data/builds'

# Remove permissions management because no_root_squash mode can't be setup in NAS
# Avoid Errno::EPERM: 'root' cannot chown /var/opt/gitlab/git-data. If using NFS mounts you will need to re-export them in 'no_root_squash' mode and try again.
manage_storage_directories['enable'] = false

# Prevent GitLab from starting if NFS data mounts are not available
# high_availability['mountpoint'] = '/var/opt/gitlab/git-data'

# Disable some components
postgresql['enable'] = false
bootstrap['enable'] = true
nginx['enable'] = true
unicorn['enable'] = true
sidekiq['enable'] = true
redis['enable'] = false
prometheus['enable'] = true
gitaly['enable'] = true
gitlab_workhorse['enable'] = true
mailroom['enable'] = true

# PostgreSQL connection details
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = '${DB_CONNECT}' # IP/hostname of database server
gitlab_rails['db_port'] = '3433'
gitlab_rails['db_password'] = '${DB_PASSWORD}'

# Redis connection details
gitlab_rails['redis_port'] = '6379'
gitlab_rails['redis_host'] = '${REDIS_CONNECT}' # IP/hostname of Redis server
gitlab_rails['redis_password'] = '${REDIS_PASSWORD}'
EOF

gitlab-ctl reconfigure >> /var/log/bootstrap.log 2>&1

echo "End installation / setup of Gitlab Application ..." >> /var/log/bootstrap.log 2>&1