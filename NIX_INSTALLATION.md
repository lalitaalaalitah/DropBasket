# ❄️ Nix Installation & Declarative Configuration Guide

> **Author:** [lalitaalaalitah](https://github.com/lalitaalaalitah)  
> **Website:** [https://www.lalitaalaalitah.com](https://www.lalitaalaalitah.com)  
> **GitHub Profile:** [https://github.com/lalitaalaalitah](https://github.com/lalitaalaalitah)  
> **Application:** DropBasket v1.1.0

This guide details all methods for executing, installing, and declaratively managing **DropBasket** on macOS using **Nix**, **Nix Flakes**, **Nix-Darwin**, and **Home Manager**.

---

## 1. ⚡ Ad-Hoc Execution via Nix Run

Run `dropbasket` immediately without persistent installation to your environment:

```bash
# Bring floating basket to cursor or start service:
nix run github:lalitaalaalitah/DropBasket --

# Pass CLI arguments:
nix run github:lalitaalaalitah/DropBasket -- --version
nix run github:lalitaalaalitah/DropBasket -- add ~/Downloads/document.pdf
nix run github:lalitaalaalitah/DropBasket -- status
```

---

## 2. 📦 Profile Installation (Imperative)

Install the package directly into your Nix profile:

```bash
nix profile install github:lalitaalaalitah/DropBasket
```

---

## 3. 🛠️ Declarative Configuration with Flakes & Nix-Darwin

### Step A: Add Flake Input

In your system `flake.nix` (e.g. `~/nix/flake.nix`):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # DropBasket Flake Input
    DropBasket.url = "github:lalitaalaalitah/DropBasket";
    DropBasket.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, DropBasket, ... }@inputs: {
    darwinConfigurations."MyMacBook" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # or "x86_64-darwin"
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        DropBasket.darwinModules.default
      ];
    };
  };
}
```

### Step B: Enable DropBasket Service in Configuration

In your `configuration.nix` or system module:

```nix
{ config, pkgs, ... }:

{
  # Enable DropBasket background service
  services.dropbasket = {
    enable = true;
  };
}
```

---

## 4. 🏠 Declarative Configuration with Home Manager

### Step A: Pass Input via `extraSpecialArgs`

In your `flake.nix`:

```nix
homeConfigurations."username" = home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages."aarch64-darwin";
  extraSpecialArgs = { inherit inputs; };
  modules = [
    ./home.nix
    DropBasket.homeModules.default
  ];
};
```

### Step B: Enable Service & Package in Home Manager

In your `home.nix`:

```nix
{ config, lib, pkgs, ... }:

{
  # Enable DropBasket background service & packages
  services.dropbasket = {
    enable = true;
  };
}
```

This automatically:
1. Adds `dropbasket` and `DropBasket.app` to `home.packages`.
2. Registers and starts the user background launch agent via `launchd.agents.dropbasket`.
3. Keeps DropBasket running continuously in the background across reboots and logins.

---

## 5. 🔄 Flake Lock Updating & System Activation Lifecycle

Whenever a new version of DropBasket is released:

```bash
# 1. Update DropBasket input lock in your nix directory
cd ~/nix
nix flake update DropBasket

# 2. Rebuild and activate system configuration
just switch
# or: darwin-rebuild switch --flake .#MyMacBook
# or: home-manager switch --flake .#username

# 3. Verify installation and service status
which dropbasket
dropbasket --version
dropbasket service status
```
