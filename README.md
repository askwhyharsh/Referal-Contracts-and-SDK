# Referral System

A simple and flexible referral system built on Ethereum that rewards users for bringing in new traders.

## Overview

The system consists of:
- Smart Contract (`Referal.sol`)
- TypeScript SDK (`referal-sdk`) for easy integration

## How it Works

### 1. Registration
- Users can register as referees by providing a referrer's address
- Each address can only be registered once
- Users cannot refer themselves

### 2. Rewards System
- Referrers earn rewards based on:
  - Base rebate percentage
  - Number of active referees
  - Total trading volume of referees
    - Maximum rebate is capped at 50%

```typescript
import { ReferalSDK } from 'referal-contracts-sdk';
// Initialize
const sdk = new ReferalSDK(provider, contractAddress);
// Register a referral
await sdk.registerReferral(referrerAddress);
// Check referrer stats
const info = await sdk.getReferrerInfo(address);
// Claim rewards
await sdk.connect(signer).claimRewards();

// admin update trading volume
await sdk.connect(signer).updateVolume(address, volume);
```

## Installation

```bash
npm install referal-contracts-sdk
```

