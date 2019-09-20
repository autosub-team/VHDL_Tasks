######################################################################################
# Common file for all testers using QuestaSim
#
# Copyright (C) 2018 Martin  Mosbeck <martin.mosbeck@tuwien.ac.at>
#
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
######################################################################################

######################################
#               SET UP               #
######################################

zero=0
one=1

# local error codes for testing sequenz (needed to clarify which log files should be saved)
FAILURE_NOATTACH=1
FAILURE_VELSANALYZE=2
FAILURE_USERANALYZE=3
FAILURE_ELABORATE=4
FAILURE_SIM=5
SUCCESS_SIM=6
FAILURE_UNHANDLED=7

#path to support files for backend_interfaces scripts
support_files_path=$backend_interfaces_path/support_files

#path to autosub
autosub_path=$(pwd)

# path for all the files that describe the created task
desc_path="$autosub_path/users/${user_id}/Task${task_nr}/desc"

#path where the testing takes place
user_task_path="$autosub_path/users/${user_id}/Task${task_nr}"

# testbench file
testbench=${task_name}_tb_${user_id}_Task${task_nr}.vhdl

# name of testbench entity
testbench_ent=${task_name}_tb

# DEBUG OUTPUT
#echo "tb_entity:${testbench_ent}"
#echo "user_task_path= $user_task_path"
#echo "desc_path= $desc_path"
#echo "task_path= $task_path"
#echo "autosub_path= $autosub_path"
#echo "backend_interfaces_path= $backend_interfaces_path"
#echo "support_files_path=$support_files_path"
#echo "---------------------------------------"

######################################
#       PARAMETERS QUESTASIM         #
######################################
vcom_params='-2008'

######################################
#       FUNCTIONS FOR TESTING        #
######################################

# generate random tag, this tag has to be attached to the Success output and is
# checked. Otherwise students could trick the system by reporting "Success" in
# their behavior file
random_tag=$(openssl rand -hex 6)

#
#-------------------------------------------------------------------------------
#

function generate_testbench {
	cd $task_path
	#generate the testbench
	python3 scripts/generateTestBench.py "$task_params" "$random_tag" > $user_task_path/$testbench
}

#
#-------------------------------------------------------------------------------
#

function desccp {
	cp $desc_path/$1 $user_task_path
}

#
#-------------------------------------------------------------------------------
#

function prepare_test {
	cd $user_task_path

	# create tmp directory for user if it does not exist
	if [ ! -d "/tmp/$USER" ]
	then
		mkdir /tmp/$USER
	fi

	# create file for error messages, which will be sent to user
	touch error_msg

	#make sure the error_attachments folder is empty
	if [ ! -d "error_attachments" ];
	then
		mkdir error_attachments
	else
		rm -r error_attachments
		mkdir error_attachments
	fi

	#------ CHECK AND PREPARE USERFILES ------
	for userfile in $userfiles
	do
		#check if the user supplied a file
		if [ ! -f $userfile ]
		then
			echo "Error with task ${task_nr}. User ${user_id} did not attach the right file."
			echo "You did not attach your solution. Please attach the file $userfile" > error_msg
			exit_and_save_results $FAILURE_NOATTACH
		fi

		# delete comments from the file to allow checks like looking for 'wait'
		# NOTE: this is not a parse and does not cover 2008 multi line
		# comments, but should work for most cases
		sed -i 's:--[^"]*$::g' $userfile
	done

	#------ COPY NEEDED FILES FOR TEST ------
	for filename in $entityfiles
	do
		desccp $filename
	done

	for filename in $extrafiles
	do
		desccp $filename
	done

	# ----- copy the .do (tcl) file for testing to user's folder -----
	# if a special version exists use it, else use common one
	if [ -f $task_path/scripts/vsim.do ]
	then
		cp "$task_path/scripts/vsim.do" $user_task_path
	else
		cp "$support_files_path/vsim.do" $user_task_path
	fi

	# prepare QuestaSim (licence, set path)
	# TODO: needs to be adjusted per server
	source /eda/QuestaSim_setup.sh
}

#
#-------------------------------------------------------------------------------
#

