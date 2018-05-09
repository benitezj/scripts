#!/usr/bin/perl
#-w
$eos="/afs/cern.ch/project/eos/installation/0.3.15/bin/eos.select";

##input the directory and the new permission code
$dir=shift; ##eos dir. eg: /eos/atlas/user/b/benitezj/test
$octal=shift; ## eg: 744  , Note that eos chmod will say it changed to 2744

$myeos="/eos/atlas/user/b/benitezj";

###Check path is in my eos area
if(`echo $dir | grep $myeos` eq ""){
    die "$dir does not match $myeos";
}

$command="$eos chmod -r $octal $dir";
print "$command\n";
`$command`

