package Sub::Spec::URI::pm;

use 5.010;
use strict;
use warnings;

use parent qw(Sub::Spec::URI);

use Scalar::Util qw(refaddr);
use Sub::Spec::Wrapper qw(wrap_sub);

our $VERSION = '0.11'; # VERSION

sub proto {
    "pm";
}

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

sub _other {
    my ($self, $other, $sub) = @_;

    local $self->{_module} = $other->{module} if exists $other->{module};
    local $self->{_sub}    = $other->{sub}    if exists $other->{sub};
    # XXX adjust $self->{_uri} too if someday needed
    $sub->();
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
    if (require $modulep) {
        if ($Sub::Spec::URI::load_module_hook) {
            $Sub::Spec::URI::load_module_hook->($self);
        }
    }
}

sub _specs {
    # need to _require first
    my ($self) = @_;
    my $module = $self->{_module};
    no strict 'refs';
    \%{"$module\::SPEC"};
}

sub spec {
    my ($self) = @_;
    unless ($self->{_spec}) {
        my $module = $self->{_module};
        my $sub    = $self->{_sub};
        die "Module not specified in URI" unless $module;
        $self->_require;
        my $specs = $self->_specs;
        if (defined $sub) {
            $self->{_spec} = $specs->{$sub} or die "Sub doesn't have spec";
            return $self->{_spec};
        } else {
            return $specs;
        }
    }
}

sub spec_other {
    my ($self, $other, %args) = @_;
    $self->_other($other, sub { $self->spec() });
}

sub list_specs {
    my ($self) = @_;
    $self->spec_other({sub=>undef});
}

# not yet implemented
#sub list_specs_other {
#}

sub list_subs {
    my ($self) = @_;
    my $module = $self->{_module};
    $self->_require;
    my $specs = $self->_specs;
    my @res;
    for my $sn (sort keys %$specs) {
        my $spec = $specs->{$sn};
        next if $spec->{type}  && $spec->{type}  ne 'sub';
        next if $spec->{scope} && $spec->{scope} ne 'public';
        push @res, $sn;
    }
    \@res;
}

# not available
# sub list_mods {}

sub call {
    my ($self, %args) = @_;
    my $module = $self->{_module};
    my $sub    = $self->{_sub};
    my $spec   = $self->spec;
    my $subref = \&{"$module\::$sub"};
    my $wrapped = __wrapped_sub($subref, $spec);
    $wrapped->(%{$self->args}, %args);
}

sub call_other {
    my ($self, $other, %args) = @_;
    $self->_other($other, sub { $self->call(%args) });
}

my %wrap_cache;
sub __wrapped_sub {
    my ($sub, $spec) = @_;
    my $key = refaddr($sub)."|".refaddr($spec);
    unless ($wrap_cache{$key}) {
        my $wrapped = wrap_sub(sub=>$sub, spec=>$spec);
        $wrap_cache{$key} = $wrapped;
    }
    $wrap_cache{$key};
}

1;
# ABSTRACT: 'pm' scheme handler for Sub::Spec::URI



__END__
=pod

=head1 NAME

Sub::Spec::URI::pm - 'pm' scheme handler for Sub::Spec::URI

=head1 VERSION

version 0.11

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

call() uses L<Sub::Spec::Wrapper> to wrap subroutine to trap exceptions. This
module assumes that specs don't change, so the resulting wrapped subroutines are
cached are cached with keys refaddr($sub)|refaddr($spec).

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

