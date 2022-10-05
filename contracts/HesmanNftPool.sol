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

contract HesmanIDO is Ownable, ReentrancyGuard, IERC721Receiver {
  using SafeMath for uint256;
  using SafeERC20 for ERC20; 

  struct userNftDetail {
    address user;
    uint256 nftId;
  }

  // Wallet
  address public idoOwner; // rec BUSD
  mapping(address => bool) public whitelistMap;
  mapping(address => bool) public paidIdoMap;
  mapping(address => uint256) public vestingMap;
  mapping(address => bool) public unstakeMap;
  
  mapping(address => userNftDetail[]) public userNftMap;
  mapping(address => uint256) public userBusdAllocationMap;
  mapping(address => uint256) public userHesmanTokenRecMap;

  mapping(address => bool) public blacklistMap;

  // General
  bool public isPause;
  uint256 generalDec = 10 ** 18;

  uint256 public limitNftPerSlot = 5;

  uint256 public payAmountPerSlot = 50 * generalDec;
  uint256 public tokenPerSlot = 2500 * generalDec; // 50 BUSD / 0.02 = 2,500 HES
  uint256 public totalOfSlot = 10000;
  uint256 public totalOfUserStaked; // User staked
  uint256 public totalOfPaid; // User paid

  // Token
  ERC20 public hesmanToken; // HES
  ERC20 public paymentToken; // BUSD
  address public hesicNftAddress;

  // Time
  // Stake: HESMAN > Whitelist
  uint256 public startStakeTime;
  uint256 public endStakeTime;
  uint256 public unStakeTime; // 1 month after

  // Buy: Stake BUSD
  uint256 public startBuyTime;
  uint256 public endBuyTime;

  // Struct
  // Vesting
  struct StageIdo {
    uint256 id;
    uint256 percent;
    uint256 startTime;
  }

  StageIdo[] public stageList; // 4 times vesting


  // Event
  event EventUserStake(address user, uint256 numberOfNft, uint256 time);
  event EventUserBuy(address user, uint256 amount, uint256 time);
  event EventUserClaim(address user, uint256 amount, uint256 time);
  event EventUserUnstake(address user, uint256 time);
  event EvenUserClaimNFT(address indexed user, address nft, uint256 tokenId, uint256 time);

  constructor(
    address _idoOwner,
    address _hesmanToken,
    address _paymentToken,
    address _hesicNftAddress
  ) {
    idoOwner = _idoOwner;
    hesmanToken = ERC20(_hesmanToken);
    paymentToken = ERC20(_paymentToken);
    hesicNftAddress = _hesicNftAddress;

    isPause = true; // Mark pause if deploy
  }

  // Modifier
  modifier validStakeTime() {
      require(startStakeTime < block.timestamp, "Time staking invalid");
      require(block.timestamp < endStakeTime, "Time staking invalid");
    _;
  }

  // Modifier
  modifier validBuyTime() {
      require(startBuyTime < block.timestamp, "Time buy invalid");
      require(block.timestamp < endBuyTime, "Time buy invalid");
    _;
  }

  modifier validUnstakeTime() {
      require(unStakeTime < block.timestamp, "Time return HESMAN invalid");
    _;
  }

  modifier isRun() {
    require(isPause == false, "Contract is paused");
    _;
  }

  function setPauseContract(bool _status) public onlyOwner {
    isPause = _status;
  }

  function setLimitNftPerSlot(uint256 _limitNftPerSlot) public onlyOwner {
    limitNftPerSlot = _limitNftPerSlot;
  }

  function setTokenIdo(address _hesmanToken, address _paymentToken, address _hesicNftAddress) public onlyOwner {
    hesmanToken = ERC20(_hesmanToken);
    paymentToken = ERC20(_paymentToken);
    hesicNftAddress = _hesicNftAddress;
  }

  // Using TimeStamp
  function setTimeStake(uint256 _startStakeTime, uint256 _endStakeTime, uint256 _unStakeTime) public onlyOwner {
      require(_startStakeTime < _endStakeTime, "Input time staking invalid");
      require(_endStakeTime < _unStakeTime, "Input time staking invalid");

      startStakeTime = _startStakeTime;
      endStakeTime = _endStakeTime;
      unStakeTime = _unStakeTime;
  }

  function setBuyTime(uint256 _startBuyTime, uint256 _endBuyTime) public onlyOwner {
      require(_startBuyTime < _endBuyTime, "Input time buy invalid");

      startBuyTime = _startBuyTime;
      endBuyTime = _endBuyTime;
  }

  function setIdoTime(uint256 _startStakeTime, uint256 _endStakeTime, uint256 _unStakeTime, uint256 _startBuyTime, uint256 _endBuyTime) public onlyOwner {
      require(_startStakeTime < _endStakeTime, "Input time staking invalid");
      require(_endStakeTime < _unStakeTime, "Input time staking invalid");
      require(_startBuyTime < _endBuyTime, "Input time buy invalid");

      startStakeTime = _startStakeTime;
      endStakeTime = _endStakeTime;
      unStakeTime = _unStakeTime;
      startBuyTime = _startBuyTime;
      endBuyTime = _endBuyTime;
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

  function setClaimTime(uint256[] calldata _startTimeList, uint256[] calldata _percentList) public onlyOwner {
    require(_startTimeList.length > 0, "Input stage invalid");
    require(_startTimeList.length == _percentList.length, "Input stage invalid");

    delete stageList;

    for (uint256 index = 0; index < _startTimeList.length; index++) {
      StageIdo memory stageObject;
      stageObject.id = index;
      stageObject.startTime = _startTimeList[index];
      stageObject.percent = _percentList[index];

      stageList.push(stageObject);
    }

  }

  // Set main wallet
  function setIdoOwner(address _idoOwner) public onlyOwner {
    idoOwner = _idoOwner;
  }

  function setPayAmountPerSlot(uint256 _payAmountPerSlot) public onlyOwner {
    payAmountPerSlot = _payAmountPerSlot;
  }

  function setTotalOfSlot(uint256 _totalOfSlot) public onlyOwner {
    totalOfSlot = _totalOfSlot;
  }

  function setIdoConfig(
        uint256 _payAmountPerSlot,
        uint256 _tokenPerSlot, 
        uint256 _startStakeTime,
        uint256 _endStakeTime,
        uint256 _unStakeTime,
        uint256 _startBuyTime,
        uint256 _endBuyTime

    ) public onlyOwner {
    
    require(_startStakeTime < _endStakeTime, "Input time staking invalid");
    require(_endStakeTime < _unStakeTime, "Input time staking invalid");
    require(_startBuyTime < _endBuyTime, "Input time buy invalid");

    startStakeTime = _startStakeTime;
    endStakeTime = _endStakeTime;
    unStakeTime = _unStakeTime;
    startBuyTime = _startBuyTime;
    endBuyTime = _endBuyTime;

    payAmountPerSlot = _payAmountPerSlot;
    tokenPerSlot = _tokenPerSlot;
  }

  // Staking HESIC to get Whitelist
  function stakeNftGetSlot( uint256[] calldata _idNftList ) public validStakeTime nonReentrant isRun {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    require(whitelistMap[msg.sender] == false, "You are in Whitelist");
    require(_idNftList.length <= limitNftPerSlot, "5 Nfts limit per slot");
    require(_idNftList.length > 0, "NFTs has to greater than 0");

    // Join whitelist
    whitelistMap[msg.sender] = true;
    totalOfUserStaked++;


    for(uint index = 0; index < _idNftList.length; index++){
        userNftDetail memory nftDetail;
        nftDetail.user = msg.sender;
        nftDetail.nftId = _idNftList[index];
        userNftMap[msg.sender].push(nftDetail);

        IERC721(hesicNftAddress).transferFrom(msg.sender, address(this), _idNftList[index]);

    }

    userBusdAllocationMap[msg.sender] = _idNftList.length * payAmountPerSlot;
    userHesmanTokenRecMap[msg.sender] = _idNftList.length * tokenPerSlot;

    emit EventUserStake(msg.sender, _idNftList.length , block.timestamp);

  }

  function buyIdo() public validBuyTime nonReentrant isRun {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    require(whitelistMap[msg.sender] == true, "You are not in whitelist");
    require(paidIdoMap[msg.sender] == false, "You are paid before");
    require(totalOfPaid < totalOfSlot, "Full buy slot");

    paidIdoMap[msg.sender] = true;
    vestingMap[msg.sender] = 0;
    totalOfPaid++;

    paymentToken.safeTransferFrom(msg.sender, idoOwner, userBusdAllocationMap[msg.sender]);

    emit EventUserBuy(msg.sender, userBusdAllocationMap[msg.sender], block.timestamp);
  }

  function claimIdo() public nonReentrant isRun {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    require(whitelistMap[msg.sender] == true, "You are not whitelist before");
    require(paidIdoMap[msg.sender] == true, "You are not paid before");
    uint256 currentIndexVesting = vestingMap[msg.sender];
    
    StageIdo memory stageObject = stageList[currentIndexVesting];
    uint256 currentPercentVesting = stageObject.percent;
    uint256 currentTimeVesting = stageObject.startTime;

    require(currentIndexVesting < stageList.length, "Claim index is invalid");
    require(currentPercentVesting > 0, "Percent vesting is invalid");
    require(currentTimeVesting < block.timestamp, "Claim time is not started");

    vestingMap[msg.sender] = currentIndexVesting + 1;

    uint256 amountClaim = currentPercentVesting.mul(userHesmanTokenRecMap[msg.sender]).div(100);
    hesmanToken.safeTransfer(msg.sender, amountClaim);

    emit EventUserClaim(msg.sender, amountClaim, block.timestamp);
  }

  function unstakeToken() public nonReentrant validUnstakeTime {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    require(whitelistMap[msg.sender] == true, "You are not stake before");
    require(unstakeMap[msg.sender] == false, "You are not staked token before");

    unstakeMap[msg.sender] = true;

    for (uint256 index = 0; index < userNftMap[msg.sender].length; index++) {
      userNftDetail storage nftDetail = userNftMap[msg.sender][index];

      // Send NFT
      IERC721(hesicNftAddress).transferFrom(address(this), msg.sender, nftDetail.nftId);
      emit EvenUserClaimNFT(msg.sender, hesicNftAddress, nftDetail.nftId, block.timestamp);
    }

    emit EventUserUnstake(msg.sender , block.timestamp);
  }

  function nextStageIndex() public view returns (uint256) {
    return vestingMap[msg.sender];
  }

  //Withdraw all HES token from contract to idoOwner
  function urgentWithdrawAllToken() public onlyOwner {
    uint256 hesmanTokenInContract = hesmanToken.balanceOf(address(this));
    if (hesmanTokenInContract > 0) {
      hesmanToken.safeTransfer(idoOwner, hesmanTokenInContract);
    }
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
      return this.onERC721Received.selector;
  }

}
