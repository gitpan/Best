package Best;

use warnings;
use strict;

our $VERSION = '0.01';

=head1 NAME

Best - Fallbackable module loader

=head1 SYNOPSIS

    # Load the best available YAML module with default imports
    use Best qw/YAML::Syck YAML/;
    use Best [ qw/YAML::Syck YAML/ ];   # also works

    # Load a YAML module and import some symbols
    use Best [ [ qw/YAML::Syck YAML/ ], qw/DumpFile LoadFile/ ];

    # Load a CGI module but import nothing
    use Best [ [ qw/CGI::Simple CGI/ ], [] ];

=head1 DESCRIPTION

Often there are several possible providers of some functionality your
program needs, but you don't know which is available at the run site. For
example, one of the modules may be implemented with XS, or not in the
core Perl distribution and thus not necessarily installed.

B<Best> attempts to load modules from a list, stopping at the first
successful load and failing only if no alternative was found.

=head1 FUNCTIONS

All the functionality B<Best> provides is on the C<use> line; there are
no callable functions as such.

If the arguments are either a simple list or a reference to a simple list,
the elements are taken to be module names and are loaded in order with
their default import function called. Any exported symbols are installed
in the caller package.

If the arguments are a listref with a listref as its first element,
this interior list is treated as the specification of modules to attempt
loading, in order; the rest of the arguments are treated as options to
pass on to the loaded module's import function.

To specify a null import (C<use Some::Module ()>), pass a zero-element
listref as the argument list. In the pathological case where you really
want to load a module and pass it C<[]> as an argument, specify C<[
[] ]> as the argument list to B<Best>.

=cut

sub import {
    my $caller = caller;
    shift; # "Best"
    return unless @_;

    @_            = [[@_]] unless ref $_[0];      # use Best  qw/a b/;
    @_            = [@_]   unless ref $_[0][0];   # use Best [qw/a b/];
    my $modules   = shift @{ $_[0] };
    my $has_args  = @{ $_[0] } > 0;
    my @args      = ref $_[0][0] ? @{ $_[0][0] } : @{ $_[0] };
                                                  # valid only if $has_args
    my $no_import = ($has_args && !@args) || @args == 1 && @{ $args[0] } == 0; # use Mod ()

    do { require Carp; Carp::carp "Best: what modules shall I load?" }
        unless $modules;

#::YY({mod=>$modules,has=>$has_args, arg=>\@args, noimport=>$no_import});

    # If we do not assume the loaded modules use Exporter, the only
    # alternative to eval-"" here is to enter a dummy package here and then
    # scan it and rexport symbols found in it. That is not necessarily
    # better, because the callee may be picky about its caller. We are in
    # compile time, and we do need to trust our caller anyway, so what the
    # hell, let's eval away.
    
    my @errors;
    for my $mod (@$modules) {
        my $loadargs = $no_import ? '()' :
                ($has_args ? '@args' : '');
        my $retval = eval qq{
            package $caller;
            use $mod $loadargs;
        };
#            my $str = qq{
#                package $caller;
#                use $mod $loadargs;
#            };
#            warn ">>>>[@args] $str";
#            my $retval = eval $str;
        # %INC is updated with the module even though it failed to load.
        # This is probably a bug in Perl 5? Clear it.
        #delete $INC{ modulize($mod) };

        return $retval unless $@;
        #warn $@;
        push @errors, $@;
    }
    die "no viable module found: $@";
    die @errors;
}

=head1 DEPLOYMENT ISSUES

If you want to use B<Best> because you aren't sure your target machine has
some modules installed, you may wonder what might warrant the assumption
that C<Best.pm> would be available, since it isn't a core module itself.

One solution is to use L<Module::Compile> to inline C<Best.pm> in your
source code. If you don't know this module, check it out -- after you
learn what it does, you may decide you don't need B<Best> at all! (If your
fallback list includes XS modules, though, you may need to stick with us.)

=head1 SEE ALSO

=over 4

=item L<Module::Load>

=item L<UNIVERSAL::require>

=item L<Module::Compile>

=back

=head1 AUTHOR

Gaal Yahas, C<< <gaal at forum2.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-patch at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Best>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Best

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Best>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Best>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Best>

=item * Search CPAN

L<http://search.cpan.org/dist/Best>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Gaal Yahas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub ::Y  { require YAML::Syck; YAML::Syck::Dump(@_) }
sub ::YY { require Carp; Carp::confess(::Y(@_)) }
"You'll never see me"; # End of Best
