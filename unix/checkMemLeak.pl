#!/usr/bin/perl
# -w



#$user=env($USER);
#$jobid=shift;
$progname=shift;
$jobid=`ps -u \$USER | grep $progname | awk -F" " '{print \$1}'`;
chomp($jobid);

$jobidcheck=$jobid;



#get the initial memory and time
$jobstats=`ps v ${jobid}`;
@jobstatswords=split(" ",$jobstats);
$initmem=$jobstatswords[18];
$inittimestring=$jobstatswords[13];
@inittimewords=split(":",$inittimestring);
$inittime=60*$inittimewords[0]+$inittimewords[1];


use POSIX;

while($jobidcheck==$jobid){
    
    #wait 2 seconds between checks;
    sleep 2;
    
    $timenow = `date | awk -F" " '{print \$4}'`;
    chomp($timenow);

    #$jobstats=`ps v ${jobid}`;
    $jobstats=`ps ef -o pid,vsize,rss,%mem ${jobid}`;
    #print " $jobstats\n";
    @jobstatswords=split(" ",$jobstats);
    
    #when job is terminated this script will terminate
    #$jobidcheck=$jobstatswords[10];
    $jobidcheck=$jobstatswords[4];
    
    #get the time
    #$timestring=$jobstatswords[13];
    #@timewords=split(":",$timestring);
    #$time=60*$timewords[0]+$timewords[1] - $inittime;

    #$FRAC=$jobstatswords[18];
    $FRAC=$jobstatswords[7];

    #$VSZ=floor($jobstatswords[5]/100.)/10;
    #$RSS=floor($jobstatswords[6]/100.)/10;
    $VSZ=floor($jobstatswords[5]/1000.);
    $RSS=floor($jobstatswords[6]/1000.);

    print "$timenow [$jobidcheck]: RSS=${RSS}Mb,VSZ=${VSZ}Mb";
    $mem=10*$initmem;
    $counter=0;
    while($mem<10*$FRAC){
	print "-";
	$mem++;
	$counter++;
    }
    if($counter>=40){
	#rescale
	$initmem=$FRAC;
    }
    
    print ">(${FRAC}%)\n";
    

}



