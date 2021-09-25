// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

interface IERC721Proxy {

  function ownerOf(uint256 tokenId) external view returns (address owner);
  
  function queryTokenType(uint256 tokenId) external view returns (uint8 tokenType);
  
  function queryCharacter(uint256 characterId) external view returns (uint256 tokenId, uint32 powerFactor, uint256[] memory tokenList, uint32 totalPower);
}