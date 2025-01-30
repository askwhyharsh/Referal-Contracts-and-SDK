# Referal Contracts

- current contract are fulluy uups upgradable
- the contract is dependent on the main volume data source for the traders, which can either be called by dex contract or can be fetched for it from the dex contract, or can be fetched from offchain data source using oracles


## Referal.sol
- This is the main contract that handles the referral system.
- It is fully upgradable and uses UUPS pattern for upgradeability.
- It is also pausable and uses Pausable pattern for pausing the contract.
- It is also ownable and uses Ownable pattern for ownership.
- It is also reentrancy guarded and uses ReentrancyGuard pattern for reentrancy.