function taskfiles_analyze {
	cd $user_task_path

	rm -rf /tmp/taskfiles_output_${user_id}_Task${task_nr}.txt
	touch /tmp/taskfiles_output_${user_id}_Task${task_nr}.txt

	#------ ANALYZE FILES WHICH ARE NOT FROM THE USER ------#
	# Sequence: extrafiles (packages etc.) - entities - testbench

	for filename in $extrafiles
	do
		vcom $vcom_params $filename > /tmp/taskfiles_output_${user_id}_Task${task_nr}.txt
		RET=$?
		if [ "$RET" -ne "$zero" ]
		then
			# message to tasks.sterr
			echo "Error with task ${task_nr} for user ${user_id} while analyzing extrafile $filename" 1>&2
			cat /tmp/taskfiles_output_${user_id}_Task${task_nr}.txt | grep '\*\* Error' 1>&2

			# message to tasks.stdout
			echo "Error with task ${task_nr} for user ${user_id} while analyzing extrafile $filename"

			# message to error_msg for user
			echo "Something went wrong with the task ${task_nr} test generation. This is not your " \
			     "fault. We are working on a solution" > error_msg

			exit_and_save_results $FAILURE_VELSANALYZE
		fi
	done

	for filename in $entityfiles
	do
		vcom $vcom_params $filename > /tmp/taskfiles_output_${user_id}_Task${task_nr}.txt
		RET=$?
		if [ "$RET" -ne "$zero" ]
		then
			# message to tasks.sterr
			echo "Error with task ${task_nr} for user ${user_id} while analyzing entity $filename" 1>&2
			cat /tmp/taskfiles_output_${user_id}_Task${task_nr}.txt | grep '\*\* Error' 1>&2

			# message to tasks.stdout
			echo "Error with task ${task_nr} for user ${user_id} while analyzing entity $filename"

			# message to error_msg for user
			echo "Something went wrong with the task ${task_nr} test generation. This is not your " \
			     "fault. We are working on a solution" > error_msg

			exit_and_save_results $FAILURE_VELSANALYZE
		fi
	done

	vcom $vcom_params $testbench > /tmp/taskfiles_output_${user_id}_Task${task_nr}.txt
	RET=$?
	if [ "$RET" -ne "$zero" ]
	then
		# message to tasks.sterr
		echo "Error with task ${task_nr} for user ${user_id} while analyzing the testbench" 1>&2
		cat /tmp/taskfiles_output_${user_id}_Task${task_nr}.txt | grep '\*\* Error' 1>&2

		# message to tasks.stdout
		echo "Error with task ${task_nr} for user ${user_id} while analyzing the testbench"

		# message to error_msg for user
		echo "Something went wrong with the task ${task_nr} test generation. This is not your " \
		     "fault. We are working on a solution" > error_msg

		exit_and_save_results $FAILURE_VELSANALYZE
	fi

	rm -f /tmp/taskfiles_output_${user_id}_Task${task_nr}.txt
}

function userfiles_analyze {
	cd $user_task_path

	rm -rf /tmp/$USER/tmp_Task${task_nr}_User${user_id}
	touch /tmp/$USER/tmp_Task${task_nr}_User${user_id}

	#------ ANALYZE FILES FROM THE USER ------#
	for filename in $userfiles
	do
		#this is the file from the user
		vcom $vcom_params $filename > /tmp/$USER/tmp_Task${task_nr}_User${user_id}
		RET=$?

		#TODO:Possible infinite loop error in QuestaSim?

		if [ "$RET" -eq "$zero" ]
		then
			# message to tasks.stdout
			echo "Task ${task_nr} analyze success for user ${user_id}!"
		else
			# message to tasks.stdout
			echo "Task ${task_nr} analyze FAILED for user ${user_id}!"

			# message to error_msg for user
			echo "Analyzation of your submitted behavior file failed:" > error_msg
			#TODO supress other errors and warnings?
			cat /tmp/$USER/tmp_Task${task_nr}_User${user_id} | grep -v 'VHDL Compiler exiting' | grep '\*\* Error' >> error_msg

			#For Debug
			#echo -e "\n\n--------------------Full Log--------------------\n" >> error_msg
			#cat /tmp/$USER/tmp_Task${task_nr}_User${user_id} >> error_msg
			#########################################################################

			exit_and_save_results $FAILURE_USERANALYZE
		fi
	done
}

#
#-------------------------------------------------------------------------------
#

function elaborate {
	: # no explicit elaboration step with QuestaSim
}

#
#-------------------------------------------------------------------------------
#

