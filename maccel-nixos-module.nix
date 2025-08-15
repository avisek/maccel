# NixOS Module for maccel - Mouse acceleration driver
# This module provides declarative configuration for the maccel kernel module and tools
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.maccel;
  
  # Build the maccel kernel module
  maccel-kernel-module = config.boot.kernelPackages.callPackage (
    { lib, stdenv, kernel, fetchFromGitHub }:
    
    stdenv.mkDerivation rec {
      pname = "maccel";
      version = "0.5.6";
      
      src = fetchFromGitHub {
        owner = "Gnarus-G";
        repo = "maccel";
        rev = "v${version}";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update with correct hash
      };
      
      nativeBuildInputs = kernel.moduleBuildDependencies;
      
      makeFlags = [
        "KVER=${kernel.modDirVersion}"
        "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        "DRIVER_CFLAGS=-DFIXEDPT_BITS=${toString stdenv.hostPlatform.parsed.cpu.bits}"
      ] ++ optionals cfg.debug [
        "DRIVER_CFLAGS+=-g -DDEBUG"
      ];
      
      preBuild = ''
        cd driver
      '';
      
      installPhase = ''
        mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/usb
        cp maccel.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/usb/
      '';
      
      meta = with lib; {
        description = "Mouse acceleration kernel module for Linux";
        homepage = "https://www.maccel.org/";
        license = licenses.gpl2Plus;
        platforms = platforms.linux;
        maintainers = with maintainers; [ ];
      };
    }
  ) {};
  
  # Build the maccel CLI and TUI tools
  maccel-tools = pkgs.rustPlatform.buildRustPackage rec {
    pname = "maccel-tools";
    version = "0.5.6";
    
    src = fetchFromGitHub {
      owner = "Gnarus-G";
      repo = "maccel";
      rev = "v${version}";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update with correct hash
    };
    
    cargoHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="; # Update with correct hash
    
    buildInputs = with pkgs; [
      # Add any system dependencies needed for the Rust build
    ];
    
    # Only build the CLI and TUI binaries
    cargoBuildFlags = [ "--bin" "maccel" ];
    
    meta = with lib; {
      description = "CLI and TUI tools for configuring maccel mouse acceleration";
      homepage = "https://www.maccel.org/";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
      maintainers = with maintainers; [ ];
    };
  };
  
  # Create parameter reset scripts directory
  paramResetScripts = pkgs.writeScriptBin "maccel-param-ownership-and-resets" ''
    #!${pkgs.bash}/bin/bash
    
    PATH='${lib.makeBinPath [ pkgs.coreutils pkgs.util-linux ]}'
    
    LOG_DIR=/var/lib/maccel/logs
    mkdir -p $LOG_DIR
    
    # Setting maccel group for some sysfs resources
    chown -v :maccel /sys/module/maccel/parameters/* &>$LOG_DIR/chown
    chown -v :maccel /dev/maccel &>$LOG_DIR/chown
    chmod g+r /dev/maccel &>$LOG_DIR/chmod
    
    # For persisting parameters values across reboots
    RESET_SCRIPTS_DIR=/var/lib/maccel/resets
    mkdir -p $RESET_SCRIPTS_DIR &>$LOG_DIR/reset-scripts
    chown -v :maccel $RESET_SCRIPTS_DIR &>$LOG_DIR/reset-scripts
    chmod -v g+w "$RESET_SCRIPTS_DIR" &>$LOG_DIR/reset-scripts
    
    for script in $(ls $RESET_SCRIPTS_DIR/set_last_*_value.sh 2>/dev/null || true); do
      if [ -f "$script" ]; then
        cat $script | bash &>$LOG_DIR/reset-scripts
        chown -v :maccel $script &>$LOG_DIR/reset-scripts
        chmod -v g+w $script &>$LOG_DIR/reset-scripts
      fi
    done
  '';

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
    
    parameters = {
      sensMultiplier = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Default sensitivity multiplier value";
      };
      
      acceleration = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Default acceleration value";
      };
      
      offset = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Default offset value";
      };
      
      outputCap = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Default output cap value";
      };
      
      mode = mkOption {
        type = types.nullOr (types.enum [ "linear" "natural" "synchronous" ]);
        default = null;
        description = "Default acceleration mode";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # Add the kernel module to available packages
    boot.extraModulePackages = [ maccel-kernel-module ];
    
    # Automatically load the module if requested
    boot.kernelModules = mkIf cfg.autoload [ "maccel" ];
    
    # Install the CLI and TUI tools
    environment.systemPackages = [ 
      maccel-tools 
      paramResetScripts
    ];
    
    # Create the maccel group
    users.groups.maccel = {};
    
    # Add udev rules for device permissions and parameter persistence
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/maccel", RUN+="${paramResetScripts}/bin/maccel-param-ownership-and-resets"
    '';
    
    # Create required directories and set permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/maccel 0755 root maccel"
      "d /var/lib/maccel/logs 0755 root maccel"
      "d /var/lib/maccel/resets 0775 root maccel"
    ];
    
    # Service to set default parameters if specified
    systemd.services.maccel-set-defaults = mkIf (
      cfg.parameters.sensMultiplier != null ||
      cfg.parameters.acceleration != null ||
      cfg.parameters.offset != null ||
      cfg.parameters.outputCap != null ||
      cfg.parameters.mode != null
    ) {
      description = "Set maccel default parameters";
      after = [ "systemd-modules-load.service" ];
      wants = [ "systemd-modules-load.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeScript "maccel-set-defaults" ''
          #!${pkgs.bash}/bin/bash
          
          # Wait for the module to be loaded and sysfs to be available
          for i in {1..30}; do
            if [ -d /sys/module/maccel/parameters ]; then
              break
            fi
            sleep 1
          done
          
          if [ ! -d /sys/module/maccel/parameters ]; then
            echo "maccel module not loaded after 30 seconds, giving up"
            exit 1
          fi
          
          ${optionalString (cfg.parameters.sensMultiplier != null) ''
            echo "Setting sensitivity multiplier to ${toString cfg.parameters.sensMultiplier}"
            ${maccel-tools}/bin/maccel set param sens-mult ${toString cfg.parameters.sensMultiplier}
          ''}
          
          ${optionalString (cfg.parameters.acceleration != null) ''
            echo "Setting acceleration to ${toString cfg.parameters.acceleration}"
            ${maccel-tools}/bin/maccel set param accel ${toString cfg.parameters.acceleration}
          ''}
          
          ${optionalString (cfg.parameters.offset != null) ''
            echo "Setting offset to ${toString cfg.parameters.offset}"
            ${maccel-tools}/bin/maccel set param offset ${toString cfg.parameters.offset}
          ''}
          
          ${optionalString (cfg.parameters.outputCap != null) ''
            echo "Setting output cap to ${toString cfg.parameters.outputCap}"
            ${maccel-tools}/bin/maccel set param output-cap ${toString cfg.parameters.outputCap}
          ''}
          
          ${optionalString (cfg.parameters.mode != null) ''
            echo "Setting mode to ${cfg.parameters.mode}"
            ${maccel-tools}/bin/maccel set mode ${cfg.parameters.mode}
          ''}
        '';
      };
    };
    
    # Security wrapper to allow maccel group members to access the CLI without sudo
    security.wrappers.maccel = {
      owner = "root";
      group = "maccel";
      permissions = "u+rx,g+rx,o-rwx";
      source = "${maccel-tools}/bin/maccel";
    };
    
    # Optional: Add users to maccel group automatically
    # This can be enabled by users in their own configurations
    # users.users.${config.users.defaultUser}.extraGroups = [ "maccel" ];
  };
}
