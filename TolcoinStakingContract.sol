// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TolcoinStaking is Ownable {
    IERC20 public immutable tolcoin;

    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardDebt;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public rewardRatePerSecond = 115740740740; // ~10% APR with 1e18 precision

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor() Ownable(0xcD1710e8A72c95BDd127CC71e1227D8C98e05Aec) {
        tolcoin = IERC20(0xEBd92716d4aAc1ABe6A73a42B5A83a42C145447d);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        _updateReward(msg.sender);

        tolcoin.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].timestamp = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0");
        require(stakes[msg.sender].amount >= amount, "Insufficient stake");

        _updateReward(msg.sender);
        stakes[msg.sender].amount -= amount;
        tolcoin.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external {
        _updateReward(msg.sender);

        uint256 reward = stakes[msg.sender].rewardDebt;
        require(reward > 0, "No reward");

        stakes[msg.sender].rewardDebt = 0;
        tolcoin.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function _updateReward(address account) internal {
        StakeInfo storage stakeInfo = stakes[account];
        if (stakeInfo.amount > 0) {
            uint256 duration = block.timestamp - stakeInfo.timestamp;
            uint256 reward = (stakeInfo.amount * duration * rewardRatePerSecond) / 1e18;
            stakeInfo.rewardDebt += reward;
        }
        stakeInfo.timestamp = block.timestamp;
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRatePerSecond = newRate;
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = tolcoin.balanceOf(address(this));
        tolcoin.transfer(owner(), balance);
    }
}