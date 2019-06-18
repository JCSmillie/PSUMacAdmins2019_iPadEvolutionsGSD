#!/bin/sh
# AppleTV_Restart_Script.sh
#
# Created by Jesse C. Smillie 8-8-2018
# 
#	NO WARRANTY APPLIED AND MILEAGE MAY VARY.  DEFINATELY TRY ON A SMALL SUBSET TO MAKE
#	SURE SCRIPT DOES WHAT YOU NEED IT TO DO FOR YOU!!!!!!
#
#	This script reboots all AppleTVs (4th Gen) in a JSS Pro group you create.
#	We have this setup in crontab to run nightly on our CentOS server.
#
# set -x	# DEBUG. Display commands and their arguments as they are executed
# set -v	# VERBOSE. Display shell input lines as they are read.
# set -n	# EVALUATE. Check syntax of the script but dont execute

## Variables
####################################################################################################

# Variables used by this script
JSS_XML_INPUT="/tmp/JSS_XML_INPUT.xml" # XML Output to be uploaed to the JSS Computer Groups API
#You must precreate a dynamic group in your JSS of the AppleTVs you want rebooted.  For example
#I only try to reboot AppleTVs that have checked in for inventory in the last 36 hrs.  Our inventory
#interval is 24hr so that should mean Im only trying to reboot units that are actively being used.
STATIC_GROUP_ID="102" # dynamic Group ID: This can be found in the URL when you click edit on a Static Group

# Variables used by JAMF Pro
USERNAME="someuser" #Username of user with API Computer read GET and Computer Group PUT access
PASSWORD="apassword" #Password of user with API Computer read GET and Computer Group PUT access
JSS_URL='https://yourserver.yourorg.org:8443' # JSS URL of the server you want to run API calls against

## Functions
####################################################################################################
function UpdateStaticGroup () {
	curl -k -v -u "$USERNAME":"$PASSWORD" $JSS_URL/JSSResource/mobiledevicegroups/id/$STATIC_GROUP_ID -T "$JSS_XML_INPUT" -X PUT
	echo "$?"
	echo "Done"
}

function GetSerialNumbers_ATV () {
	curl -k -v -u "$USERNAME":"$PASSWORD" $JSS_URL/JSSResource/mobiledevicegroups/id/$STATIC_GROUP_ID -X GET  --output /tmp/ATV_serials.txt

}

## Do Work
####################################################################################################
rm -Rf  /tmp/ATV_serials.txt
rm -Rf /tmp/ATV_idnums.txt

# run the search and return serial numbers
SEARCH=$( /usr/bin/curl -k -s 0 $JSS_URL/JSSResource/mobiledevicegroups/id/$STATIC_GROUP_ID --user "$USERNAME:$PASSWORD" -H "Content-Type: text/xml" -X GET )
SERIALNUMBERLIST=$( /bin/echo "$SEARCH" | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<serial_number>(.*?)<\/serial_number>/sg){print $1}' )
echo "$SERIALNUMBERLIST" > /tmp/ATV_serials.txt

IDLIST=$( /bin/echo "$SEARCH" | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<id>(.*?)<\/id>/sg){print $1}' )
echo "$IDLIST" | tail -n +3 > /tmp/ATV_idnums.txt


for aline in `cat /tmp/ATV_idnums.txt`; do
echo "$aline"
			curl -k -v -u "$USERNAME":"$PASSWORD" $JSS_URL/JSSResource/mobiledevicecommands/command/RestartDevice/id/$aline -X POST
		done