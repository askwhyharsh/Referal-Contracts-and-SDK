// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

contract Referal is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // Constants
    uint256 private constant SCALE = 10000; // For percentage calculations (100% = 10000)
    uint256 private constant MAX_REBATE = 5000; // Maximum 50% rebate

    // Structs
    struct ReferrerInfo { // referrer info
        uint256 totalReferees;
        uint256 activeReferees; 
        uint256 totalVolume;      
        uint256 earnedRewards;
        uint256 claimedRewards;
    }

    struct RefereeInfo { // trader info
        address referrer;
        uint256 tradingVolume;
        uint256 lastTradeTimestamp;
        bool isActive;
    }

    // State variables
    mapping(address => ReferrerInfo) public referrers; // referrer info
    mapping(address => RefereeInfo) public referees; // trader info
    mapping(address => bool) public isRegistered;
    
    // Configurable rebate parameters
    uint256 public baseRebatePercentage;     // Base rebate percentage (e.g., 1000 for 10%)
    uint256 public rebatePerReferee;         // Additional rebate per referee (e.g., 100 for 1%)
    uint256 public volumeMultiplierRate;     // Rate for volume-based multiplier (e.g., 10 for 0.1% per 1 ETH)

    // Events
    event ReferralRegistered(address indexed referrer, address indexed referee);
    event VolumeUpdated(address indexed trader, uint256 volume);
    event RewardsClaimed(address indexed referrer, uint256 amount);
    event ReferralSystemUpgraded(address indexed implementation);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _baseRebatePercentage,
        uint256 _rebatePerReferee,
        uint256 _volumeMultiplierRate
    ) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();

        baseRebatePercentage = _baseRebatePercentage;
        rebatePerReferee = _rebatePerReferee;
        volumeMultiplierRate = _volumeMultiplierRate;
    }

    // Register a new referral
    function registerReferral(address referrer) external {
        require(!isRegistered[msg.sender], "Already registered");
        require(referrer != msg.sender, "Cannot refer yourself");
        require(referrer != address(0), "Invalid referrer");
        
        // Check if referrer is already a referee
        require(referees[referrer].referrer == address(0), "Referrer is already a referee");

        isRegistered[msg.sender] = true;
        
        RefereeInfo storage referee = referees[msg.sender];
        referee.referrer = referrer;
        referee.isActive = true;
        
        ReferrerInfo storage referrerInfo = referrers[referrer];
        referrerInfo.totalReferees++;
        referrerInfo.activeReferees++;

        emit ReferralRegistered(referrer, msg.sender);
    }

    // Update trading volume
    function updateVolume(address trader, uint256 volume) external onlyOwner {
        RefereeInfo storage referee = referees[trader];
        address referrer = referee.referrer;
        
        require(referee.isActive, "Referee not active");
        
        // Added minimum time between trades to prevent wash trading
        require(block.timestamp >= referee.lastTradeTimestamp + 1 hours, "Trading too frequent");
        
        // Added maximum volume per trade to prevent manipulation
        require(volume <= 1000 ether, "Volume too large");

        referee.tradingVolume += volume;
        referee.lastTradeTimestamp = uint32(block.timestamp);

        if (referrer != address(0)) {
            referrers[referrer].totalVolume += volume;
        }

        emit VolumeUpdated(trader, volume);
    }

    // Calculate rebate based on various factors
    function calculateRebate(address referrer) public view returns (uint256) {
        ReferrerInfo storage info = referrers[referrer];
        
        // Base rebate calculation based on number of active referees
        uint256 baseRebate = (info.activeReferees * rebatePerReferee) + baseRebatePercentage;
        
        // Volume multiplier
        uint256 volumeMultiplier = (info.totalVolume / 1e18) * volumeMultiplierRate;
        
        uint256 finalRebate = baseRebate + volumeMultiplier;
        return finalRebate > MAX_REBATE ? MAX_REBATE : finalRebate;
    }

    // Claim rewards
    function claimRewards() external nonReentrant {
        ReferrerInfo storage referrer = referrers[msg.sender];
        require(referrer.earnedRewards > referrer.claimedRewards, "No rewards to claim");
        
        uint256 unclaimedRewards = referrer.earnedRewards - referrer.claimedRewards;
        referrer.claimedRewards = referrer.earnedRewards;
        
        (bool success, ) = msg.sender.call{value: unclaimedRewards}("");
        require(success, "Transfer failed");
        
        emit RewardsClaimed(msg.sender, unclaimedRewards);
    }

    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        emit ReferralSystemUpgraded(newImplementation);
    }

    // Receive function to accept ETH
    receive() external payable {}
}
