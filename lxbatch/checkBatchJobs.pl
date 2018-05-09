#!/usr/bin/perl
# -w
use POSIX;
use POSIX qw(strftime);
$now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
print "$now_string\n";

#$queue=shift;
$frequency=shift;
if($frequency==0){
    $frequency=30;
}

#get the initial number
$command="bjobs | wc -l";
$commandrun="bjobs | grep RUN |  wc -l";
$njobsinit=`${command}` - 1;

$njobs=$njobsinit;
while($njobs>0){
   
    $njobs=floor(`${command}`) - 1;
    if($njobs<=0){
	print "All jobs done\n";
	last;
    }
    if($njobs>$njobsinit){
	$njobsinit=$njobs;
    }
    $njobsrun=floor(`${commandrun}`);

    $nstar=100*($njobsrun/$njobsinit);
    $nminus=100*($njobs-$njobsrun)/$njobsinit;

    print "[ $njobsrun / $njobs ]";
    $counterstar=1;
    while($counterstar<=$nstar){
	print "*";
	$counterstar++;
    }
    $counterminus=1;
    while($counterminus<$nminus){
	print "-";
	$counterminus++;
    }
    print "|\n";

    sleep $frequency;
}



$now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
print "$now_string\n";
