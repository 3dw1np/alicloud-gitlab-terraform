#!/bin/bash

echo "Start installation / setup of Gitlab Application ..." >> /var/log/bootstrap.log 2>&1
cd /tmp
curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh >> /var/log/bootstrap.log 2>&1
bash /tmp/script.deb.sh >> /var/log/bootstrap.log 2>&1

apt-get update >> /var/log/bootstrap.log 2>&1
apt-get -y install openssh-server nfs-common gitlab-ce postgresql-client >> /var/log/bootstrap.log 2>&1

# Mount NAS
mkdir /gitlab-data
mount -t nfs ${NAS_MOUNT_POINT}:/ /gitlab-data >> /var/log/bootstrap.log 2>&1
echo "${NAS_MOUNT_POINT}:/ /gitlab-data nfs4 defaults,soft,rsize=1048576,wsize=1048576,noatime,nofail,lookupcache=positive 0 2" >> /etc/fstab

# Created shared directories
mkdir -p /gitlab-data/home/.ssh /gitlab-data/uploads /gitlab-data/shared /gitlab-data/builds /gitlab-data/git-data

# Gitlab config file
cat << EOF > /etc/gitlab/gitlab.rb
external_url 'http://127.0.0.1'

git_data_dirs({"default" => {"path": "/gitlab-data/git-data"}})
user['home'] = '/gitlab-data/home'
gitlab_rails['uploads_directory'] = '/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/gitlab-data/builds'

# Prevent GitLab from starting if NFS data mounts are not available
high_availability['mountpoint'] = '/gitlab-data'

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
gitlab_rails['auto_migrate'] = false

# Redis connection details
gitlab_rails['redis_port'] = '6379'
gitlab_rails['redis_host'] = '${REDIS_CONNECT}' # IP/hostname of Redis server
gitlab_rails['redis_password'] = '${REDIS_PASSWORD}'

# Ensure UIDs and GIDs match between servers for permissions via NFS
user['uid'] = 9000
user['gid'] = 9000
web_server['uid'] = 9001
web_server['gid'] = 9001
registry['uid'] = 9002
registry['gid'] = 9002

EOF

if [ "${INSTANCE_INDEX}" == "0" ]; then
	# First GitLab application server create the database
	PGHOST=${DB_CONNECT} \
	PGPORT=3433 \
	PGUSER=gitlab \
	PGPASSWORD=${DB_PASSWORD} \
	createdb -w -O gitlab gitlabhq_production
	# Run gitlab configuration
	gitlab-ctl reconfigure >> /var/log/bootstrap.log 2>&1
	# Initialize the database
	gitlab-rake db:migrate >> /var/log/bootstrap.log 2>&1
else
	sleep 120
	# Run gitlab configuration
	gitlab-ctl reconfigure >> /var/log/bootstrap.log 2>&1
fi

echo "End installation / setup of Gitlab Application ..." >> /var/log/bootstrap.log 2>&1