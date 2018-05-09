#!/usr/bin/perl
# -w
use File::Basename;

$samplesfile=shift; #must be a full path
print "samplesfile: $samplesfile \n";
$option=shift;
print "option: $option \n";


##determine the input and output paths
open(my $FILEHANDLE, '<:encoding(UTF-8)', $samplesfile)
or die "Could not open file '$samplesfile' $!";
$INPUTDIR = <$FILEHANDLE>;
$INPUTDIR =~ s/^\s+|\s+$//g;
$OUTPUTDIR = <$FILEHANDLE>;
$OUTPUTDIR =~ s/^\s+|\s+$//g;
print "INPUTDIR = $INPUTDIR\n";
print "OUTPUTDIR = $OUTPUTDIR\n";

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
	$command="rm -rf $OUTPUTDIR/$samp";
	print "$command \n";
	system($command);
    }


#    ####clean out the submission directory
#    print "-------------------------\n";
#    print "Removing all files in submit directory:\n";
#    print "-------------------------\n";
#    foreach $samp (@samples){
#	$command="rm -rf ${OUTPUTDIR}/${samp}";
#	print "$command \n";
#	system($command);
#    }


}


#########Condor submission script
sub makeCondorSub {
    $OUTPUTDIR=$_[0];
    $sample=$_[1];
    $idx=$_[2];
    
    $outfile="${OUTPUTDIR}/${sample}/tuple_${idx}.slrm";
    `rm -f $outfile`;
    `touch $outfile`;

    `echo "#!/bin/bash" >> $outfile`; 
    `echo "#SBATCH --output=${OUTPUTDIR}/${sample}/tuple_${idx}.log" >> $outfile`; 
    `echo "#SBATCH --nodes=1" >> $outfile`; 
    `echo "#SBATCH --ntasks-per-node=1" >> $outfile`; 
    `echo "#SBATCH --job-name=ROOT" >> $outfile`; 
    `echo "#SBATCH --time=1:00:00" >> $outfile`; 
    `echo "#SBATCH --partition=general" >> $outfile`; 
    `echo "#SBATCH --constraint=broadwell" >> $outfile`; 
    
    `echo "source ${OUTPUTDIR}/${sample}/tuple_${idx}.sh" >> $outfile`; 
 
}

#########Write config parameters for job
sub writeJobConfig {
    $outfile = $_[0];
    $sample = $_[1];
    $idx = $_[2];
    $cpout = $_[3];
    $OUTPUTDIR = $_[4];
    $algo = $_[5];
    
    if( $algo eq "root"){
	`echo "root -b ${OUTPUTDIR}/run.C" >> $outfile`;	
	`echo "${cpout} ./out.root ${OUTPUTDIR}/${sample}/tuple_${idx}.root " >> $outfile`;	
    }else {
	print "Algorithm ${algo} not found\n";
	exit(0);
    }    

    `echo "echo '+++++++++++++Output File+++++++++++:'" >> $outfile`;
    `echo "/bin/ls -l ${OUTPUTDIR}/${sample}/*_${idx}.*" >> $outfile`;   
}


