export phrase=$1
export tmppath=$2

for f in `ls $tmppath | grep -v '~' `; do 
    if [ ! -h $f ]; then
	if [ ! -d "$tmppath/$f" ]; then
	    export tmp=`cat $tmppath/$f | grep $phrase`
	    if [ "$tmp" != "" ]; then
		echo "$tmppath/$f" 
	    fi
	fi 
    fi
done
