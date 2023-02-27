// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IRewardSplitter {
    error NotAuthorized();
    event RewardsSplitted();

    function slittingRewards(address[] calldata tokens_, bool withNative_) external;

    function configFees(address[] calldata recipients_, uint256[] calldata percents_) external;

    function withdraw(address token_, address account_, uint256 amount_) external;
}
