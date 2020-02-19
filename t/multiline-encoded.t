use v6;

use Test;

use lib 'lib';
use Email::MIME;

my $mail-text = slurp 't/test-mails/multiline-encoded';

my $eml = Email::MIME.new($mail-text);
is $eml.header-str('X-Gmail-Labels'), 'Arkiverat,Viktigt,Öppnat,Kategorin Personligt,jubbered/textred,BG,jubbered', 'Multiple encoded words';
is $eml.header-str('To'), q{Keld Jørn Simonsen <keld@dkuug.dk>} , 'Mixed To field';

throws-like {
  my $subject = $eml.header-str('Subject');
}, X::AdHoc,  'Unknown ISO-8859-2 encoding', message => q{Unknown string encoding: 'iso-8859-2'};

is $eml.header-str('X-Single'), 'Arkiverat,Viktigt,Öppnat,Kategorin Pe', 'Wholly encoded header';
is $eml.header-str('Tricky-Line'), q{FDKL =? text here ?=}, 'Non-encoded but uses =? ?=';

done-testing;
