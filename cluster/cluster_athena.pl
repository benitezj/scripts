#!/usr/bin/perl
# -w
use File::Basename;
$eos="/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select";

$samplesfile=shift;#must be a full path in AFS
$option=shift;

###check submitting from an /nfs path otherwise jobs wont run
$pwd = getenv("PWD");
if( `echo $pwd | grep /nfs` eq ""){
    print "current path is not in /nfs.\n";
    exit;
}


##Determine path where log files will be written
$samplesfile = `readlink -e $samplesfile`;
chomp($samplesfile);
$SUBMITDIR = dirname($samplesfile);
###check SUBMITDIR is in /nfs otherwise jobs will fail because cannot write logs
if( `echo ${SUBMITDIR} | grep /nfs/` eq ""){
    print "SUBMITDIR is not in /nfs.\n";
    exit;
}


##determine the input and output paths
open(my $FILEHANDLE, '<:encoding(UTF-8)', $samplesfile)
or die "Could not open file '$samplesfile' $!";
$INPUTDIR = <$FILEHANDLE>;
$INPUTDIR =~ s/^\s+|\s+$//g;
$OUTPUTDIR = <$FILEHANDLE>;
$OUTPUTDIR =~ s/^\s+|\s+$//g;

print "Overriding OUTPUTDIR\n";
$OUTPUTDIR = $SUBMITDIR;

##determine if reading from EOS
$instorage="";
if( `echo $INPUTDIR | grep eos` ne ""){
$instorage="eos";
}


##determine if writing to EOS
$outstorage="";;
if( `echo $OUTPUTDIR | grep eos` ne ""){
$outstorage="eos";
}

###
print "INPUTDIR  = $INPUTDIR\n";
print "OUTPUTDIR = $OUTPUTDIR\n";
#print "SUBMITDIR = $SUBMITDIR\n";

##read the samples list
@samples=`cat $samplesfile | grep "." | grep -v "#" | grep -v '/' `;
$counter = 0;
foreach $samp (@samples){
    chomp($samp);
    $samp =~ s/^\s+|\s+$//g; ##remove beg/end spaces
    print "$option $samp\n";
    $samples[$counter] = $samp;
    $counter++;
}


####Clean out the output directory
if($option eq "clean"){
    print "-------------------------\n";
    print "Removing all files inside output directory:\n";
    print "-------------------------\n";
    foreach $samp (@samples){
	if($outstorage eq  "eos"){
	    @files=`$eos ls $OUTPUTDIR/$samp`; 
	    foreach $file (@files){
		chomp($file);
		$command="$eos rm $OUTPUTDIR/$samp/$file";
		print "$command\n";
		system($command);
	    }
	    $command="$eos rmdir $OUTPUTDIR/$samp";
	    print "$command\n";
	    system($command);
	}else {
	    $command="rm -f $OUTPUTDIR/$samp/tuple_*";
	    print "$command \n";
	    system($command);
	}
    }


    ####clean out the submission directory
    print "-------------------------\n";
    print "Removing all files in submit directory:\n";
    print "-------------------------\n";
    foreach $samp (@samples){
	$command="rm -rf ${SUBMITDIR}/${samp}";
	print "$command \n";
	system($command);
    }
}


#########Condor submission script
sub makeCondorSub {
    $SUBMITDIR=$_[0];
    $sample=$_[1];
    $idx=$_[2];
    
    $outfile="${SUBMITDIR}/${sample}/tuple_${idx}.sub";
    `rm -f $outfile`;
    `touch $outfile`;

    `echo "Universe   = vanilla" >> $outfile`; 
    `echo "Executable = /bin/bash" >> $outfile`; 
    `echo "Arguments  = ${SUBMITDIR}/${sample}/tuple_${idx}.sh" >> $outfile`; 
    `echo "Log        = ${SUBMITDIR}/${sample}/tuple_${idx}.condor.log" >> $outfile`; 
    `echo "Output     = ${SUBMITDIR}/${sample}/tuple_${idx}.log" >> $outfile`; 
    `echo "Error      = ${SUBMITDIR}/${sample}/tuple_${idx}.condor.log" >> $outfile`; 
    `echo "Queue  " >> $outfile`; 
}

