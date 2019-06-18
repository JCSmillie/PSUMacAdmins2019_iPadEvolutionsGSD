#!/bin/sh
# AddMobileDevicestoClasses_FOURGROUPS.sh
#
# Created by Jesse C. Smillie 9-8-2018
# Modified by Jesse. C. Smillie 6-18-2019
#
#	NO WARRANTY APPLIED AND MILEAGE MAY VARY.  DEFINATELY TRY ON A SMALL SUBSET TO MAKE
#	SURE SCRIPT DOES WHAT YOU NEED IT TO DO FOR YOU!!!!!!
#
#	This script takes a list of ClassIDs and attributes the mobile groups listed to
#	that class.  This is useful for Shared iPad situations where specfic classes will
#	be using a shared set of iPads.  Script can accomodate up to four mobile device
#	groups per classID.
#
#	Before running this script you need to prepare a csv file as so:
#	*CLASS ID per JAMF  
#	*Mobile Hardware Group 1 needed  
#	*Mobile Hardware Group 2 needed 
#	*Mobile Hardware Group 3 needed 
#	*Mobile Hardware Group 4 needed 
#	*Note field (Optional and ignored)
#
#	If a class doesnt need all groups just leave that field blank.
#
#	To get your class IDs go to your JAMF API page (https://yourserver.yourorg.org:8443/api) and look
#	for /classes.  Click it.  See GET /classes...  Click TRY OUT!  Now copy all of that info and take
#	it to an XMLtoCSV website (Google one up) and convert that to csv.  Save the csv and open in your
#	spreadsheet editor if choice.  
#
#	Go into JAMF Pro and click your groups of devices.  Look at the web address link to get the mobile
#	device group number for that group and write it down.  Repeat for all groups of iPads you need to
#	attribute classes to.
#
#	Now back in your spreedsheet you want to remove any info that doesnt matter.  ClassID goes in column
#	1 and I move the class name to column 6 as a note which will be ignored in the end.  Fill in columns
#	2-5 with your mobile group IDs.  Save to CSV when done.  Run against this script.
#
# set -x	# DEBUG. Display commands and their arguments as they are executed
# set -v	# VERBOSE. Display shell input lines as they are read.
# set -n	# EVALUATE. Check syntax of the script but dont execute

## Variables
####################################################################################################
# Variables used by JAMF Pro
USERNAME="someuser" #Username of user with API Computer read GET and Computer Group PUT access
PASSWORD="apassword" #Password of user with API Computer read GET and Computer Group PUT access
JSS_URL='https://yourserver.yourorg.org:8443' # JSS URL of the server you want to run API calls against
FiletoOperateOn="/Users/jsmillie/test_data.csv" #CSV File you precreated

export IFS=","

cat $FiletoOperateOn | while read CLASS GROUP1 GROUP2 GROUP3 GROUP4 NOTE;
	do
	echo "$CLASS:$GROUP1:$GROUP2:$GROUP3:$GROUP4:$NOTE"
	
	if [ -n "$GROUP4" ]; then
		#Assume if GROUP4 exists so does 3,2,1
		echo "Four Groups listed.  Processing."
		curl -sk -u $USERNAME:$PASSWORD -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><class><mobile_device_group_ids><id>$GROUP1</id><id>$GROUP2</id><id>$GROUP3</id><id>$GROUP4</id></mobile_device_group_ids></class>" $JSS_URL/JSSResource/classes/id/$CLASS -X PUT
		
		
	elif [ -n "$GROUP3" ]; then
		#Else GROUP4 is blank and GROUP3 exists assume so does 2 & 1
		echo "Three Groups listed.  Processing."
		curl -sk -u $USERNAME:$PASSWORD -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><class><mobile_device_group_ids><id>$GROUP1</id><id>$GROUP2</id><id>$GROUP3</id></mobile_device_group_ids></class>" $JSS_URL/JSSResource/classes/id/$CLASS -X PUT
		

	elif [ -n "$GROUP2" ]; then
		#Else GROUP3 & GROUP4 are blank and GROUP2 exists assume so does 1
		echo "Two Groups listed.  Processing."
		curl -sk -u $USERNAME:$PASSWORD -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><class><mobile_device_group_ids><id>$GROUP1</id><id>$GROUP2</id></mobile_device_group_ids></class>" $JSS_URL/JSSResource/classes/id/$CLASS -X PUT
		
	
	elif [ -n "$GROUP1" ]; then
		#Else GROUP2, GROUP3, & GROUP4 are blank and GROUP1 exists
		echo "One Group listed.  Processing."
		curl -sk -u $USERNAME:$PASSWORD -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><class><mobile_device_group_ids><id>$GROUP1</id></mobile_device_group_ids></class>" $JSS_URL/JSSResource/classes/id/$CLASS -X PUT
			
	else
		#If we are here all group variables are either blank or fillled in an order which is not understood...
		echo "Class with ID no. $CLASS has incorrect data submitted.  Doing nothing with it."
		echo "$CLASS:$GROUP1:$GROUP2:$GROUP3:$GROUP4:$NOTE"
	fi
	
done