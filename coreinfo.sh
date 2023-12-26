#!/bin/bash

check_prerequisites() {
  required_commands=("turbostat" "lscpu" "bc" "grep" "watch")

  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "Error: $cmd command not found. Please install it before running this script."
      exit 1
    fi
  done
}

# CPU name and core #
cpu_info() {
  echo -e "\033[1;34m$(cat /proc/cpuinfo | grep "model name" | head -n 1 | sed -e 's/model name[[:space:]]*: //; s/(R)//; s/(TM)//')\033[0m"
  echo -e "$(nproc) Cores\n"
}

cpu_package_temp() {
  package_temp=$(sensors | awk '/Package id 0:/ {print $4}')
  echo -e "\tPkgTemp: $package_temp"
}

cpu_power() {
  pkg_watt=$(sudo turbostat --Summary -q -s PkgWatt -n 1 -i 1 | tail -n 1)
  echo -n "PkgWatt: $pkg_watt"
}

# CPU freq
cpu_freq() {
  echo -e "\nCPU Freq:"
  
  # Get min max CPU freq
  min_freq=$(lscpu | grep min | awk '{print $4}')
  max_freq=$(lscpu | grep max | awk '{print $4}')
  
  # Get curr CPU freq
  current_freqs=($(cat /proc/cpuinfo | grep "cpu MHz" | awk '{print $4}'))

  # Display curr CPU freq
  for ((i=0; i<${#current_freqs[@]}; i++)); do
    freq="${current_freqs[i]}"
    core_number=$((i+1))

    # Check if the frequency is 70% or below the max
    if (( $(echo "$freq <= 0.8 * $max_freq" | bc -l) )); then
      # Blue text if below
      echo -e "\033[1;32mCore $core_number:\t\t${freq} MHz\033[0m"
    else
      # Red text if above 70%
      echo -e "\033[1;31mCore $core_number:\t\t${freq} MHz\033[0m"
    fi
  done
}

# -h help options
display_help() {
  echo "Usage: $0 [-t refresh_interval] [-1]"
  echo "Options:"
  echo "  -t refresh_interval   Specify the refresh interval in seconds (float)"
  echo "  -1                    Runs script once"
  echo "  -h                    Display this help message"
  exit 0
}


main() {
  local refresh_interval=2  # Default refresh interval
  local run_once=false

  # Check for command-line arguments
  while getopts ":t:1h" opt; do
    case $opt in
      t)
        refresh_interval=$OPTARG
        ;;
      1)
        run_once=true
        ;;
      \?)
        display_help
        exit 1
        ;;
    esac
  done

  check_prerequisites

  clear
  cpu_info

  # Continuously show freq and load changes
  while true; do
    clear
    cpu_info
    cpu_power
    cpu_package_temp
    cpu_freq
    sleep "$refresh_interval"

    # Exit if -1 option is used
    $run_once && exit 0
  done
}

# Run the main function
main "$@"
