use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use Plack::Middleware::Throttle::Lite::Backend::Redis;

can_ok 'Plack::Middleware::Throttle::Lite::Backend::Redis', qw(
    redis
    reqs_done
    increment
    rdb
);

# simple application
my $app = sub {
    [
        200,
        [ 'Content-Type' => 'text/html' ],
        [ '<html><body>OK</body></html>' ]
    ];
};

#
# catch exceptions
#
eval { $app = builder { enable 'Throttle::Lite', backend => 'Redis'; $app } };
like $@, qr|Settings should include either server or sock parameter|, 'Failed without options';

eval { $app = builder { enable 'Throttle::Lite', backend => [ 'Redis' => {} ]; $app } };
like $@, qr|Settings should include either server or sock parameter|, 'Failed without mandatory params in passed options';

eval { $app = builder { enable 'Throttle::Lite', backend => [ 'Redis' => {server => 'foo'} ]; $app } };
like $@, qr|Expected 'hostname:port'|, 'Invalid server parameter exception';

SKIP: {
    skip 'Unix specific test', 1 if $^O eq 'MSWin32';
    eval { $app = builder { enable 'Throttle::Lite', backend => [ 'Redis' => {sock => '/bogus.sock'} ]; $app } };
    like $@, qr|Nonexistent redis socket|, 'Invalid sock parameter exception';
}

eval { $app = builder { enable 'Throttle::Lite', backend => [ 'Redis' => {server => 'bogus:0'} ]; $app } };
like $@, qr|Cannot get redis handle: .*|, 'Unable to connect to redis at bogus:0';

done_testing();
