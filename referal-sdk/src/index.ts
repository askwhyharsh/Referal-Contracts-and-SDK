import { ethers } from 'ethers';
import { ReferalContract, ReferrerInfo, RefereeInfo } from './ReferalContract';

export class ReferalSDK {
  private provider: ethers.Provider;
  private contract: ReferalContract;

  constructor(
    provider: ethers.Provider,
    contractAddress: string
  ) {
    this.provider = provider;
    this.contract = new ReferalContract(contractAddress, provider);
  }

  // Connect with a signer for write operations
  connect(signer: ethers.Signer): ReferalSDK {
    this.contract = new ReferalContract(this.contract.address, signer);
    return this;
  }

  // Read methods
  async getReferrerInfo(address: string): Promise<ReferrerInfo> {
    return await this.contract.getReferrerInfo(address);
  }

  async getRefereeInfo(address: string): Promise<RefereeInfo> {
    return await this.contract.getRefereeInfo(address);
  }

  async isRegistered(address: string): Promise<boolean> {
    return await this.contract.isRegistered(address);
  }

  async calculateRebate(referrer: string): Promise<bigint> {
    return await this.contract.calculateRebate(referrer);
  }

  // Write methods
  async registerReferral(referrer: string) {
    return await this.contract.registerReferral(referrer);
  }

  async updateVolume(trader: string, volume: bigint) {
    return await this.contract.updateVolume(trader, volume);
  }

  async claimRewards() {
    return await this.contract.claimRewards();
  }
}

export default ReferalSDK;
export * from './ReferalContract'; 