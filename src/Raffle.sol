// LAYOUT OF CONTRACT:
// version
// imports
// NatSpec Docs
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// LAYOUT OF FUNCTIONS:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// FUNCTIONS FLOW:
// CEI: 1. Checks, 2. Effects(internal contract states), 3. Interactions(external contract interactions) Pattern

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Raffle smart contract
 * @author Steven Williams
 * @notice This contract is for creating a sample Raffle contract
 * @dev Implements ChainLink VRF v2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        RaffleState raffleState
    );
    error Raffle__SendMoreETHToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    /* Type Declarations: enums */
    enum RaffleState {
        OPEN,
        CALCUATING
    }

    /* State Variables */
    // Chainlink VRF Variables
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    // Lottery Variables
    uint256 private immutable i_interval; // @dev The duration of the lottery in seconds
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    RaffleState private s_raffleState;

    /* Events */
    // 0. Rule of thumb: whenever we update a storage variable, we must emit the event
    // 1. Makes migration easier
    // 2. Makes frontend "indexing" easier
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /* Constructor */
    constructor(
        uint256 _entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane, // keyHash
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    /* Public Functions */
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!"); <- legacy
        // require(msg.sender != address(0), Raffle__SendMoreETHToEnterRaffle()); <- available in solidity ^0.8.26, compile with VIR (takes time), and not gas efficient.
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreETHToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender)); // whenever we update a storage variable
        emit RaffleEntered(msg.sender); // we emit the event
    }

    // When should the winner be picked?
    /**
     * @dev This is the function that Chainlink nodes will call to see if the
     * lottery is ready to have a winner picked.
     * The followng should be true in order for upkeepNeeded to be true:
     * 1. The time interval has passed between raffles runs
     * 2. The lottery is open
     * 3. The contract has ETH
     * 4. Implicitly, your subscription has LINK
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ignored
     */

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;

        return (upkeepNeeded, hex"");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                RaffleState(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCUATING;

        // requesting ChainLInk VRF contract, by calling the 'VRF coordinator' contract to call 'requestRandomWords',
        // thorugh inheritance (import and naming contract is the inherited contract)
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash, // Gas price
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit, // Gas limit
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

        emit RequestedRaffleWinner(requestId);

        // 1.0 Get random number
        // 1.1 Request RNG
        // 1.2 Get RNG - Chainlink Oracle will return a random number
        // 2. Use random number to pick a winner
        // 3. Be automatically called
        // 4. Emit event
        // 5. Update storage
        // 6. Return
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Create Getter Functions
     */
    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getEnteredPlayersList()
        external
        view
        returns (address payable[] memory)
    {
        return s_players;
    }

    function getPickedWinner() external view returns (address) {
        return s_recentWinner;
    }
}
