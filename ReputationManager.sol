// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ReputationManager {
    mapping(address => uint256) public reputation;
    address public auctionContract;
    address public disputeContract;

    modifier onlyAuthorized() {
        require(
            msg.sender == auctionContract || msg.sender == disputeContract,
            "Not authorized"
        );
        _;
    }

    constructor(address _auctionContract, address _disputeContract) {
        auctionContract = _auctionContract;
        disputeContract = _disputeContract;
    }

    function increaseReputation(address user, uint256 amount) external onlyAuthorized {
        reputation[user] += amount;
    }

    function getReputation(address user) external view returns (uint256) {
        return reputation[user];
    }

    function setAuctionContract(address _auctionContract) external {
        require(msg.sender == auctionContract, "Only current auction contract can update");
        auctionContract = _auctionContract;
    }

    function setDisputeContract(address _disputeContract) external {
        require(msg.sender == disputeContract, "Only current dispute contract can update");
        disputeContract = _disputeContract;
    }
}
