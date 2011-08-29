package Foo;

our %SPEC;

$SPEC{f1} = {
    summary => 'f1',
    args => {},
};
sub f1 { [200, "OK", "foolish"] }

$SPEC{f2} = {
    summary => 'f2',
    args => {},
};
sub f2 { my %args=@_; [200, "OK", \%args] }

1;
