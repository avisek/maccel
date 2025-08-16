# NixOS Module for maccel - Direct parameter setting (NO CLI required!)
# This module bypasses the maccel CLI entirely and writes parameters directly
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.maccel;
  
  # Fixed-point conversion functions
  # maccel uses 64-bit fixed-point with 32 fractional bits (FIXEDPT_FBITS = 32)
  fixedPointScale = 4294967296; # 2^32 for 64-bit systems
  
  # Convert float to fixed-point integer (as string for sysfs)
  toFixedPoint = value: toString (lib.trivial.round (value * fixedPointScale));
  
  # Mode enum values (from driver/accel/mode.h)
  modeToInt = mode: {
    "linear" = "0";
    "natural" = "1"; 
    "synchronous" = "2";
    "no_accel" = "3";
  }.${mode};
  
  # Build the maccel kernel module
  maccel-kernel-module = config.boot.kernelPackages.callPackage (
    { lib, stdenv, kernel }:
    
    stdenv.mkDerivation rec {
      pname = "maccel";
      version = "0.5.6";
      
      src = builtins.fetchGit {
        url = "https://github.com/Gnarus-G/maccel.git";
        ref = "v${version}";
      };
      
      nativeBuildInputs = kernel.moduleBuildDependencies;
      
      makeFlags = [
        "KVER=${kernel.modDirVersion}"
        "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        "DRIVER_CFLAGS=-DFIXEDPT_BITS=64"  # Always use 64-bit
      ] ++ optionals cfg.debug [
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
  maccel-tools = mkIf cfg.buildTools (pkgs.rustPlatform.buildRustPackage rec {
    pname = "maccel-tools";
    version = "0.5.6";
    
    src = builtins.fetchGit {
      url = "https://github.com/Gnarus-G/maccel.git";
      ref = "v${version}";
    };
    
    cargoHash = lib.fakeHash;
    cargoBuildFlags = [ "--bin" "maccel" ];
    
    meta = with lib; {
      description = "CLI and TUI tools for configuring maccel mouse acceleration";
      homepage = "https://www.maccel.org/";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
    };
  });

  # Generate kernel module parameters string for module loading
  kernelModuleParams = 
    let
      params = []
        ++ optional (cfg.parameters.sensMultiplier != null) "SENS_MULT=${toFixedPoint cfg.parameters.sensMultiplier}"
        ++ optional (cfg.parameters.acceleration != null) "ACCEL=${toFixedPoint cfg.parameters.acceleration}"
        ++ optional (cfg.parameters.offset != null) "OFFSET=${toFixedPoint cfg.parameters.offset}"
        ++ optional (cfg.parameters.outputCap != null) "OUTPUT_CAP=${toFixedPoint cfg.parameters.outputCap}"
        ++ optional (cfg.parameters.mode != null) "MODE=${modeToInt cfg.parameters.mode}";
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
      sensMultiplier = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Sensitivity multiplier value (default: 1.0)";
      };
      
      acceleration = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Linear acceleration factor (default: 0.0)";
      };
      
      offset = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Input offset value (default: 0.0)";
      };
      
      outputCap = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Maximum output multiplier (default: 0.0)";
      };
      
      mode = mkOption {
        type = types.nullOr (types.enum [ "linear" "natural" "synchronous" "no_accel" ]);
        default = null;
        description = "Acceleration mode (default: linear)";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # Add the kernel module to available packages
    boot.extraModulePackages = [ maccel-kernel-module ];
    
    # Method 1: Load module with parameters at boot (cleanest approach)
    boot.kernelModules = mkIf cfg.autoload [ "maccel" ];
    boot.extraModprobeConfig = mkIf (kernelModuleParams != "") ''
      options maccel ${kernelModuleParams}
    '';
    
    # Method 2: Alternative - set parameters via sysfs after module loads
    # This creates files directly in sysfs without CLI
    systemd.tmpfiles.rules = 
      let
        paramRules = []
          ++ optional (cfg.parameters.sensMultiplier != null) 
             "w /sys/module/maccel/parameters/SENS_MULT - - - - ${toFixedPoint cfg.parameters.sensMultiplier}"
          ++ optional (cfg.parameters.acceleration != null)
             "w /sys/module/maccel/parameters/ACCEL - - - - ${toFixedPoint cfg.parameters.acceleration}"
          ++ optional (cfg.parameters.offset != null)
             "w /sys/module/maccel/parameters/OFFSET - - - - ${toFixedPoint cfg.parameters.offset}"
          ++ optional (cfg.parameters.outputCap != null)
             "w /sys/module/maccel/parameters/OUTPUT_CAP - - - - ${toFixedPoint cfg.parameters.outputCap}"
          ++ optional (cfg.parameters.mode != null)
             "w /sys/module/maccel/parameters/MODE - - - - ${modeToInt cfg.parameters.mode}";
      in
      # Create basic directories
      [
        "d /var/lib/maccel 0755 root maccel"
        "d /var/lib/maccel/logs 0755 root maccel"
      ] ++ paramRules;
    
    # Create the maccel group
    users.groups.maccel = {};
    
    # Add udev rules for device permissions (simplified, no parameter reset scripts needed)
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", GROUP="maccel", MODE="0664"
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", RUN+="${pkgs.coreutils}/bin/chgrp -R maccel /sys/module/maccel/parameters"
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", RUN+="${pkgs.coreutils}/bin/chmod -R g+w /sys/module/maccel/parameters"
    '';
    
    # Optional: Install CLI tools if requested
    environment.systemPackages = mkIf cfg.buildTools [ maccel-tools ];
    
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
      after = [ "systemd-modules-load.service" ];
      wantedBy = [ "multi-user.target" ];
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
