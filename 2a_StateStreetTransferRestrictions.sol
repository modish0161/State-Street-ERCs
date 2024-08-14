// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StateStreetTransferRestrictions is ERC20, Ownable, Pausable, ReentrancyGuard {

    mapping(address => bool) public accreditedInvestors;

    event InvestorAccredited(address indexed account);
    event AccreditationRevoked(address indexed account);
    event ContractPaused();
    event ContractUnpaused();
    event TokensTransferred(address indexed sender, address indexed recipient, uint256 amount);

    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
    {}

    modifier onlyAccredited(address account) {
        require(accreditedInvestors[account], "Not an accredited investor");
        _;
    }

    function transfer(address recipient, uint256 amount) 
        public 
        override 
        onlyAccredited(msg.sender) 
        onlyAccredited(recipient) 
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
        onlyAccredited(sender) 
        onlyAccredited(recipient) 
        whenNotPaused 
        nonReentrant 
        returns (bool) 
    {
        super.transferFrom(sender, recipient, amount);
        emit TokensTransferred(sender, recipient, amount);
        return true;
    }

    function accreditInvestor(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        accreditedInvestors[account] = true;
        emit InvestorAccredited(account);
    }

    function revokeAccreditation(address account) external onlyOwner {
        require(accreditedInvestors[account], "Account is not accredited");
        accreditedInvestors[account] = false;
        emit AccreditationRevoked(account);
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
