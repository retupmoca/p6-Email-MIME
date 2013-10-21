p6-Email-MIME
=============

This is a port of perl 5's Email::MIME.

This module currently requires your system to have a working '/bin/hostname' (to generate Content-ID headers). This will go away once gethost() is implemented by rakudo.

TODO: base64 (see below); non-ascii header values (reqiures a port of Encode::MIME::Header); walk-parts

Note that you can define your own base64/quoted-printable handlers by calling Email::MIME.set-encoding-handler('base64', My::Base64::Handler); - your class must simply support .encode($stuff) and .decode($stuff) methods.

I don't want to depend on MIME::Base64 at this point, as it is a parrot-only module right now; if you would like to use it, install it and then manually enable the wrapper:

    use Email::MIME::Encoder::Base64;
    Email::MIME.set-encoding-handler('base64', Email::MIME::Encoder::Base64);
