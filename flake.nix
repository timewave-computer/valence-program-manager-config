{
  inputs = {
    zero-nix.url = "github:timewave-computer/zero.nix";
    cosmos-nix.url = "github:timewave-computer/cosmos.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = inputs @ {flake-parts, zero-nix, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      imports = [
        zero-nix.flakeModules.upload-contracts
        zero-nix.flakeModules.valence-contracts
      ];
      perSystem = { lib, config, inputs', ... }: {
        valence-contracts = {
          v1 = {
            src = builtins.fetchGit {
              url = "https://github.com/timewave-computer/valence-protocol.git";
              # Exact rev of v1.0 needs to be specified in pure nix mode
              rev = "5724521f51e30a56c5e042ed98df5b7bfc9477cf";
            };
          };
        };
        upload-contracts =
          let
            inherit (config.packages) valence-contracts-v1;
            cosmosNixPkgs = inputs'.cosmos-nix.packages;
            chainConfig = builtins.fromTOML ./mainnet/chains.toml;
            # Max fees are set to rounded up 1USD to chain denom conversion
          in
          {
            chains = {
              neutron = {
                package = cosmosNixPkgs.neutron;
                node-address = chainConfig.neutron.rpc;
                denom = chainConfig.neutron.gas_denom;
                chain-id = "neutron-1";
                max-fees = "8";
              };
              juno = {
                package = cosmosNixPkgs.juno;
                node-address = chainConfig.juno.rpc;
                denom = chainConfig.juno.gas_denom;
                chain-id = "juno-1";
                max-fees = "10";
              };
              terra = {
                package = cosmosNixPkgs.terra;
                node-address = chainConfig.terra.rpc;
                denom = chainConfig.terra.gas_denom;
                chain-id = "columbus-5";
                max-fees = "6";
              };
            };
            chainDefaults = { config, ... }: {
              contracts = lib.mkMerge [
                {
                  polytone_proxy.path = "${valence-contracts-v1}/polytone_proxy.wasm";
                  valence_processor.path = "${valence-contracts-v1}s/valence_processor.wasm";
                  valence_base_account.path = "${valence-contracts-v1}s/valence_base_account.wasm";
                  valence_forwarder_library.path = "${valence-contracts-v1}s/valence_forwarder_library.wasm";
                  valence_splitter_library.path = "${valence-contracts-v1}s/valence_splitter_library.wasm";
                  valence_reverse_splitter_library.path = "${valence-contracts-v1}s/valence_reverse_splitter_library.wasm";
                }
                (lib.mkIf (config.package.pname == "neutron") {
                  valence_authorization.path = "${valence-contracts-v1}/valence_authorization.wasm";
                  valence_processor.path = "${valence-contracts-v1}/valence_processor.wasm";
                  valence_base_account.path = "${valence-contracts-v1}/valence_base_account.wasm";
                  valence_program_registry.path = "${valence-contracts-v1}s/valence_program_registry.wasm";
                  valence_drop_liquid_staker.path = "${valence-contracts-v1}s/valence_drop_liquid_staker.wasm";
                  valence_drop_liquid_unstaker.path = "${valence-contracts-v1}s/valence_drop_liquid_unstaker.wasm";
                  valence_astroport_lper.path = "${valence-contracts-v1}s/valence_astroport_lper.wasm";
                  valence_astroport_withdrawer.path = "${valence-contracts-v1}s/valence_astroport_withdrawer.wasm";
                })
                (lib.mkIf (config.package.pname != "neutron") {
                  valence_generic_ibc_transfer_library.path = "${valence-contracts-v1}s/valence_generic_ibc_transfer_library.wasm";
                })
              ];
            };
          };
      };
    };
}
