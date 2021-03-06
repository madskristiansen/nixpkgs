{ stdenv, fetchurl, makeWrapper, cacert, zlib }:

let
  inherit (stdenv.lib) optionalString;

  platform = if stdenv.system == "x86_64-linux" 
    then "x86_64-unknown-linux-gnu"
    else abort "missing boostrap url for platform ${stdenv.system}";

  bootstrapHash =
    if stdenv.system == "x86_64-linux"
    then "1hsvf1vj18fqxkqw8jhnwahhk2q5xcl5396czr034fphmp5n4haw"
    else throw "missing boostrap hash for platform ${stdenv.system}";

  needsPatchelf = stdenv.isLinux;

  src = fetchurl {
     url = "https://static.rust-lang.org/dist/${version}/rustc-nightly-${platform}.tar.gz";
     sha256 = bootstrapHash;
  };

  version = "2016-11-26";
in

rec {
  rustc = stdenv.mkDerivation rec {
    name = "rustc-nightly-${version}";

    inherit version;
    inherit src;

    meta = with stdenv.lib; {
      homepage = http://www.rust-lang.org/;
      description = "A safe, concurrent, practical language";
      maintainers = with maintainers; [ qknight ];
      license = [ licenses.mit licenses.asl20 ];
    };

    buildInputs = [ makeWrapper ];
    phases = ["unpackPhase" "installPhase"];

    installPhase = ''
      ./install.sh --prefix=$out \
        --components=rustc

      ${optionalString needsPatchelf ''
        patchelf \
          --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
          "$out/bin/rustc"
      ''}
    '';
  };
}
