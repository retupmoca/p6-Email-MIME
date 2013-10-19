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

method create {
    # TODO
}

method body-raw {
    return $!body-raw // self.body(True);
}

method parts {
    self.fill-parts unless @!parts;
    
    if +@!parts {
        return @!parts;
    } else {
        return self;
    }
}

method debug-structure {
    # TODO
}

method filename {
    # TODO
}

method invent-filename {
    # TODO
}

method filename-set {
    # TODO
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

    $!body-raw //= self.body(True);
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

method parts-set(@parts) {
    my $body = '';

    if +@parts > 1 && $!ct<discrete> eq 'multipart' {
        my $boundary = '';

        for @parts -> $part {
            $body ~= self.crlf ~ "--" ~ $boundary ~ self.crlf;
            $body ~= ~$part;
        }
        $body ~= self.crlf ~ "--" ~ $boundary ~ "--" ~ self.crlf;
        #ct
    } elsif +@parts == 1 {
        my $part = @parts[0];
        if $part.isa('Str') {
            $body = ~$part;
        } else {
            $body = $part.body;
        }
        #ct
        self.encoding-set(...);
        # remove boundary
    }

    self!compose-content-type(...);
    self.body-set($body);
    self.fill-parts;
    self!reset-cids;
}

method parts-add {
    # TODO
}

method walk-parts {
    # TODO
}

method boundary-set {
    # TODO
}

method content-type(){
  return ~self.header("Content-type");
}

method content-type-set {
    # TODO
}

method charset-set {
    # TODO
}

method name-set {
    # TODO
}

method format-set {
    # TODO
}

method disposition-set {
    # TODO
}

method as-string {
    return self.header-obj.as-string ~ self.crlf ~ self.body-raw;
}

method !compose-content-type {
    # TODO
}

method !get-cid {
    # TODO: exception (Email::MessageID doesn't exist)
}

method !reset-cids {
    # TODO
}

###
# content transfer encoding stuff here
###

my %cte-coders = ();

method set-encoding-handler($cte, $coder) {
    %cte-coders{$cte} = $coder;
}

method body($callsame_only?) {
    my $body = callwith();
    if $callsame_only {
        return $body;
    }
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
        if $body.isa('Str') {
            # ensure everything is ascii like it should be
            $body-encoded = $body.encode('ascii').decode('ascii');
        } else {
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

        if $charset ~~ m:i/^us\-ascii$/ {
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

    unless $charset {
        # well, we can't really do anything with this
        # TODO: exception
    }

    if $charset ~~ m:i/^us\-ascii$/ {
        $charset = 'ascii';
    }

    self.body-set($body.encode($charset));
}

method header-str-set($header, $value) {
    # Stubbity stub stub stub
    self.header-set($header, $value);
}
