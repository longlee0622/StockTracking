#!/usr/bin/perl -w
# usage: ./StockMonitor.pl -input <stock list>

use strict;
use warnings;
use Encode;
use Class::Struct;
use Getopt::Long;
use Term::ANSIColor;

struct Info => {
    ID          => '$',
    name        => '$',
    volumn      => '$',
    lastClose   => '$',
};

my $input;
my $interval;

# process arguments
Getopt::Long::GetOptions(
    'input=s'=>\$input,
    'interval=i'=>\$interval,
    );

$interval=3 if (!defined($interval));

# read input list
open (my $fh, "$input") or die "$!";
my @list=<$fh>;
close $fh;

my @InfoList;
my $command = "curl -s http://hq.sinajs.cn/list=";
foreach (@list) {
    chomp;
    next if ($_ eq "");
    next if (/^#/);
    my $market;
    if (/^6/) {
        $market="sh";
    }else {
        $market="sz";
    }
    # create InfoList & build command
    if (/([0-9]+)\s+([0-9]+)/) {
        my $thisInfo = Info->new();
        $thisInfo->ID($1);
        $thisInfo->volumn($2);
        push @InfoList, $thisInfo;
        $command = $command.$market.$thisInfo->ID.",";

    }else {
        print "bad stock format\n";
        exit;
    }

}

while (1) {
        my $DeltaSum = 0;
        print "--------------------------------------\n";
        print "Time      ID      Name\t\tPrice\tChange%\n";
        my @raw=`$command`;
        foreach (@raw) {
            chomp;
            Encode::from_to($_, "gb2312", "utf8");
            next if ($_ eq "");
            if(/^var hq_str_[szh]{2}([\d]{6})="([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),.*"/) {
            my $change = sprintf("%5.2f%%",($5-$4)/$4*100);
            my $output = $33."  ".$1."  ".$2."\t".$5."\t".$change."\n"; # Time Id Name Price change% 
            if ($5 < $4) {
                print color("green"), $output, color("reset");
            }else {
                print color("red"), $output, color("reset");
            }
            # calculate portfolio delta
            foreach (@InfoList) {
                $DeltaSum += $_->volumn * ($5-$4) if ($1 == $_->ID); 
            }
        }
    }
    printf("Portfolio Delta = %.2f\n", $DeltaSum);
    sleep($interval);
}
