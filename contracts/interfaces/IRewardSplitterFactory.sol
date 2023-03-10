// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IRewardSplitterFactory {
    error Factory__ExecutionFailed();

    event NewInstance(address indexed clone);
}
