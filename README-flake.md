# maccel NixOS Flake

If you're on NixOS, maccel provides a declarative flake module to seamlessly integrate and configure the mouse acceleration driver through your system configuration.

## Quick Start

Add to your `flake.nix` inputs:

```nix
maccel.url = "github:Gnarus-G/maccel";
```

Create your `maccel.nix` module:

```nix
{inputs, ...}: {
  imports = [
    inputs.maccel.nixosModules.default
  ];

  hardware.maccel = {
    enable = true;
    enableCli = true; # Optional

    parameters = {
      # Common
      sensMultiplier = 1.0;
      yxRatio = 1.0;
      inputDpi = 1000.0;
      angleRotation = 0.0;
      mode = "linear";

      # Linear mode
      acceleration = 0.3;
      offset = 2.0;
      outputCap = 2.0;

      # Natural mode
      decayRate = 0.1;
      limit = 1.5;

      # Synchronous mode
      gamma = 1.0;
      smooth = 0.5;
      motivity = 1.5;
      syncSpeed = 5.0;
    };
  };

  # Only needed if enableCli is true
  users.groups.maccel.members = ["your_username"];
}
```
