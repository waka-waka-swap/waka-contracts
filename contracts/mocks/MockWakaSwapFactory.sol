// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../wakaswap/WakaSwapFactory.sol";

contract MockWakaSwapFactory is WakaSwapFactory {
    constructor(address _feeToSetter) public WakaSwapFactory(_feeToSetter) {}
}