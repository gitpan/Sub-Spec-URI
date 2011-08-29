package Sub::Spec::URI::bar;

use 5.010;
use strict;
use warnings;

use parent qw(Sub::Spec::URI);

sub _check {
}

sub module {
    my ($self) = @_;
    "barmod";
}

sub sub {
    my ($self) = @_;
    "barsub";
}

1;
