{
  description = "NixOS module for maccel mouse acceleration driver";

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
        packages = {
          # Provide the kernel module as a package
          maccel-kernel-module = pkgs.linuxKernel.packages.linux.callPackage (
            { lib, stdenv, kernel, fetchFromGitHub }:
            
            stdenv.mkDerivation rec {
              pname = "maccel";
              version = "0.5.6";
              
              src = fetchFromGitHub {
                owner = "Gnarus-G";
                repo = "maccel";
                rev = "v${version}";
                sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update this
              };
              
              nativeBuildInputs = kernel.moduleBuildDependencies;
              
              makeFlags = [
                "KVER=${kernel.modDirVersion}"
                "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
                "DRIVER_CFLAGS=-DFIXEDPT_BITS=${toString stdenv.hostPlatform.parsed.cpu.bits}"
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
          
          # Provide the CLI/TUI tools as a package
          maccel-tools = pkgs.rustPlatform.buildRustPackage rec {
            pname = "maccel-tools";
            version = "0.5.6";
            
            src = fetchFromGitHub {
              owner = "Gnarus-G";
              repo = "maccel";
              rev = "v${version}";
              sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update this
            };
            
            cargoHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="; # Update this
            
            cargoBuildFlags = [ "--bin" "maccel" ];
            
            meta = with lib; {
              description = "CLI and TUI tools for configuring maccel mouse acceleration";
              homepage = "https://www.maccel.org/";
              license = licenses.gpl2Plus;
              platforms = platforms.linux;
            };
          };
        };
        
        # Development shell for working on the module
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nix-prefetch-git
            nix-prefetch
            cargo
            rustc
            rust-analyzer
            git
          ];
          
          shellHook = ''
            echo "maccel NixOS module development environment"
            echo "Use 'nix-prefetch-url --unpack' to get source hashes"
            echo "Use 'nix-prefetch-git' to get git source hashes"
          '';
        };
      }
    ) // {
      # Provide the NixOS module
      nixosModules.maccel = import ./maccel-nixos-module.nix;
      nixosModules.default = self.nixosModules.maccel;
      
      # Overlay for adding packages to nixpkgs
      overlays.default = final: prev: {
        maccel-kernel-module = self.packages.${final.system}.maccel-kernel-module;
        maccel-tools = self.packages.${final.system}.maccel-tools;
      };
    };
}
