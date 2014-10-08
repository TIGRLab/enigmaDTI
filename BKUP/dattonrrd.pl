$dirs = @ARGV[0];
$nhdr = @ARGV[1];

open( FILE, "< $dirs" ) ;
open( NEWFILE, "> $nhdr");
$i=0;
for (<FILE>) {
     $str = sprintf("DWMRI_gradient_%04d:= %s",$i,$_);
     print NEWFILE $str;
     $i = $i+1;
}
close (FILE);
close(NEWFILE);
