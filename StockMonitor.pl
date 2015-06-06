#!/usr/bin/perl -w
# usage: ./StockMonitor.pl -input <stock list>

use strict;
use warnings;
use Encode;
use Getopt::Long;

my $input;
my $interval;

# process arguments
Getopt::Long::GetOptions(
    'input=s'=>\$input,
    'interval=i'=>\$interval,
    );

$interval=3 if (!defined($interval));

open (my $fh, "$input") or die "$!";
my @list=<$fh>;
close $fh;

# build curl command
my $command = "curl -s http://hq.sinajs.cn/list=";
foreach (@list) {
    chomp;
    next if ($_ eq "");
    my $market;
    if (/^6/) {
        $market="sh";
    }else {
        $market="sz";
    }
    $command = $command.$market.$_.",";
}


while (1) {
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
            print $output;
        }
    }
    sleep($interval);
}
