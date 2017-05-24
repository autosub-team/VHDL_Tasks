#!/bin/bash

########################################################################
# tester.sh for VHDL task crc
# Tests the task submission, creates the error messages
#
# Copyright (C) 2015 Martin  Mosbeck   <martin.mosbeck@gmx.at>
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
########################################################################


##########################
######## RETURNS #########
##########################
# exit 3 something is wrong with test generation
# exit 1 student solution syntax or behavior wrong
# exit 0 student solution right behavior

##########################
####### PARAMETERS #######
##########################
# $1 ... UserId
# $2 ... TaskNr
# $3 ... TaskParameters

##########################
########## PATHS #########
##########################
# src path of autosub system
autosubPath=$(pwd) 
# root path of the task itself
taskPath=$(readlink -f $0|xargs dirname)
# path for all the files that describe the created path
descPath="$autosubPath/users/$1/Task$2/desc"
#path where the testing takes place
userTaskPath="$autosubPath/users/$1/Task$2"

##########################
###### DEFINITIONS #######
##########################
zero=0
userfile1="fsr_beh.vhdl"
userfile2="crc_beh.vhdl"

TaskNr=$2
logPrefix()
{
   logPre=$(date +"%Y-%m-%d %H:%M:%S,%3N ")"[tester.sh Task$TaskNr]   "
}

##########################
#### TEST PREPARATION ####
##########################
cd $taskPath

#generate the testbench and move testbench to user's folder
python3 scripts/generateTestBench.py $3 > $userTaskPath/crc_tb_$1_Task$2.vhdl 

#copy the entity vhdl files for testing to user's folder
cp $descPath/fsr.vhdl $userTaskPath
cp $descPath/crc.vhdl $userTaskPath

#change to userTaskPath, generate space for errors
cd $userTaskPath
touch error_msg

# create tmp directory
if [ ! -d "/tmp/$USER" ]
then
   mkdir /tmp/$USER
fi

#check if the user supplied a file
if [ ! -f $userfile1 ] || [ ! -f $userfile2 ]
then
    logPrefix && echo "${logPre}Error with Task $2. User $1 did not attach the right file"
    cd $autosubPath
    echo "You did not attach your solution. Please attach the file $userfile1 and $userfile2" >$userTaskPath/error_msg
    exit 1 
fi

#delete all comments from the files
sed -i 's:--.*$::g' $userfile1
sed -i 's:--.*$::g' $userfile2

##########################
######### ANALYZE ########
##########################

#entities, not from user, should have no errors
ghdl -a fsr.vhdl
RET=$? 
if [ "$RET" -ne "$zero" ]
then
   logPrefix && echo "${logPre}Error with Task $2 entity fsr for user with ID $1";
   echo "Something went wrong with the task $2 test generation. This is not your fault. We are working on a solution" > $userTaskPath/error_msg
   exit 3 
fi

ghdl -a crc.vhdl
RET=$? 
if [ "$RET" -ne "$zero" ]
then
   logPrefix && echo "${logPre}Error with Task $2 entity crc for user with ID $1";
   echo "Something went wrong with the task $2 test generation. This is not your fault. We are working on a solution" > $userTaskPath/error_msg
   exit 3 
fi

#testbench, not from user, should have no errors
ghdl -a --ieee=synopsys crc_tb_$1_Task$2.vhdl
RET=$? 
if [ "$RET" -ne "$zero" ]
then
   logPrefix && echo "${logPre}Error with Task $2 testbench for user with ID $1";
   echo "Something went wrong with the task $2 test generation. This is not your fault. We are working on a solution" > $userTaskPath/error_msg
   exit 3 
fi

#these are the files from the user
ghdl -a fsr_beh.vhdl 2> /tmp/$USER/tmp_Task$2_User$1
RET=$?

if [ "$RET" -eq "$zero" ]
then
   logPrefix && echo "${logPre}Task$2 analyze success fsr for user with ID $1!"
else
   logPrefix && echo "${logPre}Task$2 analyze FAILED for user with ID $1!"
   cd $autosubPath
   echo "Analyzation of your submitted behavior file failed:" >$userTaskPath/error_msg
   cat /tmp/$USER/tmp_Task$2_User$1 >> $userTaskPath/error_msg
   exit 1 
fi

ghdl -a crc_beh.vhdl 2> /tmp/$USER/tmp_Task$2_User$1
RET=$?

if [ "$RET" -eq "$zero" ]
then
   logPrefix && echo "${logPre}Task$2 analyze success crc for user with ID $1!"
else
  logPrefix && echo "${logPre}Task$2 analyze FAILED for user with ID $1!"
   cd $autosubPath
   echo "Analyzation of your submitted behavior file failed:" >$userTaskPath/error_msg
   cat /tmp/$USER/tmp_Task$2_User$1 >> $userTaskPath/error_msg
   exit 1 
fi

##########################
######## ELABORATE #######
##########################
ghdl -e --ieee=synopsys crc_tb 2>/tmp/$USER/tmp_Task$2_User$1
RET=$?

if [ "$RET" -eq "$zero" ]
then
   logPrefix && echo "${logPre}Task$2 elaboration success for user with ID $1!"
else
   logPrefix && echo "${logPre}Task$2 elaboration FAILED for user with ID $1!"
   cd $autosubPath
   echo "Elaboration with your submitted behavior file failed:" >$userTaskPath/error_msg
   cat /tmp/$USER/tmp_Task$2_User$1 >> $userTaskPath/error_msg
   exit 1 
fi

##########################
####### SIMULATION #######
##########################
#Simulation reports "Success" or an error message
ghdl -r crc_tb 2> /tmp/$USER/tmp_Task$2_User$1 > /tmp/$USER/tmp_Task$2_User$1_msg

egrep -oq "Success" /tmp/$USER/tmp_Task$2_User$1
RET=$?

if [ "$RET" -eq "$zero" ]
then
    logPrefix && echo "${logPre}Functionally correct for Task$2 for user with ID $1!"
    exit 0
else
    cd $autosubPath
    logPrefix && echo "${logPre}Wrong behavior for Task$2 for user with ID $1!"
    echo "Your submitted behavior file does not behave like specified in the task description:" >$userTaskPath/error_msg
    # substitute the \n in the message for real \n and attach to error msg
    echo /tmp/$USER/tmp_Task$2_User$1_msg | xargs sed 's/\\n/\n/g'  >>$userTaskPath/error_msg
    # also attach the stderr
    cat /tmp/$USER/tmp_Task$2_User$1 >>$userTaskPath/error_msg
    exit 1 
fi
