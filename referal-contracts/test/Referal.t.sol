// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Referal} from "../src/Referal.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
contract ReferalTest is Test {
    Referal public referal;
    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // Deploy implementation
        Referal implementation = new Referal();
        
        // Deploy proxy with initialization parameters
        bytes memory initData = abi.encodeWithSelector(
            Referal.initialize.selector,
            1000,   // baseRebatePercentage (10%)
            100,    // rebatePerReferee (1%)
            10      // volumeMultiplierRate (0.1% per 1 ETH)
        );
        vm.prank(owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        
        // Setup referal instance pointing to proxy
        referal = Referal(payable(address(proxy)));
    }

    function test_Initialize() public {
        assertEq(referal.owner(), address(this));
        assertEq(referal.baseRebatePercentage(), 1000);
        assertEq(referal.rebatePerReferee(), 100);
        assertEq(referal.volumeMultiplierRate(), 10);
    }

    function testFuzz_RegisterReferral(address referrer) public {
        vm.assume(referrer != address(0) && referrer != alice);
        
        vm.prank(alice);
        referal.registerReferral(referrer);

        (address storedReferrer, uint256 volume, uint256 lastTrade, bool isActive) = referal.referees(alice);
        assertEq(storedReferrer, referrer);
        assertTrue(isActive);
        assertTrue(referal.isRegistered(alice));
    }

    function test_RegisterReferral_RevertIfAlreadyRegistered() public {
        vm.startPrank(alice);
        referal.registerReferral(bob);
        
        vm.expectRevert("Already registered");
        referal.registerReferral(charlie);
        vm.stopPrank();
    }

    function test_RegisterReferral_RevertIfSelfReferral() public {
        vm.prank(alice);
        vm.expectRevert("Cannot refer yourself");
        referal.registerReferral(alice);
    }

    function test_RegisterReferral_RevertIfZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert("Invalid referrer");
        referal.registerReferral(address(0));
    }

    function test_UpdateVolume() public {
        // Setup referral relationship
        vm.prank(alice);
        referal.registerReferral(bob);

        // Update volume
        vm.prank(owner);
        referal.updateVolume(alice, 100);

        // Check referee's volume
        (,uint256 volume,,) = referal.referees(alice);
        assertEq(volume, 100);

        // Check referrer's total volume
        (,, uint256 totalVolume,,) = referal.referrers(bob);
        assertEq(totalVolume, 100);
    }

    function test_UpdateVolume_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        referal.updateVolume(bob, 100);
    }

    function test_CalculateRebate() public {
        // Register multiple referees for bob
        vm.prank(alice);
        referal.registerReferral(bob);
        
        vm.prank(charlie);
        referal.registerReferral(bob);

        // Update volume
        vm.startPrank(owner);
        referal.updateVolume(alice, 2 ether);
        referal.updateVolume(charlie, 3 ether);
        vm.stopPrank();

        uint256 rebate = referal.calculateRebate(bob);
        // Base rebate: 1000 (base) + (2 * 100) (per referee) = 1200
        // Volume multiplier: (5 ETH * 10) = 50
        // Total expected: 1250
        assertEq(rebate, 1250);
    }

    function test_CalculateRebate_DifferentParameters() public {
        // Deploy new implementation with different parameters
        Referal newImplementation = new Referal();
        bytes memory initData = abi.encodeWithSelector(
            Referal.initialize.selector,
            2000,   // baseRebatePercentage (20%)
            200,    // rebatePerReferee (2%)
            20      // volumeMultiplierRate (0.2% per 1 ETH)
        );
        vm.prank(owner);
        ERC1967Proxy newProxy = new ERC1967Proxy(address(newImplementation), initData);
        Referal newReferal = Referal(payable(address(newProxy)));

        // Register multiple referees for bob
        vm.prank(alice);
        newReferal.registerReferral(bob);
        
        vm.prank(charlie);
        newReferal.registerReferral(bob);

        // Update volume
        vm.startPrank(owner);
        newReferal.updateVolume(alice, 2 ether);
        newReferal.updateVolume(charlie, 3 ether);
        vm.stopPrank();

        uint256 rebate = newReferal.calculateRebate(bob);
        // Base rebate: 2000 (base) + (2 * 200) (per referee) = 2400
        // Volume multiplier: (5 ETH * 20) = 100
        // Total expected: 2500
        assertEq(rebate, 2500);
    }

    function test_ClaimRewards() public {
        // Setup: Give contract some ETH for rewards
        vm.deal(address(referal), 10 ether);
        
        // Setup referral and generate some rewards
        vm.prank(alice);
        referal.registerReferral(bob);

        // Simulate some earned rewards
        // Note: In real contract, you'd need a way to set earned rewards
        // This test might need modification based on how rewards are actually calculated

        // Test claiming rewards
        uint256 bobBalanceBefore = bob.balance;
        
        vm.prank(bob);
        vm.expectRevert("No rewards to claim");
        referal.claimRewards();
    }

    function test_CanBothReferrerAndReferee() public {
        // First, Alice registers with Bob as her referrer
        vm.prank(alice);
        referal.registerReferral(bob);

        // Then Charlie registers with Alice as his referrer
        vm.prank(charlie);
        referal.registerReferral(alice);

        // Verify Alice is a referee of Bob
        (address aliceReferrer,,,) = referal.referees(alice);
        assertEq(aliceReferrer, bob);

        // Verify Charlie is a referee of Alice
        (address charlieReferrer,,,) = referal.referees(charlie);
        assertEq(charlieReferrer, alice);

        // Update volumes to verify both roles work
        vm.startPrank(owner);
        // Alice generates volume as a referee
        referal.updateVolume(alice, 1 ether);
        // Charlie generates volume, which should count towards Alice's referrer stats
        referal.updateVolume(charlie, 2 ether);
        vm.stopPrank();

        // Verify Bob's stats as a referrer (from Alice's volume)
        (,, uint256 bobTotalVolume,,) = referal.referrers(bob);
        assertEq(bobTotalVolume, 1 ether);

        // Verify Alice's stats as a referrer (from Charlie's volume)
        (,, uint256 aliceTotalVolume,,) = referal.referrers(alice);
        assertEq(aliceTotalVolume, 2 ether);
    }

    receive() external payable {}
}