#########Write config parameters for job
sub writeJobConfig {
    $outfile = $_[0];
    $sample = $_[1];
    $idx = $_[2];
    $cpout = $_[3];
    $OUTPUTDIR = $_[4];
    $algo = $_[5];
    $NEVT = $_[6];
    $SKIP = $_[7];
    $CFG = $_[8];

    ##in the following use the job index as random seed
    if( $algo eq "HGTDSIM" ){
        `echo "source ${CFG} 'in/*.root*' ${NEVT} ${SKIP} ${idx}" >> $outfile`;
	`echo "cat ./log.*" >> $outfile`;	
	`echo "cat ./eventLoopHeartBeat.txt" >> $outfile`;	
	`echo "${cpout} ./HITS.pool.root ${OUTPUTDIR}/${sample}/HITS_${idx}.root " >> $outfile`;	
    }elsif( $algo eq "HGTDSIMMERGE" ){ 
        `echo "source ${CFG} 'in/*.root*' " >> $outfile`;
	`echo "cat ./log.*" >> $outfile`;	
	`echo "cat ./eventLoopHeartBeat.txt" >> $outfile`;	
	`echo "${cpout} ./HITS.pool.root ${OUTPUTDIR}/${sample}/HITS_${idx}.root " >> $outfile`;	
    }elsif( $algo eq "G4SCAN" ){
        `echo "source ${CFG} 'in/*.root*' ${NEVT} ${SKIP} ${idx}" >> $outfile`;
	`echo "cat ./log.*" >> $outfile`;	
	`echo "cat ./eventLoopHeartBeat.txt" >> $outfile`;	
	`echo "${cpout} ./rad_intLength.histo.root ${OUTPUTDIR}/${sample}/histo_${idx}.root " >> $outfile`;	
    }elsif( $algo eq "HGTDDIGI" ){ 
        `echo "source ${CFG} 'in/*.root*' ${NEVT} ${SKIP} ${idx}" >> $outfile`;
	`echo "cat ./log.*" >> $outfile`;	
	`echo "cat ./eventLoopHeartBeat.txt" >> $outfile`;	
	`echo "${cpout} ./RDO.pool.root ${OUTPUTDIR}/${sample}/RDO_${idx}.root " >> $outfile`;	
    }elsif( $algo eq "HGTDRECO" ){
        `echo "source ${CFG} 'in/*.root*' ${NEVT} ${SKIP} ${idx}" >> $outfile`;
	`echo "cat ./log.*" >> $outfile`;	
	`echo "cat ./eventLoopHeartBeat.txt" >> $outfile`;	
	`echo "${cpout} ./AOD.pool.root ${OUTPUTDIR}/${sample}/AOD_${idx}.root " >> $outfile`;	
    }elsif( $algo eq "HGTDTUPLE" ){
        `echo "export TUPLESAMPLE='in/*.root*'" >> $outfile`;
        `echo "export OUTPUTDIR=${OUTPUTDIR}" >> $outfile`;

	##Jobs accessing LArHits need to load the geometry and there is a special file created in the testarea (by the Sim step)
        ## for the inner detector that athena loads at runtime.
	## `echo "ln -s \$PWD/HGTDAnalysisTools/share/InDetIdDictFiles ./InDetIdDictFiles" >> $outfile`;
        `echo "ln -s \$PWD/InDetIdDictFiles ./InDetIdDictFiles" >> $outfile`;

	#`echo "\$PWD/InstallArea/share/bin/athena.py $CFG" >> $outfile`;
	`echo "athena.py ${CFG}" >> $outfile`;

	`echo "${cpout} ./tuple.root ${OUTPUTDIR}/${sample}/tuple_${idx}.root " >> $outfile`;	
    }else{
	print "cluster.pl: Unrecognized algorithm: ${algo} \n";
	exit;
    }

    `echo "echo '+++++++++++++Output File+++++++++++:'; /bin/ls -l ${OUTPUTDIR}/${sample}/*_${idx}.*root " >> $outfile`;
}


