import { ethers } from 'ethers';
import { ReferrerInfo, RefereeInfo } from './ReferalContract';

export interface NetworkStats {
  totalVolume: bigint;
  totalReferrers: number;
  totalReferees: number;
  averageVolumePerReferee: bigint;
  topReferrers: Array<{address: string, volume: bigint}>;
}

export interface PotentialRewards {
  currentRebate: bigint;
  projectedRebate: bigint;
  additionalVolume: bigint;
  additionalReferees: number;
}

export class ReferralHelper {
  // Generate referral link with optional UTM parameters
  static generateReferralLink(
    referrerAddress: string, 
    baseUrl: string,
    params?: {
      source?: string;
      medium?: string;
      campaign?: string;
    }
  ): string {
    const url = new URL(baseUrl);
    url.searchParams.append('ref', referrerAddress);
    
    if (params?.source) url.searchParams.append('utm_source', params.source);
    if (params?.medium) url.searchParams.append('utm_medium', params.medium);
    if (params?.campaign) url.searchParams.append('utm_campaign', params.campaign);
    
    return url.toString();
  }

  // Calculate potential rewards based on additional volume and referees
  static calculatePotentialRewards(
    currentInfo: ReferrerInfo,
    additionalVolume: bigint = 0n,
    additionalReferees: number = 0
  ): PotentialRewards {
    const baseRebatePercentage = 1000n; // 10%
    const rebatePerReferee = 100n; // 1%
    const volumeMultiplierRate = 10n; // 0.1% per 1 ETH

    const currentRebate = this.calculateRebateInternal(
      currentInfo.totalVolume,
      Number(currentInfo.activeReferees)
    );

    const projectedRebate = this.calculateRebateInternal(
      currentInfo.totalVolume + additionalVolume,
      Number(currentInfo.activeReferees) + additionalReferees
    );

    return {
      currentRebate,
      projectedRebate,
      additionalVolume,
      additionalReferees
    };
  }

  private static calculateRebateInternal(
    volume: bigint,
    activeReferees: number
  ): bigint {
    const baseRebate = (BigInt(activeReferees) * 100n) + 1000n; // Base 10% + 1% per referee
    const volumeMultiplier = (volume / ethers.parseEther("1")) * 10n; // 0.1% per 1 ETH
    const finalRebate = baseRebate + volumeMultiplier;
    
    return finalRebate > 5000n ? 5000n : finalRebate; // Cap at 50%
  }

  // Analyze referral network performance
  static async analyzeNetwork(
    referrers: Map<string, ReferrerInfo>,
    referees: Map<string, RefereeInfo>
  ): Promise<NetworkStats> {
    let totalVolume = 0n;
    let totalReferees = 0;
    const referrerVolumes = new Map<string, bigint>();

    // Calculate totals
    for (const [address, info] of referrers) {
      totalVolume += info.totalVolume;
      totalReferees += Number(info.totalReferees);
      referrerVolumes.set(address, info.totalVolume);
    }

    // Sort referrers by volume
    const topReferrers = Array.from(referrerVolumes.entries())
      .sort(([, a], [, b]) => Number(b - a))
      .slice(0, 5)
      .map(([address, volume]) => ({ address, volume }));

    return {
      totalVolume,
      totalReferrers: referrers.size,
      totalReferees,
      averageVolumePerReferee: totalReferees > 0 ? totalVolume / BigInt(totalReferees) : 0n,
      topReferrers
    };
  }

  // Handle retroactive referrals (requires contract support)
  static async createRetroactiveClaim(
    referee: string,
    referrer: string,
    historicalVolume: bigint,
    signature: string
  ): Promise<{
    referee: string;
    referrer: string;
    volume: bigint;
    signature: string;
    timestamp: number;
  }> {
    return {
      referee,
      referrer,
      volume: historicalVolume,
      signature,
      timestamp: Math.floor(Date.now() / 1000)
    };
  }

  // Calculate reward split between multiple referrers
  static calculateRewardSplit(
    totalReward: bigint,
    referrers: Array<{
      address: string;
      weight: number; // Percentage weight (0-100)
    }>
  ): Map<string, bigint> {
    const rewardSplits = new Map<string, bigint>();
    const totalWeight = referrers.reduce((sum, ref) => sum + ref.weight, 0);

    for (const referrer of referrers) {
      const share = (totalReward * BigInt(referrer.weight)) / BigInt(totalWeight);
      rewardSplits.set(referrer.address, share);
    }

    return rewardSplits;
  }
}
