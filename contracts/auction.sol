// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Auction is Ownable {
    IERC20 public PIN = IERC20(0x0E6dd7EC79912374E4567ed76F8512A8E2343B07);
    mapping(uint256 => address) public winnerAddress;
    mapping(uint256 => uint256) public winnerPrices;
    mapping(uint256 => string) public winnerStrings;
    string public currentString;
    uint256 public auctionID;
    uint256 public auctionTimestampStarted;
    address public lastWinner;
    uint256 public lastWinnerPrice;
    string public lastWinnerString;
    uint256 public finalCooldown;
    uint256 public startPrice;
    uint256 public currentPrice;
    address public currentBidder;
    bool public auctionInProgress;
    uint256 public minBidIncrement;
    uint256 public auctionTime;

    event BidPlaced (
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount
    );

    constructor() Ownable(msg.sender) {
        auctionInProgress = false;
        startPrice = 0;
        minBidIncrement = 10; // 10%
        auctionTime = 24 * 60 * 60; // 24 hours
        finalCooldown = 5 * 60; // 5 minutes
        auctionID = 0;
    }

    function startAuction() public onlyOwner {
        require(!auctionInProgress, "Auction already in progress");
        require(startPrice > 0, "Start price must be set");
        currentBidder = address(0);
        auctionInProgress = true;
        auctionTimestampStarted = block.timestamp;
        currentPrice = startPrice;
    }

    function bid(uint256 amount, string calldata userString) external {
        require(bytes(userString).length > 0);
        require(auctionInProgress, "No auction in progress");
        require(block.timestamp < auctionTimestampStarted + auctionTime, "Auction has ended");
        if (currentPrice == startPrice) {
            require(amount >= startPrice, "Bid must be higher or equal to start price");
        } else {
            require(amount >= currentPrice * (100 + minBidIncrement) / 100, "Bid must be higher than current price + minBidIncrement");
        }
        require(PIN.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(PIN.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        if (currentBidder != address(0)) {
            PIN.transfer(currentBidder, currentPrice);
        }

        if (block.timestamp + finalCooldown > auctionTimestampStarted + auctionTime) {
            auctionTimestampStarted += finalCooldown;
        }

        currentBidder = msg.sender;
        currentPrice = amount;
        currentString = userString;
        PIN.transferFrom(msg.sender, address(this), amount);
        emit BidPlaced(auctionID, msg.sender, amount);
    }

    function cancelAuction() external onlyOwner {
        require(auctionInProgress, "No auction in progress");
        auctionInProgress = false;
        if(currentBidder != address(0)) {
            PIN.transfer(currentBidder, currentPrice);
        }
        auctionID++;
    }

    function finalizeAuction() public onlyOwner {
        require(auctionInProgress, "No auction in progress");
        require(block.timestamp >= auctionTimestampStarted + auctionTime, "Auction not yet finished");

        auctionInProgress = false;
        auctionID++;
        lastWinner = currentBidder;
        lastWinnerPrice = currentPrice;
        lastWinnerString = currentString;
        winnerAddress[auctionID] = lastWinner;
        winnerPrices[auctionID] = currentPrice;
        winnerStrings[auctionID] = currentString;
        if (PIN.balanceOf(address(this)) > 0) {
            withdraw();
        }
    }

    function getLastAuctionDetails() external view returns (address, string memory, uint256) {
        return(lastWinner, winnerStrings[auctionID - 1], lastWinnerPrice);
    }

    function getDetailsById(uint256 auctionId) external view returns (address, string memory, uint256) {
        address winner = winnerAddress[auctionId];
        return(winner, winnerStrings[auctionId], winnerPrices[auctionId]);
    }

    function finalizeAndStartNewAuction() external onlyOwner {
        finalizeAuction();
        startAuction();
    }

    function withdraw() public onlyOwner {
        require(!auctionInProgress, "Auction in progress");
        PIN.transfer(owner(), PIN.balanceOf(address(this)));
    }

    function setStartPrice(uint256 _startPrice) external onlyOwner {
        startPrice = _startPrice;
    }

    function setAuctionTime(uint256 _auctionTime) external onlyOwner {
        auctionTime = _auctionTime;
    }

    function setMinBidIncrement(uint256 _minBidIncrement) external onlyOwner {
        minBidIncrement = _minBidIncrement;
    }

    function setFinalCooldown(uint256 _finalCooldown) external onlyOwner {
        finalCooldown = _finalCooldown;
    }

}
