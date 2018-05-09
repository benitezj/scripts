#!/bin/bash
export eos='/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select'

##############################################################
##Read the input/output paths and list the samples to be processed
#########################################################

#Input path (for local jobs)
export XAODSAMPLEPATH=""

#Output path (for local jobs this is where the ntuples will be written, 
#for grid jobs it is also needed to store submission directories)
export XAODOUTPATH=""

export counter=0
if [ "$2" != "" ]; then 
for s in `cat $2 | grep -v "#" `; do
echo "$counter $s"

if [ "$counter" == "0" ] ; then
export XAODSAMPLEPATH=$s
fi

if [ "$counter" == "1" ] ; then
export XAODOUTPATH=$s
fi

export counter=`echo $counter | awk '{print $1+1}'`
done
fi

echo "XAODSAMPLEPATH $XAODSAMPLEPATH"
echo "XAODOUTPATH $XAODOUTPATH"

if [ "$XAODSAMPLEPATH" == "" ] || [ "$XAODOUTPATH" == "" ]; then
echo "Wrong input/output paths."
exit
fi



####################################
###add datasets to container
####################################
export CONT=$4
if [ "$1" == "cont" ]; then
echo "Datasets in container before:"
dq2-list-datasets-container $CONT/ | grep .root | wc -l
for s in `cat $2 | grep -v "#" | grep -v / `; do
echo "============$s=========="

export gridname=`echo $s | awk -F'.' '{print $1"."$2"."$3}'`
if [ "$XAODOUTTAG" != "" ]; then
export gridname=${gridname}_${XAODOUTTAG}
fi

export datasetContainer=user.${USER}.${gridname}_outputLabel.root/

for ds in `dq2-list-datasets-container ${datasetContainer}`; do 
echo "register: $ds"
dq2-register-datasets-container $CONT/ $ds
done

echo "======================================================="
done 
echo "Datasets in container after:"
dq2-list-datasets-container $CONT/ | grep .root | wc -l
fi


######################################
#####Remove datasets from the container
######################################
export CONT=$4
if [ "$1" == "cleanCont" ]; then 
echo "Removing samples from container $CONT/"
#loop over all samples in container
for d in `dq2-list-datasets-container $CONT/`; do
#see if this dataset is in the list of the samples to be removed
for s in `cat $2 | grep -v "#" | grep -v / `; do
#use the run number as uniqe identifier
export runid=`echo $s | awk -F'.' '{print "."$2"."}'`

if [ "`echo $d | grep $runid`" != "" ]; then
export command="rucio detach user.${USER}:${CONT}/ $d"
echo $command
$command
fi

done
done
fi



#####################################
###Copy from CERN-PROD_SCRATCHDISK to eos 
#####################################
#output path must be provided as 4th argument on command line
export OUTPATH=$4
if [ "$1" == "cern2eos" ]; then
#loop over the samples
for s in `cat $2 | grep -v "#" | grep -v / `; do
echo "============Copying $s=========="

export gridname=`echo $s | awk -F'.' '{print $1"."$2"."$3}'`
if [ "$XAODOUTTAG" != "" ]; then
export gridname=${gridname}_${XAODOUTTAG}
fi

export datasetContainer=user.benitezj.${gridname}_outputLabel.root/

#print out the list of datasets in each sample
dq2-list-datasets-container $datasetContainer

#loop over the datasets in the sample
for ds in `dq2-list-datasets-container $datasetContainer`; do

#check if the dataset is at CERN
export atcern=`dq2-list-dataset-replicas $ds | grep COMPLETE: | grep CERN-PROD_SCRATCHDISK`
if [ "$atcern" != "" ]; then
echo "$ds is at CERN"

#loop over the root files 
for file in `dq2-ls -L CERN-PROD_SCRATCHDISK -fp $ds  |  grep srm://` ; do


##NOTE the following relies on this format for fullpath:
##/eos/atlas/atlasscratchdisk/rucio/user/benitezj/26/ef/user.benitezj.4644211._000024.outputLabel.root
export fullpath=`echo $file | awk -F'cern.ch' '{print $2}'`
export filename=`echo $fullpath | awk -F'/' '{print $10}'`
if [ "`echo $filename | grep .root`" == "" ];then
echo "Something is wrong with the filename from file path $fullpath"
exit 1
fi

#check the file is not already there from a previous transfer
if [ "`$eos ls $EOSDIR/CxAODSamples/$CXTAG/$s/$filename`" == "" ]; then
$eos cp $fullpath $OUTPATH/$s/
fi

done #rootfiles

fi # if dataset at CERN

done #datasets

echo "======================================================="
done #samples
fi

