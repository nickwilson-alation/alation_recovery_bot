#!/bin/bash -xe

# Function to display usage and help
display_help() {
  echo "Usage: $0 [OPTIONS] <command>"
  echo "Commands:"
  echo "  recover                               Recovers an Alation instance from backup"
  echo "Options:"
  echo "  -l <log_level>                        Log level (info, warning, debug)"
  echo "  -r <rpm_file>                         Path to the Alation installer rpm file"
  echo "  -i <license_file>                     Path to the Alation license file"
  echo "  -b <backup_file>                      Path to the Alation backup file"
  echo "  -e <eb_backup_file>                   Path to the Alation event bus backup file"
  echo "  -u <base_url>                         Base URL"
  echo "  -h                                    Display this help message"
}

do_recover(){

  # Apply latest patches and tools
  yum update -y
  yum install -y jq
  yum install -y htop
  yum install -y telnet
  yum install -y nano

  # Update pip3
  pip3 install --upgrade pip

  # Create filesystems and mount them for Alation
  while [ ! -e /dev/sdd ]; do echo Waiting for EBS volume to attach; sleep 5; done
  while [ ! -e /dev/sdb ]; do echo Waiting for EBS volume to attach; sleep 5; done
  mkfs -t ext4 /dev/sdd
  mkfs -t ext4 /dev/sdb
  mkdir /data
  mkdir /backup
  echo "$(blkid /dev/sdd | awk '{print $2}') /data ext4 rw,nosuid,nodev,noexec" | tee -a /etc/fstab # auto mount on reboot
  echo "$(blkid /dev/sdb | awk '{print $2}') /backup ext4 rw,nosuid,nodev,noexec" | tee -a /etc/fstab # auto mount on reboot
  mount -a

  # Install Alation and start the service
  rpm -ivh $rpm_file
  service alation init /data /backup
  service alation start 

  # Restore from backup
  jailhome=/opt/alation/alation
  chroot_backup_home=/alation_backup
  backup_home=$jailhome/$chroot_backup_home
  mkdir $backup_home

  chroot "$jailhome" /bin/su - alation -c "alation_conf alation.backup.restore_file -s $backup_file" 
  chroot "$jailhome" /bin/su - alation -c "alation_conf alation.backup.eb_restore_file -s $eb_backup_file" 
  chroot "$jailhome" /bin/su - alationadmin -c "sudo chown alation:alation $backup_file" # TODO: Don't need to chroot this
  chroot "$jailhome" /bin/su - alationadmin -c "sudo chown alation:alation $eb_backup_file" # TODO: Don't need to chroot this
  chroot "$jailhome" /bin/su - alationadmin -c "echo "YES" | alation_action destructive_restore_all"

  # Disable SAML
  chroot "$jailhome" /bin/su - alation -c "alation_conf alation.authentication.saml.enabled -s false" 
  chroot "$jailhome" /bin/su - alation -c "alation_conf alation.authentication.builtin.enabled -s true" 
  chroot "$jailhome" /bin/su - alation -c "alation_action deploy_conf_all"

  # Overwrite base_url
  chroot "$jailhome" /bin/su - alation -c "alation_conf alation.install.base_url -s $base_url" 

  # Restart Alation to apply conf changes
  chroot "$jailhome" /bin/su - alation -c "alation_action restart_alation" 

  # Create admin user
  
  cp ./django_bootstrap.py $jailhome/opt/alation/django/rosemeta/one_off_scripts/django_bootstrap.py
  chown alation:alation $jailhome/opt/alation/django/rosemeta/one_off_scripts/django_bootstrap.py 
  chroot "$jailhome" /bin/su - alation -c "cd /opt/alation/django/rosemeta/one_off_scripts && python django_bootstrap.py -a createUser -e \"${owner_email_address}\" -p \"${owner_password}\""

  # Set up Hydra / container service for OCF
  sudo yum downgrade -y libseccomp # Workaround for AL-144347
  yum install -y $(ls /opt/alation/alation/opt/addons/alation_container_service/*.rpm)
  yum install -y /opt/alation/alation/opt/addons/hydra/hydra.rpm
  echo '[agent]' > /etc/hydra/hydra.toml # TODO: Check if this is still necessary
  echo 'address="localhost:81"' >> /etc/hydra/hydra.toml # TODO: Check if this is still necessary
  systemctl start docker
  service hydra start 

  # Rebuild ES Index
  chroot "$jailhome" /bin/su - alation -c "alation_action rebuild_es_index"

  # Re-sync OCF sources after restore
  chroot "$jailhome" /bin/su - alation -c "alation_ypireti sync"

}

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -o xtrace

# Parse command-line options and arguments
while getopts ":l:r:i:b:e:n:g:u:s:d:k:a:t:h" opt; do
  case $opt in
    l) log_level="$OPTARG" ;;
    r) rpm_file="$OPTARG" ;;
    i) license_file="$OPTARG" ;;
    b) backup_file="$OPTARG" ;;
    e) eb_backup_file="$OPTARG" ;;
    u) base_url="$OPTARG" ;;
    h) display_help; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; display_help; exit 1 ;;
  esac
done

# Prompt for email and password
read -p "Enter owner email address: " owner_email_address
read -s -p "Enter owner password: " owner_password
echo

# Verify required arguments for 'recover' command
if [ "$command" == "recover" ]; then
  if [ -z "$log_level" ] || [ -z "$rpm_file" ] || [ -z "$license_file" ] || [ -z "$backup_file" ] || [ -z "$eb_backup_file" ] || [ -z "$base_url" ]; then
    echo "Error: Missing required argument(s) for 'recover' command."
    display_help
    exit 1
  fi
fi

case $command in
  recover)
    echo "Recovering Alation instance..."
    do_recover
    ;;
esac