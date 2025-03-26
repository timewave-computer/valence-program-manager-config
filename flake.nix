{
  inputs = {
    zero-nix.url = "github:timewave-computer/zero.nix";
    cosmos-nix.url = "github:timewave-computer/cosmos.nix";
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
          v0_1_1 = {
            src = builtins.fetchGit {
              url = "https://github.com/timewave-computer/valence-protocol.git";
              # Exact long rev needs to be specified in pure nix mode
              rev = "85ecf4974c62bcb6443ac16b9dd7d178eed07841";
              ref = "release-v0.1.1";
            };
          };
          main = {
            src = builtins.fetchGit {
              url = "https://github.com/timewave-computer/valence-protocol.git";
              # Specifically includes liquid drop staker/unstaker
              rev = "e24c96566714c6d047f9e8f1e15527dca88314c0";
            };
          };
        };
        upload-contracts =
          let
            inherit (config.packages) valence-contracts-v0_1_1 valence-contracts-main;
            cosmosNixPkgs = inputs'.cosmos-nix.packages;
            getChainConfig = network: (builtins.fromTOML (builtins.readFile ./${network}/chains.toml)).chains;
            mainnetChainConfig = getChainConfig "mainnet";
            mainContracts = [ "valence_drop_liquid_staker" "valence_drop_liquid_unstaker" ];
            valenceContracts = { config, ... }: {
              contractDefaults = { name, ... }: {
                # Only use valence-contracts-main for contracts in list above
                package = if builtins.elem name mainContracts
                          then valence-contracts-main
                          else valence-contracts-v0_1_1;
              };
              contracts = lib.mkMerge [
                # Contract paths are inferred based on name
                # but can be manually set with the `path` option within each contract
                # For example: valence_processor.path = ${valence-contracts-main}/valence_processor.wasm;
                {
                  valence_processor = {};
                  valence_base_account = {};
                  valence_forwarder_library = {};
                  valence_splitter_library = {};
                  valence_reverse_splitter_library = {};
                }
                (lib.mkIf (config.package.pname == "neutron") {
                  valence_authorization = {};
                  valence_program_registry = {};
                  valence_drop_liquid_staker = {};
                  valence_drop_liquid_unstaker = {};
                  valence_astroport_lper = {};
                  valence_astroport_withdrawer = {};
                  valence_generic_ibc_transfer_library = {};
                  valence_neutron_ibc_transfer_library = {};
                })
                (lib.mkIf (config.package.pname != "neutron") {
                  valence_generic_ibc_transfer_library = {};
                })
              ];
            };
          in
          {
            networks.mainnet.data-dir = "./mainnet/contracts-data";
            networks.mainnet.chains = {
              neutron = {
                package = cosmosNixPkgs.neutron;
                node-address = mainnetChainConfig.neutron.rpc;
                denom = mainnetChainConfig.neutron.gas_denom;
                chain-id = mainnetChainConfig.neutron.chain_id;
                max-fees = "1000000";
              };
              juno = {
                package = cosmosNixPkgs.juno;
                node-address = mainnetChainConfig.juno.rpc;
                denom = mainnetChainConfig.juno.gas_denom;
                chain-id = mainnetChainConfig.juno.chain_id;
                max-fees = "1000000";
              };
              terra = {
                package = cosmosNixPkgs.terra;
                node-address = mainnetChainConfig.terra.rpc;
                denom = mainnetChainConfig.terra.gas_denom;
                chain-id = mainnetChainConfig.terra.chain_id;
                max-fees = "6000000";
              };
            };
            networks.mainnet.chainDefaults = valenceContracts;
          };
      };
    };
}
