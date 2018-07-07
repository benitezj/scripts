export PAPER=paper
if [ "$1" != "" ]; then
export PAPER=$1
fi

# remove the file type
echo $PAPER
export PAPER=`echo ${PAPER} | sed -e 's/.tex//g'`
echo $PAPER

rm -f ${PAPER}.aux ${PAPER}.dvi ${PAPER}.log ${PAPER}.ps ${PAPER}.pdf

pdflatex ${PAPER}.tex  
#latex ${PAPER}.tex  
#dvips ${PAPER}.dvi

rm -f ${PAPER}.aux ${PAPER}.dvi ${PAPER}.log ${PAPER}.ps 