// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;
interface ILottery {
  function isContract() external view returns (bool);
  function commit(bytes32) external;
  function reveal(uint256) external;
}
