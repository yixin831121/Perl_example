##### port_comparison.pl ##### (265 lines)

#! /usr/bin/perl

# plug-in package declaration

use strict;
use warnings;
#use diagnostics;
use Switch;
use Term::ANSIColor qw(:constants);

# system setting

	# auto flush I/O buffers
	$| = 1;

	# auto reset text colour
	$Term::ANSIColor::AUTORESET = 1;

# global setting

	my $netlist;
	my $empty_module;
	my $design_name;
	my %empty_port;
	my %netlist_port;
	my $port_list = "";
	my $direction = "";
	my $step = 0;
	my $cat_next = 0;
	my $store_port = 0;
	my @port_arr;

###################### ###################### ######################
#### Initialize . #### #### Initialize . #### #### Initialize . ####
###################### ###################### ######################
INITIALIZER_ENTRY:

my $script_ref_name = $0;
$script_ref_name =~ s/^\S+\/([a-zA-Z0-9_.]+\.pl)$/$1/;

print "\n\n";
print CYAN "[Info]";
print "  Initializing : ";
print MAGENTA $script_ref_name;
print " ...\n\n";

###################### ###################### ######################
#### Input Argv . #### #### Input Argv . #### #### Input Argv . ####
###################### ###################### ######################
if((not defined $ARGV[0]) || (not defined $ARGV[1]))
{
SHOW_USAGE:

	print RED BOLD "[Error]";
	print " You didn't specify \$verilog_file ...\n";
	print "\tUsage : " . $script_ref_name . " \$verilog_file_1 \$verilog_file_2\n\n";
	exit -1;
}
else
{
	unless(-e $ARGV[0])
	{
		print RED BOLD "[Error]";
		print " Cannot find ";
		print GREEN $ARGV[0];
		print " ...\n\n";
		exit -1;
	}
	
	unless((-f $ARGV[0]) && (-r _))
	{
		print RED BOLD "[Error]";
		print " Cannot assign ";
		print GREEN $ARGV[0];
		print ", it is either a directory or not readable by effective uid/gid ...\n\n";
		exit -1;
	}

	unless(-e $ARGV[1])
	{
		print RED BOLD "[Error]";
		print " Cannot find ";
		print GREEN $ARGV[1];
		print " ...\n\n";
		exit -1;
	}
	
	unless((-f $ARGV[1]) && (-r _))
	{
		print RED BOLD "[Error]";
		print " Cannot assign ";
		print GREEN $ARGV[1];
		print ", it is either a directory or not readable by effective uid/gid ...\n\n";
		exit -1;
	}

	foreach (@ARGV)
	{
		if($_ =~ m/\/?([\w.]+(?:empty)[\w.]*)\.v\w*$/)
		{
			$empty_module = $_;
		}
		else
		{
			$_ =~ m/\/?([\w.]+)\.v\w*$/;
			$netlist = $_;
			$design_name = $1;
		}
	}
}

print "\nEmpty module: ";
print "$empty_module";
print "\n\n";
print "Netlist: ";
print "$netlist";
print "\n\nDesign name: ";
print "$design_name";

####################### ####################### #######################
#### Get IO Port . #### #### Get IO Port . #### #### Get IO Port . ####
####################### ####################### #######################
print "\n\n\n";
print CYAN "[Info]";
print "  Processing ";
print GREEN $design_name;
print " port list comparison, please wait ...\n\n\n";

%empty_port = &get_port($empty_module);
%netlist_port = &get_port($netlist);

#foreach my $key (keys %empty_port) {print " direction: $empty_port{$key}, port name: ${key}\n"};
#print "\n";
#foreach my $key (keys %netlist_port) {print " direction: $netlist_port{$key}, port name: ${key}\n"};
#print "\n";

###################### ###################### ######################
#### Port Comp . ##### #### Port Comp . ##### #### Port Comp . #####
###################### ###################### ######################
my $error_flag = 0;

foreach my $keys (keys %empty_port) {
	if(defined $netlist_port{$keys}){
		if($empty_port{$keys} ne $netlist_port{$keys}){
			print RED BOLD "[Error]";
			print " There is a mismatch between direction of port ";
			print GREEN $keys;
			print "\n\n";
			$error_flag = 1;
		}
	}
	else{
		print RED BOLD "[Error]";
		print " Port ";
		print GREEN $keys;
		print " exists in empty module but not in netlist\n\n";
		$error_flag = 1;
	}
}

foreach my $keys (keys %netlist_port) {
	unless(defined $empty_port{$keys}){
		print RED BOLD "[Error]";
		print " Port ";
		print GREEN $keys;
		print " exists in netlist but not in empty module\n\n";
		$error_flag = 1;
	}
}

print "--------No error--------\n\n" if((!$error_flag));
print "\n";
print CYAN "[Info]";
print "  Port list comparison is done!\n\n\n";


sub get_port
{
	my $verilog_file;
	my $port_list = "";
	my $direction = "";
	my $step = 0;
	my $cat_next = 0;
	my $store_port = 0;
	my @port_arr;
	my %port_list;

	if(@_ != 1)
	{
		die "\nUsage : $0 \$verilog_file\n"; 
	}
	elsif((not -e $_[0]) || (not -f $_[0]) || (not -r $_[0]))
	{
		die "\n$_[0] does not exist, or it is not readable !\n";
	}
	else
	{
		$verilog_file = $_[0];
	}
	
	open (INFILE, $verilog_file) or die $!;

	while(<INFILE>) 
	{
		chomp $_;
		$_ =~ s/\/\/.*//g;
		$_ =~ s/\/\*.*\*\///g;
 
    		if ($step == 0 && $_ =~ m/^\s*module\s+$design_name\s/) 
    		{
			$step = 1;
    		}

    		if ( ($step == 1 && $_ =~ m/^\s*(input\s|output\s|inout\s)/ ) || $cat_next == 1) 
    		{
			$port_list = $port_list . $_ ;
			if ($port_list !~ m/;/) 
			{
				$cat_next = 1;
			} 
			else 
			{
				$cat_next = 0;
				$store_port = 1;
			}
		} 

		if ($step > 0  && $_ =~ m/^\s*endmodule/) 
		{
			$step = 0;
			last;
		}

	# Store Port info.
		if ($store_port == 1) 
		{
			#print "$port_list\n";
		
			$direction = "input"   if($port_list =~ m/^\s*input\s+/);
			$direction = "output"  if($port_list =~ m/^\s*output\s+/);
			$direction = "inout"   if($port_list =~ m/^\s*inout\s+/);

			$port_list =~ s/^\s*(input\s|output\s|inout\s)//g;
			$port_list =~ s/;//g;
			$port_list =~ s/\s+//g;
			@port_arr = split (/,/,$port_list);

			foreach my $port (@port_arr) 
			{
				$port =~ s/^(\[\d+:\d+\])\b(\w+)/$2$1/;
				$port_list{$port} = $direction;
			}

			$store_port = 0;
			$direction = "";
			$port_list = "";
		}


	}
	close(INFILE);

	return %port_list;

};
