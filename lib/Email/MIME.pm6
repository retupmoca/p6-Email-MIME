use Email::Simple;

class Email::MIME is Email::Simple;

has $!ct;

method new (Str $text){
    my $self = callsame;
    $self._finish_new();
    return $self;
}
method _finish_new(){
    $!ct = self.parse-content-type(self.content-type);
}

method parse-content-type($content-type){
    return $content-type;
}

method content-type(){
  return ~self.header("Content-type");
}
