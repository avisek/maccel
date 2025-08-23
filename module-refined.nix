# maccel NixOS module
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.hardware.maccel;

  # Fixed-point conversion (64-bit, 32 fractional bits)
  fixedPointScale = 4294967296; # 2^32
  toFixedPoint = value: toString (builtins.floor (value * fixedPointScale + 0.5));

  # Mode mapping
  modeMap = {
    linear = "0";
    natural = "1"; 
    synchronous = "2";
    no_accel = "3";
  };

  # Parameter mapping
  parameterMap = {
    SENS_MULT = cfg.parameters.sensMultiplier;
    YX_RATIO = cfg.parameters.yxRatio;
    INPUT_DPI = cfg.parameters.inputDpi;
    ANGLE_ROTATION = cfg.parameters.angleRotation;
    MODE = if cfg.parameters.mode != null then modeMap.${cfg.parameters.mode} else null;
    
    ACCEL = cfg.parameters.acceleration;
    OFFSET = cfg.parameters.offset;
    OUTPUT_CAP = cfg.parameters.outputCap;
    
    DECAY_RATE = cfg.parameters.decayRate;
    LIMIT = cfg.parameters.limit;
    
    GAMMA = cfg.parameters.gamma;
    SMOOTH = cfg.parameters.smooth;
    MOTIVITY = cfg.parameters.motivity;
    SYNC_SPEED = cfg.parameters.syncSpeed;
  };

  # Generate kernel module parameters
  kernelModuleParams = let
    validParams = filterAttrs (_: v: v != null) parameterMap;
    formatParam = name: value: 
      if name == "MODE" 
      then "${name}=${value}"
      else "${name}=${toFixedPoint value}";
  in concatStringsSep " " (mapAttrsToList formatParam validParams);

  # Kernel module
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
      description = "Mouse acceleration kernel module";
      homepage = "https://www.maccel.org/";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
    };
  }) {};

  # CLI tools
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
      description = "maccel CLI and TUI tools";
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
      description = "Enable debug build";
    };

    enableCli = mkOption {
      type = types.bool;
      default = false;
      description = "Enable CLI tools for runtime configuration";
    };

    parameters = {
      sensMultiplier = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Base sensitivity multiplier";
      };

      yxRatio = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Y/X axis sensitivity ratio";
      };

      inputDpi = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Mouse DPI for normalization";
      };

      angleRotation = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Input rotation in degrees";
      };

      mode = mkOption {
        type = types.nullOr (types.enum ["linear" "natural" "synchronous" "no_accel"]);
        default = null;
        description = "Acceleration mode";
      };

      # Linear mode
      acceleration = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Linear acceleration factor";
      };

      offset = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Acceleration threshold";
      };

      outputCap = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Maximum sensitivity cap";
      };

      # Natural mode
      decayRate = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Natural curve decay rate";
      };

      limit = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Natural curve limit";
      };

      # Synchronous mode
      gamma = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Midpoint transition speed";
      };

      smooth = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sensitivity increase suddenness";
      };

      motivity = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Max sensitivity (min = 1/motivity)";
      };

      syncSpeed = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Middle sensitivity value";
      };
    };
  };

  config = mkIf cfg.enable {
    boot.extraModulePackages = [maccel-kernel-module];
    boot.kernelModules = ["maccel"];
    boot.extraModprobeConfig = mkIf (kernelModuleParams != "") ''
      options maccel ${kernelModuleParams}
    '';

    users.groups.maccel = {};

    systemd.tmpfiles.rules = [
      "d /var/lib/maccel 0755 root maccel"
    ] ++ optionals cfg.enableCli [
      "d /var/opt/maccel 0775 root maccel"
      "d /var/opt/maccel/resets 0775 root maccel"
    ];

    services.udev.extraRules = ''
      KERNEL=="maccel", GROUP="maccel", MODE="0664"
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", \
        RUN+="${pkgs.coreutils}/bin/chgrp -R maccel /sys/module/maccel/parameters", \
        RUN+="${pkgs.coreutils}/bin/chmod -R g+w /sys/module/maccel/parameters"
    '' + optionalString cfg.enableCli ''
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", \
        RUN+="${pkgs.coreutils}/bin/chgrp -R maccel /var/opt/maccel"
    '';

    environment.systemPackages = mkIf cfg.enableCli [maccel-tools];
  };
}
