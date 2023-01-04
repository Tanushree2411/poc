#!/bin/bash

cd soho
DEFAULT_MERGE_BRANCH="connectivity-sextant-dev"
DEFAULT_TARGET_BRANCH="test_debug_asan"
CURRENT_TIME=$(date "+%y.%m.%d-%H.%M.%S")
LOG_FILE="MERGE_LOGS_$CURRENT_TIME.log"

#Total args passed
ARGS="$#"
echo "Total $ARGS args passed"


#Brief: This fun will do args parsing and check whether the passed branch name exists or not
do_arg_parse()
{
	if (( ARGS==0 )); then
		TARGET_BRANCH=$DEFAULT_TARGET_BRANCH
        	MERGE_BRANCH=$DEFAULT_MERGE_BRANCH

	elif (( ARGS>0 & ARGS<=2 )); then
		if (( ARGS==1 )); then
			#PASSING FIRST ARG AS A BRANCH WE NEED TO REBASE
			MERGE_BRANCH=$DEFAULT_MERGE_BRANCH
			#check if target branch exits
			TARGET_BRANCH_EXISTS=$(git branch --list $1)
			if [ "$TARGET_BRANCH_EXISTS" ]; then
				echo "TARGET_BRANCH: $1 exists in local repository"
				TARGET_BRANCH=$1
			else
				echo "TARGET_BRANCH: $1 doesnt exists"
				exit 1
			fi
		else
			#PASSING FIRST ARG AS A BRANCH WE NEED TO REBASE
			TARGET_BRANCH=$1
            		#check if target branch exits
	    		TARGET_BRANCH_EXISTS1=$(git branch --list $1)
           	 	if [ "$TARGET_BRANCH_EXISTS1" ]; then
				MERGE_BRANCH=$2
				echo "TARGET_BRANCH: $1 exists in local repository"
        	    	else
			       	echo "TARGET_BRANCH: $1 doesnt exists"
				exit 1
	    		fi
			#passing sec arg as a branch we need to merge on
			MERGE_BRANCH_EXISTS=$(git branch --list ${MERGE_BRANCH})
	    		if [ "$MERGE_BRANCH_EXISTS" ]; then
				echo "MERGE_BRANCH: $2 exists in local repository"
            		else
				echo "MERGE_BRANCH: $2 doesnt exists"
				exit 1
			fi
		fi
	else
		echo "usage: $0 TARGET-Branch MERGE-Branch"
		exit 1
	
	fi
}

#Brief: This fun will pull the branch which is passed as its argument
do_pull()
{
	if [ -z "$1" ]; then
		echo "usage: $0 BRANCH"
		exit 1
	else
		echo "***********************************" >> $LOG_FILE
		echo "Started git pull for branch $1" | tee -a $LOG_FILE
		GIT_PULL_OUTPUT_BRANCH=$(git pull 2>&1)
		echo $GIT_PULL_OUTPUT_BRANCH >> $LOG_FILE 
		echo ${GIT_PULL_OUTPUT_BRANCH} | grep -iq 'ERROR\|ABORTING\|FATAL\|DETACHED'
		ret2=$?
		if [ "$ret2" == 0 ]; then
			echo "Error in git pull in $1"
	       		exit 1
		else
			echo "git pull for branch $1 is completed" | tee -a $LOG_FILE
			echo "***********************************" >> $LOG_FILE
		fi
	fi
}

#Brief: This fun will checkout the branch which is passed as its argument
do_checkout()
{
	if [ -z "$1" ]; then
		echo "usage: $0 BRANCH"
		exit 1

	else
	       	echo "*********************************" >> $LOG_FILE
		echo "Started git checkout for branch $1" | tee -a $LOG_FILE
		GIT_CHECKOUT_BRANCH=$(git checkout $1 2>&1)
		echo $GIT_CHECKOUT_BRANCH >> $LOG_FILE
		echo ${GIT_CHECKOUT_BRANCH} | grep -qi 'ERROR\|FATAL'
		ret1=$?
		if [ "$ret1" == 0 ]; then
			echo "Error in checkout to branch $1"
			exit 1
		else
			echo "git checkout for $1 is completed" | tee -a $LOG_FILE	
			echo "*********************************" >> $LOG_FILE
		fi
	fi
}
# Brief: This fun will merge the branch with Merge_branch
do_merge()
{
	echo "*********************************" >> $LOG_FILE
	echo "Started merging $TARGET_BRANCH to $MERGE_BRANCH" | tee -a $LOG_FILE
	GIT_MERGE_OUTPUT=$(git merge ${MERGE_BRANCH} 2>&1)
	echo $GIT_MERGE_OUTPUT >> $LOG_FILE
	echo ${GIT_MERGE_OUTPUT} | grep -iq 'ERROR\|ABORTING\|FATAL\|DETACHED\|CONFLICT\|FAILED'
	ret3=$?
	if [ "$ret3" == 0 ]; then
		echo "Error in git merge of $TARGET_BRANCH to $MERGE_BRANCH"
		exit 1
	else
		echo "git merge of $TARGET_BRANCH to $MERGE_BRANCH is completed" | tee -a $LOG_FILE
		echo "*********************************" >> $LOG_FILE
	fi

}

#Brief: This fun will push the changes in the remote Target_branch
do_push()
{
	echo "*********************************" >> $LOG_FILE
	echo "Would you like to push the changes? [y/n]" | tee -a $LOG_FILE
	read -p "Enter your ans:" -r ANS
	if [[ $ANS =~ ^[Yy]$ ]]; then
		echo "Started pushing changes to $TARGET_BRANCH" | tee -a $LOG_FILE
		GIT_PUSH_OUTPUT=$(git push -u origin ${TARGET_BRANCH} 2>&1)
		echo $GIT_PUSH_OUTPUT >> $LOG_FILE
		echo ${GIT_PUSH_OUTPUT} | grep -iq 'ERROR\|ABORTING\|FATAL\|DETACHED\|CONFLICT\|FAILED\|FAST-FORWARD\|REJECTED'
		ret4=$?
		if [ "$ret4"== 0 ]; then
			echo "Error in git push"
			exit 1
		else
			echo "*********************************" >> $LOG_FILE
			echo "git push to $TARGET_BRANCH completed" | tee -a $LOG_FILE
		fi
	fi
}

#func called for arg_parse
do_arg_parse $1 $2

echo "Logs getting saved in $LOG_FILE"
echo "Executing the scripts with TARGET_BRANCH: $TARGET_BRANCH and MERGE_BRANCH: $MERGE_BRANCH"

# checkout TO Merge BRANCH
do_checkout $MERGE_BRANCH
# pull the latest changes
do_pull ${MERGE_BRANCH}


# checkout the original branch
do_checkout $TARGET_BRANCH
#pull the latest changes of target branch
do_pull $TARGET_BRANCH

# merge on master
do_merge

# prompt to push the changes
do_push


