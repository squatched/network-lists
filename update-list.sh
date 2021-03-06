#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
IP_OR_CIDR_REGEX="(?:[[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}(?:\/[[:digit:]]{1,3})?"

target_ipset="$1"
shift

echo "Getting whitelist(s)..."
echo "" >/tmp/merged-list.txt

while [[ ${#} -gt 0 ]]; do
	curl -o "/tmp/${1}" "https://raw.githubusercontent.com/squatched/network-lists/master/lists/${1}"
	cat "/tmp/${1}" >>/tmp/merged-list.txt
	rm "/tmp/${1}"
	shift
done

echo Sorting the merged list and removing any dupes...
sort -u /tmp/merged-list.txt >/tmp/sorted-list.txt

get_list_script() {
	echo "create temp-ipset nethash --hashsize 1024 --probes 4 --resize 20"
	cat /tmp/sorted-list.txt | grep -Pv ${IP_OR_CIDR_REGEX} | sed -e "s/^/add temp-ipset [/g" -e "s/$/]/g"
	cat /tmp/sorted-list.txt | grep -P ${IP_OR_CIDR_REGEX} | sed -e "s/^/add temp-ipset /g"
}

# Create the ip set
get_list_script >/tmp/list-ipset.txt
sudo ipset -exist restore </tmp/list-ipset.txt
sudo ipset swap temp-ipset ${target_ipset}
sudo ipset destroy temp-ipset

# Cleanup cleanup, everybody, everywhere
echo Cleanup...
rm /tmp/merged-list.txt
rm /tmp/sorted-list.txt
rm /tmp/list-ipset.txt
