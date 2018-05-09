#!/usr/bin/perl
# -w

$sample=shift; #/DYJetsToLL_...
print "$sample\n";


#get the files 
@files= grep { /.root/ }  `cmsLs /store/cmst3/user/benitezj/CMG/${sample}`;
$nfiles=@files;
print "N files: $nfiles\n";

$goodevts=0;
$goodcount=0;
$counter=0;
foreach $i (0 .. $nfiles-1){
    $f=$files[$i];
    chomp($f);
    @part=split(" ",$f);
    $size=$part[1];
    $fname=$part[4];

    $command="edmFileUtil $fname";
	
    #print "$command\n";
    #$output=grep { /ERR/ } `$command`;
    #if($output==1){

    $output=`${command}`;
    chomp($output);
    @evts=split(" ",$output);

    #print "=$output=$evts[7]\n";
    if($evts[6]>1 && $evts[7] eq "events,"){
	$goodevts+=$evts[6];
	$goodcount++;
    }else {
	$rmcmd="cmsRm $fname";	
	print "$rmcmd\n";
	`$rmcmd`;
	$counter++;
    }

}

print "removed $counter files\n";
print "good files $goodcount , good events $goodevts\n";