function simulate {
	cd $user_task_path

	# set virtual memory limit to 500 MiB
	ulimit -v $((500*1024))

	# start simulation, output is written to a file called transcript, no need
	# to output the error messages to stderr, as they are also in the transcript
	timeout $simulation_timeout vsim -c -do "vsim.do" ${testbench_ent} -voptargs="+acc"  1>&2 2> /dev/null
	RET_timeout=$?

	#delete the starting # from the logfile, rename it
	sed 's/# //' transcript > vsim.log

	# check if simulation timed out:
	if [ "$RET_timeout" -eq 124 ] # timeout exits 124 if it had to kill the process. Probably the simulation has crashed.
	then
		# messagt to tasks.stdout
		echo "Task ${task_nr} simulation timeout for user ${user_id}!"

		# message to error_msg for user
		echo "The simulation of your design timed out. This is not supposed to happen. Check your design." > error_msg

		#attach warnings & errors, maybe they help user
		cat vsim.log | grep '\*\* Error' >> error_msg
		cat /tmp/$USER/tmp_Task${task_nr}_User${user_id} | grep '\*\* Warning' >> error_msg
		cat vsim.log | grep '\*\* Warning' >> error_msg

		#For Debug
		#echo -e "\n\n--------------------Full Log--------------------\n" >> error_msg
		#cat /tmp/$USER/tmp_Task${task_nr}_User${user_id} >> error_msg
		#echo -e "\n" >> error_msg
		#cat vsim.log >> error_msg
		#########################################################################

		exit_and_save_results $FAILURE_SIM
	fi

	# check if simulation reported "Success":
	egrep -q "Success_$random_tag" vsim.log
	RET_success=$?
	if [ "$RET_success" -eq "$zero" ]
	then
		echo "Functionally correct for task${task_nr} for user ${user_id}!"
		exit_and_save_results $SUCCESS_SIM
	fi

	# attach wave file:
	if [ "$attach_wave_file" -eq "$one" ]
	then
		#compression factor is approx 10, so we dont want anything above 20MB
		head --bytes=20000K signals.vcd >signals_tmp.vcd; #first x K Bytes
		rm signals.vcd
		mv signals_tmp.vcd signals.vcd
		zip wavefile.zip signals.vcd
		mv wavefile.zip error_attachments/
		rm signals.vcd
	fi

	# check for simulation errors, attach simulation&analysis  warnings:
	cat vsim.log | grep -q '\*\* Error\|\*\* Fatal:'
	RET_simulation_error=$?
	if [ "$RET_simulation_error" -eq "$zero" ]
	then
		# message to tasks.stdout
		echo "Simulation error for task ${task_nr} for user ${user_id}"

		# message to error_msg for user
		echo "Simulation Error:" > error_msg
		cat vsim.log | grep '\*\* Fatal'| sed 's/Fatal/Error/g' >> error_msg
		cat vsim.log | grep '\*\* Error' >> error_msg
		cat /tmp/$USER/tmp_Task${task_nr}_User${user_id} | grep '\*\* Warning' >> error_msg
		cat vsim.log | grep '\*\* Warning' >> error_msg

		#For Debug
		#echo -e "\n\n--------------------Full Log--------------------\n" >> error_msg
		#cat /tmp/$USER/tmp_Task${task_nr}_User${user_id} >> error_msg
		#echo -e "\n" >> error_msg
		#cat vsim.log >> error_msg
		#########################################################################

		exit_and_save_results $FAILURE_SIM
	fi

	# check for the error messages from the testbench:
	egrep -q '§{' vsim.log
	RET_tb_error_message=$?
	if [ "$RET_tb_error_message" -eq "$zero" ]
	then
		# message to tasks.stdout
		echo "Wrong behavior for task ${task_nr} for user ${user_id}"

		# message to error_msg for user
		echo "Your submitted behavior file does not behave like specified in the task description:" > error_msg

		# filter out the testbench error messages between §{...}§ , filter out Failure message
		cat vsim.log | awk '/§{/,/}§/' | sed 's/§{//g' | sed 's/}§//g' | sed 's/\*\* Failure: //g' \
			| sed 's/Simulation error//g'| sed 's/\\n/\n/g' >> error_msg

		if [ "$attach_wave_file" -eq "$one" ]
		then
			echo "Please look at the attached wave file to see what signal(s) your entity produces. Use a viewer like GTKWave" \
			      "or the EdaPlayground Waveviewer(https://www.edaplayground.com/w)." >> error_msg
		fi

		# attach warnings, maybe they help the user
		cat /tmp/$USER/tmp_Task${task_nr}_User${user_id} | grep '\*\* Warning' >> error_msg
		cat vsim.log | grep '\*\* Warning' >> error_msg

		#For Debug
		#echo -e "\n\n--------------------Full Log--------------------\n" >> error_msg
		#cat /tmp/$USER/tmp_Task${task_nr}_User${user_id} >> error_msg
		#echo -e "\n" >> error_msg
		#cat vsim.log >> error_msg
		#########################################################################

		exit_and_save_results $FAILURE_SIM
	fi

	# ------ catch unhandled errors --------

	# find last submission number
	submission_nrs=($(ls $user_task_path | grep -oP '(?<=Submission)[0-9]+' | sort -nr))
	submission_nr_last=${submission_nrs[0]}

	# message to tasks.stdout
	echo "Unhandled simulation error for task ${task_nr} for user ${user_id} for submission ${submission_nr}!" \
	     "Sent only 'Your submitted behavior file does not behave like specified in the task description.' to user"

	# message to tasks.stderr
	echo "Unhandled simulation error for task ${task_nr} for user ${user_id} for submission ${submission_nr}!" \
	     "Sent only 'Your submitted behavior file does not behave like specified in the task description.' to user" 1>&2

	# message to error_msg for user
	echo "Your submitted behavior file does not behave like specified in the task description." > error_msg

	exit_and_save_results $FAILURE_UNHANDLED
}

