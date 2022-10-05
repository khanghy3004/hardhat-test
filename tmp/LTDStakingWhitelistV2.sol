// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LTDStakingNFTWhitelist is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public startTimeStakeNFT;
  uint256 public timeEndStakeNFT;
  uint256 public timeLockNFT;
  uint256 public totalStakedUser;
  uint256 public totalClaimedUser;
  uint256 public payAmountPerSlot;
  uint256 public tokenPerSlot;

  address[] public users;
  uint256 public poolLimit;

  mapping(address => bool) public nftSupport;
  mapping(address => bool) public isUserLockNft;
  mapping(address => uint256) public userBusdAllocationMap;
  mapping(address => uint256) public userHesmanTokenRecMap;

  struct userNftDetail {
    address user;
    address nftAddress;
    uint256 nftId;
  }

  mapping(address => userNftDetail[]) public userNftDetails;
  mapping(address => uint256) public totalNftStaked;

  event EvenUserStakeNFT(
    address indexed user,
    address nft,
    uint256 tokenId,
    uint256 time
  );

  event EvenUserClaimNFT(
    address indexed user,
    address nft,
    uint256 tokenId,
    uint256 time
  );

  // PoolLimit = 0 is unlimit
  function setPoolLimit(uint256 _newPoolLimit) external onlyOwner {
    poolLimit = _newPoolLimit;
  }

  function addWhitelistNFT(address[] memory _listNFT) external onlyOwner {
    for (uint256 i = 0; i < _listNFT.length; i++) {
      nftSupport[_listNFT[i]] = true;
    }
  }

  function removeWhitelistNFT(address[] memory _listNFT) external onlyOwner {
    for (uint256 i = 0; i < _listNFT.length; i++) {
      nftSupport[_listNFT[i]] = false;
    }
  }

  function setStakeSchedule(uint256 _startTimeStakeNFT, uint256 _timeEndStake, uint256 _timeLock) external onlyOwner {
    startTimeStakeNFT = _startTimeStakeNFT;
    timeEndStakeNFT = _timeEndStake;
    timeLockNFT = _timeLock;
  }

  function setPayAmountPerSlot(uint256 _payAmountPerSlot) public onlyOwner {
    payAmountPerSlot = _payAmountPerSlot;
  }

  function setTokenPerSlot(uint256 _tokenPerSlot) public onlyOwner {
    tokenPerSlot = _tokenPerSlot;
  }

  function stakeNFTForWhitelist(address[] memory _nfts, uint256[] memory _nftIds) external nonReentrant {
    require(block.timestamp > startTimeStakeNFT, "Please wait for start time");
    require(block.timestamp < timeEndStakeNFT, "End time for stake NFT");    
    require(isUserLockNft[msg.sender] != true, "You had staking NFT before");
    require(_nfts.length == _nftIds.length, "Your input is invaid");
    for (uint256 nftIndex = 0; nftIndex < _nfts.length; nftIndex++) {
      address nftAddress = _nfts[nftIndex];
      require(nftSupport[nftAddress] == true, "Your NFT is invalid!!!");
    }

    // PoolLimit = 0 is unlimit
    if (poolLimit > 0) {
      require(totalStakedUser + 1 <= poolLimit, "Whitelist is reached limit");
    }

    // Update whitelist number
    totalStakedUser += 1;
    users.push(msg.sender);

    // Flag user staked
    isUserLockNft[msg.sender] = true;

    for (uint256 nftIndex = 0; nftIndex < _nfts.length; nftIndex++) {
      address nftAddress = _nfts[nftIndex];
      uint256 nftId = _nftIds[nftIndex];

      // Set NFT ID
      userNftDetail memory nftDetail;
      nftDetail.user = msg.sender;
      nftDetail.nftAddress = nftAddress;
      nftDetail.nftId = nftId;

      userNftDetails[msg.sender].push(nftDetail);

      // Transfer NFT
      IERC721(nftAddress).transferFrom(msg.sender, address(this), nftId);

      totalNftStaked[msg.sender] += 1;

      userBusdAllocationMap[msg.sender] += _idNftList.length * payAmountPerSlot;
      userHesmanTokenRecMap[msg.sender] = _idNftList.length * tokenPerSlot;

      emit EvenUserStakeNFT(msg.sender, nftAddress, nftId, block.timestamp);
      
    }
    
  }

  function claimAll() external nonReentrant {
    require(timeLockNFT < block.timestamp,"Time is not ended");
    require(isUserLockNft[msg.sender] == true, "Not found or claimed");

    // Flag release NFT
    isUserLockNft[msg.sender] = false;

    for (uint256 index = 0; index < totalNftStaked[msg.sender]; index++) {
      userNftDetail storage nftDetail = userNftDetails[msg.sender][index];

      // Send NFT
      IERC721(nftDetail.nftAddress).transferFrom(address(this), msg.sender, nftDetail.nftId);

      emit EvenUserClaimNFT(msg.sender, nftDetail.nftAddress, nftDetail.nftId, block.timestamp);
    }
    
    totalClaimedUser += 1;
    
  }

  function countUsers() public view returns (uint256) {
    return totalStakedUser;
  }

  // Required function to allow receiving ERC-721 - When safeTransferFrom called auto implement this func if (to) is contract address
  function onERC721Received(
    address, /*operator*/
    address, /*from*/
    uint256, /*id*/
    bytes calldata /*data*/
  ) external pure returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}