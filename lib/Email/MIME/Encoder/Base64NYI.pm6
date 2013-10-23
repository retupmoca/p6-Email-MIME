use v6;
class Email::MIME::Encoder::Base64NYI;

method encode($stuff, :$mime-header) {
    die X::Email::MIME::NYI.new('base64 encode needs port of MIME::Base64 - to use the parrot-only version, see Email::MIME readme');
}

method decode($stuff, :$mime-header) {
    die X::Email::MIME::NYI.new('base64 decode needs port of MIME::Base64 - to use the parrot-only version, see Email::MIME readme');
}