#######FUNCTION FOR MAKING JOB EXECUTION SCRIPTS
sub makeClusterJob {
    $OUTPUTDIR = $_[0];
    #print "OUTPUTDIR $OUTPUTDIR\n";
    $sample = $_[1];
    #print "sample $sample\n";
    $idx = $_[2];
    #print "idx $idx\n";
    $cpin = $_[3];
    #print "cpin $cpin\n";
    $cpout = $_[4];
    #print "cpout $cpout\n";
    $filelist = $_[5];
    #print "filelist $filelist\n";
    $algo = $_[6];
    #print "algo $algo\n";

    $outfile="${OUTPUTDIR}/${sample}/tuple_${idx}.sh";
    `rm -f $outfile`;
    `touch $outfile`;

    `echo "echo '+++++++++++++User+++++++++++:'; whoami; " >> $outfile`;

    #machine where the job executes
    `echo "echo '+++++++++++++Machine+++++++++++:'; echo \\\$HOSTNAME  " >> $outfile`;
    #`echo "echo '+++++++++++++Tokens+++++++++++:'; tokens  " >> $outfile`;
    `echo "echo '+++++++++++++Initial Dir+++++++++++:'; pwd " >> $outfile`;

    #setup environment
    #`echo "export HOME=/nfs/home/condor " >> $outfile`;
    #`echo "source \\\$HOME/.bash_profile  " >> $outfile`;    

    ###ATHENA OR ROOTCORE
    #`echo "echo '+++++++++++++ATLAS Setup+++++++++++:' " >> $outfile`; 
    #`echo "export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase  " >> $outfile`;
    #`echo "source \\\$ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh  " >> $outfile`;
    #`echo "source \$PWD/rcSetup.sh  " >> $outfile`;

    #dump PATH
    `echo "echo '+++++++++++++PATH+++++++++++++:'; echo \\\$PATH  " >> $outfile`;

    #go the execute directory
    `echo "echo '+++++++++++++Executing+++++++++++:'" >> $outfile`;
    `echo "echo TMPDIR=\\\$TMPDIR"  >> $outfile`;
    `echo "cd \\\$TMPDIR"  >> $outfile`;

    #copy the files locally
    `echo "echo '+++++++++++++Downloading files+++++++++++:'; " >> $outfile`;
    `echo "echo '+++++++++++++Execute Dir+++++++++++:'; pwd " >> $outfile`;
    `echo "rm -r ./in/ " >> $outfile`;
    `echo "mkdir -p ./in/ " >> $outfile`;
    `echo "${cpin} ${filelist} ./in/" >> $outfile`;
    `echo "echo '+++++++++++++Download Dir+++++++++++:'; /bin/ls -l ./in/  " >> $outfile`;

    #run program
    `echo "echo '+++++++++++++Enviroment+++++++:'; printenv" >> $outfile`;    
    writeJobConfig($outfile,$sample,$idx,$cpout,$OUTPUTDIR,$algo);
    `echo "echo '+++++++++++++Execute Dir+++++++++++:'; pwd; /bin/ls -l " >> $outfile`;

    makeCondorSub($OUTPUTDIR,$sample,$idx);
}

######Make the execution scripts
if($option eq "create"){

    #Number of files to merge
    $nmerge=shift;
    print "Number of files to merge per job: $nmerge \n";

    #Algorithm to run
    $algo=shift;
    print "Algorithm to run: $algo \n";
    if( $algo eq "" ){
	print "Wrong algorithm.\n";
	exit(0);
    }

    #config
    $config=shift;
    if( $config eq "" ){
	print "Wrong config.\n";
	exit(0);
    }
    `/bin/cp $config $OUTPUTDIR/`;

    #Determine how to read the input
    $cpin="/bin/cp";

    #determine how to write the output
    $cpout="/bin/cp";
    
    foreach $samp (@samples){
	#create the submission directory
	`mkdir $OUTPUTDIR/$samp`;

	#get list of files in storage
	#@dirlist=`/bin/ls $INPUTDIR/$samp | grep .root`;
	@dirlist=`find $INPUTDIR/$samp -maxdepth 1 -type f | grep .root`;
	$nrootfiles=@dirlist;

	##loop over the input files and merge
	$filelist="";
	$mergecounter=0;
	$idx=0;	
	for $f (@dirlist){
	    chomp($f);
	    #$filelist = "${filelist} ${INPUTDIR}/${samp}/${f}";
	    $filelist = "${filelist} ${f}";
	    $mergecounter++;
	    #print "$mergecounter $filelist\n";
	    
	    if( $mergecounter == $nmerge ){
 		makeClusterJob($OUTPUTDIR,$samp,$idx,$cpin,$cpout,$filelist,$algo);
		$filelist="";
		$mergecounter=0;
		$idx++;
	    }
	}
	if($mergecounter>0){
	    makeClusterJob($OUTPUTDIR,$samp,$idx,$cpin,$cpout,$filelist,$algo);
	    $idx++;
	}

	print "\n $idx : ${samp}\n";
    }
}

####define batch submit function
sub submit {
    $path = $_[0];
    $idx= $_[1];
    system("rm -f ${path}/*_${idx}.root");
    system("rm -f ${path}/*_${idx}.log");
    $command="sbatch ${path}/tuple_${idx}.slrm > ${OUTPUTDIR}/${sample}/tuple_${idx}.log";  
    print "$command\n";
    system("$command");
}

