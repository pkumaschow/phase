#!/usr/bin/perl -w

use strict;

use Astro::MoonPhase;
use DateTime;
use DateTime::Format::Strptime;
use JSON::PP;
use CGI qw(:standard -utf8);


my $query = CGI->new;

#Number of days to calculate phases for
my $period = 28;
#start date as a string
my $string;

my $input = $query->param('start');

my $strp = DateTime::Format::Strptime->new(
    pattern   => '%a %b %d %H:%M:%S %Y',
    time_zone => 'UTC',
    on_error  => 'croak'
);

my $today = DateTime->today();

#if a date has been passed in use it as the start date
if ($input) {
    $string = $input;
} else {
    $string = $today->year()."-".$today->month()."-".$today->day();
}

my ($year,$month,$day) = split('-', $string);
my @name = ('New Moon', 'First Quarter', 'Full Moon', 'Last Quarter');

my $json = JSON::PP->new;

my $startDate = DateTime->new(
    year     => $year,
    month    => $month,
    day      => $day,
    hour     => 18,
    minute   => 59,
    second   => 19,
    time_zone => 'UTC'
);

my $endDate = $startDate->clone->add( days => $period );

my $MoonPhase;
my $MoonIllum;
my $MoonAge;
my @output;
my @phaselist;

# Get phases during period
my ($phaseIndex, @times) = phaselist($startDate->epoch(), $endDate->epoch());
while (@times) {
    my $p = $name[$phaseIndex];
    my $t = scalar gmtime shift @times;
    my $dt = $strp->parse_datetime($t);
    my %phaseNames;
    $phaseNames{'Date'} = $dt->strftime("%F");
    $phaseNames{'Time'} = $dt->strftime("%r");
    $phaseNames{'Name'} = $p;
    push(@phaselist, \%phaseNames );
    $phaseIndex = ($phaseIndex + 1) % 4;
}

for (1..$period) {
    ($MoonPhase, $MoonIllum, $MoonAge) = phase($startDate->epoch());
    my %phase;
    $phase{'Date'} = $startDate->strftime("%F");
    $phase{'MoonPhase'} = $MoonPhase;
    $phase{'MoonIllum'} = $MoonIllum;
    $phase{'MoonAge'} = $MoonAge;
    push(@output, \%phase);
    $startDate->add( days => 1);
};

foreach my $listItem ( @phaselist ) {
    foreach my $outputItem ( @output ) {
        if ($outputItem->{'Date'} eq $listItem->{'Date'}) {
            $outputItem->{'Time'} = $listItem->{'Time'};
            $outputItem->{'Name'} = $listItem->{'Name'};
        };
    };
};

print header('application/json');
print $json->encode ( \@output ) . "\n";

