// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.6;

import '../general/ArmorModule.sol';
import '../general/SafeERC20.sol';
import '../general/BalanceWrapper.sol';
import '../libraries/Math.sol';
import '../libraries/SafeMath.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IRewardManager.sol';

/**
 * @dev RewardManager is nearly the exact same contract as Utilization Farm.
 *      Only difference is the initialize function instead of constructor.
**/

/**
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

contract RewardManager is BalanceWrapper, ArmorModule, IRewardManager{
    using SafeERC20 for IERC20;

    // Reward token is 0 if Ether is the reward.
    IERC20 public rewardToken;
    // address public stakeManager;
    uint256 public constant DURATION = 1 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward, uint256 totalSupply, uint256 timestamp);
    event BalanceAdded(address indexed user, uint256 indexed nftId, uint256 amount, uint256 totalSupply, uint256 timestamp);
    event BalanceWithdrawn(address indexed user, uint256 indexed nftId, uint256 amount, uint256 totalSupply, uint256 timestamp);
    event RewardPaid(address indexed user, uint256 reward, uint256 timestamp);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function initialize(address _armorMaster, address _rewardToken)
      external
      override
    {
        // require(address(stakeManager) == address(0), "Contract is already initialized.");
        initializeModule(_armorMaster);
        rewardToken = IERC20(_rewardToken);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(address _user, uint256 _amount, uint256 _nftId) external override onlyModule("STAKE") updateReward(_user) {
        _addStake(_user, _amount);
        emit BalanceAdded(_user, _nftId, _amount, totalSupply(), block.timestamp);
    }

    function withdraw(address _user, uint256 _amount, uint256 _nftId) public override onlyModule("STAKE") updateReward(_user) {
        _removeStake(_user, _amount);
        emit BalanceWithdrawn(_user, _nftId, _amount, totalSupply(), block.timestamp);
    }

    function getReward(address payable user) public override updateReward(user) doKeep {
        uint256 reward = earned(user);
        if (reward > 0) {
            rewards[user] = 0;
            
            if ( address(rewardToken) == address(0) ) user.transfer(reward);
            else rewardToken.safeTransfer(user, reward);
            
            emit RewardPaid(user, reward, block.timestamp);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        payable
        override
        onlyModule("BALANCE")
        updateReward(address(0))
    {
        //this will make sure tokens are in the reward pool
        if ( address(rewardToken) == address(0) ){
            require(msg.value == reward, "Correct reward was not sent.");
        }
        else {
            require(msg.value == 0, "Do not send ETH");
            rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        }
        
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward, totalSupply(), block.timestamp);
    }
}
