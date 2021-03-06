// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.0;

interface IARNXMVault {
    function unwrapWnxm() external;
    function buyNxmWithEther(uint256 _minAmount) external payable;
}
