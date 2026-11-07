{ lib, stdenvNoCC, writeShellScript, quickshell, brightnessctl, cliphist, wl-clipboard, hyprpicker }:

let
  qs = lib.getExe' quickshell "qs";

  # `misland` runs the shell (a second start is a no-op, so it can sit in the
  # Hyprland config). Subcommands drive the running instance.
  launcher = writeShellScript "misland" ''
    export PATH=${lib.makeBinPath [ brightnessctl cliphist wl-clipboard hyprpicker ]}:$PATH
    config=@out@/share/misland
    case "''${1:-}" in
      toggle|open|close) exec ${qs} ipc -p "$config" call notch "$1" ;;
      launcher|clipboard) exec ${qs} ipc -p "$config" call "$1" "''${2:-toggle}" ;;
      color) exec ${qs} ipc -p "$config" call color pick ;;
      "") exec ${qs} -n -p "$config" ;;
      *) exec ${qs} -p "$config" "$@" ;;
    esac
  '';
in
stdenvNoCC.mkDerivation {
  pname = "misland";
  version = "0.6.0";

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
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
