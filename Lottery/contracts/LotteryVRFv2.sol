// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LotteryVRFV2 is VRFConsumerBaseV2, Ownable {
  VRFCoordinatorV2Interface private immutable COORDINATOR;
  LinkTokenInterface private immutable LINKTOKEN;

  // Your subscription ID.
  uint64 private subscriptionId;

  // Rinkeby coordinator.
  address private constant vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // Rinkeby LINK token contract.
  address private constant link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  bytes32 private constant keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 private constant callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 private constant requestConfirmations = 3;

  // For this example, retrieve 1 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32  private constant numWords =  1;

  uint256 private randNum;

  uint256 public constant minParticipants = 2;
  uint256 public constant maxParticipants = 10;

  address payable[] public participants;
  address payable public lastWinner;

  constructor(uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
    subscriptionId = _subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  function startLottery() external onlyOwner {
    // Will revert if subscription is not set and funded.
    require(participants.length >= minParticipants, "Need more participants to start lottery");
    
    COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    randNum = randomWords[0];
    uint256 winnerIndex = randNum % participants.length;
    lastWinner = participants[winnerIndex];
    lastWinner.transfer(address(this).balance);
    delete participants;
  }

  function participate() external payable {
    require(msg.value == .1 ether, "ticket cost is .1 ether");
    require(participants.length < maxParticipants, "max participants has been reached for this round");

    participants.push(payable(msg.sender));
  }
  
  function getParticipantsCount() external view returns (uint) {
    return participants.length;
  }
}
