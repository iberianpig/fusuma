{ pkgs }: with pkgs;
let
  # be sure that gemset.nix reflects Gemfile.lock
  src = ../..;
  gems = bundlerEnv {
    inherit ruby;
    name = "fusuma";
    gemdir = src;
  };
in stdenv.mkDerivation {
  name = "fusuma";
  meta = {
    mainProgram = "fusuma";
  };
  inherit src;
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ gems ruby ];
  installPhase = ''
    mkdir -p $out/{bin,share/fusuma}
    cp -r * $out/share/fusuma
    bin=$out/bin/fusuma
    cat > $bin <<EOF
#!/bin/sh -e
${gems.wrappedRuby}/bin/ruby $out/share/fusuma/exe/fusuma "\$@"
EOF
    chmod +x $bin
    wrapProgram $out/bin/fusuma \
    --set PATH ${lib.makeBinPath [
      coreutils
      gnugrep
      libyaml
      libinput
    ]}
  '';
}