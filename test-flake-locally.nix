# Test configuration for the maccel flake (before publishing)
# This allows you to test the flake locally during development

{
  description = "Local test of maccel NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Reference the local flake (current directory)
    maccel-nixos.url = "path:.";
  };

  outputs = { nixpkgs, maccel-nixos, ... }: {
    # Test configuration
    nixosConfigurations.test = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Import the local module
        maccel-nixos.nixosModules.default
        
        # Test configuration
        {
          # Basic test setup
          hardware.maccel = {
            enable = true;
            debug = true;  # Enable debug for testing
            buildTools = true;  # Test CLI tools build
            parameters = {
              sensMultiplier = 1.0;
              acceleration = 0.3;
              offset = 2.0;
              outputCap = 2.0;
              mode = "linear";
            };
          };
          
          # Test user setup
          users.users.testuser = {
            isNormalUser = true;
            extraGroups = [ "wheel" "maccel" ];
          };
          
          # Minimal system for testing
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          
          networking.hostName = "maccel-test";
          
          system.stateVersion = "23.11";
        }
      ];
    };
    
    # Quick check configuration (minimal)
    nixosConfigurations.check = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        maccel-nixos.nixosModules.default
        {
          hardware.maccel = {
            enable = true;
            buildTools = false;  # Test without CLI tools
            parameters = {
              sensMultiplier = 1.0;
              mode = "linear";
            };
          };
          
          # Absolute minimal config
          boot.loader.systemd-boot.enable = true;
          networking.hostName = "maccel-check";
          system.stateVersion = "23.11";
        }
      ];
    };
  };
}

# Usage:
# 1. Save this as test-flake.nix in the same directory as your maccel flake
# 2. Test build: nix build .#nixosConfigurations.test.config.system.build.toplevel
# 3. Quick check: nix build .#nixosConfigurations.check.config.system.build.toplevel
# 4. Evaluate options: nix eval .#nixosConfigurations.test.config.hardware.maccel
# 5. Check flake: nix flake check
