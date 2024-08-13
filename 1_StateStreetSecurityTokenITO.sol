// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecurityTokenITO is ERC20, Ownable, Pausable, ReentrancyGuard {
    
    uint256 public immutable totalSupplyCap;
    uint256 public ITOEndTime;
    bool public isITOActive;
    uint256 public totalAllocated;
    
    struct Allocation {
        uint256 amount;
        bool claimed;
    }

    mapping(address => Allocation) public allocations;
    mapping(address => bool) public whitelistedInvestors;

    event ITOStarted(uint256 startTime, uint256 endTime);
    event ITOEnded(uint256 endTime);
    event TokensAllocated(address indexed investor, uint256 amount);
    event TokensClaimed(address indexed investor, uint256 amount);
    event InvestorWhitelisted(address indexed investor);
    
    constructor(string memory name, string memory symbol, uint256 _totalSupplyCap) 
        ERC20(name, symbol) 
    {
        require(_totalSupplyCap > 0, "Total supply cap must be greater than zero");
        totalSupplyCap = _totalSupplyCap;
        isITOActive = false;
    }

    modifier onlyDuringITO() {
        require(isITOActive && block.timestamp < ITOEndTime, "ITO is not active");
        _;
    }

    modifier onlyInvestors() {
        require(whitelistedInvestors[msg.sender], "Not a whitelisted investor");
        _;
    }

    function startITO(uint256 startTime, uint256 endTime) external onlyOwner {
        require(!isITOActive, "ITO is already active");
        require(endTime > startTime, "End time must be later than start time");

        ITOEndTime = endTime;
        isITOActive = true;

        emit ITOStarted(startTime, endTime);
    }

    function endITO() external onlyOwner {
        require(isITOActive, "ITO is not active");
        require(block.timestamp >= ITOEndTime, "ITO end time not reached");

        isITOActive = false;

        emit ITOEnded(ITOEndTime);
    }

    function whitelistInvestor(address investor) external onlyOwner {
        require(investor != address(0), "Invalid address");
        whitelistedInvestors[investor] = true;
        emit InvestorWhitelisted(investor);
    }

    function allocateTokens(address investor, uint256 amount) 
        external 
        onlyOwner 
        onlyDuringITO 
    {
        require(whitelistedInvestors[investor], "Investor is not whitelisted");
        require(totalAllocated + amount <= totalSupplyCap, "Total allocation exceeds cap");

        allocations[investor].amount += amount;
        totalAllocated += amount;

        emit TokensAllocated(investor, amount);
    }

    function claimTokens() external onlyInvestors nonReentrant whenNotPaused {
        require(!isITOActive, "ITO is still active");
        require(allocations[msg.sender].amount > 0, "No tokens to claim");
        require(!allocations[msg.sender].claimed, "Tokens already claimed");

        uint256 amount = allocations[msg.sender].amount;
        allocations[msg.sender].claimed = true;

        _mint(msg.sender, amount);

        emit TokensClaimed(msg.sender, amount);
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
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient token balance");
        IERC20(token).transfer(msg.sender, amount);
    }

    // Prevent accidentally sending Ether to the contract
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
