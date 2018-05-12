#!/bin/bash

logfile="/var/log/aws_userdata.log"

echo "$(date):start of userdata script"  >> $logfile  2>&1

# Mount EBS volume /data/artifactory
/sbin/mkfs -t ext4 /dev/xvdf >> $logfile  2>&1
/bin/mkdir -p /data/artifactory >> $logfile  2>&1
/bin/echo "/dev/xvdf /data/artifactory ext4 defaults,nofail 0 2" >> /etc/fstab

# Mount EBS volume /data/postgresql
/sbin/mkfs -t ext4 /dev/xvdh >> $logfile  2>&1
/bin/mkdir -p /data/postgresql >> $logfile  2>&1
/bin/echo "/dev/xvdh /data/postgresql ext4 defaults,nofail 0 2" >> /etc/fstab

# Mount All EBS volumes
/bin/mount -av >> $logfile  2>&1

rf -rf /data/artifactory/* /data/postgresql/*

# Install docker 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce  >> $logfile  2>&1

# Install Docker compose
curl -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname \
-s`-`uname -m` -o /usr/local/bin/docker-compose >> $logfile  2>&1

chmod +x /usr/local/bin/docker-compose >> $logfile  2>&1

mkdir /opt/artifactory-docker-compose

## source of compose file
## https://github.com/JFrogDev/artifactory-docker-examples/blob/master/docker-compose/artifactory-oss-postgresql.yml
cat > /opt/artifactory-docker-compose/docker-compose.yml << EOF
version: '2'
services:
  postgresql:
    image: docker.bintray.io/${postgres_docker_image}
    container_name: postgresql
    ports:
     - 5432:5432
    environment:
     - POSTGRES_DB=artifactory
     # The following must match the DB_USER and DB_PASSWORD values passed to Artifactory
     - POSTGRES_USER=artifactory
     - POSTGRES_PASSWORD=${postgres_password}
    volumes:
     - /data/postgresql/data:/var/lib/postgresql/data
    restart: always
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000
  artifactory:
    image: docker.bintray.io/jfrog/${artifactory_docker_image}
    container_name: artifactory
    ports:
     - 80:8081
    depends_on:
     - postgresql
    links:
     - postgresql
    volumes:
     - /data/artifactory/data:/var/opt/jfrog/artifactory
    environment:
     - DB_TYPE=postgresql
     # The following must match the POSTGRES_USER and POSTGRES_PASSWORD values passed to PostgreSQL
     - DB_USER=artifactory
     - DB_PASSWORD=${postgres_password}
     # Add extra Java options by uncommenting the following line
     #- EXTRA_JAVA_OPTIONS=-Xmx4g
    restart: always
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000
EOF

cd /opt/artifactory-docker-compose
docker-compose up -d >> $logfile  2>&1

docker ps -a >> $logfile  2>&1

echo "$(date):end of userdata script"  >> $logfile  2>&1
