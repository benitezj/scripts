#!/usr/bin/perl
# -w
use File::Basename;

$samplesfile=shift;#must be a full path in AFS
$option=shift;

###check submitting from an /nfs path otherwise jobs wont run
$pwd = getenv("PWD");

##Determine path where log files will be written
$samplesfile = `readlink -e $samplesfile`;
chomp($samplesfile);
$SUBMITDIR = dirname($samplesfile);

##determine the input and output paths
open(my $FILEHANDLE, '<:encoding(UTF-8)', $samplesfile)
or die "Could not open file '$samplesfile' $!";
$INPUTDIR = <$FILEHANDLE>;
$INPUTDIR =~ s/^\s+|\s+$//g;
$OUTPUTDIR = <$FILEHANDLE>;
$OUTPUTDIR =~ s/^\s+|\s+$//g;

###
print "SUBMITDIR = $SUBMITDIR\n";
print "INPUTDIR  = $INPUTDIR\n";
print "OUTPUTDIR = $OUTPUTDIR\n";


##read the samples list
#@samples=`cat $samplesfile | grep "." | grep -v "#" | grep -v '/' `;
$counter = 0;
#foreach $samp (@samples){
while (my $samp = <$FILEHANDLE>){
    #chomp($samp);
    $samp =~ s/^\s+|\s+$//g; ##remove beg/end spaces
    #print "$samp\n";
    $samples[$counter] = $samp;
    $counter++;
}


