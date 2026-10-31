{ pkgs ? import <nixpkgs> {} }:

 pkgs.mkShellNoCC {
    packages = [
      pkgs.rakudo
      pkgs.zef
    ];

    shellHook = ''
      export PATH=$HOME/.raku/bin:$PATH
      zef install App::Prove6 MIME::QuotedPrint
    '';    
}
