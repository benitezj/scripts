#################
### script to transfer a dataset to a local directory in lxplus
#################
## input lines must be in following form
# /store/data/Run2018A/AlCaLumiPixels/ALCARECO/AlCaPCCZeroBias-13Mar2023_UL2018_PCC-v1/2560000/33548116-C1B4-324E-857D-A96056501FD6.root

INPUT=$1
if [ -f "$INPUT" ]; then
    echo "Input: ${INPUT}"
else
    echo "invalid INPUT"
    exit 1
fi

OUTPATH=$2
if [ -d "$OUTPATH" ]; then
    echo "OUTPATH: $OUTPATH"
else
    echo "OUTPATH does not exist"
    exit 1
fi

execute=$3 
echo "EXECUTE: $execute"

#XRDPATH=root://xrootd-cms.infn.it/
XRDPATH=root://cms-xrd-global.cern.ch/
echo $XRDPATH

echo ${VOMSPASSWD} | voms-proxy-init -voms cms -rfc

while read p; do

    echo "Begin copy:"
    echo $p
    OLDIFS="$IFS"
    IFS='/' tokens=( $p )
    #echo ${tokens[*]}
    IFS="$OLDIFS" # restore IFS , is used by read

    SAMPLE=${tokens[3]}/${tokens[4]}/${tokens[5]}/${tokens[6]}/${tokens[7]}
    FILE=${tokens[8]}
    #echo $SAMPLE
    #echo $FILE

    echo "mkdir -p ${OUTPATH}/${SAMPLE}"
    echo "xrdcp ${XRDPATH}/${p} ${OUTPATH}/${SAMPLE}/"
   
    if [ "$execute" == 1 ]; then
	mkdir -p ${OUTPATH}/${SAMPLE}
	xrdcp ${XRDPATH}/${p} ${OUTPATH}/${SAMPLE}/
    fi
    
done <$INPUT

