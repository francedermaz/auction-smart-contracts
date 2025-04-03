// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    address public backend;
    uint256 public disputeCount;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => bool) public authorizedVoters;

    event DisputeOpened(uint256 disputeId, uint256 auctionId, address buyer, string reason);
    event Voted(uint256 disputeId, address voter, bool favorBuyer);
    event DisputeResolved(uint256 disputeId, bool favorBuyer);
    event VoterAuthorized(address voter);

    constructor() {
        backend = msg.sender;
    }

    modifier onlyBackend() {
        require(msg.sender == backend, "Only backend can authorize");
        _;
    }

    modifier onlyAuthorizedVoter() {
        require(authorizedVoters[msg.sender], "Not authorized to vote");
        _;
    }

    function authorizeVoter(address wallet) external onlyBackend {
        authorizedVoters[wallet] = true;
        emit VoterAuthorized(wallet);
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

    function voteDispute(uint256 _disputeId, bool _favorBuyer) external onlyAuthorizedVoter {
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

    // Admin fallback: allows the backend to resolve disputes manually if necessary
    function resolveDisputeAsBackend(uint256 _disputeId, bool _favorBuyer) external onlyBackend {
        Dispute storage d = disputes[_disputeId];
        require(!d.resolved, "Already resolved");

        d.resolved = true;
        d.favorBuyer = _favorBuyer;

        emit DisputeResolved(_disputeId, _favorBuyer);
    }
}
