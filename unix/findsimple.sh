export phrase=$1
export tmppath=$2

#echo "Find $phrase in $tmppath"

for f in `ls $tmppath | grep -v '~'`; do 
   #echo $tmppath/$f

   if [ ! -d "$tmppath/$f" ]; then
    export tmp=`cat $tmppath/$f | grep $phrase`
    
    if [ "$tmp" != "" ]; then
        echo "$tmppath/$f" 
    fi
   fi

done
