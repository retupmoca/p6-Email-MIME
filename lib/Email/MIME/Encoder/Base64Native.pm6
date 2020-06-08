use v6;
unit class Email::MIME::Encoder::Base64Native;

has &!base64-encode = (try require Base64::Native) !=== Nil
    ?? ::('Base64::Native::&base64-encode')
    !! sub () { die 'Base64::Native not installed. Can\'t use Email::MIME::Encode::Base64Native.' };
has &!base64-decode = (try require Base64::Native) !=== Nil
    ?? ::('Base64::Native::&base64-decode')
    !! sub () { die 'Base64::Native not installed. Can\'t use Email::MIME::Encode::Base64Native.' };

method encode($text, :$mime-header) {
    my $enc = &!base64-encode($text, :str);
    if $mime-header {
        return $enc;
    }
    else {
        my $max-line-len = 76;
        my $lstr = '';
        my $pos = 0;
        my $len = $enc.chars;
        while $pos + $max-line-len < $len {
            $lstr ~= $enc.substr: $pos, $max-line-len;
            $lstr ~= "\n";
            $pos += $max-line-len;
        }
        $lstr ~= $enc.substr: $pos;
        return $lstr;
    }
}

method decode($encoded) {
    return &!base64-decode($encoded).decode;
}
