#!/bin/bash
export eos='/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select'

export SAMPLELIST=`cat $1 | grep -v "#" | grep -v : | grep -v "/"`

###print the samples
for s in $SAMPLELIST; do
echo $s
done

if [ "$2" == "" ]; then 
exit
fi

echo ${VOMSPASSWD} | voms-proxy-init --pwstdin -voms atlas

#########################
##### Check sites containing the samples
#########################
if [ "$2" == "replicas" ]; then 
echo "Check replicas"
for s in $SAMPLELIST; do
export SCOPE=`echo $s | awk -F'.' '{print $1}'`
if [[ "$SCOPE" == "group" || "$SCOPE" == "user" ]] ; then
export SCOPE=`echo $s | awk -F'.' '{print $1"."$2}'`
fi
rucio list-dataset-replicas ${SCOPE}:$s
done
fi


###########################
##### estimate grid size
##########################
#output path must be provided as 4th argument on command line
if [ "$2" == "size" ]; then 
echo "estimating disk size"
for s in $SAMPLELIST; do
export SCOPE=`echo $s | awk -F'.' '{print $1}'`
if [[ "$SCOPE" == "group" || "$SCOPE" == "user" ]] ; then
export SCOPE=`echo $s | awk -F'.' '{print $1"."$2}'`
fi
#export size=`rucio list-files $SCOPE:$s | grep "Total size :" | awk -F':' '{print $2/1000000000}'`
export size=`rucio list-files $SCOPE:$s | grep "Total size :" | awk -F':' '{print $2}'`
#export Total=`echo $Total.$size | awk -F'.' '{print $1+$2}'`
echo "$size $s"
done
#echo "Total = $Total Gb"
fi

###########################
##### estimate local size
##########################
if [ "$2" == "localsize" ]; then 
export INPATH=$3
echo "estimating disk size"
for s in $SAMPLELIST; do
export size=`du -s $INPATH/$s | awk '{print $1/1000000.}'`
export Total=`echo $Total.$size | awk -F'.' '{print $1+$2}'`
echo "$size Gb : $s"
done
echo "Total = $Total Gb"
fi

###########################
##### estimate eos size
##########################
if [ "$2" == "eossize" ]; then 
export INPATH=$3
echo "estimating disk size"

export Total=0
for s in $SAMPLELIST; do

export Samp=0
for f in `$eos ls $INPATH/$s | grep .root`; do
export size=`$eos ls -l $INPATH/$s/$f | awk -F' ' '{print $5/1000000.}'`
export Samp=`echo $Samp.$size | awk -F'.' '{print $1+$2}'`
done

echo "$Samp Mb : $s"
export Total=`echo $Total.$Samp | awk -F'.' '{print $1+$2}'`
done

echo $Total | awk '{print "Total: "($1/1000)" Gb"}'
fi

##########################
#### verify downloads
##########################
#output path must be provided as 4th argument on command line
if [ "$2" == "verifylocal" ]; then 
echo "Verify local samples"
export OUTPATH=$3

for s in $SAMPLELIST; do

export SCOPE=`echo $s | awk -F'.' '{print $1}'`

if [[ "$SCOPE" == "group" || "$SCOPE" == "user" ]] ; then
export SCOPE=`echo $s | awk -F'.' '{print $1"."$2}'`
fi

#export gridsize=`rucio list-files $SCOPE:$s | grep "Total size :" | awk -F':' '{print $2/1000000}'`
export gridsize=`rucio list-files $SCOPE:$s | grep "Total size :" | awk -F':' '{print $2}'`

#####unit check (local size will be MB)
export gbcheck=`echo $gridsize | grep GB`
if [ "$gbcheck" != "" ]; then
#strip the GB unit
export gridsize=`echo $gridsize | awk -F'GB' '{print (1000*$1)}'`
else
#strip the MB unit
export gridsize=`echo $gridsize | awk -F'MB' '{print $1}'`
fi

####
export gridcheck=`echo $gridsize | awk '{print ($1 > 0.)}'`
if [ "$gridcheck" == "1" ]; then
export localsize=`du -s $OUTPATH/$s | awk -F' ' '{print $1/1000}'`
#export diff=`echo $gridsize:$localsize | awk -F':' '{print (100*sqrt(($1-$2)*($1-$2))/$1) }'`
export diff=`echo $gridsize:$localsize | awk -F':' '{print ($2/$1) }'`
#export pass=`echo $diff | awk '{print ( ($1 < 2.4) && ($1 > 2.3) )}'`
export pass="1" 
#`echo $diff | awk '{print ( $1 < 2.0 )}'`
fi

