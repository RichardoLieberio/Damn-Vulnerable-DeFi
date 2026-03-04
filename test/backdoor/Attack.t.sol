// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract Attack {
    function approve(ERC20 _token, address _to, uint256 _amount) external {
        SafeTransferLib.safeApprove(_token, _to, _amount);
    }
}