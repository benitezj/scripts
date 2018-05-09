#!/usr/bin/perl
# -w

$user=shift;
$sample=shift; #/TauPlusX/Run2011A-05Aug2011-v1/AOD/V2/PAT_CMG_V2_3_0/H2TAUTAU_Nov16
$filter=shift; # e.g fullsel

$lfnpath="/store/cmst3/user/${user}/CMG${sample}";

#filter the file names
$grep= "grep tree_CMG_";
if($filter ne ""){
    $grep="${grep} | grep ${filter}";
}

#get the list of files
@files = `cmsLs  $lfnpath | ${grep}`;
$nfiles=@files;
if($nfiles<1){ die "no files found in $lfnpath";}

##create the directory
print "mkdir -p .${sample}\n";
`mkdir -p .${sample}`;

#copy the files
$counter=0;
foreach $file (@files){
    chomp($file);
    @root=split(" ",$file);
    #print "cmsStage $root[4]\n";
    `cmsStage -f $root[4] .${sample}`;
    $counter++;
}
print "$counter files copied\n";
