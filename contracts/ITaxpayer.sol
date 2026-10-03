// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

interface ITaxpayer {
  function isContract() external view returns (bool);
  function age() external view returns (uint);
  function setTaxAllowance(uint) external;
  function getTaxAllowance() external view returns (uint);
  function isMarried() external view returns (bool);
  function spouse() external view returns (address);
}
