#!/bin/sh
# clean disseminate directories of tar files older than age in days
# must be run as daitss user
 
if [ $1 == "-help" ] || [ $# -ne 2 ]
then
 echo "usage: clean_disseminate target_dir  age"
 echo "clean out all files with extension .tar from  the  'target_dir' and all sub-dirs that exceed 'age'  days old."
 echo "use -1 for all files,  use 0 for yesterdays files, use 1 for two days ago files,   etc."
exit 1
fi



# make sure dir exists
if [ ! -d $1 ]
then
 echo "$1 does not exist, or is not a directory."
exit 2
fi
REQUIRED_USER=daitss

# Check to see if we're in the daitss group, or we're daitss.  Exit else.

if  [ "`id -un`" !=  $REQUIRED_USER  ]; then
   echo Only $REQUIRED_USER should run this script. Run this script as $REQUIRED_USER like this: sudo -u $REQUIRED_USER script_name args...
   exit 3
fi

target_dir=$1
age=$2 
cd $target_dir
filecount=`find ${target_dir} -iname "*tar" -type f -mtime +${age}|wc -l`
if [ $filecount -gt 0 ] 
then
 find ${target_dir} -iname "*tar" -type f -mtime +${age}|xargs rm     
fi 
echo "$filecount *.tar files deleted."
