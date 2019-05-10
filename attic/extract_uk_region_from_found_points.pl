#!/usr/bin/env perl

use strict;

#
# Usage:
#
#  bzcat found_points_5.3m.txt.bz2 | ./extract_uk_region_from_found_points.pl
#

open OSM, "| gzip - > osm.csv.gz" or die $!;
open OSM_K_V, "| gzip - > osm_k_v.csv.gz" or die $!;

while (<>)
{
  chomp;
  # Each row is a point of interest.
  my ($id, $dt, $uid, $lat, $lon, $name, $kv_agg) = split /</;
  next unless $id =~ /^\d+$/ and $uid =~ /^\d+/;
  # This bounding box equates, roughly, to "England".
  next  unless (50.0 < $lat and $lat < 56.26) and (-6.0 < $lon and $lon < 2.8);
  print OSM join(",", ($id, $dt, $uid, $lat, $lon, $name)) . "\n";
  # There can be multiple tags per point.
  foreach my $kv (split /\|/, $kv_agg)
  {
    my ($k, $v) = split /=/, $kv;
    $v =~ s/,//g;
    next unless $k and $v;
    print OSM_K_V join(",", ($id, $k, $v)) . "\n";
  }
}

close OSM_K_V or warn $!;
close OSM or warn $!;

