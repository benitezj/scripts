#!/usr/bin/perl
# -w

$test=0;

$localpath="/eos/user/b/benitezj/RunIISummer16MiniAODv3";
print "localpath: $localpath\n";


$samplefiles=shift; #txt file with filenames /store/mc/RunIISummer16MiniAODv3/THQ_Hincl_13TeV-madgraph-pythia8_TuneCUETP8M1/MINIAODSIM/PUMoriond17_94X_mcRun2_asymptotic_v3-v2/120000/90ADEAC0-31EB-E811-8CFF-0CC47AFC3C64.root
print "files: $samplefiles\n";



#$fqdn=shift;  #eg. dcache-se-cms.desy.de
$fqdn=`cat $samplefiles | grep site`;
@fq=split(' ',$fqdn);
$fqdn=$fq[1]; 
print "fqdn: $fqdn\n";


$samplename=`cat $samplefiles | grep -v site | grep -v .root | grep -v \\#`; #eg. /THQ_Hincl_13TeV-madgraph-pythia8_TuneCUETP8M1/RunIISummer16MiniAODv3-PUMoriond17_94X_mcRun2_asymptotic_v3-v2/MINIAODSIM
print "samplename: $samplename\n";

#get the list of files
@files = `cat $samplefiles | grep -v \\# | grep .root`;
$nfiles=@files;
if($nfiles<1){ die "no files found in $samplesfiles";}


#create the output dir
`mkdir -p ${localpath}/${samplename}`;


#copy the files
#xrdcp root://se01.indiacms.res.in:11001//store/mc/RunIISummer16MiniAODv3/THQ_Hincl_13TeV-madgraph-pythia8_TuneCUETP8M1/MINIAODSIM/PUMoriond17_94X_mcRun2_asymptotic_v3-v2/120000/90ADEAC0-31EB-E811-8CFF-0CC47AFC3C64.root /tmp/
$counter=0;
foreach $file (@files){
    chomp($file);
    print "$file\n";
    
    $command="xrdcp root://${fqdn}/${file} ${localpath}/${samplename}/";
    print "$command\n";
    if($test==0){
	`${command}`;
    }
    $counter++;
}
print "$counter files copied\n";
`/bin/ls ${localpath}/${samplename}`;


