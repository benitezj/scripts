export PAPER=paper
if [ "$1" != "" ]; then
export PAPER=$1
fi

#rm -f ${PAPER}.aux ${PAPER}.dvi ${PAPER}.log ${PAPER}.ps ${PAPER}.pdf

pdflatex ${PAPER}.tex  
#latex ${PAPER}.tex  
#dvips ${PAPER}.dvi
