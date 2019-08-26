##### random.pl ##### (51 lines)

sub randomize 
{
	my $sample_file;
	my $sample_number;

	if(@_ != 2)
	{
		die "\nUsage : $0 \$sample_file \$sample_number\n"; 
	}
	elsif((not -e $_[0]) || (not -f $_[0]) || (not -r $_[0]))
	{
		die "\n\$sample_file does not exist, or it is not readable !\n";
	}
	else
	{
		($sample_file,$sample_number) = @_;

	}

	open IN_FILE, $sample_file or die "\nCan not open $sample_file : $!\n";
	my @sample_file_content = <IN_FILE>;
	my $all_number = @sample_file_content;
	#print STDERR "Total number is |$all_number|\n";

	my %hits;
	my $wl = $sample_number;
	for(my $i = 0; $i < $all_number; $i++)
	{
		if(rand($all_number - $i) < $wl)
		{
			$hits{$i} = 1;
			$wl--;
		}

	}

	my $j = 0;
	my @out_array = ();
	foreach(@sample_file_content)
	{
		#print STDERR "$_" if($hits{$j});
		push(@out_array,$_) if($hits{$j});	
		$j++;
	}
	
	print STDOUT "\tRandomization done !\n\n";	

	return @out_array;
}

1;
