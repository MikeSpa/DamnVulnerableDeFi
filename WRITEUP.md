# Write Up

## 1) Unstoppable

Send some token outside of the depositeToken method so this line:
- `assert(poolBalance == balanceBefore);`

fails and no one can use the contract anymore.

## 2) Naive Receiver

We can call `flashloan()` from any address, so we just need to create a contract that will call this fct on behalf of the victim naiveReceiverLenderPool contract 10x so the fee will empty the contract.:

` function attack(address victim) public { for (int256 i = 0; i < 10; i++) { pool.flashLoan(victim, 1); } `

## 3) Truster

The `flashloan()` function in TrusterLenderPool contract has a line that allow us to call a method from any contract with any variable we want: `target.functionCall(data);`
So we simply create a contract that will call this method and use the `approve()` from ERC20 to approve the DVToken: 
```
const abi = ["function approve(address spender, uint256 amount)"];
const interface = new ethers.utils.Interface(abi);
const data = interface.encodeFunctionData("approve", [attackContract.address, TOKENS_IN_POOL]);

await attackContract.attack(0, attacker.address, this.token.address, data);
```
Our attack contract will call this custom function and then simply transfer the token to our account.

## 4) Side Entrance

This flash loan pool allow users to deposit and withdraw money. The `flashloan()` function check at the end whether the balance after is the same as at the start of the flash loan. But since we can deposit (and withdraw) money into the contract ourselves, we simply use the flash loan to make a deposit to the contract. The `flashloan()` fct will confirm that the money is back in the contract but the contract has register our deposit and will now let us withdraw it.