#######FUNCTION FOR MAKING JOB EXECUTION SCRIPTS
sub makeClusterJob {
    $OUTPUTDIR = $_[0];
    #print "OUTPUTDIR $OUTPUTDIR\n";
    $SUBMITDIR = $_[1];
    #print "SUBMITDIR $SUBMITDIR\n";
    $sample = $_[2];
    #print "sample $sample\n";
    $idx = $_[3];
    #print "idx $idx\n";
    $cpin = $_[4];
    #print "cpin $cpin\n";
    $cpout = $_[5];
    #print "cpout $cpout\n";
    $filelist = $_[6];
    #print "filelist $filelist\n";
    $algo = $_[7];
    #print "algo $algo\n";
    $NEVT = $_[8];
    #print "NEVT $NEVT\n";
    $SKIP = $_[9];
    #print "SKIP $SKIP\n";
    $CFG = $_[10];
    #print "CFG $CFG\n";

    $outfile="${SUBMITDIR}/${sample}/tuple_${idx}.sh";
    `rm -f $outfile`;
    `touch $outfile`;

    `echo "echo '+++++++++++++User+++++++++++:'; whoami; " >> $outfile`;

    #machine where the job executes
    `echo "echo '+++++++++++++Machine+++++++++++:'; echo \\\$HOSTNAME  " >> $outfile`;
    `echo "echo '+++++++++++++Initial Dir+++++++++++:'; pwd " >> $outfile`;

    #setup environment
    #`echo "export HOME=/nfs/home/condor " >> $outfile`;
    #`echo "source \\\$HOME/.bash_profile  " >> $outfile`;
    `echo "export HOME=\\\$TMPDIR " >> $outfile`;    

    ###environment
    `echo "echo '+++++++++++++ATLAS Setup+++++++++++:' " >> $outfile`; 
    `echo "export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase  " >> $outfile`;
    `echo "source \\\$ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh  " >> $outfile`;
    `echo "source \\\$AtlasSetup/scripts/asetup.sh --restore " >> $outfile`;

    #dump PATH
    `echo "echo '+++++++++++++PATH+++++++++++++:'; echo \\\$PATH  " >> $outfile`;

    #go the execute directory
    `echo "echo '+++++++++++++Executing+++++++++++:'" >> $outfile`;
    `echo "cd \\\$TMPDIR"  >> $outfile`;

    #copy the files locally
    `echo "echo '+++++++++++++Downloading files+++++++++++:'; " >> $outfile`;
    `echo "mkdir -p ./in " >> $outfile`;
    `echo "${cpin} ${filelist} ./in/" >> $outfile`;
    `echo "export INPUTFILELIST='${filelist}'" >> $outfile`;
    `echo "echo '+++++++++++++Download Dir+++++++++++:'; /bin/ls -l ./in/  " >> $outfile`;

    #run program
    `echo "echo '+++++++++++++Enviroment+++++++:'; printenv" >> $outfile`;    
    writeJobConfig($outfile,$sample,$idx,$cpout,$OUTPUTDIR,$algo,$NEVT,$SKIP,$CFG);
    `echo "echo '+++++++++++++Execute Dir+++++++++++:'; pwd; /bin/ls -l " >> $outfile`;

    makeCondorSub($SUBMITDIR,$sample,$idx);
}

