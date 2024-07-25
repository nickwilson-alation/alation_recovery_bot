#!/bin/bash

# Function to display usage and help
display_help() {
  echo "Usage: $0 [OPTIONS] <command>"
  echo "Commands:"
  echo "  recover                               Recovers an Alation instance from backup"
  echo "    -l <log_level>                      Sets log level (info, warning, debug)"
  echo "    -l <log_level>                      Sets log level (info, warning, debug)"
  echo "    -r <rpm_file>                       Path to the Alation installer rpm file"
  echo "    -i <license_file>                   Path to the Alation license file"
  echo "    -b <backup_file>                    Path to the Alation backup file"
  echo "    -e <eb_backup_file>                 Path to the Alation event bus backup file"
  echo "  destroy                               Destroys a previously recovered Alation instance and EC2"
  echo "    -l <log_level>                      Sets log level (info, warning, debug)"
  echo "    -n <unique_environment_name>        Unique name of the environment to be destroyed"
  echo "Options:"
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

# Check that a proper command is provided as first arg
if [ -z "$1" ] || [ "$1" != "recover" ] || [ "$1" != "destroy" ]; then
  echo "Invalid command: $1"
  display_help
  exit 1
fi

command=$1
shift

# Default values for args
log_level="warning"
rpm_file=""
license_file=""
backup_file=""
eb_backup_file=""

# Parse command-line options and arguments
while getopts ":l:r:i:b:e:n" opt; do
  case $opt in
    l)
      log_level="$OPTARG"
      ;;
    r)
      rpm_file="$OPTARG"
      ;;
    i)
      license_file="$OPTARG"
      ;;
    b)
      backup_file="$OPTARG"
      ;;
    e)
      eb_backup_file="$OPTARG"
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

verify_terraform

case $command in
  recover)
    # Check required arguments for 'recover' command
    if [ -z "$rpm_file" ] || [ -z "$license_file" ] || [ -z "$backup_file" ] || [ -z "$eb_backup_file" ]; then
      echo "Error: Missing required argument(s) for 'recover' command."
      display_help
      exit 1
    fi
    # # Check if the email ends with @alation.com
    # if [[ "$alation_owner_email_address" != *@alation.com ]]; then
    #   echo "Error: Alation owner email address must be an Alation address (must end in '@alation.com')"
    #   exit 1
    # fi
    # do_create
    # ;;
  *)
    echo "Error: Invalid command: $command"
    display_help
    exit 1
    ;;
esac