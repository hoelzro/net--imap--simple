use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 18;

sub run_tests {
    open INFC, ">informal-imap-client-dump.log";
    # we don't care very much if the above command fails

    my $imap = Net::IMAP::Simple->new($ENV{NIS_TEST_HOST}, debug=>\*INFC, use_ssl=>1)
        or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

    ok( $imap->login(@ENV{qw(NIS_TEST_USER NIS_TEST_PASS)}) )
        or die "\nlogin failure: " . $imap->errstr . "\n";

    my $nm = $imap->select("INBOX");
    $imap->delete("1:$nm");
    $imap->expunge_mailbox;
    $nm = $imap->select("INBOX");

    ok( $imap->put( INBOX => "Subject: test!\n\ntest!" ), 1 )
        or die " error putting test message: " . $imap->errstr . "\n";

    my @c = (
        [ scalar $imap->select("fake"),  $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
        [ scalar $imap->select("INBOX"), $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
        [ scalar $imap->select("fake"),  $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
        [ scalar $imap->select("INBOX"), $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
    );

    ok( $c[$_][1], "INBOX" ) for 0 .. $#c;

    ok( $c[0][0], undef );
    ok( $c[1][0], $nm+1 );
    ok( $c[2][0], undef );
    ok( $c[3][0], $nm+1 );

    { no warnings 'uninitialized';
        ok( "@{ $c[$_] }[2,3,4]", " 1 0" ) for 0 .. $#c;
    }

    ## Test EXMAINE

    ok( $imap->examine('INBOX') );
    # ok( not $imap->put( INBOX => "Subject: test!\n\ntest!" ) );
    # ok( $imap->errstr, qr/read.*only/ );
    # this worked in Net::IMAP::Server -- dovecot apparently lets you append after examine... heh

    ok( $nm = $imap->select('INBOX') );
    ok( $imap->put( INBOX => "Subject: test!\n\ntest!" ), 1 )
        or die " error putting test message: " . $imap->errstr . "\n";
    ok( $imap->select('INBOX'), 2 );
}

do "t/test_runner.pm";
