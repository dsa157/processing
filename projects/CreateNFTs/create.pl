#!/opt/local/bin/perl

my $max=15;
for( $i=1; $i<=$max; $i++ ) {
  $fn = "dsa157_" . $i;
  $range = 100;
  $rand1 = int(rand($range));

  $seed = "abcdef21572158" . $rand1;
  print("Processing $fn $i/$max\n");
  `node create1.js $fn $seed`;
}

