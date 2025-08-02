{
  description = "My dotfiles managed with nix as a flake";

  inputs = {
    # TODO amdgpu driver is broken currently, remove this and the overlay below when this PR
    # is on nixos-unstable: https://github.com/NixOS/nixpkgs/pull/420231
    # https://nixpk.gs/pr-tracker.html?pr=420231
    nixpkgs-pr420231.url = "github:NixOS/nixpkgs/pull/420231/head";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    tokyonight.url = "github:mrjones2014/tokyonight.nix";
    zjstatus.url = "github:dj95/zjstatus";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    _1password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      nix-darwin,
      home-manager,
      agenix,
      ...
    }:
    {
      nixosConfigurations = {
        homelab = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            isServer = true;
            isLinux = true;
            isThinkpad = false;
            isDarwin = false;
          };
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            {
              environment.systemPackages = [ agenix.packages.x86_64-linux.default ];
            }
            ./nixos/common.nix
            ./hosts/server
            {
              home-manager = {
                backupFileExtension = "backup";
                useUserPackages = true;
                users.mat = import ./home-manager/server.nix;
                extraSpecialArgs = {
                  inherit inputs;
                  isServer = true;
                  isLinux = true;
                  isThinkpad = false;
                  isDarwin = false;
                };
              };
            }
          ];
        };
        tower = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            isServer = false;
            isDarwin = false;
            isLinux = true;
            isThinkpad = false;
          };
          system = "x86_64-linux";
          modules = [
            {
              # TODO remove this overlay when the PR is available in nixos-unstable, see comment at top
              nixpkgs.overlays = [
                (final: prev: {
                  inherit (inputs.nixpkgs-pr420231.legacyPackages.x86_64-linux) linux-firmware;
                })
              ];
            }
            agenix.nixosModules.default
            {
              environment.systemPackages = [ agenix.packages.x86_64-linux.default ];
            }
            ./nixos/common.nix
            ./hosts/pc
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "backup";
                useUserPackages = true;
                users.mat = import ./home-manager/home.nix;
                extraSpecialArgs = {
                  inherit inputs;
                  isServer = false;
                  isDarwin = false;
                  isLinux = true;
                  isThinkpad = false;
                };
              };
            }
          ];
        };
        nixbook = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            isServer = false;
            isDarwin = false;
            isLinux = true;
            isThinkpad = true;
          };
          system = "x86_64-linux";
          modules = [
            ./nixos/common.nix
            ./hosts/laptop
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "backup";
                useUserPackages = true;
                users.mat = import ./home-manager/home.nix;
                extraSpecialArgs = {
                  inherit inputs;
                  isServer = false;
                  isDarwin = false;
                  isLinux = true;
                  isThinkpad = true;
                };
              };
            }
          ];
        };
      };
      darwinConfigurations."darwin" =
        let
          specialArgs = {
            inherit inputs;
            isServer = false;
            isDarwin = true;
            isLinux = false;
            isThinkpad = false;
          };
        in
        nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          pkgs = nixpkgs.legacyPackages."aarch64-darwin";
          modules = [
            ./hosts/darwin
            home-manager.darwinModules.default
            {
              home-manager = {
                users.mat = import ./home-manager/home.nix;
                extraSpecialArgs = specialArgs;
              };
            }
          ];
        };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (nixpkgs) lib;
        pkgs = nixpkgs.legacyPackages.${system};
        packages = lib.filterAttrs (_: pkg: builtins.any (x: x == system) pkg.meta.platforms) (
          import ./pkgs { inherit pkgs; }
        );
        checksForConfigs =
          configs: extract:
          lib.attrsets.filterAttrs (_: p: p.system == system) (lib.attrsets.mapAttrs (_: extract) configs);
      in
      {
        checks = lib.lists.foldl lib.attrsets.unionOfDisjoint packages [
          (checksForConfigs self.nixosConfigurations (c: c.config.system.build.toplevel))
          (checksForConfigs self.darwinConfigurations (c: c.darwin.system))
        ];
        devShells.ci = pkgs.mkShell {
          packages = [ pkgs.nix-fast-build ];
        };
      }
    );
}
