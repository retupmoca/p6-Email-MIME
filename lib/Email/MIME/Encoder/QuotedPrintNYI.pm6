use v6;
class Email::MIME::Encoder::QuotedPrintNYI;

method encode($stuff) {
    die X::Email::MIME::NYI.new('quoted-printable encode needs port of MIME::QuotedPrint');
}

method decode($stuff) {
    die X::Email::MIME::NYI.new('quoted-printable decode needs port of MIME::QuotedPrint');
}
