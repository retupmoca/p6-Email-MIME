use v6;
class Email::MIME::Encoder::Base64;

use MIME::Base64;

method encode($stuff, :$mime-header) {
    unless $stuff.isa('Str') {
        $stuff = $stuff.decode('ascii');
    }
    if $mime-header {
        my $str = MIME::Base64.encode_base64($stuff);
        $str ~~ s:g/\n//;
        return $str;
    } else {
        return MIME::Base64.encode_base64($stuff);
    }
}

method decode($stuff, :$mime-header) {
    my $decoded = MIME::Base64.decode_base64($stuff);
    if $decoded.isa('Str') {
        $decoded = $decoded.encode('ascii');
    }
    return $decoded;
}
