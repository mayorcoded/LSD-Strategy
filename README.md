# Fixed Rate Vault

## Problem Statement

Hopefully, you are familiar with the LSD product offered on top of the Stakehouse protocol; if not, please take a look here: https://docs.joinstakehouse.com/lsd/overview

Take a look at the section on giant pools. Users can stake in either to either choose between a fixed rate of return from consensus layer yield or get unpredictable but potentially higher returns from the fees and mev pool.

What if users can get a fixed rate of return using both sources? The idea is that they supply ETH, and someone else manages that ETH to ensure a fixed rate of return.

Challenge:
Create a yearn vault-style contract that will take ETH from users and give them an LP token back. The vault manager can choose to re-market that with either giant pool mentioned above in order to get LP tokens from those contracts. The ETH from users cannot be used for other purposes other than depositing ETH into giant pools (using `depositETH` method as appropriate).

- Withdraw dETH from giant savETH pool contract and method for selling the dETH for ETH on UniswapClaim
- ETH rewards from giant fees and mev pool contract into your contract
- Claim percentage of profits i.e. the contract will give users a fixed rate of return where any excess profits go to the manager of the contract

You can get a preview of the LSD contracts here to give you an idea of methods available for this: https://github.com/stakehouse-dev/lsd-arena

You can also use docs on LSD wizard above to find out other info.
Take a look here for contract addresses for giant pools: https://github.com/stakehouse-dev/contract-deployments#goerli-deployment-1 

## Solution steps

### FixedRateVault
The `FixedRateVault.sol` implements the key steps in from the problem statement above. The vault is an ERC20 contract that
mints a number of LP tokens to the address of a depositor when they deposit some ETH into the vault. The LP is minted at
a 1:1 ratio with respect to the amount of ETH deposited into the pool. 
The vault also exposes other functions for the users to withdraw ETH and claim their rewards. 

An annualized fixed rate of 5% was set in the vault. This amount gets prorated over 365 days and a user can claim 
rewards on their deposits depending on how much time has elapsed since they last deposited.
