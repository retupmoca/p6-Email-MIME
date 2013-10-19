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

method debug-structure($level = 0) {
    my $rv = ' ' x (5 * $level);
    $rv ~= '+ ' ~ self.content-type ~ "\n";
    if +self.parts > 1 {
        for self.parts -> $part {
            $rv ~= $part.debug-structure($level + 1);
        }
    }
    return $rv;
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
    if $!ct<type> eq "multipart" || $!ct<type> eq "message" {
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

    my $ct = self.parse-content-type(self.content-type);

    if +@parts > 1 && $!ct<type> eq 'multipart' {
        $ct<attributes><boundary> //= Email::MessageID.new.user; # TODO: exception (class doesn't exist)
        my $boundary = $ct<attributes><boundary>;

        for @parts -> $part {
            $body ~= self.crlf ~ "--" ~ $boundary ~ self.crlf;
            $body ~= ~$part;
        }
        $body ~= self.crlf ~ "--" ~ $boundary ~ "--" ~ self.crlf;
        unless $ct<type> eq 'multipart' || $ct<type> eq 'message' {
            $ct<type> = 'multipart';
            $ct<subtype> = 'mixed';
        }
    } elsif +@parts == 1 {
        my $part = @parts[0];
        $body = $part.body;
        my $thispart_ct = self.parse-content-type($part.content-type);
        $ct<type> = $thispart_ct<type>;
        $ct<subtype> = $thispart_ct<subtype>;
        self.encoding-set($part.header('Content-Transfer-Encoding'));
        $ct<attributes><boundary>.delete;
    }

    self!compose-content-type($ct);
    self.body-set($body);
    self.fill-parts;
    self!reset-cids;
}

method parts-add(@parts) {
    my @allparts = self.parts, @parts;
    self.parts-set(@allparts);
}

method walk-parts($callback) {
    # TODO
}

method boundary-set($data) {
    my $ct-hash = self.parse-content-type(self.content-type);
    if $data {
        $ct-hash<attributes><boundary> = $data;
    } else {
        $ct-hash<attributes><boundary>.delete;
    }
    self!compose-content-type($ct-hash);
    
    if +self.parts > 1 {
        self.parts-set(self.parts)
    }
}

method content-type(){
  return ~self.header("Content-type");
}

method content-type-set($ct) {
    my $ct-hash = self.parse-content-type($ct);
    self!compose-content-type($ct-hash);
    self!reset-cids;
    return $ct;
}

# TODO: make the next three methods into a macro call
method charset-set($data) {
    my $ct-hash = self.parse-content-type(self.content-type);
    if $data {
        $ct-hash<attributes><charset> = $data;
    } else {
        $ct-hash<attributes><charset>.delete;
    }
    self!compose-content-type($ct-hash);
    return $data;
}
method name-set($data) {
    my $ct-hash = self.parse-content-type(self.content-type);
    if $data {
        $ct-hash<attributes><name> = $data;
    } else {
        $ct-hash<attributes><name>.delete;
    }
    self!compose-content-type($ct-hash);
    return $data;
}
method format-set($data) {
    my $ct-hash = self.parse-content-type(self.content-type);
    if $data {
        $ct-hash<attributes><format> = $data;
    } else {
        $ct-hash<attributes><format>.delete;
    }
    self!compose-content-type($ct-hash);
    return $data;
}

method disposition-set($data) {
    self.header-set('Content-Disposition', $data);
}

method as-string {
    return self.header-obj.as-string ~ self.crlf ~ self.body-raw;
}

method !compose-content-type($ct-hash) {
    my $ct = $ct-hash<type> ~ '/' ~ $ct-hash<subtype>;
    for keys $ct-hash<attributes> -> $attr {
        $ct ~= "; " ~ $attr ~ '="' ~ $ct-hash<attributes>{$attr} ~ '"';
    }
    self.header-set('Content-Type', $ct);
    $!ct = $ct-hash;
}

method !get-cid {
    # TODO: exception (Email::MessageID doesn't exist)
}

method !reset-cids {
    my $ct-hash = self.parse-content-type(self.content-type);

    if +self.parts > 1 {
        if $ct-hash<subtype> eq 'alternative' {
            my $cids;
            for self.parts -> $part {
                my $cid = $part.header('Content-ID') // '';
                $cids{$cid}++;
            }
            if +$cids.keys == 1 {
                return;
            }

            my $cid = self!get-gid;
            for self.parts -> $part {
                $part.header-set('Content-ID', $cid);
            }
        } else {
            for self.parts -> $part {
                my $cid = self!get-cid;
                unless $part.header('Content-ID') {
                    $part.header-set('Content-ID', $cid);
                }
            }
        }
    }
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
            if $!ct<type> eq 'text' && ($!ct<subtype> eq 'plain'
                                        || $!ct<subtype> eq 'html') {
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
