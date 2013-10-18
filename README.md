p6-Email-MIME
=============

This is a (very unfinished) port of perl 5's Email::MIME.

TODO: base64 (see below) and quoted-printable (requires a port of MIME::QuotedPrint); non-ascii header values (reqiures a port of Encode::MIME::Header); .create; exceptions

Note that you can define your own base64/quoted-printable handlers by calling Email::MIME.set-encoding-handler('base64', My::Base64::Handler); - your class must simply support .encode($stuff) and .decode($stuff) methods.

I don't want to depend on MIME::Base64 at this point, as it is a parrot-only module right now; if you would like to use it, install it and then manually enable the wrapper:

    use Email::MIME::Encoder::Base64;
    Email::MIME.set-encoding-handler('base64', Email::MIME::Encoder::Base64);
