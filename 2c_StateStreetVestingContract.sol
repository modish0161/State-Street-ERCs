// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StateStreetVestingContract is ERC20, Ownable, Pausable, ReentrancyGuard {

    struct VestingSchedule {
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 amount;
        uint256 released;
        bool revoked;
    }

    mapping(address => VestingSchedule) public vestingSchedules;
    uint256 public totalVestedTokens;

    event VestingScheduleCreated(address indexed beneficiary, uint256 start, uint256 cliff, uint256 duration, uint256 amount);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingScheduleRevoked(address indexed beneficiary);
    event ContractPaused();
    event ContractUnpaused();

    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
    {}

    modifier onlyBeneficiary(address account) {
        require(msg.sender == account || msg.sender == owner(), "Not authorized");
        _;
    }

    function createVestingSchedule(
        address beneficiary,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration,
        uint256 amount
    ) 
        external 
        onlyOwner 
    {
        require(beneficiary != address(0), "Invalid address");
        require(vestingSchedules[beneficiary].amount == 0, "Vesting schedule already exists");
        require(cliffDuration <= duration, "Cliff must be less than or equal to duration");

        vestingSchedules[beneficiary] = VestingSchedule({
            start: start,
            cliff: start + cliffDuration,
            duration: duration,
            amount: amount,
            released: 0,
            revoked: false
        });

        totalVestedTokens += amount;

        emit VestingScheduleCreated(beneficiary, start, start + cliffDuration, duration, amount);
    }

    function releaseTokens(address beneficiary) external onlyBeneficiary(beneficiary) whenNotPaused nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.amount > 0, "No vesting schedule found");
        require(!schedule.revoked, "Vesting schedule is revoked");

        uint256 releasable = calculateReleasableAmount(beneficiary);
        require(releasable > 0, "No tokens are due for release");

        schedule.released += releasable;
        _mint(beneficiary, releasable);

        emit TokensReleased(beneficiary, releasable);
    }

    function revokeVesting(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.amount > 0, "No vesting schedule found");
        require(!schedule.revoked, "Vesting schedule is already revoked");

        schedule.revoked = true;
        uint256 unreleased = schedule.amount - schedule.released;
        totalVestedTokens -= unreleased;

        emit VestingScheduleRevoked(beneficiary);
    }

    function calculateReleasableAmount(address beneficiary) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (block.timestamp < schedule.cliff || schedule.revoked) {
            return 0;
        } else if (block.timestamp >= schedule.start + schedule.duration) {
            return schedule.amount - schedule.released;
        } else {
            return (schedule.amount * (block.timestamp - schedule.start)) / schedule.duration - schedule.released;
        }
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
