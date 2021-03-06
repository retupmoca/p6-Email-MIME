use v6;
use Test;

use lib 'lib';

plan 10;

use Email::MIME;

my $eml = Email::MIME.create(header-str => ['from' => 'root+github@retupmoca.com',
                                            'subject' => 'This is a»test.'],
                             attributes => {'content-type' => 'text/plain',
                                            'charset' => 'utf-8',
                                            'encoding' => 'quoted-printable'},
                             body-str => 'Hello«World');

ok $eml ~~ Email::MIME, 'Can create a simple email.';

is $eml.header-str('subject'), 'This is a»test.', 'Got subject back correctly.';
ok $eml.header('subject') ne $eml.header-str('subject'), 'raw subject is different';
is $eml.body-str, 'Hello«World', 'Got body-str back correctly.';
ok $eml.body-raw ne $eml.body-str, 'raw body is different';

ok $eml.filename-set('File name.jpg'), 'Set a pure ASCII filename';
is $eml.header('Content-Disposition'), 'inline; filename="File name.jpg"', 'Disposition is set';

ok $eml.filename-set('Hans Holbein der Ältere.jpg'), 'Set a complex filename';
is $eml.header('Content-Disposition'), 'inline; filename*=utf-8\'\'Hans%20Holbein%20der%20%C3%84ltere.jpg', 'Disposition is set';

$eml = Email::MIME.create(parts => ['asdf', 'jkl']);
ok $eml ~~ Email::MIME, 'Can create simple multi-part';

