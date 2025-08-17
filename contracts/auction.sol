// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Auction is Ownable {
    IERC20 public PIN = IERC20(0xcB8BCDb991B45bF5D78000a0b5C0A6686cE43790);
    mapping(uint256 => address) public winnerAddress;
    mapping(address => string) public userStrings;
    uint256 public auctionID;
    uint256 public auctionTimestampStarted;
    address public lastWinner;
    uint256 public finalCooldown;
    uint256 public startPrice;
    uint256 public currentPrice;
    address public currentBidder;
    bool public auctionInProgress;
    uint256 public minBidIncrement;
    uint256 public auctionTime;

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
        if (bytes(userStrings[msg.sender]).length == 0) {
            require(bytes(userString).length != 0, "No userString stored or entered");
        } else {
            userStrings[msg.sender] = userString;
        }
        require(auctionInProgress, "No auction in progress");
        require(block.timestamp > auctionTimestampStarted + auctionTime, "Auction has ended");
        require(amount >= currentPrice * (100 + minBidIncrement) / 100, "Bid must be higher than current price + minBidIncrement");
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
        PIN.transferFrom(msg.sender, address(this), amount);
    }

    function cancelAuction() external onlyOwner {
        require(auctionInProgress, "No auction in progress");
        auctionInProgress = false;
        PIN.transfer(currentBidder, currentPrice);
        auctionID++;
    }

    function finalizeAuction() public onlyOwner {
        require(auctionInProgress, "No auction in progress");
        require(block.timestamp >= auctionTimestampStarted + auctionTime, "Auction not yet finished");

        auctionInProgress = false;
        lastWinner = currentBidder;
        winnerAddress[auctionID] = lastWinner;
        auctionID++;
        lastWinner = currentBidder;
    }

    function finalizeAndStartNewAuction() external onlyOwner {
        finalizeAuction();
        startAuction();
    }

    function withdraw() external onlyOwner {
        require(!auctionInProgress, "Auction in progress");
        PIN.transfer(owner(), PIN.balanceOf(address(this)));
    }

    function getWinnerString(uint256 id) public view returns(string memory) {
        require(id <= auctionID, "No auction for ID");
        return userStrings[winnerAddress[id]];
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
