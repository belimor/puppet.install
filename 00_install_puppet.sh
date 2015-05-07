#!/bin/bash

echo -e "\n=======> Installing curl wget git tmux"
apt-get update
apt-get install -y curl wget git tmux 

echo -e "\n=======> Enabling security updates"
sudo apt-get install -y unattended-upgrades
echo """
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
""" | sudo tee /etc/apt/apt.conf.d/20auto-upgrades

echo -e "\n=======> Check your /etc/hosts"
cat /etc/hosts
