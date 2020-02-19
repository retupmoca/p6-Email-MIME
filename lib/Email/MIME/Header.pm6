use v6;

use Email::Simple::Header;
use Email::MIME::Encoder::Base64;
use MIME::QuotedPrint;

unit class Email::MIME::Header is Email::Simple::Header;

my %cte-coders = ('base64' => Email::MIME::Encoder::Base64,
        'quoted-printable' => MIME::QuotedPrint);

# The Spec allows for multiple encoded words within a header, including
# intermixed with non-encoded words. A "word" in this case may in-fact be
# multiple words separated by whitespace.
# https://tools.ietf.org/html/rfc1342
grammar EncodedHeader {
    token TOP {
        ^
        (
            | <encoded-word>
            | <text-word>
            | <special-word>
        )*
        $
    }
    token text-word {
        <-[=]>+
    }
    token special-word {
        "="
    }
    token encoded-word {
        \s? "=?" <charset> "?" <encoding> "?" <encoded-text> "?="
    }
    token charset {
        <-[?]>+
    }
    token encoding {
        <[BQ]>
    }
    token encoded-text {
        <-[?]>+
    }
}

my class EncodedHeader::Actions {
    has $.counter = 0;
    method text-word($/) {
        make $/.Str;
    }
    method special-word($/) {
        make $/.Str;
    }
    method encoded-word($/) {
        my $charset = $<charset>.Str;
        my $string = $<encoded-text>.Str;
        my $encoding = $<encoding>.Str;

        # TODO make this more flexible
        my $decoded-string;
        if $encoding.uc eq 'Q' {
            $decoded-string = %cte-coders<quoted-printable>.decode($string, :mime-header).decode($charset);
        } elsif $encoding.uc eq 'B' {
            $decoded-string = %cte-coders<base64>.decode($string, :mime-header).decode($charset);
        }

        make $decoded-string;
    }
    method TOP($/) {
        make $0.flatmap({.values[0].ast}).join;
    }
}

method set-encoding-handler($encoding, $handler){
    %cte-coders{$encoding} = $handler;
}

method header-str($header, :$multi) {
    my $values = self.header($header, :$multi);
    for $values.list -> $value is rw {
        $value = EncodedHeader.parse($value, :actions(EncodedHeader::Actions.new)).made;
    }

    return $values;
}

method header-str-set($header, *@lines is copy) {
    for @lines -> $value is rw {
        my $encode = False;
        my $blob = $value.encode('utf8');
        for $blob.list {
            if $_ > 126 || $_ < 32 {
                $encode = True;
            }
        }

        if $encode {
            # TODO use base64 instead?
            my $encoded = %cte-coders<quoted-printable>.encode($blob, :mime-header);
            $value = '=?UTF-8?Q?' ~ $encoded ~ '?=';
        }
    }
    self.header-set($header, |@lines);
}

method header-str-pairs {
    return gather {
        for self.headers -> $name {
            take [ $name, self.header-str($name) ];
        }
    };
}
