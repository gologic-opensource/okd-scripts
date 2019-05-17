#!/bin/bash
##Script pour preparer un noeud Openshift sur VM (avec Proxmox)
##Base sur https://docs.okd.io/3.9/install_config/install/host_preparation.html
#
#Par Julien Yensen Martin
#@ GoLogic
#
#Version: 0.1b

#set -e
#set -x

rpm -q nano
if [ "$?" -eq 1 ]; then
  echo "Partie 1 démarré, la machine sera redémarré à la fin"
  echo "N'oubliez pas de rouler le script une autre fois"
  echo "Le script sera disponible sous /root/"
  read -n1 -r -p "Press space to continue..." key

  #Fixing PATH
  echo 'pathmunge /bin:/sbin' > /etc/profile.d/okd.sh
  
  #UPDATE AND INSTALL REQUIRED PACKAGES
  yum update -y
  yum install wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct -y
  
  #### Selon les preferences
  yum install nano screen iperf mtr -y
  ####
  
  reboot
else
  echo "Partie 1 déjà complétée, démarrage de la partie 2"
  
  #Get the last Openshift Ansible files
  cd ~
  git clone https://github.com/openshift/openshift-ansible
  cd openshift-ansible
  git checkout release-3.9
  cd
  
  yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
  yum -y --enablerepo=epel install ansible pyOpenSSL
  
  #DOCKER SETUP
  yum install docker-1.13.1 -y
  rm -rf /etc/sysconfig/docker-storage-setup
  if [ -b "/dev/sdc" ]
  then
    blockdevice=sdc
  elif [ -b "/dev/vdc" ]
    blockdevice=vdc
  fi
  cat << EOF >> /etc/sysconfig/docker-storage-setup
DEVS=$blockdevice
VG=docker-vg
EOF
  docker-storage-setup 
  systemctl enable docker
  systemctl start docker
  systemctl is-active docker
fi
