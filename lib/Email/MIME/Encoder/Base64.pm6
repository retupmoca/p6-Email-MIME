use v6;
class Email::MIME::Encoder::Base64;

use MIME::Base64;

method encode($stuff) {
    unless $stuff.isa('Str') {
        $stuff = $stuff.decode('ascii');
    }
    return MIME::Base64.encode_base64($stuff);
}

method decode($stuff) {
    my $decoded = MIME::Base64.decode_base64($stuff);
    if $decoded.isa('Str') {
        $decoded = $decoded.encode('ascii');
    }
    return $decoded;
}
