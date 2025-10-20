#!/usr/bin/perl
#
# Dreamcast Disc Image ID Changer v1.0
# A utility for easily modifying a Dreamcast disc image's product ID.
#
# Written by Derek Pascarella (ateam)

# Modules.
use strict;
use File::Basename;

# Set version number.
my $version = "1.0";

# Set header used in CLI messages.
my $cli_header = "\nDreamcast ID Changer v" . $version .
                 "\nA utility for easily modifying a Dreamcast disc image's product ID.\n\n" .
                 "Written by Derek Pascarella (ateam)\n\n";

# Verify input file argument.
my $input_file = $ARGV[0];

if(!defined $input_file)
{
	print $cli_header;
	print STDERR "No input file specified.\n";
	print "\nPress Enter to exit.\n";
	<STDIN>;
	exit;
}

if(!-e $input_file || !-r $input_file)
{
	print $cli_header;
	print STDERR "Input file not found or unreadable: " . $input_file . "\n";
	print "\nPress Enter to exit.\n";
	<STDIN>;
	exit;
}

# Determine file type and extract track list.
my ($base_path, $track_ref, $image_type, $image_label) = get_tracks_from_image($input_file);
my @data_tracks = @$track_ref;

# Print image type message.
print $cli_header;
print $image_label . " detected.\n";
print "\nNow scanning for IP.BIN headers...\n\n";

# Verify all track files exist and are accessible.
unless(verify_tracks($base_path, @data_tracks))
{
	print STDERR "One or more track files are missing or inaccessible.\n";
	print "\nPress Enter to exit.\n";
	<STDIN>;
	exit;
}

# Scan for product ID pattern and extract matches plus current ID.
my ($header_locations, $product_id_current) = scan_tracks($base_path, @data_tracks);

# Count match totals.
my $total_matches = 0;
foreach my $file (keys %$header_locations)
{
	$total_matches += scalar @{ $header_locations->{$file} };
}

# Status message.
print "Total matches found: " . $total_matches . ":\n";

foreach my $file (sort keys %$header_locations)
{
	foreach my $offset (@{ $header_locations->{$file} })
	{
		print " -> " . $file . ": " . $offset . " (0x" . sprintf("%X", $offset) . ")\n";
	}
}

# Prompt user for new ID.
print "\nCurrent product ID:\n";
print " -> " . $product_id_current . "\n";

my $product_id_new = "";

while($product_id_new eq "")
{
	print "\nEnter new product ID (10 alphanumeric characters max.):\n";
	print " -> ";
	chomp($product_id_new = <STDIN>);

	if($product_id_new ne "")
	{
		# Clean new product ID.
		$product_id_new =~ s/^\s+|\s+$//g;
		$product_id_new =~ s/[^A-Za-z0-9]//g;
		$product_id_new = substr($product_id_new, 0, 10);
		$product_id_new = uc($product_id_new);

		print "\nYou entered \"" . $product_id_new . "\". Is this okay (Y/N)?\n";
		print " -> ";

		chomp(my $product_id_confirm = <STDIN>);

		$product_id_new = "" if(lc($product_id_confirm) ne "y");
	}
}

# Status message.
print "\nNow updating IP.BIN header in all data tracks...\n";

# Patch new product ID in all identified locations.
if(patch_tracks($base_path, $header_locations, $product_id_new))
{
	print "\nUpdate complete!\n";
}
else
{
	print STDERR "\nUpdate failed on one or more files.\n";
}

# Status message.
print "\nPress Enter to exit.\n";
<STDIN>;

