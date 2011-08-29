package Sub::Spec::URI;
BEGIN {
  $Sub::Spec::URI::VERSION = '0.04';
}

use 5.010;
use strict;
use warnings;

use JSON;
use URI;

# VERSION

our %handlers; # key = 'scheme', value = object

my $json = JSON->new->allow_nonref;

sub new {
    my ($class, $str) = @_;

    my $uri = URI->new($str);
    $uri or die "Can't parse URI";

    my $scheme = $uri->scheme;
    $scheme or die "URI must have scheme";
    $scheme =~ /\A[A-Za-z0-9_]+\z/
        or die "Bad syntax in URI scheme, must be alphanums only";
    my $h = $handlers{$scheme} // "Sub::Spec::URI::$scheme";
    my $hp = $h; $hp =~ s!::!/!g; $hp .= ".pm";
    require $hp;
    my $self = bless {_uri=>$uri}, $h;
    $self->_check;
    $self;
}

sub args {
    my ($self) = @_;
    my %form = $self->{_uri}->query_form;
    for my $k0 (keys %form) {
        my $k = $k0;
        if ($k =~ s/:j$//) {
            eval { $form{$k} = $json->decode($form{$k0}) };
            delete $form{$k0};
        }
    }
    \%form;
}

1;
# ABSTRACT: Refer to module/sub/spec/sub call via URI string


__END__
=pod

=head1 NAME

Sub::Spec::URI - Refer to module/sub/spec/sub call via URI string

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Sub::Spec::URI;

 # refer to local subroutine
 my $lsub = Sub::Spec::URI->new("pm://Mod::SubMod::func");

 # refer to remote subroutine
 my $rsub = Sub::Spec::URI->new("http://HOST/api/MOD/SUBMOD/FUNC");

 # get URI components
 print $lsub->module; # Mod::SubMod
 print $rsub->sub;    # FUNC

 # get subroutine's spec
 my $spec = $lsub->spec;

 # call subroutine
 my $res = $rsub->call(arg1=>'foo', arg2=>'bar');


 # refer to a module
 my $mod = Sub::Spec::URI->new("http://HOST/api/MOD/");

 # list subroutines
 my $subs = $mod->list_subs;

=head1 DESCRIPTION

This module lets you create an object that can represent a remote or local
module/subroutine/spec/subroutine call. This module is basically a convenience
so that we can represent those things using a string (URI), e.g. from a
command-line or inside another URI/URL.

Each scheme is handled by Sub::Spec::URI::<SCHEME>, e.g. L<Sub::Spec::URI::pm>
for local Perl modules/subroutines, L<Sub::Spec::URI::http> for remote
subroutines over HTTP.

=head1 METHODS

=head2 new(STR) => OBJ

Create a new object from URI string. Will die if URI can't be parsed (e.g.
unknown scheme or bad syntax).

=head2 $s->module() => STR

Get the module name, or undef if not specified in URI.

=head2 $s->sub() => STR

Get the subroutine name, or undef if not specified in URI.

=head2 $s->args() => HASHREF

Get the arguments, or empty hash if none are specified in URI.

=head2 $s->list_subs() => ARRAYREF

Try to list subroutines in a module. URI must specify module. Will die if fail
to retrieve, e.g. can't require module (for local modules) or connection failure
(for remote modules).

=head2 $s->spec() => HASHREF

Try to get spec for subroutine. URI must specify module and subroutine name.

=head2 $s->call(%args) => RESULT

Try to call subroutine. URI must specify module and subroutine name. Will die if
failure happens.

=head1 SEE ALSO

L<Sub::Spec>

L<Sub::Spec::HTTP>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

