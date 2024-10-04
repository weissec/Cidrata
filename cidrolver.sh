#!/bin/bash

#!/usr/bin/bash

# by weissec
echo "  ___  ____  ____  ____  _____  __  _  _  ____  ____ "
echo " / __)(_  _)(  _ \(  _ \(  _  )(  )( \/ )( ___)(  _ |"
echo "( (__  _)(_  )(_) ))   / )(_)(  )(__\  /  )__)  )   |"
echo " \___)(____)(____/(_)\_)(_____)(____)\/  (____)(_)\_)"
echo "-------------- Bash IP Ranges resolver --------------"
echo

# Check for required dependencies
if ! command -v ipcalc &> /dev/null; then
    echo "[ERROR] 'ipcalc' is not installed. Please install it to proceed."
    exit 1
fi

# Check if input file is provided
if [ -z "$1" ]; then
    	echo "[ERROR] Please provide an input file containing IP addresses and ranges."
    	echo
	echo "Usage: $0 input_file [output_file]"
	echo
	echo "The input file can include a mixture of IP/Ranges such as:"
	echo " - 10.0.0.1"
	echo " - 10.0.0.0/24"
	echo " - 10.0.0.1-255"
	echo " - 10.0.0.1-10.0.0.255"
    exit 1
fi

input_file="$1"
output_file="${2:-resolved_ips.txt}"  # Output file defaults to 'resolved_ips.txt' if not provided

echo "Calculating..."

# Temporary file for storing resolved IPs
tmpfile=$(mktemp)
trap "rm -f $tmpfile" EXIT

# Function to expand a CIDR range
expand_cidr() {
    local cidr="$1"
    # Extract the network address and broadcast address
    local network=$(ipcalc -n "$cidr" | grep -oE "Network:.*" | awk '{print $2}')
    local broadcast=$(ipcalc -b "$cidr" | grep -oE "Broadcast:.*" | awk '{print $2}')

    # Convert network and broadcast IPs to numeric format
    IFS='.' read -r net1 net2 net3 net4 <<< "$network"
    IFS='.' read -r bro1 bro2 bro3 bro4 <<< "$broadcast"

    net_num=$(( (net1 << 24) + (net2 << 16) + (net3 << 8) + net4 ))
    bro_num=$(( (bro1 << 24) + (bro2 << 16) + (bro3 << 8) + bro4 ))

    # Generate IP addresses in the range from network to broadcast
    for ((i=net_num; i<=bro_num; i++)); do
        echo "$(( (i >> 24) & 255 )).$(( (i >> 16) & 255 )).$(( (i >> 8) & 255 )).$(( i & 255 ))"
    done
}

# Function to expand dash-separated IP ranges
expand_range() {
    local range="$1"
    local start_ip end_ip base_ip start_range end_range

    # Check for single-octet range format (e.g., 210.221.213.2-56)
    if [[ "$range" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)-([0-9]+)$ ]]; then
        base_ip="${BASH_REMATCH[1]}"
        start_range="${BASH_REMATCH[2]}"
        end_range="${BASH_REMATCH[3]}"
        
        # Validate end range to ensure it is within the valid range for octets
        if (( end_range < 0 || end_range > 255 )); then
            echo "[ERROR] Invalid range: $range" >&2
            return
        fi
        
        for ((i=start_range; i<=end_range; i++)); do
            echo "$base_ip.$i"
        done

    # Check for full IP range format (e.g., 210.221.218.0-210.221.218.15)
    elif [[ "$range" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        start_ip="${BASH_REMATCH[1]}"
        end_ip="${BASH_REMATCH[2]}"

        # Convert start and end IPs to a numeric format using integer arithmetic
        IFS='.' read -r start1 start2 start3 start4 <<< "$start_ip"
        IFS='.' read -r end1 end2 end3 end4 <<< "$end_ip"

        start_range=$(( (start1 << 24) + (start2 << 16) + (start3 << 8) + start4 ))
        end_range=$(( (end1 << 24) + (end2 << 16) + (end3 << 8) + end4 ))

        for ((i=start_range; i<=end_range; i++)); do
            echo "$(( (i >> 24) & 255 )).$(( (i >> 16) & 255 )).$(( (i >> 8) & 255 )).$(( i & 255 ))"
        done
    else
        echo "[ERROR] Invalid range: $range" >&2
    fi
}

# Read input file and process each line
while IFS= read -r line; do
    # Trim whitespace
    line=$(echo "$line" | xargs)

    # Skip empty lines
    [ -z "$line" ] && continue

    # If it's a CIDR range (e.g., 10.0.0.0/24)
    if [[ "$line" =~ / ]]; then
        expand_cidr "$line" >> "$tmpfile"

    # If it's a dash-separated range (e.g., 10.0.0.1-255 or 10.0.0.1-10.0.0.255)
    elif [[ "$line" =~ - ]]; then
        expand_range "$line" >> "$tmpfile"

    # Otherwise, assume it's a single IP address
    else
        echo "$line" >> "$tmpfile"
    fi
done < "$input_file"

# Sort IP addresses correctly and remove duplicates
sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 "$tmpfile" | uniq > "$output_file"

# Output the result
echo "[DONE] Results saved in '$output_file'"
echo "Total number of IP Addresses: $(wc -l < "$output_file")"
