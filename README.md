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