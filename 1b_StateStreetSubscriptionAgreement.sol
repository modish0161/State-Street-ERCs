// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StateStreetSubscriptionAgreement is ERC20, Ownable, Pausable, ReentrancyGuard {

    uint256 public immutable totalSupplyCap;
    
    struct Subscription {
        uint256 amount;
        bool confirmed;
        string warranty;
    }

    mapping(address => Subscription) public subscriptions;
    mapping(address => bool) public whitelistedInvestors;

    event Subscribed(address indexed investor, uint256 amount);
    event SubscriptionConfirmed(address indexed investor);
    event WarrantyProvided(address indexed investor, string warranty);

    constructor(string memory name, string memory symbol, uint256 _totalSupplyCap) 
        ERC20(name, symbol) 
    {
        totalSupplyCap = _totalSupplyCap;
    }

    modifier onlyWhitelisted() {
        require(whitelistedInvestors[msg.sender], "Not a whitelisted investor");
        _;
    }

    modifier onlyConfirmed() {
        require(subscriptions[msg.sender].confirmed, "Subscription not confirmed");
        _;
    }

    function whitelistInvestor(address investor) external onlyOwner {
        require(investor != address(0), "Invalid address");
        whitelistedInvestors[investor] = true;
    }

    function subscribe(uint256 amount) external onlyWhitelisted whenNotPaused {
        require(subscriptions[msg.sender].amount == 0, "Already subscribed");
        require(totalSupplyCap >= totalSupply() + amount, "Subscription exceeds supply cap");

        subscriptions[msg.sender] = Subscription({
            amount: amount,
            confirmed: false,
            warranty: ""
        });

        emit Subscribed(msg.sender, amount);
    }

    function confirmSubscription(address investor) external onlyOwner {
        require(whitelistedInvestors[investor], "Investor is not whitelisted");
        require(subscriptions[investor].amount > 0, "No subscription found");
        require(!subscriptions[investor].confirmed, "Subscription already confirmed");

        subscriptions[investor].confirmed = true;

        emit SubscriptionConfirmed(investor);
    }

    function provideWarranty(string memory warranty) external onlyWhitelisted onlyConfirmed whenNotPaused {
        require(bytes(warranty).length > 0, "Warranty cannot be empty");

        subscriptions[msg.sender].warranty = warranty;

        emit WarrantyProvided(msg.sender, warranty);
    }

    function claimTokens() external onlyWhitelisted onlyConfirmed nonReentrant whenNotPaused {
        require(subscriptions[msg.sender].amount > 0, "No tokens to claim");

        uint256 amount = subscriptions[msg.sender].amount;
        subscriptions[msg.sender].amount = 0;

        _mint(msg.sender, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transfer(msg.sender, amount);
    }

    // Prevent accidentally sending Ether to the contract
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
