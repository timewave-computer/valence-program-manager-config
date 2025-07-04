# Valence program manager config

The program manager library is using this config to operate.

## Chains

This file hold all the chain information that is needed to communicate with the chains, if a chain information doesn't exists, the manager will not support it.

## Contracts

This file holds all the code ids of the contracts that is being used by programs per chain.

If a code id for a specific library doesn't exists, the manager will not be able to instantiate this contract on that chain.

## Bridges 

In order to operate on multiple chains we need a GMP bridge to exists, the bridge must be set before supporting a new chain, and the information for a connection of 2 chains must be given in the config.

## General

This is general information that is needed by the manager.

- registry_addr - The address of the registry contract to keep track of program configs

# Deploy contracts with nix

There are scripts created by zero.nix to automatically store contracts and dump information about the contract for each chain and for a network of chains. Configuration for each chain and contracts on them is in the [flake.nix](flake.nix).

## Uploading an individual chain

Run `nix run .#<network>-<chain>-upload-contracts`. For example, to upload neutron mainnet contracts run the following:

``` bash
nix run .#mainnet-neutron-upload-contracts -- --admin-address <admin-address>
```
Code ids will be printed out at the end in the expected toml format for the program manager.

## Uploading a network of chains

To upload all contracts for every chain in a network use:

``` bash
nix run .#mainnet-upload-contracts -- --admin-address <admin-key-name>
```
This script will create `contracts.toml` for the whole network in `mainnet/contracts-data/contracts.toml`.

The uploading process doesn't yet support command line arguments per chain, so when uploading a network of chains it is recommended to have addresses with the same key name for all chains and then pass the key name as the admin address.

If it is necessary to specify different admin addresses per chain, then it must be set in [flake.nix][flake] with the `admin-address` key. To override the mainnet neutron admin-address, for example, go to the "networks.mainnet.chains" section of [flake.nix][flake], then set admin-address like so:

``` nix
networks.mainnet.chains = {
  neutron = {
    admin-address = "neutron1...";
    package = cosmosNixPkgs.neutron;
```

## Customizing contract uploads

The contract uploading script can be passed various arguments similar to how the admin address was passed above. To see all the arguments of the script run:

``` bash
nix run github:timewave-computer/zero.nix#upload-contract -- --help
```
Note: all options have to be passed after the "--" to ensure they get passed to the script instead of the nix command.

Every option has an equivalent environment variable as described in the help menu. These variables can optionally be set in [flake.nix](flake.nix) for declarative configuration. Options passed in the command line will always override settings in environment variables (or set through nix).

As an example, to upload neutron contracts with a different rpc, run:

``` bash
nix run .#mainnet-neutron-upload-contracts --admin-address <admin-address> --node-address <rpc url>
```

## Manually print code ids
A script is available to print the code ids of any collection of chains. To do so, run:

``` bash
nix run .#print-contracts-toml <chain yaml files>
```
The chain yaml files are the ones living in the contracts-data folder created by the upload scripts.

For example, to print the contracts.toml just neutron and juno on mainnet, run:

``` bash
nix run .#print-contracts-toml mainnet/contracts-data/neutron.yaml mainnet/contracts-data/juno.yaml 
```

[flake]: flake.nix
