{
  description = "Misland — a MacBook-style notch shell for Hyprland, built on Quickshell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        misland = pkgs.callPackage ./nix/package.nix { };
        default = misland;
      });

      homeManagerModules = rec {
        misland = import ./nix/hm-module.nix self;
        default = misland;
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ quickshell brightnessctl cliphist wl-clipboard hyprpicker ];
          # Make the UI fonts visible without installing them system-wide.
          FONTCONFIG_FILE = pkgs.writeText "misland-fonts.conf" ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
            <fontconfig>
              <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
              <dir>${pkgs.inter}/share/fonts</dir>
              <dir>${pkgs.material-symbols}/share/fonts</dir>
            </fontconfig>
          '';
        };
      });
    };
}
