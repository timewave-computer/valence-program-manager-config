{
  inputs = {
    zero-nix.url = "github:timewave-computer/zero.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  nixConfig.extra-substituters = ''
    https://cosmos-nix.cachix.org
    https://timewave.cachix.org
  '';
  nixConfig.extra-trusted-public-keys = ''
    cosmos-nix.cachix.org-1:I9dmz4kn5+JExjPxOd9conCzQVHPl0Jo1Cdp6s+63d4=
    timewave.cachix.org-1:nu3Uqsm3sikI9xFK3Mt4AD4Q6z+j6eS9+kND1vtznq4=
  '';

  outputs = inputs @ {flake-parts, zero-nix, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      debug = true;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      imports = [
        zero-nix.flakeModules.upload-contracts
        # Adds all contracts in current release to all chains across networks
        zero-nix.flakeModules.upload-valence-contracts
      ];
      perSystem = { lib, config, inputs', ... }:
        let zeroNixPkgs = inputs'.zero-nix.packages; in
          {
            upload-contracts = {
              networkDefaults = { name, ... }: {
                data-dir = "./${name}/contracts-data";
                program-manager-chains-toml = ./${name}/chains.toml;
                chainDefaults = {
                  contractDefaults = {
                    # Only use valence-contracts-main for contracts in list above
                    package = lib.mkDefault zeroNixPkgs.valence-contracts-v0_1_2;
                  };
                  contracts = {
                    valence_drop_liquid_staker.package = zeroNixPkgs.valence-contracts-main;
                    valence_drop_liquid_unstaker.package = zeroNixPkgs.valence-contracts-main;
                  };
                };
              };
              networks.mainnet.chains = {
                neutron = {
                  max-fees = "1000000";
                };
                juno = {
                  max-fees = "1000000";
                };
                terra = {
                  max-fees = "6000000";
                };
              };
              networks.testnet.chains = {
                neutron = {
                  max-fees = "1000000";
                };
              };
            };
          };
    };
}
