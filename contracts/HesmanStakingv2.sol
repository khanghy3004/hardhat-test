// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract HesmanStaking is Ownable, ReentrancyGuard, IERC721Receiver {
  using SafeMath for uint256;
  using SafeERC20 for ERC20; 

  mapping(address => uint256) public stakeBlock;
  mapping(address => uint256) public unstakeBlock;
  mapping(address => uint256[]) public nftIdList;
  mapping(address => bool) public blacklistMap;
  mapping(address => bool) public isStaked;

  // General
  bool public isPause;
  uint256 public benefitPercentPerYear;  // 15
  uint256 public nftToHes;  

  // Token
  ERC20 public hesmanToken; // HES
  address public hesicNftAddress;  // HESIC

  // Time
  // Stake: HESMAN 
  uint256 public startStakeTime;
  uint256 public endStakeTime;
  uint256 public unStakeTime; 
  uint256 public totalUserStaked;
 
  // Event
  event EventUserStake(address user, uint256 numberOfNft, uint256 blockNumber, uint256 amount);
  event EventUserStakeNFT(address indexed user, address nft, uint256 tokenId, uint256 blockNumber);
  event EventUserUnstake(address user, uint256 blockNumber, uint256 amount);
  event EventUserClaimNFT(address indexed user, address nft, uint256 tokenId, uint256 blockNumber);

  constructor(
    address _hesmanToken,
    address _hesicNftAddress,
    uint256 _benefitPercentPerYear,
    uint256 _nftToHes
  ) {
    hesmanToken = ERC20(_hesmanToken);
    hesicNftAddress = _hesicNftAddress;
    benefitPercentPerYear = _benefitPercentPerYear;
    nftToHes = _nftToHes;

    isPause = true; // Mark pause if deploy
  }

  // Modifier
  modifier isRun() {
    require(isPause == false, "Contract is paused");
    _;
  }

  function setPauseContract(bool _status) public onlyOwner {
    isPause = _status;
  }

  function setToken(address _hesmanToken, address _hesicNftAddress) public onlyOwner {
    hesmanToken = ERC20(_hesmanToken);
    hesicNftAddress = _hesicNftAddress;
  }

  function setBlackList(address[] calldata userList) public onlyOwner {
    for (uint256 index = 0; index < userList.length; index++) {
      blacklistMap[userList[index]] = true;
    }
  }

  function removeBlackList(address[] calldata userList) public onlyOwner {
    for (uint256 index = 0; index < userList.length; index++) {
      blacklistMap[userList[index]] = false;
    }
  }

  function setConfig(
        uint256 _startStakeTime,
        uint256 _endStakeTime
    ) public onlyOwner {
    
    require(_startStakeTime < _endStakeTime, "Input time staking invalid");

    startStakeTime = _startStakeTime;
    endStakeTime = _endStakeTime;
    unStakeTime = startStakeTime+1;
  }

  // Staking HESIC to get benefit
  function stakeNft(uint256[] calldata _idNftList) public nonReentrant isRun {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    require(_idNftList.length > 0, "NFTs have to be greater than 0");
    require(_idNftList.length <= 50, "Max 50 NFTs");

    uint256 amountClaim = (block.number - stakeBlock[msg.sender]).mul(nftToHes).mul(nftIdList[msg.sender].length).mul(benefitPercentPerYear).div(100).div(10368000);
    stakeBlock[msg.sender] = block.number;

    for(uint256 index = 0; index < _idNftList.length; index++){
        IERC721(hesicNftAddress).transferFrom(msg.sender, address(this), _idNftList[index]);
        nftIdList[msg.sender].push(_idNftList[index]);

        emit EventUserStakeNFT(msg.sender, hesicNftAddress, _idNftList[index], block.number);
    }

    if(isStaked[msg.sender] == false){
        totalUserStaked++;
    }

    isStaked[msg.sender] = true;
    hesmanToken.safeTransfer(msg.sender, amountClaim);

    emit EventUserStake(msg.sender, _idNftList.length , block.number, amountClaim);

  }

  function unstakeToken(uint256 _amount) public nonReentrant {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    require(_amount <= 50, "Max 50 NFTs");
    require(_amount <= nftIdList[msg.sender].length,"Amount exceeded");

    unstakeBlock[msg.sender] = block.number;
    
    // Calculate benefit based on stake block and unstake block number
    uint256 userNft = nftIdList[msg.sender].length;
    uint256 amountClaim = (unstakeBlock[msg.sender] - stakeBlock[msg.sender]).mul(nftToHes).mul(userNft).mul(benefitPercentPerYear).div(100).div(10368000);
    stakeBlock[msg.sender] = block.number;
    
    // Give back NFT
    for (uint256 index = 0; index < _amount; index++) {
        IERC721(hesicNftAddress).transferFrom(address(this), msg.sender, nftIdList[msg.sender][userNft-index-1]);
        
        emit EventUserClaimNFT(msg.sender, hesicNftAddress, nftIdList[msg.sender][userNft-index-1], block.number); 
    }

    if(_amount == nftIdList[msg.sender].length){
        isStaked[msg.sender] = false;
        totalUserStaked--;
    }

    // remove staked NFTs of user
    for (uint256 index = 0; index < _amount; index++){
        nftIdList[msg.sender].pop();
    }

    hesmanToken.safeTransfer(msg.sender, amountClaim);

    emit EventUserUnstake(msg.sender, block.number, amountClaim);
  }

  function getNftNumber() public view returns(uint256){
    return nftIdList[msg.sender].length;
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
      return this.onERC721Received.selector;
  }

  function emergencyWithdrawSaleToken() external onlyOwner {
      uint256 withdrawAmount = hesmanToken.balanceOf(address(this));
      hesmanToken.transfer(msg.sender, withdrawAmount);
  }

//   function getBenefit() public view returns(uint256 nftTotalGain){ 
//     nftTotalGain = (block.number - stakeBlock[msg.sender]).mul(nftToHes).mul(amount).mul(benefitPercentPerYear).div(100).div(10368000);
//     return nftTotalGain;
//   }

    

}
