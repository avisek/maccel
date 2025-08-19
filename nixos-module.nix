# NixOS module for maccel - Mouse acceleration kernel module
# https://github.com/Gnarus-G/maccel
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.hardware.maccel;

  # Fixed-point conversion functions
  # maccel uses 64-bit fixed-point with 32 fractional bits (FIXEDPT_FBITS = 32)
  fixedPointScale = 4294967296; # 2^32 for 64-bit systems

  # Convert float to fixed-point integer (as string for sysfs)
  toFixedPoint = value: toString (builtins.floor (value * fixedPointScale + 0.5));

  # Mode enum values (from driver/accel/mode.h)
  modeToInt = mode:
    {
      "linear" = "0";
      "natural" = "1";
      "synchronous" = "2";
      "no_accel" = "3";
    }.${
      mode
    };

  # Build the maccel kernel module
  maccel-kernel-module = config.boot.kernelPackages.callPackage (
    {
      lib,
      stdenv,
      kernel,
    }:
      stdenv.mkDerivation rec {
        pname = "maccel";
        version = "unstable";

        # Automatically fetch latest version from main branch - no hash needed!
        src = builtins.fetchGit {
          url = "https://github.com/Gnarus-G/maccel.git";
          ref = "main";
        };

        nativeBuildInputs = kernel.moduleBuildDependencies;

        makeFlags =
          [
            "KVER=${kernel.modDirVersion}"
            "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
            "DRIVER_CFLAGS=-DFIXEDPT_BITS=64" # Always use 64-bit
          ]
          ++ optionals cfg.debug [
            "DRIVER_CFLAGS+=-g -DDEBUG"
          ];

        preBuild = "cd driver";

        installPhase = ''
          mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/usb
          cp maccel.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/usb/
        '';

        meta = with lib; {
          description = "Mouse acceleration kernel module for Linux";
          homepage = "https://www.maccel.org/";
          license = licenses.gpl2Plus;
          platforms = platforms.linux;
          maintainers = with maintainers; []; # Add maintainer here
        };
      }
  ) {};

  # Optional: Build CLI tools (only if user wants them)
  maccel-tools = pkgs.rustPlatform.buildRustPackage rec {
    pname = "maccel-tools";
    version = "unstable";

    # Same source as kernel module - automatically stays in sync
    src = builtins.fetchGit {
      url = "https://github.com/Gnarus-G/maccel.git";
      ref = "main";
    };

    cargoHash = "sha256-yegNw5sl9mxreTlumxrG78osWZDQeqI6gMcDJe0A5hQ=";
    cargoBuildFlags = ["--bin" "maccel"];

    meta = with lib; {
      description = "CLI and TUI tools for configuring maccel mouse acceleration";
      homepage = "https://www.maccel.org/";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
      maintainers = with maintainers; []; # Add maintainer here
    };
  };

  # Generate kernel module parameters string for module loading
  kernelModuleParams = let
    params =
      []
      # Common parameters
      ++ optional (cfg.parameters.sensMultiplier != null) "SENS_MULT=${toFixedPoint cfg.parameters.sensMultiplier}"
      ++ optional (cfg.parameters.yxRatio != null) "YX_RATIO=${toFixedPoint cfg.parameters.yxRatio}"
      ++ optional (cfg.parameters.inputDpi != null) "INPUT_DPI=${toFixedPoint cfg.parameters.inputDpi}"
      ++ optional (cfg.parameters.angleRotation != null) "ANGLE_ROTATION=${toFixedPoint cfg.parameters.angleRotation}"
      ++ optional (cfg.parameters.mode != null) "MODE=${modeToInt cfg.parameters.mode}"
      # Linear mode parameters
      ++ optional (cfg.parameters.acceleration != null) "ACCEL=${toFixedPoint cfg.parameters.acceleration}"
      ++ optional (cfg.parameters.offset != null) "OFFSET=${toFixedPoint cfg.parameters.offset}"
      ++ optional (cfg.parameters.outputCap != null) "OUTPUT_CAP=${toFixedPoint cfg.parameters.outputCap}"
      # Natural mode parameters
      ++ optional (cfg.parameters.decayRate != null) "DECAY_RATE=${toFixedPoint cfg.parameters.decayRate}"
      ++ optional (cfg.parameters.limit != null) "LIMIT=${toFixedPoint cfg.parameters.limit}"
      # Synchronous mode parameters
      ++ optional (cfg.parameters.gamma != null) "GAMMA=${toFixedPoint cfg.parameters.gamma}"
      ++ optional (cfg.parameters.smooth != null) "SMOOTH=${toFixedPoint cfg.parameters.smooth}"
      ++ optional (cfg.parameters.motivity != null) "MOTIVITY=${toFixedPoint cfg.parameters.motivity}"
      ++ optional (cfg.parameters.syncSpeed != null) "SYNC_SPEED=${toFixedPoint cfg.parameters.syncSpeed}";
  in
    concatStringsSep " " params;