if [ "$pass" != "1" ]; then
echo "FAIL: $s"
echo "    grid = $gridsize Mb , local = $localsize Mb  ,  diff/grid = $diff % "
else
#echo "PASS: $s"
echo "$diff : $s"
fi

done

fi


##########################
#### check samples against a list in an input file
##########################
if [ "$2" == "diff" ]; then 
echo "Diffing sample list"
#This can be a directory or a file
export OUTPATH=$3

export foundcounter=0
export notfoundcounter=0
for s in $SAMPLELIST; do

if [ -d "$OUTPATH" ]; then
export check=`/bin/ls $OUTPATH | grep $s`
else
export check=`cat $OUTPATH | grep $s`
fi

if [ "$check" == "" ]; then
echo $s >> diff_notfound.tmp
export notfoundcounter=`echo $notfoundcounter | awk '{print $1+1}'`
else
echo $s >> diff_found.tmp
export foundcounter=`echo $foundcounter | awk '{print $1+1}'`
fi
done

echo "FOUND : $foundcounter "
cat diff_found.tmp
echo 
echo "NOT FOUND : $notfoundcounter "
cat diff_notfound.tmp

rm -f diff_found.tmp
rm -f diff_notfound.tmp
fi


###########################
##### download Grid samples to local
##########################
#output path must be provided as 4th argument on command line
if [ "$2" == "grid2local" ]; then 
echo "Downloading xAOD samples to cluster."
export OUTPATH=$3
if [ "$OUTPATH" == "" ]; then exit; fi
for s in $SAMPLELIST; do
echo "Running Grid download for $s"
date
echo ${VOMSPASSWD} | voms-proxy-init --pwstdin -voms atlas

export SCOPE=`echo $s | awk -F'.' '{print $1}'`
if [[ "$SCOPE" == "group" || "$SCOPE" == "user" ]] ; then
export SCOPE=`echo $s | awk -F'.' '{print $1"."$2}'`
fi
rucio download --dir=$OUTPATH $SCOPE:$s &

done
fi

###########################
##### Check the sites containing the samples
##########################
if [ "$2" == "sites" ]; then 
echo "Check sites"
for s in $SAMPLELIST; do
echo "========================================"

export SCOPE=`echo $s | awk -F'.' '{print $1}'`
if [[ "$SCOPE" == "group" || "$SCOPE" == "user" ]] ; then
export SCOPE=`echo $s | awk -F'.' '{print $1"."$2}'`
fi

rucio list-dataset-replicas $SCOPE:$s
done
fi

###########################
##### download samples in the CERN disk 
##########################
#output path must be provided as 4th argument on command line
if [ "$2" == "CERN2local" ]; then 
echo "Downloading CERN DATADISK samples to cluster"
export OUTPATH=$3
echo ${VOMSPASSWD} | voms-proxy-init --pwstdin -voms atlas
if [ "$OUTPATH" == "" ]; then exit; fi

for s in $SAMPLELIST; do
echo "download for $s"
date

export SCOPE=`echo $s | awk -F'.' '{print $1}'`
if [[ "$SCOPE" == "group" || "$SCOPE" == "user" ]] ; then
export SCOPE=`echo $s | awk -F'.' '{print $1"."$2}'`
fi

for f in `rucio list-file-replicas $SCOPE:$s | grep cern.ch | grep .root | awk -F'/eos/' '{print $2}'`; do
$eos cp /eos/$f $OUTPATH/$s/
done
done
fi


#################################
##### clean out the eos directory
#################################
export OUTPATH=$3
if [ "$2" == "cleanlocal" ]; then 
echo "PATH to be cleaned: $OUTPATH"

##loop over the samples
for s in $SAMPLELIST; do
echo "SAMPLE: $s"
rm -rf $OUTPATH/$s;
done

fi

#################################
##### Copy from EOS to local/AFS
#################################
export INPATH=$3
export OUTPATH=$4
if [ "$2" == "eos2local" ]; then 
echo "Copying from eos to local:"
echo "INPATH: $INPATH"
echo "OUTPATH: $OUTPATH"

for s in $SAMPLELIST; do
echo "SAMPLE: $s"

