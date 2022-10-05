// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BamiIDO3 is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // Wallet
  address public devWallet; // rec BAMI fee
  address public idoOwner; // rec BUSD
  mapping(address => bool) public whitelistMap;
  mapping(address => bool) public paidIdoMap;
  mapping(address => uint256) public vestingMap;
  mapping(address => bool) public unstakeMap;

  mapping(address => bool) public blacklistMap;

  // General
  bool public isPause;
  uint256 generalDec = 10 ** 18;

  uint256 public payAmountPerSlot = 50 * generalDec;
  uint256 public tokenPerSlot = 2500 * generalDec; // 50 BUSD / 0.02 = 2,500 HES
  uint256 public totalOfSlot = 50;
  uint256 public totalOfPaid; // User paid
  uint256 public totalOfUserWhilist;
  uint256 public tokenInWalletRequire = 10 * generalDec;

  // Token
  ERC20 public hesmanToken; // HES
  ERC20 public paymentToken; // BUSD
  ERC20 public bamiToken; // BAMI

  // Time
  // Buy: Stake BUSD
  uint256 public startBuyTime;
  uint256 public endBuyTime;

  // Claim: claim HES token
  uint256 public startClaimTime;
  uint256 public endClaimTime;

  // Struct
  // Vesting
  struct StageIdo {
    uint256 id;
    uint256 percent;
    uint256 startTime;
  }

  StageIdo[] public stageList; // 4 times vesting


  // Event
  event EventUserStake(address user, uint256 amount, uint256 time);
  event EventUserBuy(address user, uint256 amount, uint256 time);
  event EventUserClaim(address user, uint256 amount, uint256 time);
  event EventUserUnstake(address user, uint256 amount, uint256 time);

  constructor(
    address _devWallet,
    address _idoOwner,
    address _hesmanToken,
    address _bamiToken,
    address _paymentToken
  ) {
    devWallet = _devWallet;
    idoOwner = _idoOwner;
    hesmanToken = ERC20(_hesmanToken);
    bamiToken = ERC20(_bamiToken);
    paymentToken = ERC20(_paymentToken);

    isPause = true; // Mark pause if deploy
  }

  // Modifier
  modifier validBuyTime() {
      require(startBuyTime < block.timestamp, "Time buy invalid");
      require(block.timestamp < endBuyTime, "Time buy invalid");
    _;
  }

  modifier isRun() {
    require(isPause == false, "Contract is paused");
    _;
  }

  function setPauseContract(bool _status) public onlyOwner {
    isPause = _status;
  }

  function setTokenIdo(address _hesmanToken, address _bamiToken, address _paymentToken) public onlyOwner {
    hesmanToken = ERC20(_hesmanToken);
    bamiToken = ERC20(_bamiToken);
    paymentToken = ERC20(_paymentToken);
  }

  // Using TimeStamp
  function setBuyTime(uint256 _startBuyTime, uint256 _endBuyTime) public onlyOwner {
      require(_startBuyTime < _endBuyTime, "Input time buy invalid");

      startBuyTime = _startBuyTime;
      endBuyTime = _endBuyTime;
  }

  function setIdoTime(uint256 _startBuyTime, uint256 _endBuyTime) public onlyOwner {
      require(_startBuyTime < _endBuyTime, "Input time buy invalid");

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
  function setDevWallet(address _devWallet) public onlyOwner {
    devWallet = _devWallet;
  }

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
        uint256 _totalOfSlot, 
        uint256 _startBuyTime,
        uint256 _endBuyTime

    ) public onlyOwner {
    
    startBuyTime = _startBuyTime;
    endBuyTime = _endBuyTime;

    payAmountPerSlot = _payAmountPerSlot;
    tokenPerSlot = _tokenPerSlot;
    totalOfSlot = _totalOfSlot;

  }

  // Set whitelist
  function setWhitelist(address[] calldata userList) public onlyOwner {
    for (uint256 index = 0; index < userList.length; index++) {
      whitelistMap[userList[index]] = true;
      totalOfUserWhilist++;
    }
  }

  function removeWhitelist(address[] calldata userList) public onlyOwner {
    for (uint256 index = 0; index < userList.length; index++) {
      if (whitelistMap[userList[index]]) {
        
        whitelistMap[userList[index]] = false;
        if (totalOfUserWhilist > 0) {
          totalOfUserWhilist--;
        }

      }
    }
  }

  function buyIdo() public validBuyTime nonReentrant isRun {
    require(blacklistMap[msg.sender] == false, "You are in Blacklist");
    require(whitelistMap[msg.sender] == true, "You are not in whitelist");
    require(paidIdoMap[msg.sender] == false, "You are paid before");
    require(totalOfPaid < totalOfSlot, "Full buy slot");
    require(bamiToken.balanceOf(msg.sender) >= tokenInWalletRequire, "Not enough BAMI token in your wallet");

    paidIdoMap[msg.sender] = true;
    vestingMap[msg.sender] = 0;
    totalOfPaid++;

    paymentToken.safeTransferFrom(msg.sender, idoOwner, payAmountPerSlot);

    emit EventUserBuy(msg.sender, payAmountPerSlot, block.timestamp);
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

    uint256 amountClaim = currentPercentVesting.mul(tokenPerSlot).div(100);
    hesmanToken.safeTransfer(msg.sender, amountClaim);

    emit EventUserClaim(msg.sender, amountClaim, block.timestamp);
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

    uint256 bamiTokenInContract = bamiToken.balanceOf(address(this));
    if (bamiTokenInContract > 0) {
      bamiToken.safeTransfer(idoOwner, bamiTokenInContract);
    }
  }

}
