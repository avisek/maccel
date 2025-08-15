# Example NixOS configuration for local development (no hashes needed)
# This approach uses local paths instead of fetching from GitHub

{ config, pkgs, lib, ... }:

let
  # Option 1: Use local checkout (clone maccel repo locally)
  maccel-local-src = /path/to/local/maccel/checkout;  # Update this path
  
  # Option 2: Use current directory if you're developing in the maccel repo
  # maccel-local-src = ./.;
  
in {
  # Import the no-hashes version of the module
  imports = [
    ./maccel-nixos-module-no-hashes.nix
    # ... your other imports
  ];

  # Override the maccel packages to use local source
  nixpkgs.overlays = [
    (final: prev: {
      # Override kernel module to use local source
      maccel-kernel-local = final.linuxKernel.packages.linux.callPackage (
        { lib, stdenv, kernel }:
        
        stdenv.mkDerivation rec {
          pname = "maccel-local";
          version = "dev";
          
          # Use local source - no fetching, no hashes!
          src = maccel-local-src;
          
          nativeBuildInputs = kernel.moduleBuildDependencies;
          
          makeFlags = [
            "KVER=${kernel.modDirVersion}"
            "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
            "DRIVER_CFLAGS=-DFIXEDPT_BITS=${toString stdenv.hostPlatform.parsed.cpu.bits} -g -DDEBUG"
          ];
          
          preBuild = "cd driver";
          
          installPhase = ''
            mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/usb
            cp maccel.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/usb/
          '';
        }
      ) {};
      
      # Override CLI tools to use local source
      maccel-tools-local = final.rustPlatform.buildRustPackage rec {
        pname = "maccel-tools-local";
        version = "dev";
        
        # Use local source - no fetching, no hashes!
        src = maccel-local-src;
        
        # For local development, you can use this to avoid cargo hash issues
        cargoLock = {
          lockFile = "${maccel-local-src}/Cargo.lock";
        };
        
        cargoBuildFlags = [ "--bin" "maccel" ];
      };
    })
  ];

  # Enable maccel with local packages
  hardware.maccel = {
    enable = true;
    debug = true;  # Enable debug for development
    
    parameters = {
      sensMultiplier = 1.0;
      acceleration = 0.3;
      mode = "linear";
    };
  };
  
  # Add your user to the maccel group
  users.users.yourusername.extraGroups = [ "maccel" ];
  
  # Optional: Use the local packages instead of the fetched ones
  # You can modify the module to accept custom packages
}
