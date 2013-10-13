role Email::MIME::ParseContentType;

grammar ContentTypeHeader {
    token TOP {
        ^ <discrete> \/ <component> \s* <params>? $
    }
    token discrete {
        \w+
    }
    token component {
        \w+
    }
    token params {
        \; [\s* <param>]* \s*
    }
    token param {
        <name> \= <value>
    }
    token name {
        [\w | \- | _]+
    }
    token value {
        [\w | \- | _]+
    }
}

method parse-content-type (Str $content-type) {
    my $ct-default = 'text/plain; charset=us-ascii';
    
    unless $content-type && $content-type.chars {
        return self.parse-content-type($ct-default);
    }
    
    my $result;
    
    try {
        my $parsed = ContentTypeHeader.parse($content-type);
        
        $result<discrete> = $parsed<discrete>;
        $result<component> = $parsed<component>;
        
        my @entries = $parsed<params><param>.list;
        for @entries {
            $result<attributes>{$_<name>} = $_<value>;
        }
        
        CATCH {
            default {
                $result = self.parse-content-type($ct-default);
            }
        }
    }
    
    return $result;
}