######Make the execution scripts
if($option eq "create"){

    $InputCollSize=shift;
    print "Number of events per input file : $InputCollSize\n";

    $EventsToMerge=shift;
    print "Number of events per job : $EventsToMerge\n";

    $algo=shift;
    print "Algorithm to run: $algo \n";

    $config=shift;
    print "Command to run : $config\n";
    #cfg needs to be copied for each sample in case of OUTPUTDIR is full sample path and sample=.
    #get script extension (.py is needed for athena to run)
    $cfgnw = (@cfgext=split('\.',$config)) - 1;
    $cfgextension = $cfgext[$cfgnw];
    $cfg = "$SUBMITDIR/cfg.$cfgextension";
    `/bin/cp $config $cfg`;
    

    ##check valid inputs
    if( $algo eq "" || $InputCollSize eq "" || $EventsToMerge eq "" || $config eq ""){
	print "Bad inputs provided\n";
	exit(0);
    }

    ## determine how many jobs per file
    if($InputCollSize > $EventsToMerge ){
	if($InputCollSize % $EventsToMerge > 0){
	    $NJOBS=floor($InputCollSize/$EventsToMerge) + 1;
	}else {
	    $NJOBS=floor($InputCollSize/$EventsToMerge);
	}
    }else {
	if( $EventsToMerge % $InputCollSize != 0 ){
	    print "EventsToMerge is not an integer multiple of InputCollSize\n";
	    exit(0);
	} 
	$NJOBS = $EventsToMerge/$InputCollSize;
    }
    
    #Determine how to read the input
    if($instorage eq  "eos"){
	$cpin="$eos cp";
    }else {
	$cpin="/bin/cp";
    }

    #determine how to write the output
    if($outstorage eq  "eos"){
	$cpout="$eos cp";
    }else{
	$cpout="/bin/cp";
    }
    

    foreach $samp (@samples){
	#create the submission directory
	`mkdir $SUBMITDIR/$samp`;

	#create the output directory
	if($outstorage eq  "eos"){
	    $command="$eos mkdir $OUTPUTDIR/$samp";
	    print "$command\n";
	    system($command);
	}else{
	    if($SUBMITDIR ne $OUTPUTDIR){
		$command="mkdir $OUTPUTDIR/$samp";
		print "$command\n";
		system($command);
	    }
	}

	#get list of input files
	if($instorage eq  "eos"){
	    @dirlist=`$eos ls $INPUTDIR/$samp | grep .root`;
	}else {
	    @dirlist=`/bin/ls $INPUTDIR/$samp | grep .root`;
	}

	##loop over the input files and merge
	$filecntr=0;
	$arrsize=@dirlist;
	$jobidx=0;
	$filelist="";
	$nfiles=0;
	for $file (@dirlist){
	    $filecntr++;
	    chomp($file);

	    if($InputCollSize > $EventsToMerge ){
		#loop over the jobs for this file
		for $fileidx (0 ... $NJOBS - 1){
		    makeClusterJob($OUTPUTDIR,$SUBMITDIR,$samp,$jobidx,$cpin,$cpout,"${INPUTDIR}/${samp}/${file}",$algo,$EventsToMerge,$fileidx*$EventsToMerge,$cfg);
		    $jobidx++;
		}
	    }else {
		$filelist = "${filelist} ${INPUTDIR}/${samp}/${file}";
		$nfiles++;
		if($nfiles == $NJOBS || $filecntr == $arrsize){
		    makeClusterJob($OUTPUTDIR,$SUBMITDIR,$samp,$jobidx,$cpin,$cpout,$filelist,$algo,$EventsToMerge,0,$cfg);
		    $jobidx++;
		    $nfiles=0;
		    $filelist="";
		}
	    }
	}
	print "\n $jobidx : ${samp}\n";
    }
}

####define batch submit function
sub submit {
    $path = $_[0];
    $idx= $_[1];
    system("rm -f ${path}/*_${idx}.root");
    system("rm -f ${path}/*_${idx}.*log");
    $command="condor_submit ${path}/tuple_${idx}.sub";  
    print "$command\n";
    system("$command");
}

#submit all jobs
if($option eq "sub" ){
    $MAXJOBS=shift;#submit only MAXJOBS per sample

    $SKIP=shift;#skip N jobs before submitting

    foreach $samp (@samples){
	$idx=-1;	
	$subcntr=0;
	for $f (`/bin/ls $SUBMITDIR/$samp | grep tuple_ | grep .sh`){
	    chomp($f);
	    $idx++;
	    if($SKIP ne "" && $idx<$SKIP){next;}
	    submit("$SUBMITDIR/$samp",$idx); $subcntr++;
	    if($MAXJOBS ne "" && $subcntr==$MAXJOBS){last;}
	}
	print "\n Submitted $subcntr jobs for ${samp}\n";
    }
}

