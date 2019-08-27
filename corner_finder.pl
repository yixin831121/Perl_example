##### corner_finder.pl ##### (275 lines)

#! /usr/bin/perl

# plug-in package declaration

use strict;
use warnings;
#use diagnostics;
use Switch;
use Term::ANSIColor qw(:constants);
no warnings qw(deprecated);
use Class::Struct;

# system setting

	# auto flush I/O buffers
	$| = 1;

	# auto reset text colour
	$Term::ANSIColor::AUTORESET = 1;

# user setting

	my $central_path = "/FSIM/N7_PETV_ISF_central_20181101/ISF2/design/lib/v7/";

# global setting

	my $in_csv_file;
	my $cur_compiler;
	my $in_state = 0;
	my $group_number;
	my $sram_name;
	my @mem_list = ();
	my %sram_list;
	my %target_sram_file;
#	$target_sram_file{"ctl"} = "ctl";
#	$target_sram_file{"masis"} = "masis";
#	$target_sram_file{"lef"} = "lef";
#	$target_sram_file{"db"} = "syn/nldm";
	$target_sram_file{"lib"} = "syn/nldm";
#	$target_sram_file{"v"} = "vlg";

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
if(not defined $ARGV[0])
{
SHOW_USAGE:

	print RED BOLD "[Error]";
	print " you didn't specify \$in_cvs_file ...\n";
	print "\n\tUsage : " . $script_ref_name . " \$in_csv_file (fil with configured SRAM type / list / inst. count ... etc.)\n\n";
	exit -1;
}
else
{
	if(not -e $ARGV[0])
	{
		print RED BOLD "[Error]";
		print " Cannot find ";
		print GREEN $ARGV[0];
		print " ...\n\n";
		exit -1;;
	}
	elsif((not -f $ARGV[0]) || (not -r _))
	{
		print RED BOLD "[Error]";
		print " Cannot assign ";
		print GREEN $ARGV[0];
		print " as in_csv_file, it is either a directory or not readable by effective uid/gid ...\n\n";
		exit -1;
	}
	else
	{
		$in_csv_file = $ARGV[0];
	}
}

###################### ###################### ######################
#### Processing . #### #### Processing . #### #### Processing . ####
###################### ###################### ######################
print "\n\n\n\n";
print CYAN "[Info]";
print "  Processing ";
print GREEN $in_csv_file;
print ", please wait ...\n\n";

my %corner_list = ();
my @corner_list = ();

open IN_LIST, $in_csv_file
	or die $!;

while(<IN_LIST>)
{
	switch($in_state)
	{
		case 0
		{
			if(/^begin_compiler/)
			{
				$in_state = 1;
			}
			elsif(/Num:,,Type:,([^,]+)/ || /^\d+,\d+,\d+,[^,]+/ || /^end_compiler/)
			{
				print RED BOLD "[Error]";
				print " Parser error in in_csv_file : ";
				print GREEN $in_csv_file;
				print ", in line : ";
				print BLUE $.;
				print ", in script line : ";
				print BLUE __LINE__;
				print ", terminating ...\n\n";

				exit -1;
			}
		}
		case 1
		{
			if(/Num:,,Type:,([^,]+)/)
			{
				$cur_compiler = $1;
				$in_state = 2;
			}
			elsif(/^\d+,\d+,\d+,[^,]+/ || /^begin_compiler/ || /^end_compiler/)
			{
				print RED BOLD "[Error]";
				print " Parser error in in_csv_file : ";
				print GREEN $in_csv_file;
				print ", in line : ";
				print BLUE $.;
				print ", in script line : ";
				print BLUE __LINE__;
				print ", terminating ...\n\n";

				exit -1;
			}
		}
		case 2
		{
			if(/^\d+,(\d+),\d+,([^,]+)/)
			{
				$group_number = $1;
				$sram_name = uc($2);

				if(defined $sram_list{$2})
				{
					if($sram_list{$2} ne $cur_compiler)
					{
						print "\t";
						print YELLOW BOLD "[Warn]";
						print "  sram : ";
						print BLUE $2;
						print " is defined in multiple compiler list, i.e., ";
						print BLUE $sram_list{$2};
						print ", ";
						print BLUE $cur_compiler;
						print ", it is highly recommended to check your csv file ...\n\n";
					}
				}
				else
				{
					$sram_list{$2} = $cur_compiler;

					print "\n\t";
					print CYAN "[Info]";
					print "  processing memory : " . $sram_name . ",from group " . $group_number . "\n\n";
	
					foreach my $target_sram_file_key (keys %target_sram_file)
					{
						my $exec_cmd = "find " . $central_path . $target_sram_file{$target_sram_file_key} . " -iname " . "\"" . $2 . "*." . $target_sram_file_key . "\"";
						my @target_list = `$exec_cmd`;
						unshift(@target_list,"${group_number} ${sram_name}\n");
						#@target_list = ("${group_number} ${sram_name}\n",@target_list);
	
						if($#target_list eq "-1")
						{
							print "\n\t\t";
							print RED BOLD "[Error]";
							print " No any available " . $target_sram_file_key . " file found ...\n\n";
						}
						else
						{
							print "\n\t\t";
							print CYAN "[Info]";
							print "  listing " . $target_sram_file_key . " file ...\n\n";
							foreach my $target_list_content (@target_list)
							{
								#chomp($target_list_content);
								#print "\t\t\t--> "; 
								print "\t\t$target_list_content";
								#system("cp -L " . $target_list_content . " " . $target_path . $cur_compiler . "/" . $2 . "/" . $target_sram_path{$target_sram_file_key}) if($real_flag eq 1);
							
								if($target_list_content =~ m/\/?[a-zA-Z0-9]\_(\w+)\.lib$/)
								{
									my $corner_name = $1;
									if($corner_name =~ m/^\w+\_\w+v\_\w+v\_\w+/)
									{
										$corner_list{$corner_name} = "dual_vdd";
									}
									elsif($corner_name =~ m/^\w+\_\w+v\_\w+/)
									{
										$corner_list{$corner_name} = "single_vdd";
									}
								}

							}
							print "\n";
						}
					}
				}
			}
			elsif(/^end_compiler/)
			{
				$in_state = 0;
			}
			elsif(/Num:,,Type:,([^,]+)/ || /^begin_compiler/)
			{
				print RED BOLD "[Error]";
				print " Parser error in in_csv_file : ";
				print GREEN $in_csv_file;
				print ", in line : ";
				print BLUE $.;
				print ", in script line : ";
				print BLUE __LINE__;
				print ", terminating ...\n\n";

				exit -1;
			}
		}
	}
}

close IN_LIST
	or warn $!;

open(TOTAL,">","/twhome/chengyhc/Intern/Others/total_corner_list.txt");
open(SINGLE,">","/twhome/chengyhc/Intern/Others/single_vdd_corner_list.txt");
open(DUAL,">","/twhome/chengyhc/Intern/Others/dual_vdd_corner_list.txt");

foreach my $corner (sort {$a cmp $b} keys %corner_list)
{
	if($corner_list{$corner} eq "dual_vdd")
	{
		print TOTAL "$corner\n";
		print DUAL "$corner\n";
	}
	elsif($corner_list{$corner} eq "single_vdd")
	{
		print TOTAL "$corner\n";
		print SINGLE "$corner\n";
	}
}

close TOTAL;
close SINGLE;
close DUAL;
#print my $corner_number = @corner_list;
print "\n";
print CYAN "[Info]";
print "  Completed!! ";
print "\n\n";