#rm -rf $OUTPATH/$s
mkdir -p $OUTPATH/$s 

for f in `$eos ls $INPATH/$s | grep .root`; do
$eos cp $INPATH/$s/$f $OUTPATH/$s/
done

done
fi


#################################
##### Copy from EOS to local/AFS (input path stored in file)
#################################
export OUTPATH=$3
if [ "$2" == "eos2localHbb" ]; then 

##INPATH should be the first line in the file 
export INPATH=`cat $1 | grep -v "#" | grep "/"`


echo "Copying from eos to local:"
echo "INPATH: $INPATH"
echo "OUTPATH: $OUTPATH"

for s in $SAMPLELIST; do
echo "SAMPLE: $s"

mkdir -p $OUTPATH/$s 

for f in `$eos ls $INPATH/$s | grep .root`; do
$eos cp $INPATH/$s/$f $OUTPATH/$s/
done

done
fi

#################################
##### Copy from EOS to local/AFS (samples are actually directories containing samples)
#################################
export INPATH=$3
export OUTPATH=$4
if [ "$2" == "eos2localdirs" ]; then 

echo "Copying from eos to local:"
echo "INPATH: $INPATH"
echo "OUTPATH: $OUTPATH"

for d in $SAMPLELIST; do
echo "DIR: $d"

for s in `$eos ls -l $INPATH/$d | awk -F" " '{if (match($1,"d")>0){ print $9;}}'`; do
mkdir -p $OUTPATH/$d/$s

for f in `$eos ls $INPATH/$d/$s | grep .root`; do
$eos cp $INPATH/$d/$s/$f $OUTPATH/$d/$s/
done

done

done
fi


#################################
##### Copy  local/AFS to EOS (samples are actually directories containing samples)
#################################
export INPATH=$3
export OUTPATH=$4
if [ "$2" == "local2eosdirs" ]; then 

echo "Copying from local:"
echo "INPATH: $INPATH"
echo "OUTPATH: $OUTPATH"

for d in $SAMPLELIST; do
echo "DIR: $d"
$eos mkdir  $OUTPATH/$d

for s in `/bin/ls $INPATH/$d`; do
$eos mkdir $OUTPATH/$d/$s

for f in `/bin/ls $INPATH/$d/$s | grep .root`; do
$eos cp $INPATH/$d/$s/$f $OUTPATH/$d/$s/
sleep 1
done

done

done
fi


#################################
##### Verify EOS to local/AFS (samples are actually directories containing samples)
#################################
export INPATH=$3
export OUTPATH=$4
if [ "$2" == "verifyeos2localdirs" ]; then 

for d in $SAMPLELIST; do
#echo "DIR: $d"

export SIZE=0
export COUNTER=0
for s in `$eos ls -l $INPATH/$d | awk -F" " '{if (match($1,"d")>0){ print $9;}}'`; do
for f in `$eos ls $INPATH/$d/$s | grep .root`; do
export FSIZE=`$eos ls -l $INPATH/$d/$s/$f | awk -F" " '{print $5/1000000}'`
export SIZE=`echo $FSIZE $SIZE | awk '{print $1+$2}'`
export COUNTER=`echo $COUNTER | awk '{print $1+1}'`
done
done

##get local values
export LOCALSIZE=`du -sb $OUTPATH/$d | awk -F" " '{print $1/1000000}'`
export LOCALCOUNTER=`find $OUTPATH/$d -type f | wc -l`

export SIZERATIO=`echo $LOCALSIZE $SIZE | awk -F" " '{printf("%.3f",$1/$2)}'`

echo "$SIZERATIO : $d [$LOCALSIZE/$SIZE][$LOCALCOUNTER/$COUNTER] "

done
fi


#################################
##### clean out the eos directory
#################################
export EOSPATH=$3
if [ "$2" == "cleaneos" ]; then 
echo "PATH to be cleaned: $EOSPATH"

##loop over the samples
for s in $SAMPLELIST; do
echo "SAMPLE: $s"

##Delete what is there if any
for f in `$eos ls $EOSPATH/$s`; do
$eos rm $EOSPATH/$s/$f;
done

##create the directory
$eos rmdir $EOSPATH/$s 

done
fi

#################################
##### Copy from local/AFS to EOS
#################################
export INPATH=$3
export OUTPATH=$4
if [ "$2" == "local2eos" ]; then 
echo "Copying from local to EOS:"
echo "INPATH: $INPATH"
echo "OUTPATH: $OUTPATH"

