#! /bin/bash                                                                                                                                                                                                      
### Stephen Kay, University of Regina
### 03/03/21
### stephen.kay@uregina.ca
### A batch submission script based on an earlier version by Richard Trotta, Catholic University of America                       
##### Modify required resources as needed!                                                                                                                                   

echo "Running as ${USER}"
SPEC=$1
### Check you have provided the first argument correctly
if [[ ! $1 =~ ^("HMS"|"SHMS")$ ]]; then
    echo "Please specify spectrometer, HMS or SHMS"
    exit 2
fi
RunList=$2
if [[ -z "$2" ]]; then
    echo "I need a run list process!"
    echo "Please provide a run list as input"
    exit 2
fi
### Check if a third argument was provided, if not assume -1, if yes, this is max events              
if [[ $3 -eq "" ]]; then
    MAXEVENTS=-1
else
    MAXEVENTS=$3
fi

##Output history file##             
historyfile=hist.$( date "+%Y-%m-%d_%H-%M-%S" ).log
##Output batch script##
batch="${USER}_Job.txt"
##Input run numbers##
inputFile="/group/c-pionlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH/InputRunLists/${RunList}"
## Tape stub  
MSSstub='/mss/hallc/spring17/raw/coin_all_%05d.dat'
auger="augerID.tmp"

while true; do
    read -p "Do you wish to begin a new batch submission? (Please answer yes or no) " yn
    case $yn in
        [Yy]* )
            i=-1
            (
            ##Reads in input file##
            while IFS='' read -r line || [[ -n "$line" ]]; do
                echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                echo "Run number read from file: $line"
                echo ""
                ##Run number#
                runNum=$line
                tape_file=`printf $MSSstub $runNum`
                tmp=tmp
                ##Finds number of lines of input file##
                numlines=$(eval "wc -l < ${inputFile}")
                echo "Job $(( $i + 2 ))/$(( $numlines +1 ))"
                echo "Running ${batch} for ${runNum}"
                cp /dev/null ${batch}
                ##Creation of batch script for submission##
                echo "PROJECT: c-kaonlt" >> ${batch}
		echo "TRACK: analysis" >> ${batch}
		#echo "TRACK: debug" >> ${batch}
                echo "JOBNAME: KaonLT_HodoCalib_${SPEC}_${runNum}" >> ${batch}
		echo "DISK_SPACE: 20 GB" >>${batch}
                echo "MEMORY: 3000 MB" >> ${batch}
                #echo "OS: centos7" >> ${batch}
                echo "CPU: 1" >> ${batch} ### hcana single core, setting CPU higher will lower priority!
		echo "INPUT_FILES: ${tape_file}" >> ${batch}
		echo "COMMAND:/group/c-pionlt/USERS/${USER}/hallc_replay_lt/UTIL_BATCH/Analysis_Scripts/HodoCalib_Batch.sh ${runNum} ${SPEC} ${MAXEVENTS}" >> ${batch} 
                echo "MAIL: ${USER}@jlab.org" >> ${batch}
                echo "Submitting batch"
                eval "jsub ${batch} 2>/dev/null"
                echo " "
                i=$(( $i + 1 ))
		if [ $i == $numlines ]; then
		    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		    echo " "
		    echo "###############################################################################################################"
		    echo "############################################ END OF JOB SUBMISSIONS ###########################################"
		    echo "###############################################################################################################"
		    echo " "
		fi
	    done < "$inputFile"
	    )
	    break;;
        [Nn]* ) 
	    exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
