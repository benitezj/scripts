#!/usr/bin/perl
# -w

#First and last job to kill 
#All job ids in between will also be killed but not affected as they do not belong to me

$first=shift;
$last=shift;

$bjobid=$first;
while($bjobid<=$last){ 
    system("bkill -u benitezj $bjobid");
    #print "bkill $bjobid\n";
    $bjobid++;  
}
   
$nkilled=$last-$first+1;
print "killed $nkilled\n";
exit;
