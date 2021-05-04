use v6;
use Test;

use lib 'lib';
use Email::MIME::AttributeHeaderParsing;

plan 22;

my $result = Email::MIME::AttributeHeaderParsing::parse-content-type('');
is $result<type>, 'text', "Default content type parses <type>(text)...";
is $result<subtype>, 'plain', "...and <subtype>(plain)...";
is $result<attributes><charset>, 'us-ascii', "...and charset attribute.";

$result = Email::MIME::AttributeHeaderParsing::parse-content-type('text/html; charset=utf-8');
is $result<type>, 'text', "Passed content type parses <type>(text)...";
is $result<subtype>, 'html', "...and <subtype>(plain)...";
is $result<attributes><charset>, 'utf-8', "...and charset attribute.";

$result = Email::MIME::AttributeHeaderParsing::parse-content-type(
    "multipart/mixed; boundary=\"1154731954.d55bF4462.2751\"; charset=\"us-ascii\"");
is $result<type>, 'multipart', "Complex content type parses <type>...";
is $result<subtype>, 'mixed', "...and <subtype>...";
is $result<attributes><charset>, 'us-ascii', "...and charset attribute...";
is $result<attributes><boundary>, '1154731954.d55bF4462.2751', "...and boundary attribute.";

$result = Email::MIME::AttributeHeaderParsing::parse-content-type(
    "multipart/mixed; boundary=\"1154731954.d55bF4462.2751\";\n charset=\"us-ascii\"");
is $result<type>, 'multipart', "Complex with newline content type parses <type>...";
is $result<subtype>, 'mixed', "...and <subtype>...";
is $result<attributes><charset>, 'us-ascii', "...and charset attribute...";
is $result<attributes><boundary>, '1154731954.d55bF4462.2751', "...and boundary attribute.";

$result = Email::MIME::AttributeHeaderParsing::parse-content-type(
    "image/x-portable-greymap");
is $result<type>, "image", "content type with dashes <type>...";
is $result<subtype>, "x-portable-greymap", "...and <subtype>";

$result = Email::MIME::AttributeHeaderParsing::parse-content-disposition(
    "attachment;filename=text.txt");
is $result<type>, "attachment", "disposition type ...";
is $result<attributes><filename>, "text.txt", "...and filename";

$result = Email::MIME::AttributeHeaderParsing::parse-content-disposition(
    "attachment;filename*=utf-8'en-us'Tr%C3%B6deln.txt");
is $result<type>, "attachment", "disposition type ...";
is $result<attributes><filename>, "Trödeln.txt", "...and filename in utf-8";

$result = Email::MIME::AttributeHeaderParsing::parse-content-disposition(
    "attachment;filename*=ascii'en-us'rep%6Frt.txt");
is $result<type>, "attachment", "disposition type ...";
is $result<attributes><filename>, "report.txt", "...and filename in encoded ASCII";
