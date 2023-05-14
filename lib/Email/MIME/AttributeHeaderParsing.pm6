unit module Email::MIME::AttributeHeaderParsing;

my grammar AttributeHeader {
    token ContentDispositionHeader {
        ^ <type> \s* <params>? $
    }
    token ContentTypeHeader {
        ^ <type> \/ <subtype> \s* <params>? $
    }
    token type {
        \w+
    }
    token subtype {
        [\w+]+ %% ['-']
    }
    token params {
        [\; \s* [ <param> | <param-rfc2231> ] ]* \s*
    }
    token param {
        <name> \= \"?<value>\"?
    }
    token param-rfc2231 {
        <name> '*=' <charset>? "'" <language>? "'" <value>
    }
    token charset {
        <-[\s']>+
    }
    token language {
        <-[\s']>+
    }
    token name {
        <[\w-]>+
    }
    token value {
        <-[";]>+
    }
}

our sub parse-content-type (Str $content-type) {
    my $ct-default = 'text/plain; charset=us-ascii';
    
    unless $content-type && $content-type.chars {
        return parse-content-type($ct-default);
    }
    
    my $result;
    
    try {
        my $parsed = AttributeHeader.parse($content-type, rule => 'ContentTypeHeader');
        $result<type> = ~$parsed<type>;
        $result<subtype> = ~$parsed<subtype>;
        $result<attributes> = parse-attributes($parsed<params>);

        CATCH {
            default {
                $result = parse-content-type($ct-default);
            }
        }
    }
    
    return $result;
}

our sub compose-content-type(Str $type, Str $subtype, %attributes --> Str) {
    return $type ~ '/' ~ $subtype ~ compose-attributes(%attributes);
}


our sub parse-content-disposition (Str $content-disposition) {
    my $result;
    my $parsed = AttributeHeader.parse($content-disposition, rule => 'ContentDispositionHeader');
    $result<type> = ~$parsed<type>;
    $result<attributes> = parse-attributes($parsed<params>);
    return $result;
}

our sub compose-content-disposition (Str $name, %attributes --> Str) {
    my $result = $name ~ compose-attributes(%attributes);
}

sub compose-attributes (%attributes --> Str) {
    my $result = '';
    for %attributes.kv -> $name, $value {
        try { $value.encode('ascii', :!replacement) }
        if $! {
            $result ~= '; ' ~ $name ~ "*=utf-8''" ~ encode-percent-encoding($value);
        }
        else {
            $result ~= '; ' ~ $name ~ '="' ~ $value ~ '"';
        }
    }
    return $result;
}

sub parse-attributes ($param-match) {
    my %params;

    for $param-match<param>.list {
        %params{~$_<name>} = ~$_<value>;
    }

    for $param-match<param-rfc2231>.list {
        my $charset = ~$_<charset>;
        if $charset {
            %params{~$_<name>} = decode-percent-encoding(~$_<value>, $charset);
        }
        else {
            %params{~$_<name>} = ~$_<value>;
        }
    }
    return %params;
}

sub decode-percent-encoding (Str $text, Str $encoding --> Str) {
    my $pos1 = 0;
    my $pos2 = 0;
    my Buf $buf .= new;
    while $pos2 = $text.index('%', $pos2) {
        $buf.append: $text.substr($pos1..$pos2-1).encode: 'ascii';
        $buf.append: ('0x' ~ $text.substr($pos2+1, 2)).Numeric;
        $pos1 = $pos2 = $pos2 + 3;
    }
    $buf.append: $text.substr($pos1).encode('ascii');
    return $buf.decode: $encoding;
}

sub encode-percent-encoding (Str $value --> Str) {
    return $value.subst( /(<-[a..z A..Z 0..9 \- \. \_ \~]>)/, { $0.Str.encode('utf8').map({ '%' ~ $_.base(16) }).join('') }, :g );
}

