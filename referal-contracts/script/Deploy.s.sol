// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {Referal} from "../src/Referal.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";
contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        Referal implementation = new Referal();
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            Referal.initialize.selector,
            1000,   // baseRebatePercentage (10%)
            100,    // rebatePerReferee (1%)
            10      // volumeMultiplierRate (0.1% per 1 ETH)
        );

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        // Log the addresses
        console.log("Implementation deployed to:", address(implementation));
        console.log("Proxy deployed to:", address(proxy));

        vm.stopBroadcast();
    }
}
