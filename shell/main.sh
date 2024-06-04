#!/bin/bash

# Function to display usage and help
display_help() {
  echo "Usage: $0 [OPTIONS] <command>"
  echo "Commands:"
  echo "  recover                               Recovers an Alation instance from backup"
  echo "  destroy                               Destroys a previously recovered Alation instance and EC2"
  echo "Options:"
  echo "  -c <config_file>                      Path to configuration file"
  echo "  -s <section>                          Section in the configuration file"
  echo "  -h                                    Display this help message"
}

verify_terraform() {
  # Check if Terraform is installed
  if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install before running this script: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli."
    echo -e "\n"
    exit
  fi

  # Verify terraform Install
  echo -e "\n"
  echo "Verifying terraform install..."
  terraform -v
}

# Load config file and section
CONFIG_FILE="shell/config.ini"
SECTION="default"
while getopts ":c:s:h" opt; do
  case $opt in
    c)
      CONFIG_FILE="$OPTARG"
      ;;
    s)
      SECTION="$OPTARG"
      ;;
    h)
      display_help
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      display_help
      exit 1
      ;;
  esac
done

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Configuration file not found: $CONFIG_FILE"
  display_help
  exit 1
fi

# Source configuration file
source <(awk -F= -v section="$SECTION" '
  /^\[/{current_section = $1}
  current_section == "[" section "]" && /^[^#].*=.*$/ {
    gsub(/^[ \t]+|[ \t]+$/, "", $2);
    print $1 "=\"" $2 "\""
  }' $CONFIG_FILE)

# Prompt for email
read -p "Enter owner email address: " owner_email_address
echo

# Prompt for password
read -s -p "Enter owner password: " owner_password
echo

# Check that a proper command is provided as first arg
if [ -z "$1" ] || { [ "$1" != "recover" ] && [ "$1" != "destroy" ]; }; then
  echo "Invalid command: $1"
  display_help
  exit 1
fi

command=$1
shift

verify_terraform

case $command in
  recover)
    # Check required arguments for 'recover' command
    if [ -z "$rpm_file" ] || [ -z "$license_file" ] || [ -z "$backup_file" ] || [ -z "$eb_backup_file" ] || [ -z "$unique_environment_name" ] || [ -z "$owner_email_address" ] || [ -z "$owner_password" ] || [ -z "$region" ] || [ -z "$base_url" ] || [ -z "$ec2_root_size" ] || [ -z "$ec2_data_size" ] || [ -z "$ec2_backup_size" ] || [ -z "$ec2_ami" ] || [ -z "$ec2_itype" ]; then
      echo "Error: Missing required argument(s) for 'recover' command."
      display_help
      exit 1
    fi
    echo "Recovering Alation instance..."
    terraform apply -var "log_level=$log_level" \
                    -var "rpm_file=$rpm_file" \
                    -var "license_file=$license_file" \
                    -var "backup_file=$backup_file" \
                    -var "eb_backup_file=$eb_backup_file" \
                    -var "unique_environment_name=$unique_environment_name" \
                    -var "owner_email_address=$owner_email_address" \
                    -var "owner_password=$owner_password" \
                    -var "region=$region" \
                    -var "base_url=$base_url" \
                    -var "ec2_root_size=$ec2_root_size" \
                    -var "ec2_data_size=$ec2_data_size" \
                    -var "ec2_backup_size=$ec2_backup_size" \
                    -var "ec2_ami=$ec2_ami" \
                    -var "ec2_itype=$ec2_itype"
    ;;
  destroy)
    # Check required arguments for 'destroy' command
    if [ -z "$unique_environment_name" ]; then
      echo "Error: Missing required argument(s) for 'destroy' command."
      display_help
      exit 1
    fi
    echo "Destroying Alation instance..."
    terraform destroy -var "unique_environment_name=$unique_environment_name"
    ;;
  *)
    echo "Error: Invalid command: $command"
    display_help
    exit 1
    ;;
esac
