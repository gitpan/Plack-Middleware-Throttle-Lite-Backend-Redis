package Plack::Middleware::Throttle::Lite::Backend::Redis;

# ABSTRACT: Redis-driven storage backend for Throttle-Lite

use strict;
use warnings;
use feature ':5.10';
use Carp ();
use parent 'Plack::Middleware::Throttle::Lite::Backend::Abstract';
use Redis 1.955;

our $VERSION = '0.01'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

__PACKAGE__->mk_attrs(qw(redis rdb));

sub init {
    my ($self, $args) = @_;

    my $croak = sub { Carp::croak $_[0] };

    if (!defined $args->{server} && !defined $args->{sock}) {
        $croak->("Settings should include either server or sock parameter!");
    }

    my %options = (
        debug     => $args->{debug}     || 0,
        reconnect => $args->{reconnect} || 10,
        every     => $args->{every}     || 100,
    );

    $options{password} = $args->{password} if $args->{password};

    if (defined $args->{sock}) {
        $croak->("Nonexistent redis socket ($args->{sock})!") unless -e $args->{sock} && -S _;
    }

    if (defined $args->{server}) {
        $croak->("Expected 'hostname:port' for parameter server!") unless $args->{server} =~ /(.*)\:(\d+)/;
    }

    if (defined $options{sock}) {
        $options{sock} = $args->{sock};
    }
    else {
        $options{server} = $args->{server};
    }

    $self->rdb($args->{database} || 0);

    my $_handle;
    eval { $_handle = Redis->new(%options) };
    $croak->("Cannot get redis handle: $@") if $@;

    $self->redis($_handle);
}

sub increment {
    my ($self) = @_;

    $self->redis->select($self->rdb);
    $self->redis->incr($self->cache_key);
    $self->redis->expire($self->cache_key, 1 + $self->expire_in);

}

sub reqs_done {
    my ($self) = @_;

    $self->redis->select($self->rdb);
    $self->redis->get($self->cache_key) || 0;
}

1; # End of Plack::Middleware::Throttle::Lite::Backend::Redis

__END__

=pod

=head1 NAME

Plack::Middleware::Throttle::Lite::Backend::Redis - Redis-driven storage backend for Throttle-Lite

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This is implemetation of the storage backend for B<Plack::Middleware::Throttle::Lite>. It uses redis-server
to hold throttling data, automatically sets expiration time for stored keys to save memory consumption.

=encoding utf8

=head1 SYNOPSYS

    # inside your app.psgi
    enable 'Throttle::Lite',
        backend => [
            'Redis' => {
                server   => 'redis.example.com:6379',
                database => 1,
                password => 'VaspUtnuNeQuiHesGapbootsewWeonJadacVebEe'
            }
        ];

=head1 OPTIONS

This storage backend must be configured in order to use. All options should be passed as a hash reference. The
following options are available to tune it for your needs.

=head2 server

A string consist of a hostname (or an IP address) and port number (delimited with a colon) of the redis-server
instance to connect to. You have to point either this one or L</sock>.
B<Warning!> This option has lower priority than L</sock>.

=head2 sock

A unix socket path of the redis-server instance to connect to. You have to point either this one or L</server>.
B<Warning!> This option has higher priority than L</server>.

=head2 database

A redis-server database number to store throttling data. Not obligatory option. If this one omitted then value B<0> will
be assigned.

=head2 password

Password string for redis-server's AUTH command to processing any other commands. Optional. Check the redis-server
manual for directive I<requirepass> if you would to use redis internal authentication.

=head2 reconnect

A time (in seconds) to re-establish connection to the redis-server before an exception will be raised. Not required.
Default value is B<10> sec.

=head2 every

Interval (in milliseconds) after which will be an attempt to re-establish lost connection to the redis-server. Not required.
Default value is B<100> ms.

=head2 debug

Enables debug information to STDERR, including all interactions with the redis-server. Not required.
Default value is B<0> (disabled).

=head1 METHODS

=head2 redis

Returns a redis connection handle.

=head2 rdb

A redis database number to store data.

=head2 init

See L<Plack::Middleware::Throttle::Lite::Backend::Abstract/"ABSTRACT METHODS">

=head2 reqs_done

See L<Plack::Middleware::Throttle::Lite::Backend::Abstract/"ABSTRACT METHODS">

=head2 increment

See L<Plack::Middleware::Throttle::Lite::Backend::Abstract/"ABSTRACT METHODS">

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Throttle-Lite-Backend-Redis/issues>

=head1 SEE ALSO

L<Redis>

L<Plack::Middleware::Throttle::Lite>

L<Plack::Middleware::Throttle::Lite::Backend::Abstract>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
