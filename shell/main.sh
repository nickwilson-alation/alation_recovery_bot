#!/bin/bash

# Function to display usage and help
display_help() {
  echo "Usage: $0 [OPTIONS] <command>"
  echo "Commands:"
  echo "  recover                               Recovers an Alation instance from backup"
  echo "    -l <log_level>                      Sets log level (info, warning, debug)"
  echo "    -i <instance_name>                  Sets the instance name, which is unique per Alation deployment"
  echo "    -e <owner_email_address>            Sets the first user owner's email address for the Alation instance"
  echo "  destroy                               Destroy a resource"
  echo "    -l <log_level>                      Set log level (info, warning, debug)"
  echo "    -i <instance_name>                  The name of the instance to be destroyed"
  echo "Options:"
  echo "  -h                                    Display this help message"
}

# Parse command-line options and arguments
while getopts ":l:i:n:e:s:t:r:p:h" opt; do
  case $opt in
    l)
      log_level="$OPTARG"
      ;;
    i)
      instance_name="$OPTARG"
      ;;
    e)
      owner_email_address="$OPTARG"
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

