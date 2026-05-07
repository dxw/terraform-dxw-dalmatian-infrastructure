#!/bin/bash

# Install useful packages
sudo dnf -y update --security

if ! command -v aws &> /dev/null
then
  sudo dnf -y install aws-cli
fi

sudo dnf -y install \
  jq \
  rsync \
  vim

# Add kernel live patching
sudo dnf -y install kpatch-dnf
sudo dnf -y install kernel-livepatch auto

sudo dnf -y install kpatch-runtime
sudo systemctl enable --now --no-block kpatch.service