####Check the job output
if($option eq "check"){
    $resub=shift;

    $MAXJOBS=shift;#submit only MAXJOBS per sample

    $SKIP=shift;#skip N jobs before checking 

    $sampidx=0;
    foreach $samp (@samples){
	chomp($samp);
	$samp =~ s/^\s+|\s+$//g; ##remove beg/end spaces

	$idx=-1;
	$totallogfiles=0;
	$failedlist="";
	$failcounter=0;
	$failcounterwithlog=0;
        $checkcounter=0;
	for $f (`/bin/ls $SUBMITDIR/$samp | grep tuple_ | grep .sh | grep -v "~" `){
	    $idx++;
	    if($SKIP ne "" && $idx < $SKIP ) {next;} # skip this job
	    if($MAXJOBS ne "" && $checkcounter>=$MAXJOBS){last;} # terminate loop
            $checkcounter++;

	    #chomp($f);
	    $job="${samp}/tuple_${idx}";
	    #print "JOB: ${job}\n";

	    $failed=0;
	    $log=0;

 	    #check the root file was produced
	    $rootfile=`/bin/ls ${OUTPUTDIR}/${samp} |  grep _${idx}.root`;
	    chomp($rootfile);
	    if($rootfile eq ""){
		print "JOB${idx}: No root file \n";
		$failed = 1; 
	    }

	    #check a log file was produced
	    if(!(-e "${SUBMITDIR}/${job}.log")){ 
		print "JOB${idx}: No log file \n"; 
		$failed = 1; 
	    }
	    else {
		$log=1;
		$totallogfiles++;

		###for Debugging
		$FATAL=`tail -n 100 ${SUBMITDIR}/${job}.log |  grep FATAL`;
		if($FATAL ne ""){
		    #print "JOB${idx}: $FATAL \n";
		    $failed = 1; 
		}

		$KILLED=`tail -n 100 ${SUBMITDIR}/${job}.log |  grep Killed`;
		if($KILLED ne ""){
		    #print "JOB${idx}: $KILLED \n";
		    $failed = 1; 
		}

		if($failed == 1){
		    $MACHINE=`head -10 ${SUBMITDIR}/${job}.log |  grep uiowapc`;
		    chomp($MACHINE);
		    $KILLED= $KILLED ne "";
		    $FATAL= $FATAL ne "";
		    print "JOB${idx}: $MACHINE, FATAL=$FATAL, KILLED=$KILLED\n";
		}

	    }
	    
	    





	    ###Resubmit
	    if($failed == 1){
		$failcounter++;	
		$failedlist="${failedlist},${idx}";
		if($log){ $failcounterwithlog++; }

		if($resub eq "clean"){
		    ##do not resubmit job just remove root files
		    `/bin/rm ${OUTPUTDIR}/${samp}/*_${idx}.root`;
		}
	
		if($resub eq "sub" ){
		    submit("${SUBMITDIR}/${samp}",$idx);
		    print "Job $idx resubmitted.\n";
		}
	    }
	    
	}

	$totaljobs= $idx + 1;
	$Summary[$sampidx++]="Failed: $failcounter ($failcounterwithlog) / $totaljobs ($totallogfiles): ${samp} \n ${failedlist}";
    }

    $sampidx=0;
    foreach $samp (@samples){
	print "$Summary[$sampidx]\n";
	$sampidx++;
    }
}

######################################################################
##### job info 
######################################################################
if($option eq "info"){

    $sampidx=0;
    foreach $samp (@samples){
	chomp($samp);
	$samp =~ s/^\s+|\s+$//g; ##remove beg/end spaces

	$idx=-1;	
	for $f (`/bin/ls $SUBMITDIR/$samp | grep tuple_ | grep .sh | grep -v "~" `){
	    $idx++;
	    
	    #chomp($f);
	    $job="${SUBMITDIR}/${samp}/tuple_${idx}";

	    $machine="";
	    if(-e "${job}.log"){
		$machine=`cat ${job}.log | grep -v "running on" | grep -v nfs | grep "uiowapc" | grep ".cern.ch"`;
		chomp($machine);
	    }

	    $mem[5]=0;
	    $startTime[2]="";
	    $startTime[3]="";
	    $endTime[2]="";
	    $endTime[3]="";
	    if(-e "${job}.condor.log"){
		@mem=split(" ",`cat ${job}.condor.log | grep "Memory (MB)"`);
		@startTime=split(" ",`cat ${job}.condor.log | grep "Job executing on host"`);
		@endTime=split(" ",`cat ${job}.condor.log | grep "Job terminated"`);
	    }
	    
	    ##Compute total wall time
	    $deltaT=0;
	    @startString=split(":",$startTime[3]);
	    $startMinute=60*$startString[0]+$startString[1];
	    @endString=split(":",$endTime[3]);
	    $endMinute=60*$endString[0]+$endString[1];
	    if($startTime[2] ne $endTime[2]){$endMinute += 60*24;}##in case job ended next day
	    if($endTime[2] ne ""){$deltaT=$endMinute-$startMinute;}


	    print "$idx : $machine, $mem[5] Mb, $deltaT min \n";
	}
    }
}


