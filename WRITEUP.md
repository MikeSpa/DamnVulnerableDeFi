# Write Up

## 1) Unstoppable

Send some token outside of the depositeToken method so this line:
- `assert(poolBalance == balanceBefore);`

fails and no one can use the contract anymore.

## 2) Naive Receiver
*Flash loan*

We can call `flashloan()` from any address, so we just need to create a contract that will call this fct on behalf of the victim naiveReceiverLenderPool contract 10x so the fee will empty the contract.:

` function attack(address victim) public { for (int256 i = 0; i < 10; i++) { pool.flashLoan(victim, 1); } `

## 3) Truster
*Flash loan*

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
*Flash loan*

This flash loan pool allow users to deposit and withdraw money. The `flashloan()` function check at the end whether the balance after is the same as at the start of the flash loan. But since we can deposit (and withdraw) money into the contract ourselves, we simply use the flash loan to make a deposit to the contract. The `flashloan()` fct will confirm that the money is back in the contract but the contract has register our deposit and will now let us withdraw it.

## 5) The Rewarder
*Flash loan*

Pretty simple, we use a flash loan to deposit a huge amount of DVT into the reward pool and gain most of the reward token.

## 6) Selfie
*Flash loan | Governance DAO*

We can see in `_hasEnoughVotes()` that need to have a majority of vote to propose an action. We borrow the governance token with our flash loan and now that we have over 50% of the supply we create a new snapshot of our balance so we can then execute an action. We choose to `drainAllFunds()` which will transfer all the funds to our account. 2 days later, the proposed action gets executed and we receive our money.

## 7) Compromised
*Private key*

The website give us two string:
```
4d 48 68 6a 4e 6a 63 34 5a 57 59 78 59 57 45 30 4e 54 5a 6b 59 54 59 31 59 7a 5a 6d 59 7a 55 34 4e 6a 46 6b 4e 44 51 34 4f 54 4a 6a 5a 47 5a 68 59 7a 42 6a 4e 6d 4d 34 59 7a 49 31 4e 6a 42 69 5a 6a 42 6a 4f 57 5a 69 59 32 52 68 5a 54 4a 6d 4e 44 63 7a 4e 57 45 35

4d 48 67 79 4d 44 67 79 4e 44 4a 6a 4e 44 42 68 59 32 52 6d 59 54 6c 6c 5a 44 67 34 4f 57 55 32 4f 44 56 6a 4d 6a 4d 31 4e 44 64 68 59 32 4a 6c 5a 44 6c 69 5a 57 5a 6a 4e 6a 41 7a 4e 7a 46 6c 4f 54 67 33 4e 57 5a 69 59 32 51 33 4d 7a 59 7a 4e 44 42 69 59 6a 51 34

```
We convert these two hexadecimal string to ascii and obtain:
```
MHhjNjc4ZWYxYWE0NTZkYTY1YzZmYzU4NjFkNDQ4OTJjZGZhYzBjNmM4YzI1NjBiZjBjOWZiY2RhZTJmNDczNWE5
MHgyMDgyNDJjNDBhY2RmYTllZDg4OWU2ODVjMjM1NDdhY2JlZDliZWZjNjAzNzFlOTg3NWZiY2Q3MzYzNDBiYjQ4
```
Then convert these two string from base64 to ascii and we get two private keys:
```
0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9
0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48
```
The privates keys belong to two of the trusted oracles. Once we have access to two of the three oracles, we simply lower the price of the NFT before buying one and then raise the price to the balance of the exchange and sell the nft to drain all ETH fro m the contract.

## 8) Puppet 
*Uniswap liquidity pool*

We need to take all token from the lending pool. To withdraw the token, we need to deposit a collaterl of ETH. The price of DVT per ETH is determined by a uniswap exchange.
We first need to devalue the DVT token on uniswap. Once that is done, we can borrow all the DVT in the lending pool with just under 10 ETH. We then deposit the DVT in uniswap to get ETH back and revalue the DVT.

## 9) Puppet v2
*Uniswap V2 liquidity pool | Uniswap oracle*

Once again we need to take all token from the lending pool. The `PuppetV2Pool.sol` is similar to the previous contract. The main differene is how the value of token is calculated. Instead of using the Pair balance, it uses the `quote()` fct for the `UniswapV2Library.sol`. The attack stay the same though, we need to devalue the DVT token so we can borrow WETH cheaply. We first swap DVT for WETH and devalue the WETH token. We then borrow the WETH.

## 10) Free Rider
*ERC721 | NFT Marketplace | Unisawp V2 flash swap*

### Vulnerabilities
The private `_buyOne()` function handle the check to be sure we send a sufficient amount of ether when we call the public `buyMany()` function. Except `buyMany()` call `_buyOne()` several time and never update the value we sent so we can sent 15 ether and buy all NFT for the price of one. There is a second vulnerability in this function. It first transfer the NFT to the buyer:
```
// transfer from seller to buyer
token.safeTransferFrom(token.ownerOf(tokenId), msg.sender, tokenId);
```
and then pay the seller:
```
// pay seller
payable(token.ownerOf(tokenId)).sendValue(priceToPay);
```
or more precisely, pay the owner of the NFT. The problem is that the current owner of the NFT is no longer the seller but the buyer, i.e. us.

### The Attack

We only need to get 15 ether. We will then be able to buy all NFTs and get paid for each one.
To get 15 ether we will first make a swap on the uniswap DVT-WETH liquidity pair. Then we will change that WETH in ETH. Once we have 15 ETH, we can buy all 6 NFT for 15 ETH and the marketplace will send our attack contract 6 NFTs and 90 ETH. We then change 15 ETH in WETH to repay the liquidity pair (plus a small fee). We can then send those 6 NFT to the buyer and get 45 ETH in exchange. We finally withdraw the 75 ETH from our contract.

In the end, we gain -15 + 90 + 45 = 120 ether for the cost of a few transaction and a 3% fee on uniswap for our 15 eth flash loan, the buyer got 6 NFTs for 45 ether, the marketplace lost 75 ether and the seller lost all of their NFTs.

[Uniswap Flash Swap](https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/using-flash-swaps)