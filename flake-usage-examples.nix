# Examples of how users can consume the maccel NixOS module via flakes

# =============================================================================
# Example 1: Basic usage (recommended for most users)
# =============================================================================

{
  description = "My NixOS configuration with maccel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Add maccel module as input
    maccel-nixos.url = "github:yourusername/maccel-nixos";  # Replace with actual repo
    # Or use a specific commit/tag for stability:
    # maccel-nixos.url = "github:yourusername/maccel-nixos?ref=v1.0.0";
  };

  outputs = { nixpkgs, maccel-nixos, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Import the maccel module
        maccel-nixos.nixosModules.default
        
        # Your configuration
        {
          # Enable maccel with direct parameters
          hardware.maccel = {
            enable = true;
            parameters = {
              sensMultiplier = 1.0;
              acceleration = 0.3;
              mode = "linear";
            };
          };
          
          # Add your user to maccel group (optional, for CLI access)
          users.users.myuser.extraGroups = [ "maccel" ];
          
          # ... rest of your config
        }
      ];
    };
  };
}

# =============================================================================
# Example 2: Using with multiple hosts
# =============================================================================

{
  description = "Multi-host configuration with maccel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    maccel-nixos.url = "github:yourusername/maccel-nixos";
  };

  outputs = { nixpkgs, maccel-nixos, ... }: {
    nixosConfigurations = {
      # Gaming desktop with high acceleration
      gaming-pc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          maccel-nixos.nixosModules.default
          {
            hardware.maccel = {
              enable = true;
              buildTools = true;  # Include CLI for tweaking
              parameters = {
                sensMultiplier = 1.2;
                acceleration = 0.5;
                offset = 1.5;
                outputCap = 3.0;
                mode = "linear";
              };
            };
          }
        ];
      };
      
      # Laptop with gentle acceleration
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          maccel-nixos.nixosModules.default
          {
            hardware.maccel = {
              enable = true;
              buildTools = false;  # No CLI needed
              parameters = {
                sensMultiplier = 1.0;
                acceleration = 0.2;
                offset = 2.0;
                mode = "natural";
                decayRate = 0.15;
                limit = 1.3;
              };
            };
          }
        ];
      };
    };
  };
}

# =============================================================================
# Example 3: Using with home-manager
# =============================================================================

{
  description = "NixOS + Home Manager with maccel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    maccel-nixos.url = "github:yourusername/maccel-nixos";
  };

  outputs = { nixpkgs, home-manager, maccel-nixos, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # System-level maccel configuration
        maccel-nixos.nixosModules.default
        {
          hardware.maccel = {
            enable = true;
            buildTools = true;
          };
        }
        
        # Home manager configuration
        home-manager.nixosModules.home-manager
        {
          home-manager.users.myuser = {
            # User-specific maccel settings via CLI
            home.file.".maccel-profile-gaming".text = ''
              #!/bin/bash
              maccel set param sens-mult 1.5
              maccel set param accel 0.7
              maccel set mode linear
            '';
            
            home.file.".maccel-profile-work".text = ''
              #!/bin/bash
              maccel set param sens-mult 1.0
              maccel set param accel 0.2
              maccel set mode natural
            '';
          };
        }
      ];
    };
  };
}

# =============================================================================
# Example 4: Pinning to specific version for stability
# =============================================================================

{
  description = "Stable maccel configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";  # Stable release
    
    # Pin maccel to specific commit for reproducibility
    maccel-nixos = {
      url = "github:yourusername/maccel-nixos?ref=abc123def456";  # Specific commit
      inputs.nixpkgs.follows = "nixpkgs";  # Use same nixpkgs
    };
  };

  outputs = { nixpkgs, maccel-nixos, ... }: {
    nixosConfigurations.production-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        maccel-nixos.nixosModules.default
        {
          hardware.maccel = {
            enable = true;
            buildTools = false;  # Production: no CLI tools
            parameters = {
              sensMultiplier = 1.0;
              acceleration = 0.1;  # Very gentle for server work
              mode = "linear";
            };
          };
        }
      ];
    };
  };
}

# =============================================================================
# Example 5: Development setup with local override
# =============================================================================

{
  description = "Development setup with local maccel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    maccel-nixos.url = "github:yourusername/maccel-nixos";
  };

  outputs = { nixpkgs, maccel-nixos, ... }: {
    nixosConfigurations.dev-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        maccel-nixos.nixosModules.default
        {
          hardware.maccel = {
            enable = true;
            buildTools = true;
            debug = true;  # Enable debug output
            parameters = {
              sensMultiplier = 1.0;
              acceleration = 0.3;
              mode = "linear";
            };
          };
          
          # Development tools
          environment.systemPackages = with pkgs; [
            # Add packages for development
          ];
        }
      ];
    };
  };
}
