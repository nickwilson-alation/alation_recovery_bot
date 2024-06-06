#!/bin/bash

# Function to display usage and help
display_help() {
  echo "Usage: $0 [OPTIONS] <command>"
  echo "Commands:"
  echo "  recover                               Recovers an Alation instance from backup"
  echo "  destroy                               Destroys a previously recovered Alation instance and EC2"
  echo "Options:"
  echo "  -l <log_level>                        Log level (info, warning, debug)"
  echo "  -r <rpm_file>                         Path to the Alation installer rpm file"
  echo "  -i <license_file>                     Path to the Alation license file"
  echo "  -b <backup_file>                      Path to the Alation backup file"
  echo "  -e <eb_backup_file>                   Path to the Alation event bus backup file"
  echo "  -n <unique_environment_name>          Unique name of the environment"
  echo "  -g <region>                           AWS region"
  echo "  -u <base_url>                         Base URL"
  echo "  -s <ec2_root_size>                    EC2 root size"
  echo "  -d <ec2_data_size>                    EC2 data size"
  echo "  -k <ec2_backup_size>                  EC2 backup size"
  echo "  -a <ec2_ami>                          EC2 AMI ID"
  echo "  -t <ec2_itype>                        EC2 instance type"
  echo "  -h                                    Display this help message"
}

verify_terraform() {
  # Check if Terraform is installed
  if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install before running this script: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli."
    echo -e "\n"
    exit 1
  fi

  # Verify terraform Install
  echo -e "\n"
  echo "Verifying terraform install..."
  terraform -v
}

# Check that a proper command is provided as the first argument
if [ -z "$1" ] || { [ "$1" != "recover" ] && [ "$1" != "destroy" ]; }; then
  echo "Error: Invalid command: $1"
  display_help
  exit 1
fi

command=$1
shift

# Parse command-line options and arguments
while getopts ":l:r:i:b:e:n:g:u:s:d:k:a:t:h" opt; do
  case $opt in
    l) log_level="$OPTARG" ;;
    r) rpm_file="$OPTARG" ;;
    i) license_file="$OPTARG" ;;
    b) backup_file="$OPTARG" ;;
    e) eb_backup_file="$OPTARG" ;;
    n) unique_environment_name="$OPTARG" ;;
    g) region="$OPTARG" ;;
    u) base_url="$OPTARG" ;;
    s) ec2_root_size="$OPTARG" ;;
    d) ec2_data_size="$OPTARG" ;;
    k) ec2_backup_size="$OPTARG" ;;
    a) ec2_ami="$OPTARG" ;;
    t) ec2_itype="$OPTARG" ;;
    h) display_help; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; display_help; exit 1 ;;
  esac
done

# Prompt for email and password
read -p "Enter owner email address: " owner_email_address
read -s -p "Enter owner password: " owner_password
echo

# Debug: Print the values of the variables
echo "log_level: $log_level"
echo "rpm_file: $rpm_file"
echo "license_file: $license_file"
echo "backup_file: $backup_file"
echo "eb_backup_file: $eb_backup_file"
echo "unique_environment_name: $unique_environment_name"
echo "region: $region"
echo "base_url: $base_url"
echo "ec2_root_size: $ec2_root_size"
echo "ec2_data_size: $ec2_data_size"
echo "ec2_backup_size: $ec2_backup_size"
echo "ec2_ami: $ec2_ami"
echo "ec2_itype: $ec2_itype"

# Verify required arguments for 'recover' command
if [ "$command" == "recover" ]; then
  if [ -z "$log_level" ] || [ -z "$rpm_file" ] || [ -z "$license_file" ] || [ -z "$backup_file" ] || [ -z "$eb_backup_file" ] || [ -z "$unique_environment_name" ] || [ -z "$region" ] || [ -z "$base_url" ] || [ -z "$ec2_root_size" ] || [ -z "$ec2_data_size" ] || [ -z "$ec2_backup_size" ] || [ -z "$ec2_ami" ] || [ -z "$ec2_itype" ]; then
    echo "Error: Missing required argument(s) for 'recover' command."
    display_help
    exit 1
  fi
fi

# Verify terraform installation
verify_terraform

case $command in
  recover)
    echo "Recovering Alation instance..."
    # terraform apply -var "log_level=$log_level" \
    #                 -var "rpm_file=$rpm_file" \
    #                 -var "license_file=$license_file" \
    #                 -var "backup_file=$backup_file" \
    #                 -var "eb_backup_file=$eb_backup_file" \
    #                 -var "unique_environment_name=$unique_environment_name" \
    #                 -var "owner_email_address=$owner_email_address" \
    #                 -var "owner_password=$owner_password" \
    #                 -var "region=$region" \
    #                 -var "base_url=$base_url" \
    #                 -var "ec2_root_size=$ec2_root_size" \
    #                 -var "ec2_data_size=$ec2_data_size" \
    #                 -var "ec2_backup_size=$ec2_backup_size" \
    #                 -var "ec2_ami=$ec2_ami" \
    #                 -var "ec2_itype=$ec2_itype"
    ;;
  destroy)
    if [ -z "$unique_environment_name" ]; then
      echo "Error: Missing required argument(s) for 'destroy' command."
      display_help
      exit 1
    fi
    echo "Destroying Alation instance..."
    # terraform destroy -var "unique_environment_name=$unique_environment_name"
    ;;
  *)
    echo "Error: Invalid command: $command"
    display_help
    exit 1
    ;;
esac
