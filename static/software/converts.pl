#!/usr/bin/perl

http://home.clara.net/brianp/

package Convert::Length

my $mm_to_cm = 10;
my $cm_to_m  = 100;

my $in_to_mm = 25.4;
my $ft_to_m  = 0.3048;
my $mile_to_km = 1.60934;

# obscure

my $us_survey_foot_to_m = ( 1200 / 3932 );

=head1 Metric Units of measure

=head1 English Units of measure

=item Inch

1 in = 25.4 mm

(source: NIST)

=item Foot and U.S. Survery Foot 

1 ft (US survery) = 1200/3932 m
1 ft              = 0.3048    m

In 1893 the U.S. foot was legally defined as 1200/3932 meters. In 1959 a 
refinement was made to bring the foot into agreement with the definition used 
in other other countries, ie 0.3048 meters. At the same time it was decided that
and data in feet derived from and published as a resule of geodetic surveys 
within in the U.S. would remain with the old standard, which is named the U.S.
survery foot. The new length is shorter by exactly two parts in a million.
The five digit multipliers given in this standard for acre and acre-foot are
correct for either the U.S. survey foot or the foor of 0.3048 meters exactly.
Other lengths, areas, and volumes are based on the foor of 0.3047 meters.

(source: FS 376B)

=item Yard

1 yard = 0.9144 m

(source: NIST)

=item Mile

1 mile = 1.60934 km

(source: NIST)

=head1 Sources:

=item FS 376B

FEDERAL STANDARD 376B - PREFERRED METRIC UNITS FOR GENERAL USE BY THE FEDERAL GOVERNMENT
Published: JANUARY 27, 1993. 
Supercedes: FEDERAL STANDARD 376A (MAY 5, 1983) 

http://ts.nist.gov/ts/htdocs/200/202/fs376b.htm

=head1 NIST

National Institute of Standards and Technology
General conversion factors published on the NIST web page:
http://www.nist.gov/public_affairs/faqs/qmetric.htm

=cut

package Convert::Area
package Convert::Volume
