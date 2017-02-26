package LWP::ConsoleLogger::Everywhere;
use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use LWP::UserAgent;
use Class::Method::Modifiers ();

no warnings 'once';

my $loggers;

Class::Method::Modifiers::install_modifier(
    'LWP::UserAgent',
    'around',
    'new' => sub {
        my $orig = shift;
        my $self = shift;

        my $ua = $self->$orig(@_);
        push @{ $loggers }, debug_ua($ua);

        return $ua;
    }
);

sub loggers {
    return $loggers;
}

1;

__END__

# ABSTRACT: LWP tracing everywhere

=pod

=head1 DESCRIPTION

This module turns on C<LWP::ConsoleLogger::Easy> debugging for every L<LWP::UserAgent>
based user agent anywhere in your code. It doesn't matter what package or class it is in,
or if you have access to the object itself. All you need to do is C<use> this module
anywhere in your code and it will work.

You can access and configure the loggers after they have been created using
the C<loggers> class method.

=head1 SYNOPSIS

    use LWP::ConsoleLogger::Everywhere;

    # somewhere deep down in the guts of your program
    # there is some other module that creates an LWP::UserAgent
    # and now it will tell you what it's up to

    # somewhere else you can access and fine-tune those loggers
    my $loggers = LWP::ConsoleLogger::Everywhere->loggers;
    $loggers->[0]->pretty(0);

    # Redact sensitive data for all user agents
    $ENV{LWPCL_REDACT_HEADERS} = 'Authorization,Foo,Bar';
    $ENV{LWPCL_REDACT_PARAMS} = 'seekrit,password,credit_card';

=head1 CLASS METHODS

=head2 loggers

    my $loggers = LWP::ConsoleLogger::Everywhere->loggers;
    foreach my $logger ( @{ $loggers } ) {
        # stop dumping headers
        $logger->dump_headers( 0 );
    }

This class method returns an array reference of all L<LWP::ConsoleLogger> objects that have
been created so far, with the newest one last. You can use them to fine-tune settings. If there
is more than one user agent in your application you will need to figure out which one is which.
Since this is for debugging only, trial and error is a good strategy here.

=head1 CAVEATS

If there are several different user agents in your application, you will get debug
output from all of them. This could be quite cluttered.

Since L<LWP::ConsoleLogger::Everywhere> does its magic during compile time it will
most likely catch every user agent in your application, unless
you C<use LWP::ConsoleLogger::Everywhere> inside a file that gets loaded at runtime.
If the user agent you wanted to debug had already been created at that time it
cannot hook into the constructor any more.

L<LWP::ConsoleLogger::Everywhere> works by catching new user agents directly in
L<LWP::UserAgent> when they are created. That way all properly implemented sub classes
like L<WWW::Mechanize> will go through it. But if you encounter one that installs its
own handlers into the user agent after calling C<new> in L<LWP::UserAgent>
that might overwrite the ones L<LWP::ConsoleLogger> installed.

L<LWP::ConsoleLogger::Everywhere> will keep references to all user agents that were
ever created during for the lifetime of your application. If you have a lot of lexical
user agents that you recycle all the time they will not actually go away and might
consume memory.

=head1 SEE ALSO

For more information or if you want more detailed control see L<LWP::ConsoleLogger>.

=cut
