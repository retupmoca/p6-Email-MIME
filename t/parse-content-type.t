use v6;
use Test;

use lib 'lib';
use Email::MIME::ParseContentType;

plan 14;

my $result = Email::MIME::ParseContentType.parse-content-type('');
is $result<discrete>, 'text', "Default content type parses <discrete>(text)...";
is $result<component>, 'plain', "...and <component>(plain)...";
is $result<attributes><charset>, 'us-ascii', "...and charset attribute.";

$result = Email::MIME::ParseContentType.parse-content-type('text/html; charset=utf-8');
is $result<discrete>, 'text', "Passed content type parses <discrete>(text)...";
is $result<component>, 'html', "...and <component>(plain)...";
is $result<attributes><charset>, 'utf-8', "...and charset attribute.";

$result = Email::MIME::ParseContentType.parse-content-type(
    "multipart/mixed; boundary=\"1154731954.d55bF4462.2751\"; charset=\"us-ascii\"");
is $result<discrete>, 'multipart', "Complex content type parses <discrete>...";
is $result<component>, 'mixed', "...and <component>...";
is $result<attributes><charset>, 'us-ascii', "...and charset attribute...";
is $result<attributes><boundary>, '1154731954.d55bF4462.2751', "...and boundary attribute.";

$result = Email::MIME::ParseContentType.parse-content-type(
    "multipart/mixed; boundary=\"1154731954.d55bF4462.2751\";\n charset=\"us-ascii\"");
is $result<discrete>, 'multipart', "Complex with newline content type parses <discrete>...";
is $result<component>, 'mixed', "...and <component>...";
is $result<attributes><charset>, 'us-ascii', "...and charset attribute...";
is $result<attributes><boundary>, '1154731954.d55bF4462.2751', "...and boundary attribute.";
