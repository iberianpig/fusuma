{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    pkgs.ruby
    pkgs.libyaml
    pkgs.libinput
    pkgs.bundix
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
