#!/opt/local/bin/perl

use File::Slurp;
use JSON;

my %results;
opendir(D, "output");
while (readdir(D)) {
	next unless /json/;
	my $json = read_file("output/$_");
	my $hashref = decode_json($json);
	foreach (keys %$hashref) {
		next if /^FileName$/;
		next if /Zoom/;
		next if /Tint/;
		next if /Blur/;
		next if /DesignType/;
		next if /ColorIteration/;
		next if /GradientSliceType/;
		next if /GradientType/;
		next if /^Palette$/;

		my $key = "$_" . "-" . $$hashref{$_};
		$results{$key} = $results{$key} + 1;
	}
	#print($json);
	#exit;
}

print "--------\n";
foreach (sort keys %results) {
	print $_ . "=" . $results{$_} . "\n";
}

