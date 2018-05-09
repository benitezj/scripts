#!/usr/bin/perl
# -w
$file=shift; 

##read the samples
$maxvalue=0.;
$lastmaxvalue=1000000.;
$linecounter = 0;
open FILE, "< ${file}" or die "no  file\n";
while($line=<FILE>){
    #print $line;
    $maxline="not found";
    open FILE2, "< ${file}" or die "no  file\n";
    while($line2=<FILE2>){
	chomp($line2);
	#print "$line2\n";
	@v=split(" ",$line2);
	#print "$v[0]\n";
	if($maxvalue<$v[0] && $v[0]<$lastmaxvalue){
	    $maxvalue=$v[0];
	    $maxline=$line2;
	}
	#print "$maxvalue\n";
	
    }
    close FILE2;
    print "$maxline\n";
    
    $lastmaxvalue=$maxvalue;
    $maxvalue=0.;
    $linecounter++;
}
close FILE;

print "# of lines $linecounter\n";
