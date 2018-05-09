export pkg=$1

for c in `/bin/ls $pkg/$pkg | grep .h | grep -v '~'`; do 
    #export class=`echo $c | awk -F'.h' '{print $1}'`
    export class=$c
    echo "::::::::::::::$class:::::::::::::::::::::::::"
    for d in `/bin/ls $pkg | grep -v '\-gcc'`; do 
       if [ -d "$pkg/$d" ] && [ ! -h $pkg/$d ]; then
         for f in `/bin/ls $pkg/$d | grep -v '~'`; do 
           if [ ! -d "$pkg/$d/$f" ] && [ ! -h $pkg/$d/$f ]; then
               export tmp=`cat $pkg/$d/$f | grep $class`
      
               if [ "$tmp" != "" ]; then
		   echo "$pkg/$d/$f" 
               fi
	   fi
         done
      fi
    done
done
