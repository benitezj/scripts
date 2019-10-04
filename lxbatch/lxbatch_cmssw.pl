#!/usr/bin/perl
# -w
use File::Basename;
use POSIX ();

$eos="/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select";

$samplesfile=shift;#must be a full path in AFS
$option=shift;

###check submitting from an /afs path otherwise jobs wont run
$pwd = $ENV{'PWD'};#getenv("PWD");
if( `echo $pwd | grep /afs` eq ""){
    print "current path is not in /afs.\n";
    exit;
}


##Determine path where log files will be written
$samplesfile = `readlink -e $samplesfile`;
chomp($samplesfile);
$SUBMITDIR = dirname($samplesfile);
###check SUBMITDIR is in /nfs otherwis jobs will fail because cannot write logs
if( `echo ${SUBMITDIR} | grep /afs/` eq ""){
    print "SUBMITDIR is not in /afs.\n";
    exit;
}


##determine the input and output paths
open(my $FILEHANDLE, '<:encoding(UTF-8)', $samplesfile)
or die "Could not open file '$samplesfile' $!";
$INPUTDIR = <$FILEHANDLE>;
$INPUTDIR =~ s/^\s+|\s+$//g;
$OUTPUTDIR = <$FILEHANDLE>;
$OUTPUTDIR =~ s/^\s+|\s+$//g;

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


##
print "INPUTDIR  = $INPUTDIR\n";
print "OUTPUTDIR = $OUTPUTDIR\n";
print "SUBMITDIR = $SUBMITDIR\n";

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
	    $command="rm -rf $OUTPUTDIR/$samp";
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

    ## here need to check how the inputfiles get fed
    `echo "cmsRun \$PWD/${CFG}" >> $outfile`;

    ## here need to check what is the out file name
    `echo "${cpout} ./file.root ${OUTPUTDIR}/${sample}/tuple_${idx}.root " >> $outfile`;	

}


#######FUNCTION FOR MAKING JOB EXECUTION SCRIPTS
sub makeBatchJob {
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

    ###environment
    `echo "set TOP=\\\$PWD "  >> $outfile`;
    `echo "cd \\\$LS_SUBCWD  "  >> $outfile`;
    `echo "eval \\\`scramv1 runtime -sh\\\`  "  >> $outfile`;
    `echo "cd \\\$TOP  "  >> $outfile`;
    
    ####copy the files locally
    `echo "echo '+++++++++++++Downloading files+++++++++++:'; " >> $outfile`;
    `echo "mkdir -p ./in/${sample} " >> $outfile`;
    `echo "${cpin} ${filelist} ./in/${sample}/" >> $outfile`;
    `echo "/bin/ls -l ./in/${sample}" >> $outfile`;

    ####run program
    `echo "echo '+++++++++++++Enviroment+++++++:'; printenv" >> $outfile`;    
    writeJobConfig($outfile,$sample,$idx,$cpout,$OUTPUTDIR,$algo,$NEVT,$SKIP,$CFG);

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


    ##chec inputs
    if( $algo eq "" ){
	print "Wrong algorithm.\n";
	exit(0);
    }

    if($InputCollSize > $EventsToMerge ){
	if($InputCollSize % $EventsToMerge > 0){
	    $NJOBS=POSIX::floor($InputCollSize/$EventsToMerge) + 1;
	}else {
	    $NJOBS=POSIX::floor($InputCollSize/$EventsToMerge);
	}
    }else{
	if( $EventsToMerge % $InputCollSize != 0 ){
	    print "EventsToMerge is not an integer multiple of InputCollSize\n";
	    exit(0);
	} 
	$NJOBS = $EventsToMerge/$InputCollSize;
    }


    #Determine how to read the input
    if($instorage eq  "eos"){
	$cpin="$eos cp";
    }else if($instorage eq  "grid"){
	$cpin="";
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

	#get list of files in storage
	if($instorage eq  "eos"){
	    @dirlist=`$eos ls $INPUTDIR/$samp | grep .root`;
	}else {
	    @dirlist=`/bin/ls $INPUTDIR/$samp | grep .root`;
	}

	##loop over the input files and merge
        $filecntr=0;
        $arrsize=@dirlist;
	$filelist="";
        $nfiles=0;
	$jobidx=0;	
	for $file (@dirlist){
	    $filecntr++;
	    chomp($file);

	    if($InputCollSize > $EventsToMerge ){
		#loop over the jobs for this file
		for $fileidx (0 ... $NJOBS - 1){
		    makeBatchJob($OUTPUTDIR,$SUBMITDIR,$samp,$jobidx,$cpin,$cpout,"${INPUTDIR}/${samp}/${file}",$algo,$EventsToMerge,$fileidx*$EventsToMerge,$config);
		    $jobidx++;
		    print "In>Out: $jobidx\n";
		}
	    }else {
		$filelist = "${filelist} ${INPUTDIR}/${samp}/${file}";
		$nfiles++;
		if($nfiles == $NJOBS || $filecntr == $arrsize){
		    makeBatchJob($OUTPUTDIR,$SUBMITDIR,$samp,$jobidx,$cpin,$cpout,$filelist,$algo,$EventsToMerge,0,$config);
		    $jobidx++;
		    $nfiles=0;
		    $filelist="";
		    print "In<Out: $jobidx\n";
		}	
	    }
	}
	print "\n $jobidx : ${samp}\n";
    }
}

