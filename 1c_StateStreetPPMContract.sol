// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StateStreetPPMContract is ERC20, Ownable, Pausable, ReentrancyGuard {

    uint256 public immutable totalSupplyCap;
    uint256 public issuedTokens;

    struct Investor {
        bool accredited;
        uint256 subscribedAmount;
        bool subscriptionConfirmed;
        string complianceDetails;
    }

    mapping(address => Investor) public investors;

    event InvestorAccredited(address indexed investor);
    event Subscribed(address indexed investor, uint256 amount);
    event SubscriptionConfirmed(address indexed investor);
    event ComplianceRecorded(address indexed investor, string complianceDetails);
    event TokensIssued(address indexed investor, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 _totalSupplyCap) 
        ERC20(name, symbol) 
    {
        totalSupplyCap = _totalSupplyCap;
    }

    modifier onlyAccredited() {
        require(investors[msg.sender].accredited, "Not an accredited investor");
        _;
    }

    modifier onlyConfirmed() {
        require(investors[msg.sender].subscriptionConfirmed, "Subscription not confirmed");
        _;
    }

    function accreditInvestor(address investor) external onlyOwner {
        require(investor != address(0), "Invalid address");
        investors[investor].accredited = true;

        emit InvestorAccredited(investor);
    }

    function subscribeToPPM(uint256 amount) external onlyAccredited whenNotPaused {
        require(investors[msg.sender].subscribedAmount == 0, "Already subscribed");
        require(totalSupplyCap >= issuedTokens + amount, "Subscription exceeds supply cap");

        investors[msg.sender].subscribedAmount = amount;

        emit Subscribed(msg.sender, amount);
    }

    function confirmSubscription(address investor) external onlyOwner {
        require(investors[investor].accredited, "Investor is not accredited");
        require(investors[investor].subscribedAmount > 0, "No subscription found");
        require(!investors[investor].subscriptionConfirmed, "Subscription already confirmed");

        investors[investor].subscriptionConfirmed = true;

        emit SubscriptionConfirmed(investor);
    }

    function recordInvestorCompliance(address investor, string memory complianceDetails) external onlyOwner {
        require(investors[investor].accredited, "Investor is not accredited");
        require(bytes(complianceDetails).length > 0, "Compliance details cannot be empty");

        investors[investor].complianceDetails = complianceDetails;

        emit ComplianceRecorded(investor, complianceDetails);
    }

    function issueTokens() external onlyAccredited onlyConfirmed nonReentrant whenNotPaused {
        require(investors[msg.sender].subscribedAmount > 0, "No tokens to issue");

        uint256 amount = investors[msg.sender].subscribedAmount;
        investors[msg.sender].subscribedAmount = 0;
        issuedTokens += amount;

        _mint(msg.sender, amount);

        emit TokensIssued(msg.sender, amount);
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
