// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Auction {

    IERC20 public usdcToken;
    address public owner;

    constructor(address _usdcAddress) {
        usdcToken = IERC20(_usdcAddress);
        owner = msg.sender;
    }

    struct AuctionData {
        address seller;
        uint startTime;
        uint duration;
        uint basePrice;
        uint highestBid;
        address highestBidder;
        bool ended;
        bool deliveryConfirmed;
    }

    mapping(uint => AuctionData) public auctions;
    mapping(uint => mapping(address => uint)) public bids;

    uint public auctionCount;

    event AuctionCreated(uint id, address seller, uint basePrice, uint duration);
    event BidPlaced(uint id, address bidder, uint amount);
    event AuctionEnded(uint id, address winner, uint amount);
    event DeliveryConfirmed(uint id, uint sellerAmount, uint feeAmount);

    function createAuction(uint _durationInSeconds, uint _basePrice) external {
        auctions[auctionCount] = AuctionData({
            seller: msg.sender,
            startTime: block.timestamp,
            duration: _durationInSeconds,
            basePrice: _basePrice,
            highestBid: 0,
            highestBidder: address(0),
            ended: false,
            deliveryConfirmed: false
        });

        emit AuctionCreated(auctionCount, msg.sender, _basePrice, _durationInSeconds);
        auctionCount++;
    }

    function placeBid(uint _id, uint _amount) external {
        AuctionData storage auction = auctions[_id];

        require(block.timestamp <= auction.startTime + auction.duration, "Auction ended");
        require(_amount >= auction.basePrice, "Below base price");
        require(_amount > auction.highestBid, "Bid too low");

        if (auction.highestBid > 0) {
            usdcToken.transfer(auction.highestBidder, auction.highestBid);
        }

        bool success = usdcToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Transfer failed");

        auction.highestBid = _amount;
        auction.highestBidder = msg.sender;
        bids[_id][msg.sender] = _amount;

        emit BidPlaced(_id, msg.sender, _amount);
    }

    function endAuction(uint _id) external {
        AuctionData storage auction = auctions[_id];
        require(block.timestamp > auction.startTime + auction.duration, "Auction still active");
        require(!auction.ended, "Already ended");

        auction.ended = true;
        emit AuctionEnded(_id, auction.highestBidder, auction.highestBid);
    }

    function confirmDelivery(uint _id) external {
        AuctionData storage auction = auctions[_id];
        require(msg.sender == auction.highestBidder, "Not winner");
        require(auction.ended, "Auction not ended");

        auction.deliveryConfirmed = true;

        uint fee = (auction.highestBid * 2) / 100;
        uint sellerAmount = auction.highestBid - fee;

        usdcToken.transfer(owner, fee);
        usdcToken.transfer(auction.seller, sellerAmount);

        emit DeliveryConfirmed(_id, sellerAmount, fee);
    }
}
