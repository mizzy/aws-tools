#!/usr/bin/env perl

use strict;
use warnings;
use AWS::CLIWrapper;
use Data::Dumper;
$Data::Dumper::Indent = 1;

my $aws = AWS::CLIWrapper->new;

my $res = $aws->ec2('describe-volumes');

my $total_size = 0;

my $instances = [];

for my $volume ( @{$res->{Volumes} } ) {
    my $size = $volume->{Size};
    $total_size += $size;

    my $instance = $aws->ec2('describe-instances', {
        instance_ids => [ $volume->{Attachments}->[0]->{InstanceId} ],
    });

    my $name = get_instance_name($instance);

    my $exists = 0;
    for my $instance ( @$instances ) {
        if ( $instance->{name} eq $name ) {
            $instance->{size} += $size;
            $exists = 1;
        }
    }

    push @$instances, { name => $name, size => $size } unless $exists;
}

for my $instance ( @$instances ) {
    printf "%s %d %f\n", $instance->{name}, $instance->{size}, $instance->{size} / $total_size * 100;
}

sub get_instance_name {
    my $instance = shift;

    for my $tag (  @{ $instance->{Reservations}->[0]->{Instances}->[0]->{Tags} } ) {
        if ( $tag->{Key} eq 'Name' ) {
            return $tag->{Value};
        }
    }
}

