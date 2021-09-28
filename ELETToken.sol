// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Strings.sol";
import "./Governed.sol";
import "./ERC20.sol";
import "./IERC721.sol";
import "./ERC20Burnable.sol";
import "./IERC721Proxy.sol";
import "./IEverLight.sol";

contract ELETToken is Governed, ERC20, ERC20Burnable {
    using SafeMath for uint256;
    using Strings  for uint256;

    uint256 public constant MIN_STAKING_TIME = 6 * 60 * 60 / 2; // 6h * 60m * 60s / 2

    // Contract address for external references.
    IERC721Proxy public erc721Proxy;       
    IEverLight   public everLight;
    bool         public isActive = false;
    string       private _rules = '';

    struct StakingInfo {
       bool initial;
       uint256 tokenId;
       uint256 stakeBn;
    }

    mapping(address => mapping(uint256 => StakingInfo)) private _stakingUserList;
    mapping(uint256 => uint256) private _stakingPowerlist;  // tokenId => power

    event StakeEvent(address indexed from, uint256 characterId, uint256 power, uint256 stakeBn);
    event RedeemEvent(address indexed from, uint256 characterId, uint256 redeemBn);

    constructor(string memory name, string memory symbol, address erc721ProxyAddr, address everLightAddr) ERC20(name, symbol) {
        Governed._initialize(msg.sender);
        erc721Proxy = IERC721Proxy(erc721ProxyAddr);
        everLight = IEverLight(everLightAddr);
    }

    // stake character 
    function stake(uint256 tokenId) external {
        require(isActive, 'Contract is not active');
        require(address(erc721Proxy) != address(0x0), "erc721Proxy not setting");
        require(address(everLight) != address(0x0), "everLight not setting");
        require(erc721Proxy.ownerOf(tokenId) == msg.sender, "tokenId no owner");
        require(!_stakingUserList[msg.sender][tokenId].initial, "already stake");

        // check: the type for tokenId(1-character,2-parts, 3-luckStone)

        uint256 tokenType = everLight.queryTokenType(tokenId);
        require(tokenType == 1, "Not be character");
        (, , , uint32 totalPower ) = everLight.queryCharacter(tokenId);

        // check: execute transfer 
        _transferERC721(address(erc721Proxy), msg.sender, address(this), tokenId);

        _stakingUserList[msg.sender][tokenId] = StakingInfo(true, tokenId, block.number);
        _stakingPowerlist[tokenId] = totalPower;

        emit StakeEvent(msg.sender, tokenId, totalPower, block.number);
    }

    function redeem(uint256 tokenId) external {
        require(isActive, 'Contract is not active');
        require(_stakingUserList[msg.sender][tokenId].tokenId == tokenId, "invalid tokenId");
        require(_stakingUserList[msg.sender][tokenId].initial, "already redeem");
        require(erc721Proxy.ownerOf(tokenId) == address(this), "not owner for contract");

        // calc stake time.
        //uint256 currentBn = block.number;
        //uint256 stakingBn = _stakingUserList[msg.sender][tokenId].stakeBn;
        uint256 intervalBn = block.number - _stakingUserList[msg.sender][tokenId].stakeBn;
        require(intervalBn >= MIN_STAKING_TIME, "Insufficient stake time");
        
        // Calculate how many coins the user can get.
        // power * stakeTime(6h) * 0.0015 / 4
        uint256 times = intervalBn / MIN_STAKING_TIME;
        uint256 coinAmount =  _stakingPowerlist[tokenId].mul(times).mul(15).div(4).div(1000);

        // mint
        coinAmount = coinAmount * 10 ** decimals();
        _mint(msg.sender, coinAmount);

        // transfer character
        _transferERC721(address(erc721Proxy), address(this), msg.sender, tokenId);
        
        delete _stakingUserList[msg.sender][tokenId];
        delete _stakingPowerlist[tokenId];

        emit RedeemEvent(msg.sender, tokenId, block.number);
    }

    function setIsActive(bool _isActive) external onlyGovernor {
        isActive = _isActive;
    }

    function setRules(string memory data) external onlyGovernor {
        _rules = data;
    }

    function rules() external view returns (string memory) {
        // rules: {"minPower": MIN_STAKING_POWER, "curPR": currentWinningPR, "desc":""}
        return _rules;
    }

    function stakeBlockNumber(address account, uint256 tokenId) external view returns (uint256) {
       return _stakingUserList[account][tokenId].stakeBn;
    }


    function _transferERC721(address contractAddress, address from, address to, uint256 tokenId) internal {
        address ownerBefore = IERC721(contractAddress).ownerOf(tokenId);
        require(ownerBefore == from, "Not own token");
        
        IERC721(contractAddress).transferFrom(from, to, tokenId);

        address ownerAfter = IERC721(contractAddress).ownerOf(tokenId);
        require(ownerAfter == to, "Transfer failed");
    }
}