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

contract HesmanToken is Ownable, ReentrancyGuard, IERC721Receiver {
  using SafeMath for uint256;
  using SafeERC20 for ERC20; 

  struct userNftDetail {
    address user;
    uint256 nftId;
  }

  // Wallet
  //address public owner; // rec BUSD
  mapping(address => bool) public stakedUserMap;
  mapping(address => bool) public unstakeMap;
  mapping(address => uint256) public stakeBlock;
  mapping(address => uint256) public unstakeBlock;
  mapping(address => userNftDetail[]) public userNftMap;
  mapping(address => bool) public blacklistMap;
  mapping(address => uint256) public nftStakedNumber;
  //mapping(address => uint256) public claimAmountMap;

  // General
  bool public isPause;
  uint256 generalDec = 10 ** 18;
  uint256 public totalOfUserStaked; // User staked
  uint256 public benefitPercentPerYear;
  uint256 public nftPrice;

  // Token
  ERC20 public hesmanToken; // HES
  address public hesicNftAddress;

  // Time
  // Stake: HESMAN 
  uint256 public startStakeTime;
  uint256 public endStakeTime;
  uint256 public unStakeTime; 
 
  // Event
  event EventUserStake(address user, uint256 numberOfNft, uint256 time);
  //event EventUserBuy(address user, uint256 amount, uint256 time);
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

  // Staking HESIC to get Whitelist
  function stakeNft(uint256[] calldata _idNftList) public nonReentrant isRun {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    //require(stakedUserMap[msg.sender] == false, "You are in Whitelist");
    require(_idNftList.length > 0, "NFTs have to be greater than 0");

    // Join whitelist
    stakedUserMap[msg.sender] = true;
    stakeBlock[msg.sender] = block.number;
    totalOfUserStaked++;


    for(uint index = 0; index < _idNftList.length; index++){
        userNftDetail memory nftDetail;
        nftDetail.user = msg.sender;
        nftDetail.nftId = _idNftList[index];
        userNftMap[msg.sender].push(nftDetail);

        IERC721(hesicNftAddress).transferFrom(msg.sender, address(this), _idNftList[index]);
    }
    
    nftStakedNumber[msg.sender] += _idNftList.length;

    emit EventUserStake(msg.sender, _idNftList.length , block.timestamp);

  }

  function unstakeToken() public nonReentrant {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    require(stakedUserMap[msg.sender] == true, "You did not stake before");
    require(unstakeMap[msg.sender] == false, "You have unstaked already");

    stakedUserMap[msg.sender] = false;
    unstakeMap[msg.sender] = true;
    unstakeBlock[msg.sender] = block.number;
    totalOfUserStaked--;
    //claimAmountMap[msg.sender] += (unstakeBlock[msg.sender] - stakeBlock[msg.sender]);

    for (uint256 index = 0; index < userNftMap[msg.sender].length; index++) {
      userNftDetail storage nftDetail = userNftMap[msg.sender][index];

      // Send NFT
      IERC721(hesicNftAddress).transferFrom(address(this), msg.sender, nftDetail.nftId);
      emit EventUserClaimNFT(msg.sender, hesicNftAddress, nftDetail.nftId, block.timestamp);
    }

    emit EventUserUnstake(msg.sender , block.timestamp);
  }

  function claimToken() public nonReentrant isRun {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    //require(stakedUserMap[msg.sender] == true, "You did not stake before");
    require(unstakeMap[msg.sender] == true, "You should unstake first");  // cannot claim before unstake
    
    uint256 nftTotalPrice = nftPrice * nftStakedNumber[msg.sender];
    console.log(unstakeBlock[msg.sender]);
    console.log(stakeBlock[msg.sender]);
    console.log(unstakeBlock[msg.sender] - stakeBlock[msg.sender]);
    console.log(benefitPercentPerYear);
    console.log(nftTotalPrice);
    uint256 amountClaim = (unstakeBlock[msg.sender] - stakeBlock[msg.sender]).mul(nftTotalPrice).mul(benefitPercentPerYear).div(100).div(10368000);
    console.log(amountClaim);
    hesmanToken.safeTransfer(msg.sender, amountClaim);
    //claimAmountMap[msg.sender] = 0;

    emit EventUserClaim(msg.sender, amountClaim, block.timestamp);
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
      return this.onERC721Received.selector;
  }

}
