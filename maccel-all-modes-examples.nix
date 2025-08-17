# Complete examples for all maccel acceleration modes
# These examples show how to configure each acceleration mode with the direct approach

{ config, pkgs, lib, ... }:

{
  imports = [ ./maccel-nixos-direct.nix ];

  # Choose ONE of the configurations below by uncommenting it

  # =============================================================================
  # LINEAR MODE - Simple acceleration that increases linearly with input speed
  # =============================================================================
  
  hardware.maccel = {
    enable = true;
    parameters = {
      # Common parameters
      sensMultiplier = 1.0;     # Base sensitivity multiplier
      yxRatio = 1.0;           # Equal X/Y sensitivity
      inputDpi = 1000.0;       # Mouse DPI
      mode = "linear";
      
      # Linear-specific parameters
      acceleration = 0.3;      # How much acceleration to apply (0.0 = none, higher = more)
      offset = 2.0;           # Speed threshold to start acceleration (lower = starts sooner)
      outputCap = 2.0;        # Maximum sensitivity multiplier (caps the acceleration)
    };
  };

  # =============================================================================
  # NATURAL MODE - Smooth, natural-feeling acceleration curve
  # =============================================================================
  
  # hardware.maccel = {
  #   enable = true;
  #   parameters = {
  #     # Common parameters  
  #     sensMultiplier = 1.0;
  #     yxRatio = 1.0;
  #     inputDpi = 1000.0;
  #     mode = "natural";
  #     
  #     # Natural-specific parameters
  #     decayRate = 0.1;        # How quickly acceleration decays (0.1 = default, lower = slower decay)
  #     offset = 2.0;          # Speed threshold (shared with linear mode parameter name)
  #     limit = 1.5;           # Maximum acceleration limit (1.5 = 50% increase max)
  #   };
  # };

  # =============================================================================
  # SYNCHRONOUS MODE - Advanced mode with precise control over acceleration curve
  # =============================================================================
  
  # hardware.maccel = {
  #   enable = true;
  #   parameters = {
  #     # Common parameters
  #     sensMultiplier = 1.0;
  #     yxRatio = 1.0;
  #     inputDpi = 1000.0;
  #     mode = "synchronous";
  #     
  #     # Synchronous-specific parameters
  #     gamma = 1.0;           # Controls transition speed around midpoint (higher = faster transition)
  #     smooth = 0.5;          # Controls suddenness (0.5 = default, lower = more sudden)
  #     motivity = 1.5;        # Max sensitivity, min = 1/motivity (1.5 = 50% increase, 67% decrease)
  #     syncSpeed = 5.0;       # The "middle" input speed between min and max sensitivity
  #   };
  # };

  # =============================================================================
  # NO ACCELERATION MODE - Just sensitivity adjustment, no acceleration
  # =============================================================================
  
  # hardware.maccel = {
  #   enable = true;
  #   parameters = {
  #     # Only common parameters apply
  #     sensMultiplier = 0.8;   # Reduce sensitivity to 80%
  #     yxRatio = 1.2;         # Make Y-axis 20% more sensitive than X-axis
  #     inputDpi = 1600.0;     # High-DPI mouse
  #     angleRotation = 15.0;  # Rotate input by 15 degrees
  #     mode = "no_accel";
  #   };
  # };

  # =============================================================================
  # ADVANCED CONFIGURATION - Using additional features
  # =============================================================================
  
  # hardware.maccel = {
  #   enable = true;
  #   debug = true;             # Enable debug info service
  #   buildTools = true;        # Include CLI tools for runtime adjustment
  #   
  #   parameters = {
  #     # Common parameters with advanced settings
  #     sensMultiplier = 1.2;
  #     yxRatio = 0.9;          # Slightly reduce Y sensitivity
  #     inputDpi = 1600.0;      # Gaming mouse DPI
  #     angleRotation = -5.0;   # Slight counter-clockwise rotation
  #     mode = "linear";
  #     
  #     # Linear parameters optimized for gaming
  #     acceleration = 0.25;
  #     offset = 1.5;
  #     outputCap = 1.8;
  #   };
  # };

  # Add your user to maccel group (optional, only needed if buildTools = true)
  users.users.yourusername.extraGroups = [ "maccel" ];
}

# =============================================================================
# PARAMETER EXPLANATIONS
# =============================================================================

# Common Parameters (all modes):
# - sensMultiplier: Base sensitivity multiplier applied after acceleration
#   * 1.0 = no change, <1.0 = lower sensitivity, >1.0 = higher sensitivity
#
# - yxRatio: Ratio of Y-axis to X-axis sensitivity
#   * 1.0 = equal sensitivity, >1.0 = Y more sensitive, <1.0 = X more sensitive
#
# - inputDpi: Mouse DPI for normalization (helps with different mouse types)
#   * Usually your mouse's actual DPI setting (800, 1000, 1600, etc.)
#
# - angleRotation: Rotate all mouse input by this many degrees
#   * 0.0 = no rotation, positive = clockwise, negative = counter-clockwise
#
# - mode: Acceleration curve type
#   * "linear" = simple linear acceleration
#   * "natural" = smooth, natural feeling curve
#   * "synchronous" = advanced curve with precise control
#   * "no_accel" = no acceleration, just sensitivity adjustment

# Linear Mode Parameters:
# - acceleration: How much acceleration to apply
#   * 0.0 = no acceleration, higher values = more acceleration
#
# - offset: Input speed threshold to start acceleration
#   * Lower values = acceleration starts at slower movements
#   * Higher values = acceleration only at faster movements
#
# - outputCap: Maximum sensitivity multiplier
#   * Caps how high the sensitivity can go (prevents excessive acceleration)

# Natural Mode Parameters:
# - decayRate: How quickly acceleration effect decays
#   * Lower values = smoother, more gradual transitions
#
# - limit: Maximum acceleration multiplier
#   * Similar to outputCap but for natural curve
#
# - offset: Speed threshold (same parameter name as linear mode)

# Synchronous Mode Parameters:
# - gamma: Controls how quickly you transition around the midpoint
#   * Higher values = faster transition from low to high sensitivity
#
# - smooth: Controls suddenness of sensitivity changes
#   * Lower values = more sudden changes, higher = smoother
#
# - motivity: Defines the sensitivity range
#   * Max sensitivity = motivity, Min sensitivity = 1/motivity
#   * 1.5 means max 1.5x sensitivity and min 0.67x sensitivity
#
# - syncSpeed: The input speed that maps to 1.0x sensitivity
#   * The "neutral" point between min and max sensitivity

# =============================================================================
# TYPICAL USE CASES
# =============================================================================

# Gaming (FPS): Linear mode with moderate acceleration
# - acceleration = 0.2-0.4, offset = 1.0-2.0, outputCap = 1.5-2.0

# Productivity: Natural mode for smooth cursor movement  
# - decayRate = 0.05-0.15, limit = 1.3-1.7

# Precision work: No acceleration mode with fine sensitivity control
# - sensMultiplier = 0.6-0.9, mode = "no_accel"

# Gaming (RTS/Strategy): Synchronous mode for precise control
# - gamma = 0.8-1.2, smooth = 0.3-0.7, motivity = 1.2-1.8
