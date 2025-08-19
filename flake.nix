{
  description = "maccel NixOS Module - Direct parameter approach with zero maintenance";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Export individual packages for advanced users
        packages = {
          # Kernel module package
          kernel-module = pkgs.linuxKernel.packages.linux.callPackage (
            { lib, stdenv, kernel }:
            
            stdenv.mkDerivation rec {
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
          
          # CLI/TUI tools package
          cli-tools = pkgs.rustPlatform.buildRustPackage rec {
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
        };
        
        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            nix-prefetch-git
          ];
          
          shellHook = ''
            echo "🐭 maccel NixOS Module Development Environment"
            echo "Use this environment to test and develop the module"
          '';
        };
      }
    ) // {
      # Export the NixOS module - this is what users will import
      nixosModules = {
        # Main module export
        maccel = import ./maccel-nixos-direct.nix;
        
        # Default export (same as maccel)
        default = self.nixosModules.maccel;
      };
      
      # For backwards compatibility and alternative access
      nixosModule = self.nixosModules.default;
      
      # Overlay for adding packages to nixpkgs
      overlays.default = final: prev: {
        maccel-kernel-module = self.packages.${final.system}.kernel-module;
        maccel-cli-tools = self.packages.${final.system}.cli-tools;
      };
    };
}