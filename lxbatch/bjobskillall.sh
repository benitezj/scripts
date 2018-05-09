for j in `bjobs | awk -F" " '{print $1}' | grep -v JOBID`; do 
#echo $j
bkill $j
done
