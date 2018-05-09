export phrase=$1
export tmppath=$2

for f in `ls $tmppath | grep -v '~' | grep -v RootCoreBin`; do 
 if [ ! -h $f ]; then
   if [ ! -d "$tmppath/$f" ]; then
   
      export tmp=`echo $tmppath/$f | grep $phrase`
      
      if [ "$tmp" != "" ]; then
         echo "$tmppath/$f" 
      fi
   
   else
     
     findrecursiveDIR.sh $phrase $tmppath/$f
       
   fi 

 fi
done
