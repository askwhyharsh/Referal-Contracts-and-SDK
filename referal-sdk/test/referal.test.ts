import { ethers } from 'ethers';
import { ReferalSDK, ReferrerInfo } from '../src/index';
import { jest, expect, beforeEach, describe, test, beforeAll, afterAll } from '@jest/globals';
import * as dotenv from 'dotenv';
dotenv.config();

describe('ReferalSDK', () => {
  let sdk: ReferalSDK;
  let provider: ethers.Provider;
  let signer: ethers.Signer;
  let contractAddress: string;

  beforeAll(async () => {
    // For Anvil, default RPC URL is http://127.0.0.1:8545
    provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545');
    
    // Anvil's default first private key
    const ANVIL_PRIVATE_KEY = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
    signer = new ethers.Wallet(ANVIL_PRIVATE_KEY, provider);
    
    if (!process.env.CONTRACT_ADDRESS) {
      throw new Error('CONTRACT_ADDRESS not found in .env file');
    }
    
    contractAddress = process.env.CONTRACT_ADDRESS;
    sdk = new ReferalSDK(provider, contractAddress);
  });

  afterAll(async () => {
    // Close the provider connection
    await provider.destroy();
  });

  describe('Read Methods', () => {
    test('getReferrerInfo returns data', async () => {
      const result = await sdk.getReferrerInfo(await signer.getAddress());
      
      expect(result).toBeDefined();
      expect(typeof result.totalReferees).toBe('bigint');
      expect(typeof result.activeReferees).toBe('bigint');
      expect(typeof result.totalVolume).toBe('bigint');
      expect(typeof result.earnedRewards).toBe('bigint');
      expect(typeof result.claimedRewards).toBe('bigint');
    });

    test('getRefereeInfo returns data', async () => {
      const result = await sdk.getRefereeInfo(await signer.getAddress());
      
      expect(result).toBeDefined();
      expect(typeof result.tradingVolume).toBe('bigint');
      expect(typeof result.lastTradeTimestamp).toBe('bigint');
      expect(typeof result.isActive).toBe('boolean');
      expect(ethers.isAddress(result.referrer)).toBe(true);
    });

    test('isRegistered returns boolean', async () => {
      const result = await sdk.isRegistered(await signer.getAddress());
      expect(typeof result).toBe('boolean');
    });

    test('calculateRebate returns amount', async () => {
      const result = await sdk.calculateRebate(await signer.getAddress());
      expect(typeof result).toBe('bigint');
    });
  });

  describe('Write Methods', () => {
    beforeEach(() => {
      sdk.connect(signer);
    });

    test('registerReferral fails when referring self', async () => {
      const selfAddress = await signer.getAddress();
      await expect(sdk.registerReferral(selfAddress))
        .rejects.toThrow('Cannot refer yourself');
    });

    test('registerReferral executes successfully with different address', async () => {
      const referrerAddress = '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC';
      const tx = await sdk.registerReferral(referrerAddress);
      await tx.wait();
      expect(tx.hash).toBeDefined();
    });

    test('updateVolume executes successfully', async () => {
      const trader = await signer.getAddress();
      const volume = BigInt(1000);
      
      const tx = await sdk.updateVolume(trader, volume);
      await tx.wait();
      expect(tx.hash).toBeDefined();
    });

    test('claimRewards executes successfully when rewards are available', async () => {
      const referrerInfo = await sdk.getReferrerInfo(await signer.getAddress());
      const unclaimedRewards = referrerInfo.earnedRewards - referrerInfo.claimedRewards;
      
      if (unclaimedRewards > 0n) {
        const tx = await sdk.claimRewards();
        await tx.wait();
        expect(tx.hash).toBeDefined();
      } else {
        console.log('Skipping claim rewards test - no rewards available');
      }
    });
  });

  test('connect returns instance of SDK', () => {
    const connectedSDK = sdk.connect(signer);
    expect(connectedSDK).toBeInstanceOf(ReferalSDK);
  });
});