####Clean out the output directory
if($option eq "clean"){

    print "-------------------------\n";
    print "Removing all files inside output directory:\n";
    print "-------------------------\n";
    foreach $samp (@samples){
	$command="rm -f $OUTPUTDIR/$samp_*.root";
	print "$command \n";
	system($command);
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
    
    $outfile="${SUBMITDIR}/${sample}/job_${idx}.sub";
    `rm -f $outfile`;
    `touch $outfile`;

    `echo "Universe   = vanilla" >> $outfile`; 
    `echo "+JobFlavour = \\\"workday\\\" " >> $outfile`;
    `echo "Executable = /bin/bash" >> $outfile`; 
    `echo "Arguments  = ${SUBMITDIR}/${sample}/job_${idx}.sh" >> $outfile`; 
    `echo "Log        = ${SUBMITDIR}/${sample}/job_${idx}.condor.log" >> $outfile`; 
    `echo "Output     = ${SUBMITDIR}/${sample}/job_${idx}.log" >> $outfile`; 
    `echo "Error      = ${SUBMITDIR}/${sample}/job_${idx}.condor.log" >> $outfile`; 
    `echo "Queue  " >> $outfile`; 
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
    #print "cpout $cpout\n";
    $filelist = $_[4];
    #print "filelist $filelist\n";

    $outfile="${SUBMITDIR}/${sample}/job_${idx}.sh";
    `rm -f $outfile`;
    `touch $outfile`;

    `echo "echo '+++++++++++++User+++++++++++:'; whoami; " >> $outfile`;

    #machine where the job executes
    `echo "echo '+++++++++++++Machine+++++++++++:'; echo \\\$HOSTNAME  " >> $outfile`;
    `echo "echo '+++++++++++++Mounts+++++++++++:'; mount;  " >> $outfile`;
    `echo "echo '+++++++++++++Initial Dir+++++++++++:'; pwd " >> $outfile`;

    #setup environment
    `echo "cd ${SUBMITDIR}" >> $outfile`;
    `echo "eval \\\`scramv1 runtime -sh\\\`" >> $outfile`;
    `echo "cd \\\$TMPDIR" >> $outfile`;
    
#    $CMSSWBASE= getenv("CMSSW_BASE");
#    $CMSSWV=getenv("CMSSW_VERSION");
#    `echo "/bin/cp -r ${CMSSWBASE} . " >> $outfile`;
#    `echo "cd ${CMSSWV}/src " >> $outfile`;
#    `echo "scramv1 b ProjectRename "  >> $outfile`;
#    `echo "scramv1 runtime -sh"  >> $outfile`;

    #copy the files locally
    #`echo "echo '+++++++++++++Downloading files+++++++++++:'; " >> $outfile`;
    #`echo "mkdir -p ./${sample} " >> $outfile`;
    #`echo "/bin/cp ${filelist} ./${sample}/" >> $outfile`;
    #`echo "/bin/ls -l ./${sample}/  " >> $outfile`;

    #`echo "export INPUTDIR=./${sample}/" >> $outfile`;
    `echo "export INPUT=\\\"${filelist}\\\" " >> $outfile`;

    #dump PATH
    `echo "echo '+++++++++++++PATH+++++++++++++:'; echo \\\$PATH  " >> $outfile`;

    `echo "echo '+++++++++++++Enviroment+++++++:'; printenv" >> $outfile`;    

    #run program   
    `echo "echo '+++++++++++++Executing+++++++++++:'" >> $outfile`;
    `echo "cmsRun ${SUBMITDIR}/cfg.py" >> $outfile`;

    `echo "echo '+++++++++++++Execute Dir+++++++++++:'; pwd; /bin/ls -l " >> $outfile`;
    
    # copy back the output
    $output=$sample;
    $output =~ s/\//_/g; 
    `echo "/bin/cp ./output.root ${OUTPUTDIR}/${output}_${idx}.root " >> $outfile`;	
    
    makeCondorSub($SUBMITDIR,$sample,$idx);
}

######Make the execution scripts
if($option eq "create"){

    $config=shift;
    print "config to run : $config\n";
    `/bin/cp $config ${SUBMITDIR}/cfg.py`;
    
    $nfilesperjob=shift;
    print "number of files per job: $nfilesperjob\n";


    #create the output directory
    if($SUBMITDIR ne $OUTPUTDIR){
	$command="mkdir $OUTPUTDIR";
	print "$command\n";
	system($command);
    }


    foreach $samp (@samples){
	#print "$samp\n";
	#create the submission directory
	`mkdir -p $SUBMITDIR/$samp`;
	
	#get list of input files
	if($INPUTDIR eq "grid"){
	    @dirlist=`dasgoclient -query="file dataset=$samp" | grep .root`
	}else{
	    @dirlist=`/bin/ls -d $INPUTDIR/$samp/*/*/* | grep .root`;
	}   

	##loop over the input files and merge
	$filecntr=0;
	$arrsize=@dirlist;
	$jobidx=0;
	$filelist="";
	$nfiles=0;
	for $file (@dirlist){
	    #print "$file\n";
	    $filecntr++;
	    chomp($file);

	    if($INPUTDIR eq "grid"){
		$filelist = "${filelist} root://cms-xrd-global.cern.ch/${file}";
	    } else {
		$filelist = "${filelist} file:${file}";
	    }

	    $nfiles++;
	    if($nfiles == $nfilesperjob || $filecntr == $arrsize){
		makeClusterJob($OUTPUTDIR,$SUBMITDIR,$samp,$jobidx,$filelist,$cfg);
		$jobidx++;
		$nfiles=0;
		$filelist="";
	    }
	}
	print "\n $jobidx ${samp}\n";
    }
}

####define batch submit function
sub submit {
    $path = $_[0];
    $idx= $_[1];
    system("rm -f ${path}/*_${idx}.root");
    system("rm -f ${path}/*_${idx}.*log");
    $command="condor_submit ${path}/job_${idx}.sub";  
    print "$command\n";
    system("$command");
}

#submit all jobs
if($option eq "sub" ){
    $MAXJOBS=shift; #submit only MAXJOBS per sample

    $SKIP=shift; #skip N jobs before submitting

    foreach $samp (@samples){
	$idx=-1;	
	$subcntr=0;
	for $f (`/bin/ls $SUBMITDIR/$samp | grep job_ | grep .sh`){
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
	for $f (`/bin/ls $SUBMITDIR/$samp | grep job_ | grep .sh | grep -v "~" `){
	    $idx++;
	    if($SKIP ne "" && $idx < $SKIP ) {next;} # skip this job
	    if($MAXJOBS ne "" && $checkcounter>=$MAXJOBS){last;} # terminate loop
            $checkcounter++;

	    #chomp($f);
	    $job="${samp}/job_${idx}";
	    #print "JOB: ${job}\n";

	    $failed=0;
	    $log=0;

 	    #check the root file was produced
	    $rootfile=`/bin/ls ${OUTPUTDIR} | grep ${samp} | grep _${idx}.root`;
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
		@Selected=split(":",`tail -n 100 ${SUBMITDIR}/${job}.log |  grep "Events selected:"`);
		if($Selected[0] eq "" || $Selected[1]==0 ){
		    print "JOB${idx}: no events selected : $Selected[0] , $Selected[1]\n";
		    $failed = 1; 
		}

		$Normal=`tail -n 100 ${SUBMITDIR}/${job}.condor.log |  grep "Normal termination"`;
		if($Normal eq ""){
		    print "JOB${idx}: abnormal termination \n";
		    $failed = 1; 
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
	$Summary[$sampidx++]="Failed (with log): $failcounter ($failcounterwithlog) / $totaljobs ($totallogfiles): ${samp} \n ${failedlist}";
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
	for $f (`/bin/ls $SUBMITDIR/$samp | grep job_ | grep .sh | grep -v "~" `){
	    $idx++;
	    
	    #chomp($f);
	    $job="${SUBMITDIR}/${samp}/job_${idx}";

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
	for $f (`/bin/ls $SUBMITDIR/$samp | grep job_ | grep .sh | grep -v "~" `){
	    
	    $rootfile[$idx]=`/bin/ls $OUTPUTDIR/$samp | grep  _${idx}.root`;
	    chomp($rootfile[$idx]);
	    
	    if($rootfile[$idx] ne "" && ($idx>=$SKIP || $SKIP eq "")){
		$tuplefile=`echo $rootfile[$idx] | grep job_`;
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