######################################################################
##### number of events
######################################################################
if($option eq "events"){
    $MAXJOBS=shift;
    $SKIP=shift;#skip N jobs before checking 

    $sampidx=0;
    foreach $samp (@samples){
	chomp($samp);
	$samp =~ s/^\s+|\s+$//g; ##remove beg/end spaces

	$idx=0;	
	$checkcounter=0;
	for $f (`/bin/ls $SUBMITDIR/$samp | grep tuple_ | grep .sh | grep -v "~" `){
	    
	    $rootfile[$idx]=`/bin/ls $OUTPUTDIR/$samp | grep  _${idx}.root`;
	    chomp($rootfile[$idx]);
	    
	    if($rootfile[$idx] ne "" && ($idx>=$SKIP || $SKIP eq "")){
		$tuplefile=`echo $rootfile[$idx] | grep tuple_`;
		if($tuplefile ne ""){
		    $NEVT[$idx]=`checkrootfile  $OUTPUTDIR/$samp/$rootfile[$idx] tuple`;
		}else { 
		    $NEVT[$idx]=`checkrootfile  $OUTPUTDIR/$samp/$rootfile[$idx] CollectionTree`; 
		}
		chomp($NEVT[$idx]);
		$checkcounter++;
	    }

	    #print "JOB$idx: $NEVT[$idx]  $OUTPUTDIR/$samp/$rootfile[$idx] \n";
	    $idx++;	  
	    if($checkcounter==$MAXJOBS){last;}
	}
	
	$totalevents=0;		
	for $i (0 ... $idx-1){
	    if( $rootfile[$i] ne ""){
		print "JOB$i: $NEVT[$i] $samp/$rootfile[$i] \n";
		$totalevents+=$NEVT[$i]
	    }else {
		print "JOB$i: -\n";
	    }
	} 	
	print "$totalevents $samp\n";

    }
}



######################################################################
##### Check the jobs running in the cluster
######################################################################
if($option eq "monitor" ){
    use POSIX;
    use POSIX qw(strftime);
    
    $frequency=shift;
    if($frequency==0){
	$frequency=20;
    }
    
    #get the initial number
    #$command="condor_q -global benitezj | grep 'jobs;' | awk -F' ' '{print \$1}'";
    #$commandrun="condor_q -global benitezj | grep 'jobs;' | awk -F' ' '{print \$9}'";
    #$command="condor_q -totals | grep 'jobs;' | awk -F' ' '{print \$1}'";
    #$commandrun="condor_q -totals | grep 'jobs;' | awk -F' ' '{print \$9}'";
    $command="condor_q -totals benitezj | grep 'jobs;' | awk -F' ' '{print \$1}'";
    $commandrun="condor_q -totals benitezj | grep 'jobs;' | awk -F' ' '{print \$9}'";

    
    $njobsinit=`${command}`;
    chomp($njobsinit);

    $njobs=$njobsinit;
    while($njobs>0){
	
	##total number of jobs in queue
	$njobs=`${command}`;
	chomp($njobs);
	$njobs=floor($njobs);
	if($njobs<=0){
	    print "All jobs done\n";
	    last;
	}
	if($njobs>$njobsinit){
	    $njobsinit=$njobs;
	}

	###total number of jobs running
	$njobsrun=`${commandrun}`;
	chomp($njobsrun);
	$njobsrun=floor($njobsrun);


	###display : running jobs with *'s , total jobs with -'s
	$nstar=100*($njobsrun/$njobsinit);
	$nminus=100*($njobs-$njobsrun)/$njobsinit;


	#$now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
	$now_string = strftime "%H:%M:%S", localtime;
	print "[$now_string] ";

	print " $njobsrun / $njobs :";
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
}
