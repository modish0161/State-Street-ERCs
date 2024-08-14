// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract InitialTokenOffering is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public tokenPrice;
    uint256 public totalSupply;
    uint256 public tokensSold;
    bool public saleActive;

    mapping(address => uint256) public balances;
    mapping(address => bool) public whitelistedInvestors;
    bytes32 public complianceCriteria;

    event SaleStarted(uint256 startTime, uint256 endTime);
    event TokensPurchased(address indexed investor, uint256 amount);
    event SaleEnded();
    event TokensDistributed(address indexed investor, uint256 amount);
    event TokensClaimed(address indexed investor, uint256 amount);
    event InvestorWhitelisted(address indexed investor);
    event ComplianceChecked(address indexed investor, bool compliant);

    constructor(IERC20 _token, uint256 _tokenPrice, uint256 _totalSupply) {
        token = _token;
        tokenPrice = _tokenPrice;
        totalSupply = _totalSupply;
    }

    modifier onlyDuringSale() {
        require(saleActive, "Sale is not active");
        _;
    }

    function startSale(uint256 startTime, uint256 endTime) external onlyOwner {
        require(!saleActive, "Sale is already active");
        saleActive = true;
        emit SaleStarted(startTime, endTime);
    }

    function buyTokens() external payable onlyDuringSale nonReentrant {
        require(whitelistedInvestors[msg.sender], "Investor is not whitelisted");
        uint256 tokensToBuy = msg.value.div(tokenPrice);
        require(tokensToBuy <= totalSupply.sub(tokensSold), "Not enough tokens available");

        tokensSold = tokensSold.add(tokensToBuy);
        balances[msg.sender] = balances[msg.sender].add(tokensToBuy);

        emit TokensPurchased(msg.sender, tokensToBuy);
    }

    function endSale() external onlyOwner {
        require(saleActive, "Sale is not active");
        saleActive = false;
        emit SaleEnded();
    }

    function distributeTokens(address investor, uint256 amount) external onlyOwner {
        require(balances[investor] >= amount, "Insufficient balance");
        token.transfer(investor, amount);
        balances[investor] = balances[investor].sub(amount);

        emit TokensDistributed(investor, amount);
    }

    function claimTokens() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No tokens to claim");

        balances[msg.sender] = 0;
        token.transfer(msg.sender, amount);

        emit TokensClaimed(msg.sender, amount);
    }

    function whitelistInvestor(address investor) external onlyOwner {
        whitelistedInvestors[investor] = true;
        emit InvestorWhitelisted(investor);
    }

    function setComplianceCriteria(bytes32 criteria) external onlyOwner {
        complianceCriteria = criteria;
    }

    function checkCompliance(address investor) external view returns (bool) {
        return whitelistedInvestors[investor];  // Implement actual compliance logic
    }
}
