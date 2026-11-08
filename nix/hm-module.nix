self:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.misland;
  json = pkgs.formats.json { };
  inherit (lib) mkOption mkEnableOption mkIf types;
in
{
  options.programs.misland = {
    enable = mkEnableOption "Misland, a notch shell for Hyprland";

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The Misland package.";
    };

    settings = mkOption {
      description = ''
        Written to ~/.config/misland/config.json. The shell watches that file,
        so changes apply without a restart. Unset keys use the defaults below.
      '';
      default = { };
      type = types.submodule {
        freeformType = json.type;

        options = {
          screen = mkOption {
            type = types.str;
            default = "";
            example = "DP-5";
            description = "Output that shows the notch. Empty means the first screen.";
          };

          scale = mkOption {
            type = types.float;
            default = 1.0;
            description = ''
              Extra size multiplier. The notch already scales with the screen's
              logical height (1080 px = 1.0), so this is only for taste.
            '';
          };

          reserveSpace = mkOption {
            type = types.bool;
            default = true;
            description = "Reserve the collapsed notch height so windows tile below it.";
          };

          clock = {
            timeFormat = mkOption {
              type = types.str;
              default = "HH:mm";
              description = "Qt time format for the collapsed notch, e.g. \"h:mm AP\" or \"HH:mm:ss\".";
            };
            dateFormat = mkOption {
              type = types.str;
              default = "ddd, MMM d";
              description = "Qt date format next to the time. Empty hides the date.";
            };
            separator = mkOption {
              type = types.str;
              default = "·";
              description = "Text between time and date.";
            };
          };

          calendar.firstDayOfWeek = mkOption {
            type = types.ints.between 1 7;
            default = 1;
            description = "First column of the month grid: 1 = Monday … 7 = Sunday.";
          };

          brightness.device = mkOption {
            type = types.str;
            default = "";
            example = "amdgpu_bl1";
            description = "Entry in /sys/class/backlight. Empty picks the first one; none hides the slider.";
          };

          power =
            let
              command = default: mkOption {
                type = types.listOf types.str;
                inherit default;
                description = "Command (argv) for this power button.";
              };
            in
            {
              lock = command [ "loginctl" "lock-session" ];
              suspend = command [ "systemctl" "suspend" ];
              # Empty: exit Hyprland over IPC, in Lua or hyprlang syntax as needed.
              logout = command [ ];
              reboot = command [ "systemctl" "reboot" ];
              poweroff = command [ "systemctl" "poweroff" ];
            };

          notifications = {
            timeout = mkOption {
              type = types.number;
              default = 5;
              description = "Seconds a popup stays when the app does not set a timeout. Critical ones stay until closed.";
            };
            maxHistory = mkOption {
              type = types.ints.positive;
              default = 50;
              description = "Notifications kept in the notch history.";
            };
            autoDndOnScreenShare = mkOption {
              type = types.bool;
              default = true;
              description = "Hide notification popups while the screen is being shared.";
            };
          };

          activities =
            let
              toggle = what: mkOption {
                type = types.bool;
                default = true;
                description = "Show a live activity in the notch for ${what}.";
              };
            in
            {
              volume = toggle "volume changes";
              brightness = toggle "brightness changes";
              power = toggle "the charger being plugged in or out";
              bluetooth = toggle "Bluetooth devices connecting or disconnecting";
              track = toggle "track changes";
            };

          edges = {
            workspaces = mkOption {
              type = types.bool;
              default = true;
              description = "Workspaces drop down when the pointer touches the top edge left of the notch.";
            };
            tray = mkOption {
              type = types.bool;
              default = true;
              description = "The system tray drops down when the pointer touches the top edge right of the notch.";
            };
            triggerSize = mkOption {
              type = types.number;
              default = 2;
              description = "Thickness in pixels of the hover strip along the top edge.";
            };
            triggerLength = mkOption {
              type = types.number;
              default = 0.35;
              description = "Length of each hover strip as a fraction of the screen width, from the corner inward.";
            };
            persistentWorkspaces = mkOption {
              type = types.ints.unsigned;
              default = 5;
              description = "Workspaces 1..N are always listed, even when empty.";
            };
            showOnSwitch = mkOption {
              type = types.bool;
              default = true;
              description = "Pop the workspaces out of their corner for a moment on every workspace switch.";
            };
            showOnSwitchMs = mkOption {
              type = types.ints.positive;
              default = 1200;
              description = "How long, in milliseconds, the workspaces stay out after a switch.";
            };
          };

          launcher = {
            maxResults = mkOption {
              type = types.ints.positive;
              default = 7;
              description = "Rows shown in the launcher.";
            };
            terminal = mkOption {
              type = types.listOf types.str;
              default = [ "kitty" "-e" ];
              description = "Prefix used to run desktop entries with Terminal=true.";
            };
          };

          clipboard = {
            watch = mkOption {
              type = types.bool;
              default = true;
              description = "Record clipboard history (wl-paste --watch cliphist store). Turn off if something else already feeds cliphist.";
            };
            maxItems = mkOption {
              type = types.ints.positive;
              default = 100;
              description = "Entries listed in the clipboard view.";
            };
          };

          colorPicker.format = mkOption {
            type = types.enum [ "hex" "rgb" "hsl" "hsv" "cmyk" ];
            default = "hex";
            description = "Format the colour picker copies.";
          };

          animation = {
            spring = mkOption {
              type = types.float;
              default = 3.6;
              description = "Spring stiffness of the expand animation.";
            };
            damping = mkOption {
              type = types.float;
              default = 0.55;
              description = "Spring damping, 0..1; lower values bounce more.";
            };
          };
        };
      };
    };

    systemd = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Start Misland as a systemd user service with the graphical session.
          Turn off to start it from the Hyprland config instead (`misland`).
        '';
      };
      target = mkOption {
        type = types.str;
        default = "graphical-session.target";
        example = "hyprland-session.target";
        description = "Systemd target that starts and stops Misland.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Only one process can own org.freedesktop.Notifications.
    warnings = map (name: "programs.misland is the notification daemon; disable services.${name}.")
      (lib.filter (name: lib.attrByPath [ "services" name "enable" ] false config) [ "mako" "dunst" "swaync" "fnott" ]);

    home.packages = [ cfg.package pkgs.inter pkgs.material-symbols ];
    fonts.fontconfig.enable = true;

    xdg.configFile."misland/config.json".source =
      json.generate "misland-config.json" cfg.settings;

    systemd.user.services.misland = mkIf cfg.systemd.enable {
      Unit = {
        Description = "Misland notch shell";
        PartOf = [ cfg.systemd.target ];
        After = [ cfg.systemd.target ];
      };
      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 2;
        # Quickshell can hang on exit after many live reloads; do not wait long.
        TimeoutStopSec = 3;
      };
      Install.WantedBy = [ cfg.systemd.target ];
    };
  };
}
