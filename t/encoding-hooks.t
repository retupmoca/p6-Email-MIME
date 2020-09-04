use v6;

class TestEncoding {
    method encode($bodytext){
        return "Encode";
    }

    method decode($encodedtext){
        return "Decode";
    }
}

use Test;

use lib 'lib';
use Email::MIME;

plan 9;

my $mail-text = slurp 't/test-mails/encoding-hooks';

my $eml = Email::MIME.new($mail-text);
is $eml.body-str, "This is some testing text.\n", 'Test empty decoder hook';
$eml.body-str-set('stuff here');
is $eml.body-raw, 'stuff here', 'Test empty encoder hook';

Email::MIME.set-encoding-handler('testencoding', TestEncoding);
$eml = Email::MIME.new($mail-text);
is $eml.body-str, 'Decode', 'Test decoder hook';
$eml.body-str-set('stuff here');
is $eml.body-raw, 'Encode', 'Test encoder hook';

# Check header-pairs and a sampling of fields within that dataset.
my @header-pairs = $eml.header-str-pairs;
is @header-pairs.elems, 7, '7 Header pairs';
for @header-pairs -> @pair {
    my ($name, $value) = @pair;

    given $name {
        when 'From' {is $value, 'example@example.com', 'From is correct'};
        when 'To' {is $value, 'example2@example.com', 'To is correct'};
        when 'Subject' {is $value, 'Test encoding', 'Subject is correct'};
        when 'Date' {is $value, 'Fri, 4 Aug 2006 18:52:34 -0400', 'Date is correct'};
    }
}