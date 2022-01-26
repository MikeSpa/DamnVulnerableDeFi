# Write Up

## 1) Unstoppable

Send some token outside of the depositeToken method so this line:
- `assert(poolBalance == balanceBefore);`

fails and no one can use the contract anymore.

## 2) Naive Receiver

We can call `flashloan()` from any address, so we just need to create a contract that will call this fct on behalf of the victim naiveReceiverLenderPool contract 10x so the fee will empty the contract.:

` function attack(address victim) public { for (int256 i = 0; i < 10; i++) { pool.flashLoan(victim, 1); } `


