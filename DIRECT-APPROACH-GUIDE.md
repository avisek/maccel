# 🎯 Direct Parameter Approach: No CLI Required!

This approach completely eliminates the need for the maccel CLI for parameter setting, making the NixOS integration cleaner, faster, and more reliable.

## 🔍 **Problem with CLI-Based Approach**

The original approach was unnecessarily complex:

```
NixOS Config (1.0) → systemd service → maccel CLI → convert to fixed-point (4294967296) → write to sysfs
```

**Issues:**

- ❌ Requires CLI tools to be built and working
- ❌ Depends on systemd services running at boot
- ❌ Creates temporary script files for persistence
- ❌ Slower boot due to service dependencies
- ❌ More failure points (CLI, service, scripts)

## ✅ **Direct Parameter Solution**

The new approach cuts out the middleman:

```
NixOS Config (1.0) → convert to fixed-point at build time (4294967296) → kernel module parameters
```

**Benefits:**

- ✅ **No CLI dependency** - works even if CLI build fails
- ✅ **Faster boot** - no systemd services to wait for
- ✅ **More reliable** - fewer moving parts
- ✅ **Cleaner** - no temporary files or scripts
- ✅ **Atomic** - parameters set during module load
- ✅ **Traditional Linux** - uses standard kernel module parameters

## 📊 **Technical Details**

### How Parameter Conversion Works

The maccel kernel module uses 64-bit fixed-point arithmetic:

```
Fixed-point value = float_value * (2^32)
Fixed-point value = float_value * 4294967296
```

**Examples:**

- `1.0` → `4294967296` (sensitivity multiplier)
- `0.3` → `1288490189` (acceleration)
- `2.0` → `8589934592` (output cap)

### Parameter Setting Methods

**Method 1: Kernel Module Parameters (Recommended)**

```nix
# Parameters set at module load time
boot.extraModprobeConfig = ''
  options maccel SENS_MULT=4294967296 ACCEL=1288490189
'';
```

**Method 2: sysfs tmpfiles (Alternative)**

```nix
# Parameters set via systemd-tmpfiles after module loads
systemd.tmpfiles.rules = [
  "w /sys/module/maccel/parameters/SENS_MULT - - - - 4294967296"
  "w /sys/module/maccel/parameters/ACCEL - - - - 1288490189"
];
```

## 🚀 **Usage Comparison**

### Old CLI-Based Approach

```nix
# maccel-nixos-module.nix (with CLI dependency)
hardware.maccel = {
  enable = true;
  parameters = {
    sensMultiplier = 1.0;
    acceleration = 0.3;
  };
};

# What happens:
# 1. Boot with default parameters
# 2. systemd service: maccel-set-defaults.service starts
# 3. Service calls: maccel set param sens-mult 1.0
# 4. CLI converts and writes to sysfs
# 5. CLI creates reset script
```

### New Direct Approach

```nix
# maccel-nixos-direct.nix (NO CLI needed)
hardware.maccel = {
  enable = true;
  parameters = {
    sensMultiplier = 1.0;
    acceleration = 0.3;
  };
};

# What happens:
# 1. Boot with: modprobe maccel SENS_MULT=4294967296 ACCEL=1288490189
# 2. Done!
```

## 🔧 **Complete Migration Guide**

### Step 1: Replace Module

```bash
# Replace the old module
mv maccel-nixos-module.nix maccel-nixos-module-OLD.nix
cp maccel-nixos-direct.nix maccel-nixos-module.nix
```

### Step 2: Update Configuration

```nix
# Your configuration.nix stays exactly the same!
hardware.maccel = {
  enable = true;
  parameters = {
    sensMultiplier = 1.0;
    acceleration = 0.3;
    mode = "linear";
  };
};
```

### Step 3: Optional CLI Tools

```nix
# Only if you want CLI tools for manual adjustment
hardware.maccel = {
  enable = true;
  buildTools = true;  # Add this line
  parameters = { /* ... */ };
};
```

### Step 4: Deploy

```bash
sudo nixos-rebuild switch
```

## 🔍 **Verification**

Check that parameters are applied correctly:

```bash
# Method 1: Check kernel module parameters
cat /sys/module/maccel/parameters/SENS_MULT
# Should show: 4294967296 (for sensMultiplier = 1.0)

# Method 2: Check modinfo
modinfo maccel

# Method 3: Check module load parameters
dmesg | grep maccel

# Method 4: If debug enabled, check service output
systemctl status maccel-info
```

