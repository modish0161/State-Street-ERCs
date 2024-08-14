// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StateStreetLockUpContract is ERC20, Ownable, Pausable, ReentrancyGuard {

    mapping(address => uint256) public lockUpPeriods;

    event LockUpPeriodSet(address indexed account, uint256 lockUntil);
    event LockUpPeriodRemoved(address indexed account);
    event ContractPaused();
    event ContractUnpaused();
    event TokensTransferred(address indexed sender, address indexed recipient, uint256 amount);

    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
    {}

    modifier isNotLocked(address account) {
        require(block.timestamp > lockUpPeriods[account], "Account is currently locked");
        _;
    }

    function setLockUpPeriod(address account, uint256 lockUntil) external onlyOwner {
        require(account != address(0), "Invalid address");
        require(lockUntil > block.timestamp, "Lock-up period must be in the future");

        lockUpPeriods[account] = lockUntil;
        emit LockUpPeriodSet(account, lockUntil);
    }

    function removeLockUpPeriod(address account) external onlyOwner {
        require(lockUpPeriods[account] > 0, "No lock-up period set for account");

        lockUpPeriods[account] = 0;
        emit LockUpPeriodRemoved(account);
    }

    function transfer(address recipient, uint256 amount) 
        public 
        override 
        isNotLocked(msg.sender) 
        isNotLocked(recipient) 
        whenNotPaused 
        nonReentrant 
        returns (bool) 
    {
        super.transfer(recipient, amount);
        emit TokensTransferred(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) 
        public 
        override 
        isNotLocked(sender) 
        isNotLocked(recipient) 
        whenNotPaused 
        nonReentrant 
        returns (bool) 
    {
        super.transferFrom(sender, recipient, amount);
        emit TokensTransferred(sender, recipient, amount);
        return true;
    }

    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused();
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
