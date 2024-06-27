# sddmSugarCandy4Nix

![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/sddm_laptop_catppuccin_nixos.png)

This repository is a wrapper of the fork of the Sugar Candy login theme for SDDM made by Marian Arlt available [here](https://framagit.org/MarianArlt/sddm-sugar-candy/-/tree/master).

> I cloned the source into ./src just to ensure that it can be built and does not depend on framagit.
In addition, version 1.5 is available in the author's repository, but version 1.6 can be found [here](https://store.kde.org/p/1312658/).
I didn't actually compare the differences, but decided to add the most current source code.
Unfortunately, I don't know QML syntax and can't support the theme's source code.
The author's last commit dates back to 2020, but sugar-candy still works great.


## Table of content

- [sddmSugarCandy4Nix](#sddmsugarcandy4nix)
  - [Table of content](#table-of-content)
- [Goal](#goal)
  - [How it works?](#how-it-works)
- [Installation](#installation)
    - [First step](#first-step)
    - [Second step](#second-step)
    - [Third step](#third-step)
    - [Fourth step](#fourth-step)
- [Configuration](#configuration)
- [Examples](#examples)


# Goal

The main goal is to provide the ability to add a theme to a NixOS configuration
and still be able to use all available theme customizations declaratively.

There is already a [repository](https://github.com/Zhaith-Izaliel/sddm-sugar-candy-nix)
on GitHub that allows you to add a theme as a NixOS module that wraps
services.displayManager.sddm and adds a theme option there.
It works great, but I think this approach is redundant for two reasons:

- `services.displayManager.sddm.theme` expects the path to the directory
with the theme (as you understand, it is enough to simply provide the path
to the derivation `"${pkgs.my-ssdm-theme}"`)
The option here is redundant, we just need a theme package.
- a module that is built into a standard one is difficult to maintain.
More recently, `displayManager.sddm` has been moved up a level from the attribute set.


## How it works?

To implement it, we need to use two features:

- `overlays` using flake to add the package to the pkgs attribute set
- `override` change the package build by passing custom properties

More details in sections: [Installation](#installation) and [Configuration](#configuration)


# Installation

To install it you **must have flake enabled** and your NixOS configuration
**must be managed with flakes.** See [Flakes](https://nixos.wiki/wiki/Flakes) for
instructions on how to install and enable them on NixOS.

### First step

You can add this flake as inputs in `flake.nix` in the repository
containing your NixOS configuration:

```nix
inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  # ...
    sddmSugarCandy4Nix = {
      url = "github:MOIS3Y/sddmSugarCandy4Nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  # ...
}
```

This flake provides an overlay for Nixpkgs, with package and a NixOS module.

They are respectively found in the flake as

- `inputs.sddmSugarCandy4Nix.overlays.default`
- `inputs.sddmSugarCandy4Nix.overlays.sddm-suger-candy`
- `inputs.ssddmSugarCandy4Nix.packages.${system}.default`
- `inputs.ssddmSugarCandy4Nix.packages.${system}.sddm-suger-candy`
(Where `${system}` is either `x86_64-linux` or `aarch64-linux`)


### Second step

Output data can be added in different ways, for example this is how I do it:

```nix
  outputs = { self, nixpkgs, ... }@inputs:  # <-- it is important to pass inputs as an argument
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs { inherit system; };
      specialArgs = { inherit system; inherit inputs; }; 
    in {
    nixosConfigurations = {
      desktop-laptop = lib.nixosSystem {
        inherit specialArgs;  # <-- it is important inputs will be available anywhere in the configuration
        modules = [
          ./hosts/desktop-laptop/configuration.nix  # set your own file from your-awesome-nix-conf
        ];
      };
      # ... add more hosts here:
    };
  };

```

Here's my full [nixos-configurations](https://github.com/MOIS3Y/nixos-configurations/blob/main/flake.nix) flake

If you are new to NixOS here is a useful channel [Vimjoyer](https://www.youtube.com/watch?v=rEovNpg7J0M)


### Third step

All we have to do is add sddm-sugar-candy to the list of available packages using overlays

Somewhere in your `configuration.nix`

```nix
{ config, pkgs, inputs, ... }: {  # <-- inputs from flake
  # ...
  nixpkgs = { 
    overlays = [
      (final: prev: {
        sddm-sugar-candy = inputs.sddmSugarCandy4Nix.packages."${pkgs.system}".sddm-sugar-candy;
      })
    ];
  };
  # ...
}
```

Now you can call the package anywhere as a package from nixpkgs

- `pkgs.sddm-sugar-candy`
- `"${pkgs.sddm-sugar-candy}"` will return a string with the full path of the theme /nix/store/longhash-sddm-sugar-candy-1.6


### Fourth step

Tell sddm to use the theme sddm-sugar-candy

Somewhere in your `configuration.nix`

```nix
{ config, pkgs, inputs, ... }: {
  # ...
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.theme = "${pkgs.sddm-sugar-candy}";  # <-- it's string interpolation
  services.displayManager.sddm.extraPackages = with pkgs; [
    libsForQt5.qt5.qtgraphicaleffects  # <-- if suddenly sugar-candy does not find dependencies
  ];
  # ...
}
```

SDDM will use sugar-candy with default settings.

Want customization, easy...


# Configuration

To change the theme build parameters, use the `override` function

- sddm-sugar-candy will expect a attribute set of `settings`.
- if you don't pass the attribute the default value will be used
- remember that ultimately the final package should be passed to `services.displayManager.sddm.theme` as a string

Below is an example of `override` with all available attributes
What each attribute means and what value can be set you will find in [README.md](https://github.com/MOIS3Y/sddmSugarCandy4Nix/tree/main/src#configuration)


Somewhere in your `configuration.nix`

```nix
{ config, pkgs, inputs, ... }: {
  # ...
  services = {
    displayManager = {
      enable = true;
      sddm = { 
        enable = true;
        extraPackages = with pkgs; [
          libsForQt5.qt5.qtgraphicaleffects  # <-- if suddenly sugar-candy does not find dependencies
        ];
        theme = ''${  # <-- string interpolation and nix expression inside {}
          pkgs.sddm-sugar-candy.override {
            settings = {
              Background="Backgrounds/Mountain.jpg";  # <-- string (path to image)
              DimBackgroundImage="0.0";
              ScaleImageCropped=true;
              ScreenWidth="1440";
              ScreenHeight="900";
              FullBlur=false;
              PartialBlur=true;
              BlurRadius="100";
              HaveFormBackground=false;
              FormPosition="left";
              BackgroundImageHAlignment="center";
              BackgroundImageVAlignment="center";
              MainColor="white";
              AccentColor="#fb884f";
              BackgroundColor="#444";
              OverrideLoginButtonTextColor="";
              InterfaceShadowSize="6";
              InterfaceShadowOpacity="0.6";
              RoundCorners="20";
              ScreenPadding="0";
              Font="Noto Sans";
              FontSize="";
              ForceRightToLeft=false;
              ForceLastUser=true;
              ForcePasswordFocus=true;
              ForceHideCompletePassword=false;
              ForceHideVirtualKeyboardButton=false;
              ForceHideSystemButtons=false;
              AllowEmptyPassword=false;
              AllowBadUsernames=false;
              Locale="";
              HourFormat="HH:mm";
              DateFormat="dddd, d of MMMM";
              HeaderText="Welcome!";
              TranslatePlaceholderUsername="";
              TranslatePlaceholderPassword="";
              TranslateShowPassword="";
              TranslateLogin="";
              TranslateLoginFailedWarning="";
              TranslateCapslockWarning="";
              TranslateSession="";
              TranslateSuspend="";
              TranslateHibernate="";
              TranslateReboot="";
              TranslateShutdown="";
              TranslateVirtualKeyboardButton="";
            };
          }
        }'';
      };
    };
  };
  # ...
}
```

# Examples

|  |  |  |  |
|-----------|--------------|--------------|--------------|
| ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/sddm_laptop_catppuccin_nixos.png) | ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/login_screen_catppuccin_nixos.png) | ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/sddm_laptop_catppuccin_misc.png) | ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/login_screen_catppuccin_misc.png) |
| ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/sddm_laptop_yoru_nixos.png) | ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/login_screen_yoru_nixos.png) | ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/sddm_laptop_yoru_misc.png) | ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/login_screen_yoru_misc.png) |
| ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/sddm_laptop_everblush_nixos.png) | ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/login_screen_everblush_nixos.png) | ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/sddm_laptop_everblush_misc.png) | ![image info](https://github.com/MOIS3Y/sddmSugarCandy4Nix/blob/main/.github/login_screen_everblush_misc.png) |
