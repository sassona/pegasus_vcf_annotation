#!/usr/bin/perl
# This script takes run manifest as input and based on metadata in the manifest, 
# decides what workflow to run and submit one workflow per sample to run through Pegasus

# Version 1.0 (Stable version)
use warnings;
use strict;
use Getopt::Long;
use File::Temp qw/tempfile/;
use File::Spec;
use File::Path;
use File::Basename;
use Cwd qw/abs_path getcwd/;

$0 =~ s-.*/--g;

#input output option
my ($inputF,$coderoot,$outputpath);
GetOptions( 'i|in=s'  => \$inputF,
	    'r|root=s' =>\$coderoot,
	   );

{
	print "\nInput File: $inputF";
	
	open (iFP2,$inputF);

	my $cwd1 = getcwd;
	my @name =split("/",$inputF);
	my $oname = pop(@name);
	$oname =~ s/.txt$//;
	my $output=">$cwd1"."/".$oname.".sh";
	print "\nOutput File: $output \n";
	open (oFP,$output); 

	my $cntr =0;
	#my $peg_source = "/nas/is1/NGS_Diag/pegasus/source/config/";

	# instead of hardcoding where pipelines are, let's use the input -r path
	my $peg_source = $coderoot."/config/"; 
   
	my $cp_config = "cp -r $peg_source . \n";
	print oFP $cp_config;

	while (my $line2 = <iFP2> ) {
	chomp $line2;
	my $len = length($line2);
	if(($line2 =~ /^\#/ || $len<1)) {
	    next;
	}

	$cntr++;
#	my @parameter_array=split("\t",$line2);
	my $d = "";
#	print "$cntr : coverting $line2 \n";
	$d =&generate_pegasus_script($line2,$cntr);
	print oFP $d;
	
	
	}
	print "Number of files to annotate: $cntr\n\n";
	close(oFP);
}

sub generate_pegasus_script{
    
#    my $inputA = shift;
#    open (iFP,$inputA);
    
    my $info = shift;
    my $cnt= shift;
    my @parameter_array=split('\t',$info);
    my @name_array = split('/',$parameter_array[0]);
    my $sample_name=pop(@name_array);
    $sample_name=~ s/.vcf$//;
    my $len = @parameter_array;
    
  
#########################Run Parameters
#Global - don't change from input
    
    my $pegasus_dir="/share/apps/pegasus/bin/";
    my $cwd = getcwd; #TOP in make 
    my $run_dir ="$cwd"."/annotate/";
    my $config_dir="$cwd"."/config/";
    my $pipelinever ="annotate_v1";
    my $ini_file="$config_dir".$pipelinever."/"."annotate.ini";
    my $ftl_name = "annotate.ftl";
    my $ftl_file="$config_dir".$pipelinever."/".$ftl_name;

#    print "$info - $sample_name - $len - $pegasus_dir - $cwd - $run_dir - $config_dir - $pipelinever - $ini_file - $ftl_name -  $ftl_file\n\n\n";
    
#Runs sppecific
    my $results_dir="$run_dir";
    my $rs_dir="RS=$results_dir\n";
    my $hold_rel_pegLog="run/"."$sample_name"."_"."$pipelinever";
    my $rel_peglog="pegLog=".$run_dir."pegasus_log\n";

    my $create_directory_structure = $rs_dir.$rel_peglog;
    my $output_prefix = $sample_name;
    my $dax_file="$results_dir"."$sample_name".".dax";

#    my $node_prefix = $sample_name . "_" . $pipelinever;
    my $node_prefix = "X". $cnt;

    my $header = "\#"." Commands for Project -> $parameter_array[0]\; Run -> $pipelinever\; Sample -> $sample_name\;\n";

    my $command1 = "java -jar /nas/is1/NGS_Diag/pegasus/paramMaker.jar $ini_file --coderoot=$coderoot --filename=$sample_name --start_file=$parameter_array[0] --outputprefix=$output_prefix --pipeline_ver=$pipelinever --outputfolder=$results_dir --nodeprefix=$node_prefix  --user=\$USER --host=\$HOSTN $ftl_file $dax_file";

    my $command2 = "$pegasus_dir"."pegasus-plan --conf /nas/is1/NGS_Diag/pegasus/pegasusrc --dir $cwd --dax $dax_file -o local --submit --sites condorpool";


##   my $out = $create_directory_structure.$create_symlinks.$dax_file."\n".$header."$command1\n"."$command2\n";
    my $out = $create_directory_structure."mkdir -p annotate/log\n".$header."$command1\n"."$command2\n";
#    print "$out\n --------------------------------------------\n\n\n";

    return $out;

}

sub usage {

    print "\nusage: $0 \n[-i SOLiD QV file you want to analyze\n -o output file name]\n\n";
    print "outputs a matrix where the rows represent the positions and the columns represent the quality scores.\n";
    print "the numbers represented in the matrix are the counts of that score at that positions.\n\n";
    print "example: $0 -i Frag.qual -o Frag_QV_analysis.txt\n\n";
    exit;

}
