// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StateStreetTokenSplitter is ERC20, Ownable, Pausable, ReentrancyGuard {

    event TokensSplit(address indexed account, uint256 originalAmount, uint256 newAmount, uint256 splitRatio);
    event TokensMerged(address indexed account, uint256 originalAmount, uint256 newAmount, uint256 mergeRatio);
    event ContractPaused();
    event ContractUnpaused();

    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
    {}

    modifier validSplitRatio(uint256 splitRatio) {
        require(splitRatio > 0, "Split ratio must be greater than zero");
        _;
    }

    modifier validMergeRatio(uint256 mergeRatio) {
        require(mergeRatio > 0, "Merge ratio must be greater than zero");
        _;
    }

    function splitTokens(uint256 splitRatio) 
        external 
        validSplitRatio(splitRatio) 
        whenNotPaused 
        nonReentrant 
    {
        uint256 originalAmount = balanceOf(msg.sender);
        require(originalAmount > 0, "No tokens to split");

        uint256 newAmount = originalAmount * splitRatio;
        _burn(msg.sender, originalAmount);
        _mint(msg.sender, newAmount);

        emit TokensSplit(msg.sender, originalAmount, newAmount, splitRatio);
    }

    function mergeTokens(uint256 mergeRatio) 
        external 
        validMergeRatio(mergeRatio) 
        whenNotPaused 
        nonReentrant 
    {
        uint256 originalAmount = balanceOf(msg.sender);
        require(originalAmount >= mergeRatio, "Not enough tokens to merge");

        uint256 newAmount = originalAmount / mergeRatio;
        require(newAmount > 0, "Merge ratio too high, results in zero tokens");

        _burn(msg.sender, originalAmount);
        _mint(msg.sender, newAmount);

        emit TokensMerged(msg.sender, originalAmount, newAmount, mergeRatio);
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
