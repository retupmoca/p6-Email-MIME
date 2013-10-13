use Email::Simple;

use Email::MIME::ParseContentType;

class Email::MIME is Email::Simple does Email::MIME::ParseContentType;

has $!ct;
has $!parts;

method new (Str $text){
    my $self = callsame;
    $self._finish_new();
    return $self;
}
method _finish_new(){
    $!ct = self.parse-content-type(self.content-type);
    self.parts;
}

method parts {
    self.fill-parts unless $!parts;
    
    if $!parts.length {
        return $!parts;
    } else {
        return self;
    }
}

method subparts {
    self.fill-parts unless $!parts;
    return $!parts;
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
    $!parts = [];
}

method parts-multipart {
    my $boundary = $!ct<attributes><boundary>
    
    
}

method content-type(){
  return ~self.header("Content-type");
}
