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
import "hardhat/console.sol";

contract HesmanStaking is Ownable, ReentrancyGuard, IERC721Receiver {
  using SafeMath for uint256;
  using SafeERC20 for ERC20; 

// store number of NFT, its id and stake block number of user
  struct userNftDetail {
    uint256 stakeBlock;
    uint256 nftId;
  }

  // Wallet
  mapping(address => bool) public stakedUserMap;
  mapping(address => userNftDetail[]) public userNftMap;
  mapping(address => bool) public blacklistMap;
  mapping(address => uint256) public amountClaim;  // total amount of HES which user can claim
  uint256 public totalUserStaked;

  // General
  bool public isPause;
  uint256 generalDec = 10 ** 18;
  uint256 public benefitPercentPerYear;  // 15
  uint256 public nftPrice;  

  // Token
  ERC20 public hesmanToken; // HES
  address public hesicNftAddress;  // HESIC

  // Time
  // Stake: HESMAN 
  uint256 public startStakeTime;
  uint256 public endStakeTime;
  uint256 public unStakeTime; 
 
  // Event
  event EventUserStake(address user, uint256 numberOfNft, uint256 time);
  event EventUserClaim(address user, uint256 amount, uint256 time);
  event EventUserUnstake(address user, uint256 time);
  event EventUserClaimNFT(address indexed user, address nft, uint256 tokenId, uint256 time);

  constructor(
    address _hesmanToken,
    address _hesicNftAddress,
    uint256 _benefitPercentPerYear,
    uint256 _nftPrice
  ) {
    hesmanToken = ERC20(_hesmanToken);
    hesicNftAddress = _hesicNftAddress;
    benefitPercentPerYear = _benefitPercentPerYear;
    nftPrice = _nftPrice;

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

    if (stakedUserMap[msg.sender] == false) {
      stakedUserMap[msg.sender] = true;
      totalUserStaked++;
    }

    userNftDetail memory nftDetail;

    for (uint256 index = 0; index < _idNftList.length; index++) {
      nftDetail.stakeBlock = block.number;
      nftDetail.nftId = _idNftList[index];
      userNftMap[msg.sender].push(nftDetail);
      IERC721(hesicNftAddress).transferFrom(msg.sender, address(this), _idNftList[index]);
    }

    emit EventUserStake(msg.sender, _idNftList.length , block.number);
  }

  function unstakeToken(uint256 _amountNft) public nonReentrant {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");

    uint256 nftTotalGain;  
    uint256 userNft = userNftMap[msg.sender].length;
    
    require(userNft > 0, "You did not stake before");

    console.log("userNft in unstake", userNft);
    // Calculate benefit based on stake block and unstake block number
    for (uint256 index = 0; index < _amountNft; index++) {
      uint256 numberOfBlocks = block.number - userNftMap[msg.sender][index].stakeBlock;
      console.log("numberOfBlocks", numberOfBlocks);
      nftTotalGain = numberOfBlocks.mul(nftPrice);
      amountClaim[msg.sender] += nftTotalGain.mul(benefitPercentPerYear).div(100).div(10368000);
      console.log(nftTotalGain, nftTotalGain.mul(benefitPercentPerYear).div(100).div(10368000));
    }
    // unstake NFT
    for (uint256 index = 0; index < _amountNft; index++) {
      userNftDetail storage nftDetail = userNftMap[msg.sender][index];
      IERC721(hesicNftAddress).transferFrom(address(this), msg.sender, nftDetail.nftId);
      console.log("nftId", nftDetail.nftId);
    }
    // Remove first NFT from userNftMap
    for (uint256 index = 0; index < _amountNft; index++) {
      userNftMap[msg.sender][index] = userNftMap[msg.sender][userNftMap[msg.sender].length - 1];
      userNftMap[msg.sender].pop();
    }

    console.log('ammount:', amountClaim[msg.sender]);

    emit EventUserUnstake(msg.sender, block.number);
  }

  // claim HES 
  function claimToken() public nonReentrant isRun {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    
    uint256 nftTotalGain;  
    uint256 userNft = userNftMap[msg.sender].length;
    console.log("userNft in claim", userNft);
    for (uint256 index = 0; index < userNft; index++) {
      uint256 numberOfBlocks = block.number - userNftMap[msg.sender][index].stakeBlock;
      console.log("numberOfBlocks", numberOfBlocks);

      nftTotalGain = numberOfBlocks.mul(nftPrice);
      amountClaim[msg.sender] += nftTotalGain.mul(benefitPercentPerYear).div(100).div(10368000);
      console.log(nftTotalGain, nftTotalGain.mul(benefitPercentPerYear).div(100).div(10368000));
      userNftMap[msg.sender][index].stakeBlock = block.number;
    }

    console.log('ammount:', amountClaim[msg.sender]);

    uint256 amount = amountClaim[msg.sender];
    hesmanToken.safeTransfer(msg.sender, amount);
    amountClaim[msg.sender] = 0;  // reset amount after claim

    emit EventUserClaim(msg.sender, amount, block.timestamp);
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
      return this.onERC721Received.selector;
  }

  function emergencyWithdrawSaleToken() external onlyOwner {
      uint256 withdrawAmount = hesmanToken.balanceOf(address(this));
      hesmanToken.transfer(msg.sender, withdrawAmount);
  }
}