# Subroutine to universally get track files for a disc image.
sub get_tracks_from_image
{
	my $file = shift;
	my $ext = lc(( $file =~ /\.([^.]+)$/ )[0] // '');
	my $base_path = dirname($file);
	$base_path = "." if $base_path eq "";

	my @tracks;
	my $label = "";
	my $type = $ext;

	if($ext eq "cue")
	{
		@tracks = parse_cue($file);
		$label = 'Redump CUE/BIN';
	}
	elsif($ext eq "gdi")
	{
		@tracks = parse_gdi($file);
		$label = "TOSEC GDI";
	}
	elsif($ext eq "cdi")
	{
		@tracks = (basename($file));
		$label = "CDI";
	}
	else
	{
		print $cli_header;
		print STDERR "Unsupported file type: " . $file . "\n";
		print "\nPress Enter to exit.\n";
		<STDIN>;
		exit;
	}

	return($base_path, \@tracks, $type, $label);
}

# Subroutine to parse a Dreamcast Redump CUE to return an array of data track file names.
sub parse_cue
{
	my $file = $_[0];
	my @tracks;
	my $current_file = '';

	open(my $fh, '<', $file) or die "Could not open \"$file\": $!";

	while(my $line = <$fh>)
	{
		chomp($line);

		if($line =~ /^FILE\s+"([^"]+)"\s+BINARY/i)
		{
			$current_file = $1;

			next;
		}
		if($line =~ /^\s*TRACK\s+\d+\s+MODE/i && $current_file ne '')
		{
			push(@tracks, $current_file) unless(grep { $_ eq $current_file } @tracks);
		}
	}

	close($fh);

	return @tracks;
}

# Subroutine to parse a Dreamcast TOSEC GDI to return an array of data track file names.
sub parse_gdi
{
	my $file = $_[0];
	my @tracks;

	open(my $fh, '<', $file) or die "Could not open \"" . $file . "\": " . $! . "\n";

	while(my $line = <$fh>)
	{
		chomp($line);

		if($line =~ /\b(\S+\.(?:bin|iso))\b/i)
		{
			push(@tracks, $1);
		}
	}

	close($fh);

	return @tracks;
}

# Subroutine that returns true if all disc image files exist, are readable, and are writable.
sub verify_tracks
{
	my $base_path = shift @_;
	my @tracks = @_;

	foreach my $track (@tracks)
	{
		my $full_path = ($track =~ m{^/}) ? $track : "$base_path/$track";

		return 0 unless(-e $full_path && -r _ && -w _);
	}

	return 1;
}

# Subroutine to build and return hash of IP.BIN header start in all data tracks.
sub scan_tracks
{
	my $base_path = shift @_;
	my @tracks = @_;

	my $target = pack("H*", '5345474120534547414B4154414E41205345474120454E544552505249534553');

	my %results;
	my $ascii_value = "";
	my $found_ascii = 0;

	foreach my $track (@tracks)
	{
		my $full_path = ($track =~ m{^/}) ? $track : "$base_path/$track";

		open(my $fh, '<:raw', $full_path) or next;
		local $/;
		my $data = <$fh>;
		close($fh);

		my $pos = -1;

		while(1)
		{
			$pos = index($data, $target, $pos + 1);
			
			last if($pos == -1);

			push(@{ $results{$track} }, $pos);

			if(!$found_ascii)
			{
				my $start = $pos + 64;
				my $raw = substr($data, $start, 10);

				$ascii_value = $raw;
				$ascii_value =~ s/[^\x20-\x7E]//g;
				$ascii_value =~ s/^\s+|\s+$//g;

				$found_ascii = 1;
			}
		}
	}

	return(\%results, $ascii_value);
}

# Subroutine to patch disc image with new product ID.
sub patch_tracks
{
	my ($base_path, $header_locations, $product_id_new) = @_;

	$product_id_new = sprintf("%-10s", $product_id_new);

	my $error_count = 0;

	foreach my $track (keys %$header_locations)
	{
		my $full_path = ($track =~ m{^/}) ? $track : $base_path . "/" . $track;

		my $fh;

		unless(open($fh, "+<:raw", $full_path))
		{
			print STDERR "ERROR: Could not open \"" . $full_path . "\" for writing: " . $! . "\n";

			$error_count ++;

			next;
		}

		foreach my $offset (@{ $header_locations->{$track} })
		{
			my $patch_pos = $offset + 64;

			unless(seek($fh, $patch_pos, 0))
			{
				print STDERR "ERROR: Seek failed in \"" . $track . "\" at " . $patch_pos . ": " . $! . "\n";
				
				$error_count ++;
				
				next;
			}

			print $fh $product_id_new;
		}

		close($fh);
	}

	return $error_count == 0;
}