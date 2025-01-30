import { ethers } from 'ethers';

// ABI for the Referal contract
const REFERAL_ABI = [
  "function registerReferral(address referrer) external",
  "function updateVolume(address trader, uint256 volume) external",
  "function calculateRebate(address referrer) public view returns (uint256)",
  "function claimRewards() external",
  "function referrers(address) public view returns (uint256 totalReferees, uint256 activeReferees, uint256 totalVolume, uint256 earnedRewards, uint256 claimedRewards)",
  "function referees(address) public view returns (address referrer, uint256 tradingVolume, uint256 lastTradeTimestamp, bool isActive)",
  "function isRegistered(address) public view returns (bool)"
];

export interface ReferrerInfo {
  totalReferees: bigint;
  activeReferees: bigint;
  totalVolume: bigint;
  earnedRewards: bigint;
  claimedRewards: bigint;
}

export interface RefereeInfo {
  referrer: string;
  tradingVolume: bigint;
  lastTradeTimestamp: bigint;
  isActive: boolean;
}

export class ReferalContract {
  private contract: ethers.Contract;
  public address: string; // contract address for the referrer
  constructor(
    address: string,
    signerOrProvider: ethers.Signer | ethers.Provider
  ) {
    this.address = address;
    this.contract = new ethers.Contract(address, REFERAL_ABI, signerOrProvider);
  }

  async registerReferral(referrer: string) {
    return await this.contract.registerReferral(referrer);
  }

  async updateVolume(trader: string, volume: bigint) {
    return await this.contract.updateVolume(trader, volume);
  }

  async calculateRebate(referrer: string): Promise<bigint> {
    return await this.contract.calculateRebate(referrer);
  }

  async claimRewards() {
    return await this.contract.claimRewards();
  }

  async getReferrerInfo(address: string): Promise<ReferrerInfo> {
    return await this.contract.referrers(address);
  }

  async getRefereeInfo(address: string): Promise<RefereeInfo> {
    return await this.contract.referees(address);
  }

  async isRegistered(address: string): Promise<boolean> {
    return await this.contract.isRegistered(address);
  }
}
