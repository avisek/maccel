# NixOS Module for maccel - Direct parameter setting (NO CLI required!)
# This module bypasses the maccel CLI entirely and writes parameters directly
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
        };
      }
  ) {};

  # Optional: Build CLI tools (only if user wants them)
  maccel-tools = pkgs.rustPlatform.buildRustPackage rec {
    pname = "maccel-tools";
    version = "unstable";

    src = builtins.fetchGit {
      url = "https://github.com/Gnarus-G/maccel.git";
      ref = "main";
    };

    cargoLock = {
      lockFile = "${src}/Cargo.lock";
    };
    
    cargoBuildFlags = ["--bin" "maccel"];

    meta = with lib; {
      description = "CLI and TUI tools for configuring maccel mouse acceleration";
      homepage = "https://www.maccel.org/";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
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
      description = "Enable debug build of the kernel module";
    };

    autoload = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically load the maccel kernel module at boot";
    };

    buildTools = mkOption {
      type = types.bool;
      default = false;
      description = "Build and install CLI/TUI tools (optional, not needed for basic functionality)";
    };

    parameters = {
      # Common parameters (all modes)
      sensMultiplier = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sensitivity multiplier applied after acceleration calculation (default: 1.0)";
      };

      yxRatio = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Y/X ratio - factor by which Y-axis sensitivity is multiplied (default: 1.0)";
      };

      inputDpi = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "DPI of the mouse, used to normalize effective DPI to 1 in/sec (default: 1000.0)";
      };

      angleRotation = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Apply rotation in degrees to mouse movement input (default: 0.0)";
      };

      mode = mkOption {
        type = types.nullOr (types.enum ["linear" "natural" "synchronous" "no_accel"]);
        default = null;
        description = "Acceleration mode (default: linear)";
      };

      # Linear mode parameters
      acceleration = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Linear acceleration factor - controls sensitivity calculation (default: 0.0)";
      };

      offset = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Input speed past which to allow acceleration (default: 0.0)";
      };

      outputCap = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Maximum sensitivity multiplier cap (default: 0.0)";
      };

      # Natural mode parameters
      decayRate = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Decay rate of the Natural acceleration curve (default: 0.1)";
      };

      limit = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Limit of the Natural acceleration curve (default: 1.5)";
      };

      # Synchronous mode parameters
      gamma = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Controls how fast you get from low to fast around the midpoint (default: 1.0)";
      };

      smooth = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Controls the suddenness of the sensitivity increase (default: 0.5)";
      };

      motivity = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sets max sensitivity while setting min to 1/MOTIVITY (default: 1.5)";
      };

      syncSpeed = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sets the middle sensitivity between min and max sensitivity (default: 5.0)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Add the kernel module to available packages
    boot.extraModulePackages = [maccel-kernel-module];

    # Method 1: Load module with parameters at boot (cleanest approach)
    boot.kernelModules = mkIf cfg.autoload ["maccel"];
    boot.extraModprobeConfig = mkIf (kernelModuleParams != "") ''
      options maccel ${kernelModuleParams}
    '';

    # # Method 2: Alternative - set parameters via sysfs after module loads
    # # This creates files directly in sysfs without CLI
    # systemd.tmpfiles.rules = let
    #   paramRules =
    #     []
    #     # Common parameters
    #     ++ optional (cfg.parameters.sensMultiplier != null)
    #     "w /sys/module/maccel/parameters/SENS_MULT - - - - ${toFixedPoint cfg.parameters.sensMultiplier}"
    #     ++ optional (cfg.parameters.yxRatio != null)
    #     "w /sys/module/maccel/parameters/YX_RATIO - - - - ${toFixedPoint cfg.parameters.yxRatio}"
    #     ++ optional (cfg.parameters.inputDpi != null)
    #     "w /sys/module/maccel/parameters/INPUT_DPI - - - - ${toFixedPoint cfg.parameters.inputDpi}"
    #     ++ optional (cfg.parameters.angleRotation != null)
    #     "w /sys/module/maccel/parameters/ANGLE_ROTATION - - - - ${toFixedPoint cfg.parameters.angleRotation}"
    #     ++ optional (cfg.parameters.mode != null)
    #     "w /sys/module/maccel/parameters/MODE - - - - ${modeToInt cfg.parameters.mode}"
    #     # Linear mode parameters
    #     ++ optional (cfg.parameters.acceleration != null)
    #     "w /sys/module/maccel/parameters/ACCEL - - - - ${toFixedPoint cfg.parameters.acceleration}"
    #     ++ optional (cfg.parameters.offset != null)
    #     "w /sys/module/maccel/parameters/OFFSET - - - - ${toFixedPoint cfg.parameters.offset}"
    #     ++ optional (cfg.parameters.outputCap != null)
    #     "w /sys/module/maccel/parameters/OUTPUT_CAP - - - - ${toFixedPoint cfg.parameters.outputCap}"
    #     # Natural mode parameters
    #     ++ optional (cfg.parameters.decayRate != null)
    #     "w /sys/module/maccel/parameters/DECAY_RATE - - - - ${toFixedPoint cfg.parameters.decayRate}"
    #     ++ optional (cfg.parameters.limit != null)
    #     "w /sys/module/maccel/parameters/LIMIT - - - - ${toFixedPoint cfg.parameters.limit}"
    #     # Synchronous mode parameters
    #     ++ optional (cfg.parameters.gamma != null)
    #     "w /sys/module/maccel/parameters/GAMMA - - - - ${toFixedPoint cfg.parameters.gamma}"
    #     ++ optional (cfg.parameters.smooth != null)
    #     "w /sys/module/maccel/parameters/SMOOTH - - - - ${toFixedPoint cfg.parameters.smooth}"
    #     ++ optional (cfg.parameters.motivity != null)
    #     "w /sys/module/maccel/parameters/MOTIVITY - - - - ${toFixedPoint cfg.parameters.motivity}"
    #     ++ optional (cfg.parameters.syncSpeed != null)
    #     "w /sys/module/maccel/parameters/SYNC_SPEED - - - - ${toFixedPoint cfg.parameters.syncSpeed}";
    # in
    #   # Create basic directories
    #   [
    #     "d /var/lib/maccel 0755 root maccel"
    #     "d /var/lib/maccel/logs 0755 root maccel"
    #   ]
    #   ++ paramRules;

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

    # Informational service showing applied parameters
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
