package Sub::Spec::URI::pm;

use 5.010;
use strict;
use warnings;

use parent qw(Sub::Spec::URI);

our $VERSION = '0.05'; # VERSION

sub _check {
    my ($self) = @_;
    $self->{_uri} =~ m!\Apm:/*
                       (\w+(?:::\w+)*)
                       /?(\w+)?(?:\?|\z)!x
        or die "Invalid pm URI syntax ($self->{_uri}), ".
            "use pm:Module::SubMod::func?arg=val";
    $self->{_module} = $1;
    $self->{_sub}    = $2;
}

sub module {
    my ($self) = @_;
    $self->{_module};
}

sub sub {
    my ($self) = @_;
    $self->{_sub};
}

sub _require {
    my ($self) = @_;
    my $module = $self->{_module};
    die "Module not specified in URI" unless $module;
    my $modulep = $module; $modulep =~ s!::!/!g; $modulep .= ".pm";
    require $modulep;
}

sub _spec {
    my ($self) = @_;
    my $module = $self->{_module};
    no strict 'refs';
    \%{"$module\::SPEC"};
}

sub spec {
    my ($self) = @_;
    my $module = $self->{_module};
    my $sub    = $self->{_sub};
    die "Module/sub not specified in URI" unless $module && $sub;
    $self->_require;
    my $spec = $self->_spec;
    $spec->{$sub};
}

sub list_subs {
    my ($self) = @_;
    my $module = $self->{_module};
    $self->_require;
    my $spec = $self->_spec;
    [sort keys %$spec];
}

# sub list_mods {}

sub call {
    my ($self, %args) = @_;
    my $module = $self->{_module};
    my $sub    = $self->{_sub};
    die "Module/sub not specified in URI" unless $module && $sub;
    $self->_require;
    my $subref = \&{"$module\::$sub"};
    $subref->(%{$self->args}, %args);
}

1;
# ABSTRACT: 'pm' scheme handler for Sub::Spec::URI



__END__
=pod

=head1 NAME

Sub::Spec::URI::pm - 'pm' scheme handler for Sub::Spec::URI

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 # specify module
 pm:Foo::Bar

 # specify module & sub name
 pm:Foo::Bar/func

 # specify module, sub, and arguments
 pm:Foo::Bar/func?arg1=1&arg2=2

=head1 DESCRIPTION

This handler lets us refer to local modules/subroutines. Modules will be loaded
using Perl's require(). Spec will be retrieved from %SPEC package variables.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