##loop over the samples
for s in $SAMPLELIST; do
echo "SAMPLE: $s"

##create the directory
$eos mkdir -p $OUTPATH/$s 

##copy each file
for f in `/bin/ls $INPATH/$s | grep .root`; do
$eos cp $INPATH/$s/$f $OUTPATH/$s/
done

done
fi


#################################
##### Copy files to different folder (ignore sample name)
#################################
export INPATH=$3
export OUTPATH=$4
if [ "$2" == "eosmovefiles" ]; then 
echo "Copying files:"
echo "INPATH: $INPATH"
echo "OUTPATH: $OUTPATH"

for f in `$eos ls $INPATH | grep .root`; do
$eos cp $INPATH/$f $OUTPATH/
done

fi



#################################
##### fix permissions in EOS
#################################
export OUTPATH=$3
if [ "$2" == "eoschmod" ]; then 
echo "Set file  permissions in eos: 750"

#for s in $SAMPLELIST; do
##echo "$OUTPATH/$s"
#$eos chmod -r 750 $OUTPATH/$s
#done

$eos chmod -r 750 $OUTPATH

fi


###################################
############ list samples in local/AFS space
##################################
#output path must be provided as 4th argument on command line
export OUTPATH=$3
if [ "$2" == "lafs" ]; then 
echo "Samples in $OUTPATH/:"
for s in $SAMPLELIST; do
echo "====$s==="
/bin/ls $OUTPATH/$s
done
fi

##################################
############list samples in eos
##################################
#output path must be provided as 4th argument on command line
export OUTPATH=$3
if [ "$2" == "leos" ]; then 
echo "Samples in $OUTPATH:"
for s in $SAMPLELIST; do
echo "======$s========"
$eos ls $OUTPATH/$s
done 
fi

###################################
############remove afs sample
##################################
#output path must be provided as 4th argument on command line
export OUTPATH=$3
if [ "$2" == "rmafs" ]; then 
echo "Removing samples on /afs"
for s in $SAMPLELIST; do
echo "Removing $s:"
rm -rf $OUTPATH/$s
done 
fi

##################################
############remove eos sample
##################################
#$3 is the full path to the eos folder containing the sample
export OUTPATH=$3
#$4 is the string to match files 
export MATCH=$4
if [ "$2" == "rmeos" ]; then 
echo "Removing samples on eos: $OUTPATH"
for s in $SAMPLELIST; do
echo "Removing $s:"
for f in `$eos ls $OUTPATH/$s | grep $MATCH`; do
$eos rm $OUTPATH/$s/$f;
#echo "rm $OUTPATH/$s/$f\n";
done
$eos rmdir $OUTPATH/$s/
done 
fi


#################################
##### merge hist and CxAOD.root (DB framework)
#################################
export OUTPATH=$3
if [ "$2" == "merge" ]; then 
echo "Merging"
for s in $SAMPLELIST; do
echo "$s"

#get the short sample name
export SAMPLE=`echo $s | awk -F '.' '{print $1"."$2"."$3"."$4"."$5}'`

rm -rf $OUTPATH/$s.merged 
mkdir $OUTPATH/$s.merged 

export HISTSAMP=`cat $1.hist | grep $SAMPLE`

for f in `/bin/ls $OUTPATH/$s | grep CxAOD.root`; do
#echo "$OUTPATH/$s/$f"
export HISTFILE=`echo $f | sed 's/CxAOD.root/hist-output.root/'`

if [ -e "$OUTPATH/$HISTSAMP/$HISTFILE" ]; then
#echo "$OUTPATH/$HISTSAMP/$HISTFILE"
hadd $OUTPATH/$s.merged/$f $OUTPATH/$s/$f $OUTPATH/$HISTSAMP/$HISTFILE
fi

done

done
fi



#######################################
#### LPC #############################

#################################
#####download LPC eos -> local
#################################
export INPATH=$3
export OUTPATH=$4
if [ "$2" == "scplpc" ]; then 
echo "Copying files:"
echo "INPATH: $INPATH"
echo "OUTPATH: $OUTPATH"

for s in $SAMPLELIST; do
echo "$s"
scp benitezj@cmslpc-sl6.fnal.gov:$INPATH/$s $OUTPATH/
done

fi


