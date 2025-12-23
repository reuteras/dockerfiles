#!/bin/bash

echo "Add Microsoft package repo."
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb && rm -f packages-microsoft-prod.deb
echo "Update apt and install SysmonForLinux."
sudo apt-get update
sudo apt-get install sysmonforlinux
echo "Install sysmon for Linux and reload systemd."
sudo sysmon -accepteula -i SysmonForLinux/SysmonForLinux-CollectAll-Config.xml 
sudo systemctl daemon-reload 
