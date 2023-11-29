#!/usr/bin/bash

# by weissec
echo "  ___  ____  ____  ____  _____  __  _  _  ____  ____ "
echo " / __)(_  _)(  _ \(  _ \(  _  )(  )( \/ )( ___)(  _ |"
echo "( (__  _)(_  )(_) ))   / )(_)(  )(__\  /  )__)  )   |"
echo " \___)(____)(____/(_)\_)(_____)(____)\/  (____)(_)\_)"
echo "-------------- Bash IP Ranges resolver --------------"
echo
	
# Check file provided to make sure it is as expected and format it.
echo "* Checking user input.."

filei="$1"
output="$2"

# Check if first argument was provided
if [ -z "$filei" ]
	then
		echo
		echo "[ERROR] Please enter the path of the file containing the list of IP addresses/ranges."
		echo
		echo "This tool creates a list of ordered IP addresses from a list of mixed ranges."
		echo "WHY? Useful if you need a list of all the IP addresses included in various ranges."
		echo
		echo "USAGE: ./cidrolver.sh list.txt output.txt"
		echo
                echo "(Output file path is optional)"
		echo
		echo "The list can include a mixture of IP/Ranges such as:"
		echo " - 10.0.0.1"
		echo " - 10.0.0.0/24"
		echo " - 10.0.0.1-255"
		echo " - 10.0.0.1-10.0.0.255"
		echo
		exit
fi

# Check if any output file provided
if [ -z "$output" ]
	then
		output="resolved.txt"
fi

# Check if file exist
if [ ! -f $filei ]; then
	echo -e "[ERROR] The specified file does not exist. \n"
	exit
fi

# Check if list is empty
targetnum=$(wc -l < $filei)

if [ ${targetnum} -eq 0 ]; then
	echo "[ERROR] The file specified looks empty."
	echo
	echo "The list can include a mixture of IP/Ranges such as:"
	echo " - 10.0.0.1"
	echo " - 10.0.0.0/24"
	echo " - 10.0.0.1-255"
	echo " - 10.0.0.1-10.0.0.255"
	echo
	exit
fi

# Check for invalid characters
for ip in $(cat $filei); do
	if [[ "$ip" =~ [a-zA-Z] ]]
		then
    		echo "[ERROR] The file provided contains invalid targets."
    		echo
		echo " Please make sure the files only contains IP Addresses or ranges."
		echo " Accepted values example:"
		echo " - 10.0.0.1"
		echo " - 10.0.0.0/24"
		echo " - 10.0.0.1-255"
		echo " - 10.0.0.1-10.0.0.255"
		echo
		exit
	fi
done

# Formatting entries
# Replace , with \n
# Remove spaces 
echo "* Creating temporary files.."

cat $filei | tr "," "\\n" | tr -d " " > list.tmp

echo "* Formatting entries.."
sed -e 's/\s\+/\n/g' list.tmp > $output

echo "* Resolving ranges.."
# Check for CIDR Ranges

# Resolving type: 10.11.1.1-10.11.1.255, 10.11.1.1-255
grep "-" "$output" > list.tmp

# Starting to resolve the addresses
for ip in $(cat "list.tmp"); do

	# Check what type of range
	rangetype=$(echo $ip | cut -d "-" -f2)
	before=$(echo $ip | cut -d '.' -f1-3)
	primo=$(echo $ip | cut -d "-" -f1 | cut -d "." -f4)

	if [[ ${#rangetype} -lt 4 ]]; then
    		ultimo=$(echo $ip | cut -d "-" -f2)
	else
		after=$(echo $rangetype | cut -d '.' -f1-3)
		if [ "$before" != "$after" ]; then
			echo -e "[ERROR] Invalid range found. Please check your file again. \n"
			menu
		fi

		ultimo=$(echo $rangetype | cut -d '.' -f4)
	fi

	for ((i=$primo; i<=$ultimo; i++)); do
		echo $before'.'$i >> $output
	done

done

# Resolving type: 10.11.1.1/24
grep "/" "$output" > list.tmp

for ip in $(cat "list.tmp"); do

	# Assign each octet to variable
	# $w.$x.$y.$z/$mask

	w=$(echo $ip | cut -d '.' -f1)
	x=$(echo $ip | cut -d '.' -f2)
	y=$(echo $ip | cut -d '.' -f3)
	z=$(echo $ip | cut -d '.' -f4 | cut -d '/' -f1)
	mask=$(echo $ip | cut -d '/' -f2)

	# Check if each octet is a number (no characters, no symbols) and not > 255

	if [[ ! $w =~ ^[0-9]+$ ]]
	then
		echo -e "[ERROR] Invalid range found. Please check your file again. \n"
		menu
	fi
	if [[ ! $x =~ ^[0-9]+$ ]]
	then
		echo -e "[ERROR] Invalid range found. Please check your file again. \n"
		menu
	fi
	if [[ ! $y =~ ^[0-9]+$ ]]
	then
		echo -e "[ERROR] Invalid range found. Please check your file again. \n"
		menu
	fi
	if [[ ! $z =~ ^[0-9]+$ ]]
	then
		echo -e "[ERROR] Invalid range found. Please check your file again. \n"
		menu
	fi
	if [[ ! $mask =~ ^[0-9]+$ ]]
	then
		echo -e "[ERROR] Invalid range found. Please check your file again. \n"
		menu
	fi
		# Check if /mask is beetween ($mask < 16 || $mask > 32) (also no characters, symbols)

	if [[ $mask -lt 16 ]] || [[ $mask -gt 32 ]]
	then
		echo -e "[ERROR] Invalid range found. Please check your file again. \n"
		menu
	fi

	# Math start

	num=$((2 ** (32 - $mask)))

	for (( i=$num; $i>0; i-- )); do

		echo $w'.'$x'.'$y'.'$z >> $output
		(( z++ ))

		if [[ $z -gt 255 ]]; then
			(( y++ ))
			z=0
		fi
		if [[ $y -gt 255 ]]; then
			(( x++ ))
			y=0
		fi
		if [[ $x -gt 255 ]]; then
			(( w++ ))
			x=0
		fi
	done
done

# Remove ranges from targets
sed -i '/-/d' $output
sed -i '/\//d' $output

# Sort and Uniq the targets
echo "* Sorting the results.."
cat $output > list.tmp
echo "* Saving results.."
sort -u list.tmp > $output
echo "* Removing temporary files.."
rm ./list.tmp
echo "* [DONE] Results saved in '$output'"
echo
echo "Total number of IP Addresses: "$(wc -l < $output)
# Done
exit