####define batch submit function
sub submit {
    $path = $_[0];
    $idx = $_[1];
    $qu = $_[2];

    if($qu ne "1nh" && $qu ne "8nh" && $qu ne "1nd" && $qu ne "2nd"){ 
        $qu="1nd";
    }
    
    system("rm -f ${path}/tuple_${idx}.log");
    $command="bsub -C 0 -R \"pool>10000\" -q ${qu} -J ${idx} -o ${path}/tuple_${idx}.log < ${path}/tuple_${idx}.sh";    
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
	    submit("$SUBMITDIR/$samp",$idx,"1nd"); $subcntr++;
	    if($MAXJOBS ne "" && $subcntr==$MAXJOBS){last;}
	}
	print "\n Submitted $subcntr jobs for ${samp}\n";
    }
}

####Check the job output
if($option eq "check"){
    $resub=shift;

    $MAXJOBS=shift;#Number of jobs to check

    $SKIP=shift;#skip N jobs before checking 

    $sampidx=0;
    foreach $samp (@samples){
	chomp($samp);
	$samp =~ s/^\s+|\s+$//g; ##remove beg/end spaces

	$idx=-1;	
	$failcounter=0;
	$checkcounter=0;
	for $f (`/bin/ls $SUBMITDIR/$samp | grep tuple_ | grep .sh | grep -v "~" `){
	    $idx++;
	    if($SKIP ne "" && $idx < $SKIP ) {next;} #go to next event
	    if($MAXJOBS ne "" && $checkcounter>=$MAXJOBS){last;} # terminate loop
	    $checkcounter++;
	    $job="${samp}/tuple_${idx}";

	    $failed=0;

	    #check a log file was produced
	    if($failed == 0 && !(-e "${SUBMITDIR}/${job}.log")){ 
		print "JOB${idx}: No log file \n"; 
		$failed = 1; 
	    }

 	    # there were input events
 	    if( $failed == 0){ 

		$inputEvents=`cat ${SUBMITDIR}/${job}.log | grep "Successfully completed."`;
		chomp($inputEvents);
		if( $inputEvents eq ""){
		    print "JOB${idx}: Successfully completed. NOT FOUND \n"; 
		    $failed = 1;
		}

		$FATAL=`cat ${SUBMITDIR}/${job}.log | grep "FATAL" | grep -v "PyJobTransforms.transform.execute"`;
		chomp($FATAL);
		if($FATAL ne ""){
		    print "JOB${idx}: $FATAL \n";
		    $failed = 1;
 		}

 	    }

 	    #check the root file was produced
	    if($outstorage ne  "eos"){
		$rootfile=`/bin/ls ${OUTPUTDIR}/${samp} |  grep _${idx}.root`;
		chomp($rootfile);
		if($rootfile eq ""){
		    print "JOB${idx}: No root file \n";
		    $failed = 1; 
		}
	    }
	

	    ###Resubmit
	    if($failed == 1){
		$failcounter++;	
		if($resub eq "clean" && $outstorage ne  "eos"){
		    ##do not resubmit job just remove root files
		    `/bin/rm ${OUTPUTDIR}/${samp}/*_${idx}.root`;
		}
	
		if($resub eq "sub"){
		    submit("${SUBMITDIR}/${samp}",$idx,"2nd");
		    print "JOB${idx}: resubmitted.\n";
		}
	    }
	    
	}

	$Summary[$sampidx++]="Failed $failcounter / $checkcounter : ${samp}";
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
	    
	    $job="${SUBMITDIR}/${samp}/tuple_${idx}";

	    $qu="";
	    $deltaT=0;
	    $mem=0;
	    if(-e "${job}.log"){
		@QUEUE=split(" ",`cat ${job}.log | grep "Job was executed on host" | grep "queue"`);
		$qu=$QUEUE[8];
		chomp($qu);

		$success=`cat ${job}.log | grep "Successfully completed."`;
		chomp($success);

		@MEMORY=split(":",`cat ${job}.log | grep "Max Memory :"`);
		$mem=$MEMORY[1];
		chomp($mem);

		@TIME=split(":",`cat ${job}.log | grep "Run time :"`);
		$deltaT=$TIME[1];
		chomp($deltaT);
	    }

	    ##Compute total wall time
	    print "JOB$idx : $qu $mem , $deltaT, $success\n";
	    if($success eq ""){
		print "${job}.log\n";
	    }
	}
    }
}

