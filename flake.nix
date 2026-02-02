{
  description = "NixOS flake for the super computer";

  inputs = {
    # Input stable nixpkgs for use in the OS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Unstable packages for things like tailscale
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # SOPS for secret management.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # Lanzaboote
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    # Don't follow nixpkgs to avoid broken rust builds
    # lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    disko,
    sops-nix,
    lanzaboote,
    treefmt-nix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
    treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
  in {
    # Add overlays
    overlays = import ./overlays {inherit inputs;};
    formatter = eachSystem (pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);
    nixosConfigurations =
      {
        # Configuration for the NixOS system
        superdator = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit (self) inputs outputs;};
          modules = [
            ./nixos/configuration.nix

            # add sops secrets
            sops-nix.nixosModules.sops
          ];
        };
      }
      # ROS2 full env workstations
      // pkgs.lib.genAttrs ["dunning" "kruger"] (
        hostname:
          nixpkgs.lib.nixosSystem {
            specialArgs = {inherit (self) inputs outputs;};
            modules = [
              {nixpkgs.overlays = builtins.attrValues self.overlays;}
              sops-nix.nixosModules.sops
              disko.nixosModules.disko
              lanzaboote.nixosModules.lanzaboote

              {
                networking.hostName = hostname;
              }

              ./ros2/common
              (./ros2 + "/disko-${hostname}.nix")
              (./ros2 + "/hardware-configuration-${hostname}.nix")
              (./ros2 + "/bootloader-${hostname}.nix")
            ];
          }
      )
      # ROS2 minimal workstations
      // pkgs.lib.genAttrs ["murphy" "splinter" "leonardo" "donatello"] (
        hostname:
          nixpkgs.lib.nixosSystem {
            specialArgs = {inherit (self) inputs outputs;};
            modules = [
              {nixpkgs.overlays = builtins.attrValues self.overlays;}
              sops-nix.nixosModules.sops
              disko.nixosModules.disko
              lanzaboote.nixosModules.lanzaboote
              {
                networking.hostName = hostname;
              }

              ./ros2/common/default-minimal.nix
              (./ros2 + "/disko-${hostname}.nix")
              (./ros2 + "/hardware-configuration-${hostname}.nix")
              (./ros2 + "/bootloader-${hostname}.nix")
            ];
          }
      );

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [neovim nixd bat ripgrep alejandra git nixos-generators age sops frankenphp helix];
    };
  };
}
