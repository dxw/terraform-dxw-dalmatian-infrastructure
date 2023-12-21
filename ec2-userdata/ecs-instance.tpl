#!/bin/bash

# Mount docker storage volume
sudo mkfs -t xfs ${docker_storage_volume_device_name}
sudo mkdir -p /var/lib/docker
sudo mount -o prjquota ${docker_storage_volume_device_name} /var/lib/docker

# Configure ECS with Docker
echo ECS_CLUSTER="${ecs_cluster_name}" >> /etc/ecs/ecs.config
echo ECS_ENGINE_AUTH_TYPE=dockercfg >> /etc/ecs/ecs.config
echo 'ECS_ENGINE_AUTH_DATA={"https://index.docker.io/v1/": { "auth": "${dockerhub_token}", "email": "${dockerhub_email}"}}' >> /etc/ecs/ecs.config
# Set low task cleanup - reduces chance of docker thin pool running out of free space
echo "ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=15m" >> /etc/ecs/ecs.config

# Configure Docker options
sed -i s/OPTIONS/#OPTIONS/ /etc/sysconfig/docker
echo 'OPTIONS="--default-ulimit nofile=1024:4096 --storage-opt overlay2.size=${docker_storage_size}G"' >> /etc/sysconfig/docker
sudo service docker restart

# Install useful packages
sudo yum update -y

if ! command -v aws &> /dev/null
then
  sudo yum install -y aws-cli
fi

sudo yum install -y \
  jq \
  rsync