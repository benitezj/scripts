export TUPLECONFIG=data/TupleMaker_VHbbResonance/HGTD_TupleMaker.cfg
export TUPLENFILES=1
export TUPLEINPATH=/nfs/uiowapc/data/det-hgtd/aod_nopu
export TUPLESAMPLENAME=VBFH125_bb
export TUPLEOUTPATH=.

###########################################
####Make and plot a ntuple
###########################################
export TUPLECHANNEL=$1
rm -rf $TUPLEOUTPATH/$TUPLESAMPLENAME
tuplemaker local
rm -f $TUPLEOUTPATH/$TUPLESAMPLENAME/*.root 
mv $TUPLEOUTPATH/$TUPLESAMPLENAME/data-output/tuple.root $TUPLEOUTPATH/$TUPLESAMPLENAME/
ls -l $TUPLEOUTPATH/$TUPLESAMPLENAME/tuple.root

