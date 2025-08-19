# Example NixOS configuration for maccel mouse acceleration
# Copy this to your NixOS configuration or use as reference

{ config, pkgs, lib, ... }:

{
  # Import the maccel module
  imports = [
    # Method 1: If using this repo directly
    ./nixos/module.nix
    
    # Method 2: If downloaded the module file
    # ./path/to/downloaded/module.nix
    
    # Your other imports...
  ];

  # == Basic maccel configuration ==
  hardware.maccel = {
    enable = true;
    
    # Optional: Enable debug info (shows applied parameters)
    debug = false;
    
    # Optional: Build CLI tools (enables `maccel` command and TUI)
    buildTools = false;  # Set to true if you want CLI for runtime adjustments
    
    # Set your mouse acceleration parameters
    parameters = {
      # Common parameters (work with all acceleration modes)
      sensMultiplier = 1.0;     # Base sensitivity multiplier
      yxRatio = 1.0;           # Y/X axis ratio (1.0 = equal)
      inputDpi = 1000.0;       # Your mouse DPI for normalization
      angleRotation = 0.0;     # Input rotation in degrees
      mode = "linear";         # Acceleration curve type
      
      # Linear mode parameters (when mode = "linear")
      acceleration = 0.3;      # Acceleration strength
      offset = 2.0;           # Speed threshold before acceleration kicks in
      outputCap = 2.0;        # Maximum sensitivity cap
      
      # Uncomment for Natural mode (when mode = "natural")
      # decayRate = 0.1;      # Decay rate of natural curve
      # limit = 1.5;          # Maximum acceleration limit
      
      # Uncomment for Synchronous mode (when mode = "synchronous")  
      # gamma = 1.0;          # Transition speed around midpoint
      # smooth = 0.5;         # Suddenness of sensitivity increase
      # motivity = 1.5;       # Max sensitivity (min = 1/motivity)
      # syncSpeed = 5.0;      # Middle sensitivity between min/max
    };
  };
  
  # Add your user to the maccel group (needed for CLI tools)
  # Replace 'yourusername' with your actual username
  users.users.yourusername.extraGroups = [ "maccel" ];
  
  # Alternative: Add all wheel users to maccel group
  # users.users = lib.mapAttrs (name: user: 
  #   if lib.elem "wheel" user.extraGroups 
  #   then user // { extraGroups = user.extraGroups ++ [ "maccel" ]; }
  #   else user
  # ) config.users.users;

  # == Example configurations for different use cases ==
  
  # Gaming setup (high acceleration for quick movements)
  # hardware.maccel.parameters = {
  #   sensMultiplier = 1.2;
  #   acceleration = 0.8;
  #   offset = 1.0;
  #   outputCap = 4.0;
  #   mode = "linear";
  # };
  
  # Productivity setup (gentle acceleration for precision)
  # hardware.maccel.parameters = {
  #   sensMultiplier = 1.0;
  #   acceleration = 0.2;
  #   offset = 3.0;
  #   outputCap = 1.8;
  #   mode = "natural";
  #   decayRate = 0.05;
  #   limit = 1.3;
  # };
  
  # No acceleration (just sensitivity adjustment)
  # hardware.maccel.parameters = {
  #   sensMultiplier = 1.5;
  #   mode = "no_accel";
  # };

  # == After applying this configuration ==
  #
  # 1. Rebuild your system:
  #    sudo nixos-rebuild switch
  #
  # 2. Verify maccel is working:
  #    lsmod | grep maccel
  #    cat /sys/module/maccel/parameters/SENS_MULT
  #
  # 3. If you enabled buildTools = true, you can use:
  #    maccel tui          # Interactive terminal UI
  #    maccel get param sens-mult    # Check current values
  #    maccel set param accel 0.5    # Temporary runtime changes
  #
  # 4. To change parameters permanently:
  #    Edit this configuration file and rebuild with:
  #    sudo nixos-rebuild switch
  #
  # The configuration is automatically applied at boot and persists
  # across reboots. No manual module loading or parameter setting required!
}
