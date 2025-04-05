// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ReputationManager.sol";

contract DisputeManager {
    struct Dispute {
        uint256 auctionId;
        address buyer;
        string reason;
        uint256 voteCount;
        uint256 voteThreshold;
        bool resolved;
        bool favorBuyer;
        mapping(address => bool) voted;
    }

    ReputationManager public reputationManager;
    address public backend;
    uint256 public disputeCount;
    uint256 public minReputationToVote = 10;

    mapping(uint256 => Dispute) public disputes;

    event DisputeOpened(uint256 disputeId, uint256 auctionId, address buyer, string reason);
    event Voted(uint256 disputeId, address voter, bool favorBuyer);
    event DisputeResolved(uint256 disputeId, bool favorBuyer);

    constructor(address _reputationManager) {
        backend = msg.sender;
        reputationManager = ReputationManager(_reputationManager);
    }

    modifier onlyBackend() {
        require(msg.sender == backend, "Only backend");
        _;
    }

    modifier onlyReputableVoter() {
        uint256 rep = reputationManager.getReputation(msg.sender);
        require(rep >= minReputationToVote, "Not enough reputation to vote");
        _;
    }

    function openDispute(uint256 _auctionId, string calldata _reason) external {
        Dispute storage d = disputes[disputeCount];
        d.auctionId = _auctionId;
        d.buyer = msg.sender;
        d.reason = _reason;
        d.voteThreshold = 3;

        emit DisputeOpened(disputeCount, _auctionId, msg.sender, _reason);
        disputeCount++;
    }

    function voteDispute(uint256 _disputeId, bool _favorBuyer) external onlyReputableVoter {
        Dispute storage d = disputes[_disputeId];
        require(!d.resolved, "Dispute already resolved");
        require(!d.voted[msg.sender], "Already voted");

        if (_favorBuyer) {
            d.voteCount++;
        }

        d.voted[msg.sender] = true;

        emit Voted(_disputeId, msg.sender, _favorBuyer);

        if (d.voteCount >= d.voteThreshold) {
            d.resolved = true;
            d.favorBuyer = true;
            emit DisputeResolved(_disputeId, true);
        }
    }

    function resolveDisputeAsBackend(uint256 _disputeId, bool _favorBuyer) external onlyBackend {
        Dispute storage d = disputes[_disputeId];
        require(!d.resolved, "Already resolved");

        d.resolved = true;
        d.favorBuyer = _favorBuyer;

        emit DisputeResolved(_disputeId, _favorBuyer);
    }

    function updateMinReputation(uint256 _newRep) external onlyBackend {
        minReputationToVote = _newRep;
    }
}
