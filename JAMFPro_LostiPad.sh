#!/bin/sh
#
# 	Created by Jesse C. Smillie 4-8-2019

#		**THiS SCRIPT IS PROVIDED AS REFERENCE AND WILL NOT WORK OUT OF THE BOX IN PROBABLY ANY ENVIROMENT***
#
#	This script is called from the command line to enable/disable lost iPad mode
#	on an iPad based on its asset tag.  It should be pretty universal other than:
#		*I use Slacktee to post to a slackfeed called "mdm_activity" which you may want to comment out
#		*My GETSERIAL function is based off our XATAFACE inventory system.  In base however you just need
#		*A way to get your serial number for the device in question.
#
#
#
# Variables used by JAMF Pro
USERNAME="someuser" #Username of user with API Computer read GET and Computer Group PUT access
PASSWORD="apassword" #Password of user with API Computer read GET and Computer Group PUT access
JSS_URL='https://yourserver.yourorg.org:8443' # JSS URL of the server you want to run API calls against

ACTION2DO="$1"
GSDTAG="$2"
RUNNING_USER="$3"  #<---OPTIONAL

##########################
###   Functions
##########################
WorkProblemFromTag() {
	#Take given GSD tag and query GSD inventory to get a serial
	GETSERIAL=$(curl -k -v "http://10.1.12.201/testing/inventory/index.php?-table=invtable2&-action=export_xml&-cursor=0&-skip=0&-limit=30&-mode=list&id=$GSDTAG" | grep "<serial>" | head -1 | /usr/bin/awk -F'<serial>|</serial>' '{print $2}' | perl -ne '$_=~s/(\r|\n)//;print(uc($_))' )
	echo "SERIAL===$GETSERIAL"
	if [ -z "$GETSERIAL" ]; then
		echo "Device serial is not in inventory.  Cannot continue!"
		echo "Device serial is not in inventory.  Cannot continue!" | /backup/new_scripts/slacktee/slacktee.sh -q -a "#000000" -c mdm_activity
		exit 1
		
	else
		#Take serial gathered from inventory and run against JSS
		#to figure out its device ID.
		GETJAMFID=$(curl -k -v -u "$USERNAME":"$PASSWORD" $JSS_URL/JSSResource/mobiledevices/serialnumber/"$GETSERIAL" -X GET | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<id>(.*?)<\/id>/sg){print $1}' | head -1)
		if [ -z "$GETJAMFID" ]; then
			echo "Device can't be found in the JSS.  Cannot Continue!"
			echo "Device serial is not in the JSS.  Cannot continue!" | /backup/new_scripts/slacktee/slacktee.sh -q -a "#000000" -c mdm_activity
			exit 1
		else
			#Build the XML file we need to run against the commands.
			MakeXML
		
		fi
	fi
}

#Format XML Needed for Parsing Commands
MakeXML() {
echo '<?xml version="1.0" encoding="utf-8"?>' > /tmp/tmpxml.xml
echo "<mobile_device_command>" >> /tmp/tmpxml.xml
echo "<lost_mode_message>This iPad has been reported at lost.  Please take to the Main Office ASAP!!</lost_mode_message>"  >> /tmp/tmpxml.xml
echo "<lost_mode_phone>412-858-0453 or Extension 21603</lost_mode_phone>" >> /tmp/tmpxml.xml
echo "<lost_mode_footnote>This iPad is Gateway School District Property and we can track its location when it is in Lost mode!</lost_mode_footnote>" >>  /tmp/tmpxml.xml
echo "<lost_mode_with_sound>true</lost_mode_with_sound>" >> /tmp/tmpxml.xml
echo "<mobile_devices>" >> /tmp/tmpxml.xml
echo "<mobile_device>" >> /tmp/tmpxml.xml
echo "<id>$GETJAMFID</id>" >> /tmp/tmpxml.xml
echo "</mobile_device>" >> /tmp/tmpxml.xml
echo "</mobile_devices>" >> /tmp/tmpxml.xml
echo "</mobile_device_command>" >> /tmp/tmpxml.xml
}

EnableLostMode() {
	echo "LOST MODE ENABLED: by $RUNNING_USER" > /tmp/output.txt
	echo " GSD TAG--> $GSDTAG" >> /tmp/output.txt
	echo " SERIAL NUMBER-> $GETSERIAL" >> /tmp/output.txt
	echo " JAMF ID-> $GETJAMFID" >> /tmp/output.txt
	curl -ksu "$USERNAME":"$PASSWORD" -H "Content-type: application/xml" $JSS_URL/JSSResource/mobiledevicecommands/command/EnableLostMode/id/$GETJAMFID -X POST -T /tmp/tmpxml.xml
	cat /tmp/output.txt | /backup/new_scripts/slacktee/slacktee.sh -q -a "#F32029" -c mdm_activity
}

PlayLostSound() {
	echo "LOST MODE SOUND PLAYED: $RUNNING_USER" > /tmp/output.txt
	echo " GSD TAG--> $GSDTAG" >> /tmp/output.txt
	echo " SERIAL NUMBER-> $GETSERIAL" >> /tmp/output.txt
	echo " JAMF ID-> $GETJAMFID" >> /tmp/output.txt
	curl -ksu "$USERNAME":"$PASSWORD" -H "Content-type: application/xml" $JSS_URL/JSSResource/mobiledevicecommands/command/PlayLostModeSound/id/$GETJAMFID -X POST -T /tmp/tmpxml.xml
	cat /tmp/output.txt | /backup/new_scripts/slacktee/slacktee.sh -q -a "#F38120" -c mdm_activity
}

DisableLostMode() {
	echo "LOST MODE DISABLE: $RUNNING_USER" > /tmp/output.txt
	echo " GSD TAG--> $GSDTAG" >> /tmp/output.txt
	echo " SERIAL NUMBER-> $GETSERIAL" >> /tmp/output.txt
	echo " JAMF ID-> $GETJAMFID" >> /tmp/output.txt
	curl -ksu "$USERNAME":"$PASSWORD" -H "Content-type: application/xml" $JSS_URL/JSSResource/mobiledevicecommands/command/DisableLostMode/id/$GETJAMFID -X POST -T /tmp/tmpxml.xml
	cat /tmp/output.txt | /backup/new_scripts/slacktee/slacktee.sh -q -a "#29F320" -c mdm_activity
}


##########################
###   Do Work
##########################

#See if we know who ran this otherwise note it as Console did it
if [ -z "$RUNNING_USER" ]; then
	RUNNING_USER="<<Console>>"
fi


if [ -z "$GSDTAG" ]; then
	echo "Please provide GSD tag"
	#Run and tell Slack Feed Too
	echo "Please provide GSD tag" | /backup/new_scripts/slacktee/slacktee.sh -q -a "#000000" -c mdm_activity
	
else
	#Get the serial number from inventory and figure out tag number
	WorkProblemFromTag
	
	#Run our cases
	case "$ACTION2DO" in
	enable)
		EnableLostMode
		;;
	
	disable)
		DisableLostMode
		;;
	sound)
		PlayLostSound
		;;
	
	*)
		echo "Usage: $0 {enable|disable|sound} <GSD_TAG>"
		exit 1
	esac
	
fi
