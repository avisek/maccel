# NixOS module for maccel mouse acceleration driver
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

  # Mode enum mapping (from driver/accel/mode.h)
  modeMap = {
    linear = "0";
    natural = "1";
    synchronous = "2";
    no_accel = "3";
  };

  # Parameter mapping (from driver/params.h)
  parameterMap = {
    # Common parameters
    SENS_MULT = cfg.parameters.sensMultiplier;
    YX_RATIO = cfg.parameters.yxRatio;
    INPUT_DPI = cfg.parameters.inputDpi;
    ANGLE_ROTATION = cfg.parameters.angleRotation;
    MODE =
      if cfg.parameters.mode != null
      then modeMap.${cfg.parameters.mode}
      else null;

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
  in
    concatStringsSep " " (mapAttrsToList formatParam validParams);

  # Build kernel module
  maccel-kernel-module = config.boot.kernelPackages.callPackage ({
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
          "DRIVER_CFLAGS=-DFIXEDPT_BITS=64"
        ]
        ++ optionals cfg.debug ["DRIVER_CFLAGS+=-g -DDEBUG"];

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
    enable = mkEnableOption "Enable maccel mouse acceleration driver (kernel module). Be sure to specify parameters.";

    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable debug build of the kernel module";
    };

    enableCli = mkOption {
      type = types.bool;
      default = false;
      description = "Enable CLI and TUI tools for temporary runtime configuration. Use this for finding the best parameters. Be sure to set the final parameters in the configuration.";
    };

    parameters = {
      # Common parameters
      sensMultiplier = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sensitivity multiplier applied after acceleration calculation";
      };

      yxRatio = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Y/X ratio - factor by which Y-axis sensitivity is multiplied";
      };

      inputDpi = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "DPI of the mouse, used to normalize effective DPI";
      };

      angleRotation = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Apply rotation in degrees to mouse movement input";
      };

      mode = mkOption {
        type = types.nullOr (types.enum ["linear" "natural" "synchronous" "no_accel"]);
        default = null;
        description = "Acceleration mode";
      };

      # Linear mode parameters
      acceleration = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Linear acceleration factor";
      };

      offset = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Input speed past which to allow acceleration";
      };

      outputCap = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Maximum sensitivity multiplier cap";
      };

      # Natural mode parameters
      decayRate = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Decay rate of the Natural acceleration curve";
      };

      limit = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Limit of the Natural acceleration curve";
      };

      # Synchronous mode parameters
      gamma = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Controls how fast you get from low to fast around the midpoint";
      };

      smooth = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Controls the suddenness of the sensitivity increase";
      };

      motivity = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sets max sensitivity while setting min to 1/MOTIVITY";
      };

      syncSpeed = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sets the middle sensitivity between min and max sensitivity";
      };
    };
  };

  config = mkIf cfg.enable {
    # Add kernel module
    boot.extraModulePackages = [maccel-kernel-module];

    # Load module with parameters
    boot.kernelModules = ["maccel"];
    boot.extraModprobeConfig = mkIf (kernelModuleParams != "") ''
      options maccel ${kernelModuleParams}
    '';

    # Create maccel group
    users.groups.maccel = {};

    # Create necessary directories
    systemd.tmpfiles.rules =
      [
        "d /var/lib/maccel 0755 root maccel"
      ]
      ++ optionals cfg.enableCli [
        "d /var/opt/maccel 0775 root maccel"
        "d /var/opt/maccel/resets 0775 root maccel"
      ];

    # Set device permissions
    services.udev.extraRules =
      ''
        # Device and parameter permissions
        KERNEL=="maccel", GROUP="maccel", MODE="0664"
        ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", \
          RUN+="${pkgs.coreutils}/bin/chgrp -R maccel /sys/module/maccel/parameters", \
          RUN+="${pkgs.coreutils}/bin/chmod -R g+w /sys/module/maccel/parameters"
      ''
      + optionalString cfg.enableCli ''
        ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", \
          RUN+="${pkgs.coreutils}/bin/chgrp -R maccel /var/opt/maccel"
      '';

    # Install CLI tools if requested
    environment.systemPackages = mkIf cfg.enableCli [maccel-tools];
  };
}
