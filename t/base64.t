use v6;

use Test;

use lib 'lib';
use Email::MIME;

plan 2;

my $email-text = 'Some body text';
my $email-raw = 'U29tZSBib2R5IHRleHQ=';

{
    my $email = Email::MIME.create(
        attributes => {
            content-type => 'text/plain',
            charset      => 'utf-8',
            encoding     => 'base64',
        },
        body-str => $email-text);
    is $email.body-raw, $email-raw, 'Base64 encoding works';
}

{
    my $email = Email::MIME.create(
        attributes => {
            content-type => 'text/plain',
            charset      => 'utf-8',
            encoding     => 'base64',
        },
        body-raw => $email-raw);
    is $email.body-str, $email-text, 'Base64 decoding works';
}

