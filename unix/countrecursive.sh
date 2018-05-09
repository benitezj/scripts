export tmppath=$1
export match=$2
export FILECOUNTER=0

for f in `/bin/ls $tmppath | grep -v '~'`; do 
 if [ ! -d "$tmppath/$f" ]; then
      if [ "$match" != "" ]; then
          export check=`cat $tmppath/$f | grep $match`
          if [ "$check" != "" ] ; then
            export FILECOUNTER=`echo $FILECOUNTER | awk '{print $1+1}'`
          fi
      else
          export FILECOUNTER=`echo $FILECOUNTER | awk '{print $1+1}'`
      fi
 else

 ##recursive not working (counter does not become global)
 ##countrecursive.sh $tmppath/$f $match

   export SAMPLEFILECOUNTER=0
   for f2 in `/bin/ls $tmppath/$f | grep -v '~'`; do 
       if [ ! -d "$tmppath/$f/$f2" ]; then     
            if [ "$match" != "" ]; then
              export check=`cat $tmppath/$f/$f2 | grep $match`
              if [ "$check" != "" ] ; then
                export SAMPLEFILECOUNTER=`echo $SAMPLEFILECOUNTER | awk '{print $1+1}'`
              fi
            else
              export SAMPLEFILECOUNTER=`echo $SAMPLEFILECOUNTER | awk '{print $1+1}'`
            fi
       fi
   done
   echo "$SAMPLEFILECOUNTER : $f"
   export FILECOUNTER=`echo $SAMPLEFILECOUNTER:$FILECOUNTER | awk -F':' '{print $1+$2}'`

 fi
done
echo "======Total:"
echo "$FILECOUNTER : $tmppath"