## 📋 **Supported Parameters**

### Common Parameters (All Modes)

| NixOS Option     | Kernel Parameter | Fixed-Point Conversion | Default | Description                                            |
| ---------------- | ---------------- | ---------------------- | ------- | ------------------------------------------------------ |
| `sensMultiplier` | `SENS_MULT`      | `value * 4294967296`   | 1.0     | Base sensitivity multiplier applied after acceleration |
| `yxRatio`        | `YX_RATIO`       | `value * 4294967296`   | 1.0     | Y/X axis sensitivity ratio                             |
| `inputDpi`       | `INPUT_DPI`      | `value * 4294967296`   | 1000.0  | Mouse DPI for normalization                            |
| `angleRotation`  | `ANGLE_ROTATION` | `value * 4294967296`   | 0.0     | Input rotation in degrees                              |
| `mode`           | `MODE`           | See below              | linear  | Acceleration curve type                                |

### Linear Mode Parameters

| NixOS Option   | Kernel Parameter | Fixed-Point Conversion | Default | Description                            |
| -------------- | ---------------- | ---------------------- | ------- | -------------------------------------- |
| `acceleration` | `ACCEL`          | `value * 4294967296`   | 0.0     | Linear acceleration factor             |
| `offset`       | `OFFSET`         | `value * 4294967296`   | 0.0     | Input speed threshold for acceleration |
| `outputCap`    | `OUTPUT_CAP`     | `value * 4294967296`   | 0.0     | Maximum sensitivity multiplier cap     |

### Natural Mode Parameters

| NixOS Option | Kernel Parameter | Fixed-Point Conversion | Default | Description                              |
| ------------ | ---------------- | ---------------------- | ------- | ---------------------------------------- |
| `decayRate`  | `DECAY_RATE`     | `value * 4294967296`   | 0.1     | Decay rate of natural curve              |
| `limit`      | `LIMIT`          | `value * 4294967296`   | 1.5     | Maximum acceleration limit               |
| `offset`     | `OFFSET`         | `value * 4294967296`   | 0.0     | Input speed threshold (shared parameter) |

### Synchronous Mode Parameters

| NixOS Option | Kernel Parameter | Fixed-Point Conversion | Default | Description                                 |
| ------------ | ---------------- | ---------------------- | ------- | ------------------------------------------- |
| `gamma`      | `GAMMA`          | `value * 4294967296`   | 1.0     | Controls transition speed around midpoint   |
| `smooth`     | `SMOOTH`         | `value * 4294967296`   | 0.5     | Controls suddenness of sensitivity increase |
| `motivity`   | `MOTIVITY`       | `value * 4294967296`   | 1.5     | Sets max sensitivity (min = 1/motivity)     |
| `syncSpeed`  | `SYNC_SPEED`     | `value * 4294967296`   | 5.0     | Middle sensitivity between min and max      |

### Mode Values

| Mode String     | Kernel Value | Description                                  |
| --------------- | ------------ | -------------------------------------------- |
| `"linear"`      | 0            | Simple linear acceleration                   |
| `"natural"`     | 1            | Smooth, natural-feeling curve                |
| `"synchronous"` | 2            | Advanced curve with precise control          |
| `"no_accel"`    | 3            | No acceleration, just sensitivity adjustment |

## 🎯 **When to Use Each Approach**

### Use Direct Approach When:

- ✅ You want the fastest, most reliable setup
- ✅ You primarily use static parameters
- ✅ You prefer traditional Linux kernel module approach
- ✅ You want minimal dependencies

### Use CLI Approach When:

- ❌ You need to change parameters frequently at runtime
- ❌ You want to use the TUI interface regularly
- ❌ You're developing/debugging acceleration curves

**Recommendation**: Start with the direct approach. You can always add `buildTools = true` later if you need the CLI tools.

## 🔄 **Runtime Parameter Changes**

Even with the direct approach, you can still change parameters at runtime:

```bash
# Direct sysfs write (no CLI needed)
echo 6442450944 | sudo tee /sys/module/maccel/parameters/SENS_MULT  # 1.5

# Or if you built the CLI tools
maccel set param sens-mult 1.5

# Or use the TUI
maccel tui
```

## 🎉 **Summary**

The direct approach transforms maccel from a complex, multi-service setup into a simple, traditional kernel module configuration. It's faster, more reliable, and follows Linux best practices.

**Bottom Line**: Same functionality, same configuration syntax, but much cleaner implementation! 🚀
