#!/opt/local/bin/perl

my $max=15;
for( $i=1; $i<=$max; $i++ ) {
  $fn = "dsa157_" . $i;
  $seed = "abcdef21572158" . $i;
  print("Processing $fn $i/$max\n");
  `node create1.js $fn $seed`;
}

