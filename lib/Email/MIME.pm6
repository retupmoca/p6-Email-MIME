use Email::Simple;

use Email::MIME::ParseContentType;

class Email::MIME is Email::Simple does Email::MIME::ParseContentType;

has $!ct;
has @!parts;
has $!body-raw;

method new (Str $text){
    my $self = callsame;
    $self._finish_new();
    return $self;
}
method _finish_new(){
    $!ct = self.parse-content-type(self.content-type);
    self.parts;
}

method body-raw {
    return $!body-raw // self.body;
}

method parts {
    self.fill-parts unless @!parts;
    
    if +@!parts {
        return @!parts;
    } else {
        return self;
    }
}

method subparts {
    self.fill-parts unless @!parts;
    return @!parts;
}

method fill-parts {
    if $!ct<discrete> eq "multipart" || $!ct<discrete> eq "message" {
        self.parts-multipart;
    } else {
        self.parts-single-part;
    }
    
    return self;
}

method parts-single-part {
    @!parts = ();
}

method parts-multipart {
    my $boundary = $!ct<attributes><boundary>;

    $!body-raw //= self.body;
    my @bits = split(/\-\-$boundary/, self.body-raw);
    my $x = 0;
    for @bits {
        if $x {
            unless $_ ~~ /^\-\-/ {
                $_ ~~ s/^\n//;
                $_ ~~ s/\n$//;
                @!parts.push(self.new($_));
            }
        } else {
            $x++;
            self.body-set($_);
        }
    }

    return @!parts;
}

method content-type(){
  return ~self.header("Content-type");
}

###
# content transfer encoding stuff here
###

my %cte-coders = ();

method set-encoding-coder($cte, $coder) {
    %cte-coders{$cte} = $coder;
}

method body {
    my $body = callsame;
    my $cte = ~self.header('Content-Transfer-Encoding') // '';
    $cte ~~ s/\;.*$//;
    $cte ~~ s:g/\s//;

    if $cte && %cte-coders{$cte}.can('decode') {
        return %cte-coders{$cte}.decode($body);
    } else {
        return $body.encode('ascii');
    }
}

method body-set($body) {
    my $cte = ~self.header('Content-Transfer-Encoding') // '';
    $cte ~~ s/\;.*$//;
    $cte ~~ s:g/\s//;

    my $body-encoded;
    if $cte && %cte-coders{$cte}.can('encode') {
        $body-encoded = %cte-coders{$cte}.encode($body);
    } else {
        if($body.isa('Str')){
            # ensure everything is ascii like it should be
            $body-encoded = $body.encode('ascii').decode('ascii');
        }else{
            $body-encoded = $body.decode('ascii');
        }
    }

    $!body-raw = $body-encoded;
    callwith($body-encoded);
}

method encoding-set($enc) {
    my $body = self.body;
    self.header-set('Content-Transfer-Encoding', $enc);
    self.body-set($body);
}

###
# charset stuff here
###

method body-str {
    my $body = self.body;
    if $body.isa('Str') {
        # if body is a Str, we assume it's already been decoded
        return $body;
    }
    if $body.can('decode') {
        my $charset = $!ct<attributes><charset>;

        if $charset eq 'us-ascii' {
            $charset = 'ascii';
        }

        unless $charset {
            if $!ct<discrete> eq 'text' && ($!ct<component> eq 'plain'
                                            || $!ct<component> eq 'html') {
                return $body.decode('ascii');
            }

            # I have a Buf with no charset. Can't really do anything...
            # TODO: exception
        }

        return $body.decode($charset);
    }
    # Not a Buf or a Str? We don't know how to handle it.
    # Call .body and do it yourself!
    # TODO: exception
}

method body-str-set(Str $body) {
    my $charset = $!ct<attributes><charset>;

    if $charset eq 'us-ascii' {
        $charset = 'ascii';
    }

    unless $charset {
        # well, we can't really do anything with this
        # TODO: exception
    }

    self.body-set($body.encode($charset));
}

method header-str-set($header, $value) {
    # Stubbity stub stub stub
    self.header-set($header, $value);
}
