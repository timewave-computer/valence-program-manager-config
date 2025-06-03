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

  outputs = inputs @ {
    flake-parts,
    zero-nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      imports = [
        zero-nix.flakeModules.upload-contracts
        # Adds all contracts in current release to all chains across networks
        zero-nix.flakeModules.valence-contracts
      ];
      perSystem = {
        lib,
        inputs',
        ...
      }: let
        zeroNixPkgs = inputs'.zero-nix.packages;
      in {
        valence-contracts.upload = false;
        upload-contracts = {
          network-defaults = {name, ...}: {
            data-dir = "./${name}/contracts-data";
            program-manager-chains-toml = ./${name}/chains.toml;
            chain-defaults = {
              contract-defaults = {
                # Only use valence-contracts-main for contracts in list above
                package = lib.mkDefault zeroNixPkgs.valence-contracts-v0_1_2;
              };
              contracts = {
                # valence_drop_liquid_staker.package = zeroNixPkgs.valence-contracts-main;
                #valence_drop_liquid_unstaker.package = zeroNixPkgs.valence-contracts-main;
                valence_splitter_library.package = zeroNixPkgs.valence-contracts-v0_1_2;
                valence_reverse_splitter_library.package = zeroNixPkgs.valence-contracts-v0_1_2;
                valence_base_account.package = zeroNixPkgs.valence-contracts-v0_1_2;
                valence_forwarder_library.package = zeroNixPkgs.valence-contracts-v0_1_2;
                valence_processor.package = zeroNixPkgs.valence-contracts-v0_1_2;
                valence_generic_ibc_transfer_library.package = zeroNixPkgs.valence-contracts-v0_1_2;
                valence_osmosis_cl_lper.package = zeroNixPkgs.valence-contracts-v0_1_2;
                valence_osmosis_cl_withdrawer.package = zeroNixPkgs.valence-contracts-v0_1_2;
                valence_osmosis_gamm_lper.package = zeroNixPkgs.valence-contracts-v0_1_2;
                valence_osmosis_gamm_withdrawer.package = zeroNixPkgs.valence-contracts-v0_1_2;
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
            osmosis = {
              max-fees = "1000000";
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
