use v6;
use Test;

use lib 'lib';
use Email::MIME::ParseContentType;

plan 6;

my $result = Email::MIME::ParseContentType.parse-content-type('');
is $result<discrete>, 'text', "Default content type parses <discrete>(text)...";
is $result<component>, 'plain', "...and <component>(plain)...";
is $result<attributes><charset>, 'us-ascii', "...and charset attribute.";

$result = Email::MIME::ParseContentType.parse-content-type('text/html; charset=utf-8');
is $result<discrete>, 'text', "Passed content type parses <discrete>(text)...";
is $result<component>, 'html', "...and <component>(plain)...";
is $result<attributes><charset>, 'utf-8', "...and charset attribute.";