in {
  options.hardware.maccel = {
    enable = mkEnableOption "maccel mouse acceleration driver";

    debug = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Enable debug build of the kernel module";
    };

    autoload = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc "Automatically load the maccel kernel module at boot";
    };

    buildTools = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Build and install CLI/TUI tools (optional, not needed for basic functionality)";
    };

    parameters = {
      # Common parameters (all modes)
      sensMultiplier = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Sensitivity multiplier applied after acceleration calculation (default: 1.0)";
      };

      yxRatio = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Y/X ratio - factor by which Y-axis sensitivity is multiplied (default: 1.0)";
      };

      inputDpi = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "DPI of the mouse, used to normalize effective DPI to 1 in/sec (default: 1000.0)";
      };

      angleRotation = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Apply rotation in degrees to mouse movement input (default: 0.0)";
      };

      mode = mkOption {
        type = types.nullOr (types.enum ["linear" "natural" "synchronous" "no_accel"]);
        default = null;
        description = lib.mdDoc "Acceleration mode (default: linear)";
      };

      # Linear mode parameters
      acceleration = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Linear acceleration factor - controls sensitivity calculation (default: 0.0)";
      };

      offset = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Input speed past which to allow acceleration (default: 0.0)";
      };

      outputCap = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Maximum sensitivity multiplier cap (default: 0.0)";
      };

      # Natural mode parameters
      decayRate = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Decay rate of the Natural acceleration curve (default: 0.1)";
      };

      limit = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Limit of the Natural acceleration curve (default: 1.5)";
      };

      # Synchronous mode parameters
      gamma = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Controls how fast you get from low to fast around the midpoint (default: 1.0)";
      };

      smooth = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Controls the suddenness of the sensitivity increase (default: 0.5)";
      };

      motivity = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Sets max sensitivity while setting min to 1/MOTIVITY (default: 1.5)";
      };

      syncSpeed = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = lib.mdDoc "Sets the middle sensitivity between min and max sensitivity (default: 5.0)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Add the kernel module to available packages
    boot.extraModulePackages = [maccel-kernel-module];

    # Load module with parameters at boot (cleanest approach)
    boot.kernelModules = mkIf cfg.autoload ["maccel"];
    boot.extraModprobeConfig = mkIf (kernelModuleParams != "") ''
      options maccel ${kernelModuleParams}
    '';

    # Create the maccel group
    users.groups.maccel = {};

    # Create directories needed by CLI tools (when buildTools = true)
    systemd.tmpfiles.rules =
      [
        # Basic directories
        "d /var/lib/maccel 0755 root maccel"
        "d /var/lib/maccel/logs 0755 root maccel"
      ]
      ++ optionals cfg.buildTools [
        # CLI tools expect these directories for parameter persistence
        "d /var/opt/maccel 0775 root maccel"
        "d /var/opt/maccel/resets 0775 root maccel"
        "d /var/opt/maccel/logs 0775 root maccel"
      ];

    # Add udev rules for device permissions
    services.udev.extraRules = ''
      # Set permissions for the /dev/maccel character device
      KERNEL=="maccel", GROUP="maccel", MODE="0664"
      
      # Set permissions for module parameters
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", GROUP="maccel", MODE="0664"
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", RUN+="${pkgs.coreutils}/bin/chgrp -R maccel /sys/module/maccel/parameters"
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", RUN+="${pkgs.coreutils}/bin/chmod -R g+w /sys/module/maccel/parameters"
    '' + optionalString cfg.buildTools ''
      
      # Set permissions for CLI persistence directories (when buildTools = true)
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", RUN+="${pkgs.coreutils}/bin/chgrp -R maccel /var/opt/maccel"
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", RUN+="${pkgs.coreutils}/bin/chmod -R g+w /var/opt/maccel"
    '';

    # Optional: Install CLI tools if requested
    environment.systemPackages = mkIf cfg.buildTools [maccel-tools];

    # Optional: Security wrapper for CLI tools
    security.wrappers = mkIf cfg.buildTools {
      maccel = {
        owner = "root";
        group = "maccel";
        permissions = "u+rx,g+rx,o-rwx";
        source = "${maccel-tools}/bin/maccel";
      };
    };

    # Informational service showing applied parameters (debug mode)
    systemd.services.maccel-info = mkIf cfg.debug {
      description = "Show applied maccel parameters";
      after = ["systemd-modules-load.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeScript "maccel-info" ''
          #!${pkgs.bash}/bin/bash

          echo "=== maccel parameters ==="

          if [ -d /sys/module/maccel/parameters ]; then
            for param in /sys/module/maccel/parameters/*; do
              name=$(basename "$param")
              value=$(cat "$param" 2>/dev/null || echo "unreadable")
              echo "$name = $value"
            done
          else
            echo "maccel module not loaded"
          fi
        '';
      };
    };
  };
}
