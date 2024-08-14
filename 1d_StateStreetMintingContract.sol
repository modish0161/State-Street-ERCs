// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StateStreetMintingContract is ERC20, Ownable, Pausable, ReentrancyGuard {

    uint256 public immutable totalSupplyCap;
    uint256 public totalMinted;

    mapping(address => bool) public authorizedMinters;

    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event MinterAuthorized(address indexed account);
    event MinterRevoked(address indexed account);
    event ContractPaused();
    event ContractUnpaused();

    constructor(string memory name, string memory symbol, uint256 _totalSupplyCap) 
        ERC20(name, symbol) 
    {
        totalSupplyCap = _totalSupplyCap;
    }

    modifier onlyAuthorized() {
        require(authorizedMinters[msg.sender], "Not an authorized minter");
        _;
    }

    modifier withinSupplyCap(uint256 amount) {
        require(totalMinted + amount <= totalSupplyCap, "Minting exceeds supply cap");
        _;
    }

    function mintTokens(address to, uint256 amount) 
        external 
        onlyAuthorized 
        withinSupplyCap(amount) 
        whenNotPaused 
        nonReentrant 
    {
        totalMinted += amount;
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function burnTokens(address from, uint256 amount) 
        external 
        onlyAuthorized 
        whenNotPaused 
        nonReentrant 
    {
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

    function authorizeMinter(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        authorizedMinters[account] = true;
        emit MinterAuthorized(account);
    }

    function revokeMinter(address account) external onlyOwner {
        require(authorizedMinters[account], "Account is not an authorized minter");
        authorizedMinters[account] = false;
        emit MinterRevoked(account);
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
