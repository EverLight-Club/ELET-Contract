// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

interface IEverLight {

  // returns the type for tokenId(1 charactor, 2 parts, 3 lucklyStone)
  function queryTokenType(uint256 tokenId) external view returns (uint8 tokenType);
  
  function queryCharacter(uint256 characterId) external view returns (uint256 tokenId, uint32 powerFactor, uint256[] memory tokenList, uint32 totalPower);

}
