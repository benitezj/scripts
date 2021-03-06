#!/usr/bin/perl
# -w

$file1 = shift;#
$file2 = shift;#


####read the files only once and store run and event ids in arrays
$N1=0;
foreach $line1 (`cat $file1`){
    chomp($line1);
    $line1 =~ s/^\s+|\s+$//g; ##remove beg/end spaces
    @linewords1=split(" ",$line1);    
    $run1[$N1]   = $linewords1[0];
    $event1[$N1] = $linewords1[1];
    $N1++;
}

$N2=0;
foreach $line2 (`cat $file2`){
    chomp($line2);
    $line2 =~ s/^\s+|\s+$//g; ##remove beg/end spaces
    @linewords2=split(" ",$line2);    
    $run2[$N2]   = $linewords2[0];
    $event2[$N2] = $linewords2[1];
    $N2++;
}



#########################################################
print "\n ===============\n";
print "Events NOT in $file2\n";
$notinFile2=0;
foreach $i (0 ... $N1-1){
    $found=0;
    foreach $j (0 ... $N2-1){
	if(  $event2[$j]==$event1[$i]){
	    $found=1;
	    last;##found it, skip the rest 
	}
    }
    
    if($found==0){
	print "$run1[$i] $event1[$i]\n";
	$notinFile2++;
    }

}

#########################################################
print "\n ===============\n";
print "Events NOT in $file1\n";
$notinFile1=0;
foreach $j (0 ... $N2-1){
    $found=0;
    foreach $i (0 ... $N1-1){
	if( $event2[$j]==$event1[$i]){
	    $found=1;
	    last;##found it, skip the rest 
	}
    }
    if($found==0){
	print "$run2[$j] $event2[$j]\n";
	$notinFile1++;
    }
}

#####################
print "$notinFile2 Events NOT in $file2 \n";
print "$notinFile1 Events NOT in $file1 \n";