#
#-------------------------------------------------------------------------------
#

############################################################################################################
# before exiting the simulation, first copy all relevant simulation and log files to the submission folder #
############################################################################################################
function exit_and_save_results {

	########################################################################################
	# generate subfolder inside submission folder for saving the simulation and log files  #
	########################################################################################

	# find last submission number
	submission_nrs=($(ls $user_task_path | grep -oP '(?<=Submission)[0-9]+' | sort -nr))
	submission_nr_last=${submission_nrs[0]}

	# jump into last submission folder and get the correct name (name includes time, which is unknown to this script)
	cd $user_task_path/Submission${submission_nr_last}_*
	user_submission_path="$user_task_path/${PWD##*/}"

	# create subfolder test_results
	if [ ! -d "test_results" ]
	then
		mkdir test_results
	fi

	# jump back to user task path
	cd $user_task_path

	####################################################
	# always save the error message and used testbench #
	####################################################
	if [ -f $user_task_path/error_msg ]
	then
		src=$user_task_path/error_msg
		tgt=$user_submission_path/test_results/error_msg
		cp $src $tgt
	fi

	#copy testbench into task_results folder
	if [ -f $user_task_path/$testbench ]
	then
		src=$user_task_path/$testbench
		tgt=$user_submission_path/test_results/${task_name}_tb_${user_id}_Task${task_nr}.vhdl
		cp $src $tgt
	fi

	##############################################################################
	# depending on point of exit during test phase, save the relevant log files  #
	##############################################################################
	touch $user_submission_path/test_results/submission_log

	# Failure: user attached not the correct files
	if [ $1 = $FAILURE_NOATTACH ]
	then
		echo "User has not attached the correct files, so no simulation was started." > $user_submission_path/test_results/submission_log
		exit $FAILURE

	# Failure: VELS files (not files from user) throw error
	elif [ $1 = $FAILURE_VELSANALYZE ]
	then
		echo "Error while analyzing files which are not from the user, please have a look at the global task error log." > $user_submission_path/test_results/submission_log
		if [ -f $user_task_path/error_msg ]
		then
			src=/tmp/taskfiles_output_${user_id}_Task${task_nr}.txt
			tgt=$user_submission_path/test_results/taskfiles_output_${user_id}_Task${task_nr}.txt
			mv $src $tgt
		fi

		exit $TASKERROR

	# Failure: Analyzing user files throws error
	elif [ $1 = $FAILURE_USERANALYZE ]
	then
		echo "Error while analyzing user files." > $user_submission_path/test_results/submission_log

		if [ -f /tmp/$USER/tmp_Task${task_nr}_User${user_id} ]
		then
			src=/tmp/$USER/tmp_Task${task_nr}_User${user_id}
			tgt=$user_submission_path/test_results/tmp_Task${task_nr}_User${user_id}
			mv $src $tgt
		fi
		exit $FAILURE

	# Failure: Elaboration failed. NOT POSSIBLE WITH QUESTASIM
	#elif [ $1 = $FAILURE_ELABORATE ]
	#then

	# Failure: Simulation fails (either timeout, user syntax error or wrong behaviour)
	elif [ $1 = $FAILURE_SIM ]
	then
		echo "Simulation failed: either timeout, user syntax error or wrong behaviour." > $user_submission_path/test_results/submission_log

		if [ -f $user_task_path/vsim.log ]
		then
			src=$user_task_path/vsim.log
			tgt=$user_submission_path/test_results/vsim.log
			mv $src $tgt
		fi
		exit $FAILURE

	# Success
	elif [ $1 = $SUCCESS_SIM ]
	then
		echo "Simulation was successfull, correct solution." > $user_submission_path/test_results/submission_log

		if [ -f $user_task_path/vsim.log ]
		then
			src=$user_task_path/vsim.log
			tgt=$user_submission_path/test_results/vsim.log
			mv $src $tgt
		fi
		exit $SUCCESS

        # Failure: Unhandled failure occured
	elif [ $1 = $FAILURE_UNHANDLED ]
	then
		echo "Unhandled error occured" > $user_submission_path/test_results/submission_log

		if [ -f $user_task_path/vsim.log ]
		then
			src=$user_task_path/vsim.log
			tgt=$user_submission_path/test_results/vsim.log
			mv $src $tgt
		fi

		if [ -f /tmp/$USER/tmp_Task${task_nr}_User${user_id} ]
		then
			src=/tmp/$USER/tmp_Task${task_nr}_User${user_id}
			tgt=$user_submission_path/test_results/tmp_Task${task_nr}_User${user_id}
			mv $src $tgt
		fi

		exit $FAILURE
	fi
}
