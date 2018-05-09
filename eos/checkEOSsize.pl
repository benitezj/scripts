#!/usr/bin/perl
#-w

$dir=shift; ##like this /CMG/TEST
#$enable=shift;    

$myeos="/store/cmst3/user/benitezj";
$fullpath="${myeos}/${dir}";
@dirs=`cmsLs $fullpath | grep store`;
$ndirs=@dirs;
print "number dirs = $ndirs\n";

$total=0;
for $d (@dirs){
    chomp($d);
    @dirw=split(" ",$d);
    $dir=$dirw[4];
    @ext=split(/\./,$d);
    $next=@ext;
    if($next==1){
	
	#$command="eos find --size /eos/cms/$dir | awk -F= '{size+=\$3}END{print size/1024/1024/1024}'";
	$command="/afs/cern.ch/project/eos/installation/0.1.0-22d/bin/eos.select find --size /eos/cms/$dir | awk -F= '{size+=\$3}END{print size/1024/1024/1024}'";
	#print "$command\n";
	$size=`$command`;
	chomp($size);
	print "$size Gb $dir\n";
	$total+=$size;
    }
}
print "Total size $total Gb\n";
