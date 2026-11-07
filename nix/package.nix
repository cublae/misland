{ lib, stdenvNoCC, writeShellScript, quickshell, brightnessctl }:

let
  qs = lib.getExe' quickshell "qs";

  # `misland` runs the shell; `misland toggle|open|close` and
  # `misland launcher [toggle|open|close]` drive the running one.
  launcher = writeShellScript "misland" ''
    export PATH=${lib.makeBinPath [ brightnessctl ]}:$PATH
    config=@out@/share/misland
    case "''${1:-}" in
      toggle|open|close) exec ${qs} ipc -p "$config" call notch "$1" ;;
      launcher) exec ${qs} ipc -p "$config" call launcher "''${2:-toggle}" ;;
      *) exec ${qs} -p "$config" "$@" ;;
    esac
  '';
in
stdenvNoCC.mkDerivation {
  pname = "misland";
  version = "0.5.0";

  src = ../shell;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/misland $out/bin
    cp -r . $out/share/misland
    substitute ${launcher} $out/bin/misland --subst-var out
    chmod +x $out/bin/misland
    runHook postInstall
  '';

  meta = {
    description = "MacBook-style notch shell for Hyprland, built on Quickshell";
    mainProgram = "misland";
    platforms = lib.platforms.linux;
  };
}
