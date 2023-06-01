#################
### script to transfer a dataset to a local directory in lxplus
#################
## input lines must be in following form
# /store/data/Run2018A/AlCaLumiPixels/ALCARECO/AlCaPCCZeroBias-13Mar2023_UL2018_PCC-v1/2560000/33548116-C1B4-324E-857D-A96056501FD6.root


INPUT=$1
if [ -e $INPUT ]; then
    echo "Input: ${INPUT}"
else
    echo "invalid INPUT"
    exit 1
fi

OUTPATH=$2
if [ "$OUTPATH" == "" ]; then
    OUTPATH="."
fi
echo "OUTPUTPATH: $OUTPATH"

execute=$3 


XRDPATH=root://xrootd-cms.infn.it/
echo $XRDPATH

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

    command="mkdir -p ${OUTPATH}/${SAMPLE}; xrdcp $XRDPATH/$p $OUTPATH/$SAMPLE/"
    echo $command
    if [ $execute == 1 ]; then
	`$command`
    fi
    
done <$INPUT

