#!/usr/bin/perl
#-w
## NOTE: you can remove directories like this: eos rm -r /eos/...
## Note: script searches only 2 layers into the top folder 
## Note: will create a .sh script to be executed later for actual removal

$dir=shift; ##full path director in eos : /eos/...  , below check it is my area

$eos="/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select";

#$myeos="/eos/cms/store/cmst3/user/benitezj";
$myeos="/eos/atlas/user/b/benitezj";

###Check path is in my eos area
if(`echo $dir | grep $myeos` eq ""){
    die "$dir does not match $myeos";
}

#must create sh file to be executed later (cannot execute eos rm command from inside this script?)
$executeFile="rmEOSdir_$dir.sh";
$executeFile=~ s/\//_/g;
open OUTFILE, "> ./$executeFile" or die "@_";


#@files = `xrd eoscms dirlistrec $dir | grep eos`;
@files = `xrd eosatlas dirlistrec $dir | grep eos`;
$nfiles=@files;
if($nfiles==0){
    print "No files/dirs found inside dir\n";
}

##will be reversed later
$dircounter=0;
$dirstorm[$dircounter]="$dir";
$dircounter++;


###determine which are the files and which are the directories
$filermcounter=0;
for $f (@files){
    chomp($f);
    @linewords=split(" ",$f);
    $file=$linewords[4];
    if($f =~ /^d/ ){   
	$dirstorm[$dircounter]=$file;
	$dircounter++;
	
	###go down 1 layer
	@files2 = `xrd eosatlas dirlistrec $file | grep eos`;
	for $f2 (@files2){
	    chomp($f2);
	    @linewords2=split(" ",$f2);
	    $file2=$linewords2[4];
	    if($f2 =~ /^d/ ){   
		$dirstorm[$dircounter]=$file2;
		$dircounter++;	
		
		###go down 2 layers
		@files3 = `xrd eosatlas dirlistrec $file2 | grep eos`;
		for $f3 (@files3){
		    chomp($f3);
		    @linewords3=split(" ",$f3);
		    $file3=$linewords3[4];
		    if($f3 =~ /^d/ ){   
			$dirstorm[$dircounter]=$file3;
			$dircounter++;	
		    }else{
			print OUTFILE "eos rm $file3\n";
			$filermcounter++;
		    }
		}
	    }else{
		print OUTFILE "eos rm $file2\n";
		$filermcounter++;
	    }
	}
    }else{
	print OUTFILE "eos rm $file\n";
	$filermcounter++;
    }
}

##remove in reverse
$dirrmcounter=0;
for $i (0 .. $dircounter-1){
    $d=$dirstorm[$dircounter-1-$i];
    $command="eos rmdir $d";
    print OUTFILE "$command\n";
    $dirrmcounter++;
}

close OUTFILE;


###check all files to remove are in my eos area
$nTotFilesToRM=`cat $executeFile | wc -l`;
$nMyFilesToRM=`cat $executeFile | grep $myeos | wc -l`;
if($nTotFilesToRM != $nMyFilesToRM){
    print "Safety check not passed. Some lines do not match my eos path.\n";
    `cat $executeFile`;
    `rm -f $executeFile`;
}

###
print "remove $filermcounter files and $dirrmcounter directories: $executeFile\n";

