# NixOS Module for maccel - Direct parameter setting approach
# This module bypasses the CLI and sets kernel module parameters directly via modprobe
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.hardware.maccel;

  # Fixed-point arithmetic constants
  # maccel uses 64-bit fixed-point with 32 fractional bits (scale = 2^32)
  fixedPointScale = 4294967296;
  toFixedPoint = value: toString (builtins.floor (value * fixedPointScale + 0.5));

  # Mode enum mapping (from driver/accel/mode.h)
  modeMap = {
    linear = "0";
    natural = "1"; 
    synchronous = "2";
    no_accel = "3";
  };

  # Parameter mapping for cleaner code generation
  parameterMap = {
    # Common parameters
    SENS_MULT = cfg.parameters.sensMultiplier;
    YX_RATIO = cfg.parameters.yxRatio;
    INPUT_DPI = cfg.parameters.inputDpi;
    ANGLE_ROTATION = cfg.parameters.angleRotation;
    MODE = if cfg.parameters.mode != null then modeMap.${cfg.parameters.mode} else null;
    
    # Linear mode parameters
    ACCEL = cfg.parameters.acceleration;
    OFFSET = cfg.parameters.offset;
    OUTPUT_CAP = cfg.parameters.outputCap;
    
    # Natural mode parameters
    DECAY_RATE = cfg.parameters.decayRate;
    LIMIT = cfg.parameters.limit;
    
    # Synchronous mode parameters
    GAMMA = cfg.parameters.gamma;
    SMOOTH = cfg.parameters.smooth;
    MOTIVITY = cfg.parameters.motivity;
    SYNC_SPEED = cfg.parameters.syncSpeed;
  };

  # Generate modprobe parameter string
  kernelModuleParams = let
    validParams = filterAttrs (_: v: v != null) parameterMap;
    formatParam = name: value: 
      if name == "MODE" 
      then "${name}=${value}"
      else "${name}=${toFixedPoint value}";
  in concatStringsSep " " (mapAttrsToList formatParam validParams);

  # Build kernel module
  maccel-kernel-module = config.boot.kernelPackages.callPackage ({
    lib,
    stdenv, 
    kernel,
  }: stdenv.mkDerivation rec {
    pname = "maccel";
    version = "unstable";

    src = builtins.fetchGit {
      url = "https://github.com/Gnarus-G/maccel.git";
      ref = "main";
    };

    nativeBuildInputs = kernel.moduleBuildDependencies;

    makeFlags = [
      "KVER=${kernel.modDirVersion}"
      "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      "DRIVER_CFLAGS=-DFIXEDPT_BITS=64"
    ] ++ optionals cfg.debug ["DRIVER_CFLAGS+=-g -DDEBUG"];

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
  }) {};

  # Optional CLI tools
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
      description = "CLI and TUI tools for configuring maccel";
      homepage = "https://www.maccel.org/";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
    };
  };
in {
  options.hardware.maccel = {
    enable = mkEnableOption "maccel mouse acceleration driver";

    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable debug build and parameter info service";
    };

    autoload = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically load the kernel module at boot";
    };

    buildTools = mkOption {
      type = types.bool;
      default = false;
      description = "Build and install CLI/TUI tools (optional)";
    };

    parameters = {
      # Common parameters
      sensMultiplier = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sensitivity multiplier (default: 1.0)";
      };

      yxRatio = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Y/X sensitivity ratio (default: 1.0)";
      };

      inputDpi = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Mouse DPI for normalization (default: 1000.0)";
      };

      angleRotation = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Rotation angle in degrees (default: 0.0)";
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
        description = "Linear acceleration factor (default: 0.0)";
      };

      offset = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Speed threshold for acceleration (default: 0.0)";
      };

      outputCap = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Maximum sensitivity multiplier (default: 0.0)";
      };

      # Natural mode parameters
      decayRate = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Natural curve decay rate (default: 0.1)";
      };

      limit = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Natural curve limit (default: 1.5)";
      };

      # Synchronous mode parameters  
      gamma = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Transition speed around midpoint (default: 1.0)";
      };

      smooth = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sensitivity increase suddenness (default: 0.5)";
      };

      motivity = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Max/min sensitivity ratio (default: 1.5)";
      };

      syncSpeed = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Middle sensitivity point (default: 5.0)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install kernel module
    boot.extraModulePackages = [maccel-kernel-module];

    # Load module with parameters
    boot.kernelModules = mkIf cfg.autoload ["maccel"];
    boot.extraModprobeConfig = mkIf (kernelModuleParams != "") ''
      options maccel ${kernelModuleParams}
    '';

    # Create maccel group
    users.groups.maccel = {};

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d /var/lib/maccel 0755 root maccel"
      "d /var/lib/maccel/logs 0755 root maccel"
    ] ++ optionals cfg.buildTools [
      "d /var/opt/maccel 0775 root maccel"
      "d /var/opt/maccel/resets 0775 root maccel"
    ];

    # Device permissions via udev
    services.udev.extraRules = ''
      # Device and parameter permissions
      KERNEL=="maccel", GROUP="maccel", MODE="0664"
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", \
        RUN+="${pkgs.coreutils}/bin/chgrp -R maccel /sys/module/maccel/parameters", \
        RUN+="${pkgs.coreutils}/bin/chmod -R g+w /sys/module/maccel/parameters"
    '' + optionalString cfg.buildTools ''
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", \
        RUN+="${pkgs.coreutils}/bin/chgrp -R maccel /var/opt/maccel"
    '';

    # Install CLI tools if requested
    environment.systemPackages = mkIf cfg.buildTools [maccel-tools];

    # Debug service to show parameters
    systemd.services.maccel-info = mkIf cfg.debug {
      description = "Show maccel parameters";
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
              echo "$(basename "$param") = $(cat "$param" 2>/dev/null || echo "unreadable")"
            done
          else
            echo "maccel module not loaded"
          fi
        '';
      };
    };
  };
}