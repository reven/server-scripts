#!/usr/bin/bash

# dyndns.sh
# a temporary solution to lack of linode support in the ddclient on OPNSense
#
# Checks external IP, compares to one in DNS and updates as needed
# Reven Nov22

# config
# our linode api token
TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# hard coded domain and record values
DOMAIN_ID=XXXXXX
RECORD_ID=XXXXXXX

# where are we
SCRIPT_LOC=$(pwd)

# make sure history file exists and create it if not
touch -a $SCRIPT_LOC/.ip.history

# load last value saved to file
{ read -rd '' IP_OLD<$SCRIPT_LOC/.ip.history;} 2>/dev/null

# get our current IP
IP_LOCAL=$(curl -s icanhazip.com)

# check to see that it is not empty. Should probably error check the format too
if [ -z "$IP_LOCAL" ]
then
  echo "$(date) [ERROR]: couldn't get our current IP" >> $SCRIPT_LOC/dyndns.log
  exit 2
fi

# check to see that it has changed
if [ "$IP_OLD" = "$IP_LOCAL" ]
then
  # No need to continue, our IP hasn't changed
  # We don't want our log file to become monsterous if we are running this often
  #echo "$(date) [ OK  ]: IPs are the same!" >> $SCRIPT_LOC/dyndns.log
  exit 1
fi

# lets check the IP the nameserver has, just in case, so that we don't do unecesary updates
IP_REMOTE=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN"  https://api.linode.com/v4/domains/$DOMAIN_ID/records/$RECORD_ID | sed -n 's|.*"target": *"\([^"]*\)".*|\1|p')
if [ "$IP_OLD" = "$IP_REMOTE" ]
then
  # No need to continue, our IP hasn't changed, but something weird has happened with icanhazip
  echo "$(date) [WARN ]: IPs are the same, but icanhazip check failed" >> $SCRIPT_LOC/dyndns.log
  exit 1
fi

# at this point our IP is different, we need to update it
curl -s -o /dev/null -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -X PUT -d '{"type": "A", "target": "$IP_LOCAL"}' https://api.linode.com/v4/domains/$DOMAIN_ID/records/$RECORD_ID
# catch the error to make sure all went well
retVal=$?
if [ $retVal -ne 0 ]; then
  echo "$(date) [ERROR]: The update to the server failed!!" >> $SCRIPT_LOC/dyndns.log
  exit $retVal
fi
# log and save the new IP
echo "$(date) [ OK  ]: New IP $IP_LOCAL was sent to server!" >> $SCRIPT_LOC/dyndns.log
echo "$IP_LOCAL" > $SCRIPT_LOC/.ip.hist
