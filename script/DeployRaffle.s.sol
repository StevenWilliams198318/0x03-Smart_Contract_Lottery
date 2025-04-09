// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployRaffleContract();
    }

    function deployRaffleContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // helperConfig contract
        // on local -> we deploy mocks, get local network config
        // on sepolia -> we get sepolia network config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); // helperConfig's NetworkConfig contract

        if (config.subscriptionId == 0) {
            // create subscription ID
            CreateSubscription createSubscriptionContract = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = 
                createSubscriptionContract.createSubscriptionUsingVRFCoordinator(config.vrfCoordinator);
            
            // Fund it!
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        // No need to Broadcast... already broadcasted in Interactions.AddConsumer(). 
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);

        return (raffle, helperConfig);
    }
}