######submit all jobs
if($option eq "sub" ){
    $nsub=shift;
    $skip=shift;
    foreach $samp (@samples){
	$idx=0;	
	$counter=0;
	for $f (`/bin/ls $OUTPUTDIR/$samp | grep tuple_ | grep .sh`){
	    chomp($f);
	    if(($nsub eq "" || $counter<$nsub) && ($skip eq "" || $idx>=$skip)){
		submit("$OUTPUTDIR/$samp",$idx);
		$counter++;
	    }
	    $idx++;
	}
	print "\n Submitted $counter jobs for ${samp}\n";
    }
}

####Check the job output
if($option eq "check"){
    $resub=shift;

    $sampidx=0;
    foreach $samp (@samples){
	chomp($samp);
	$samp =~ s/^\s+|\s+$//g; ##remove beg/end spaces

	$idx=0;	
	$failcounter=0;
	for $f (`/bin/ls $OUTPUTDIR/$samp | grep tuple_ | grep .sh | grep -v "~" `){
	    chomp($f);
	    $job="${OUTPUTDIR}/${samp}/tuple_${idx}";

	    $failed=0;

 	    #check the root file was produced
 	    if($failed == 0){
		$rootfile=`/bin/ls ${OUTPUTDIR}/${samp} |  grep ${idx}.root`;
		chomp($rootfile);
		if($rootfile eq ""){
		    print "No root file \n ${job}\n";
		    $failed = 1; 
		}
 	    }

	    #check a log file was produced
	    if($failed == 0 && !(-e "${job}.log")){ 
		print "No log file \n ${job}\n"; 
		$failed = 1; 
	    }

 	    # there were input events: inputCounter = 100000
 	    if( $failed == 0){ 
		
		$failedTuple=0;
		$inputEvents=`tail -n 150  ${job}.log | grep inputCounter`;
		if($inputEvents eq "") {
		    $inputEvents=`tail -n 150  ${job}.log | grep inputCounter`;
		}
 		chomp($inputEvents);
 		@evtsproc=split(" ",$inputEvents);
 		if( !($evtsproc[2] > 0)){
 		    $failedTuple = 1;
 		}
 
		############################
		##in case of CxAOD job:
		##############################
		$failedTuple = 0;
		#do not use cat as some log files have binary format at the beggining 
		#$inputEvents=`tail -n 100  ${job}.log | grep 'Info in' | grep processed`;
		#$inputEvents=`tail -n 150  ${job}.condor.log | grep finalize | grep processed`;
                ##AnalysisBase_DB::final... INFO      processed                 = 30781	
		#$inputEvents=`tail -n 150  ${job}.log | grep "INFO      processed                 ="`;	
		$inputEvents=`cat ${job}.log | grep "hello"`;	
		chomp($inputEvents);
		@evtsproc=split("=",$inputEvents);
		if( !($evtsproc[1] > 0) ){
		    $failedCxAOD = 1;
		}

		#####if neither passed
		$failed = $failedTuple;
		if($failed){
		    print "Failed input events check\n ${job}\n"; 
 		}

 	    }
	
	    
	    ###Resubmit
	    if($failed == 1){
		$failcounter++;	
		if($resub eq "clean"){
		    `/bin/rm ${OUTPUTDIR}/${samp}/*_${idx}.root`;
		}
	
		if($resub eq "sub"){
		    submit("${OUTPUTDIR}/${samp}",$idx);
		    print "Job $idx resubmitted.\n";
		}
	    }
	    
	    $idx++;
	}
	##print "Failed $failcounter / $idx : ${samp} \n";
	$Summary[$sampidx++]="Failed $failcounter / $idx : ${samp}";
    }

    $sampidx=0;
    foreach $samp (@samples){
	print "$Summary[$sampidx]\n";
	$sampidx++;
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
    $command="squeue -u jbenitez | grep general | wc -l ";
    $commandrun="squeue -u jbenitez -t RUNNING | grep general | grep ' R ' | wc -l";

    
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
