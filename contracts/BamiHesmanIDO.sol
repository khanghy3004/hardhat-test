// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BamiHesmanPool1 {
    mapping(address => bool) public whitelistMap;
    mapping(address => uint256) public vestingMap;
}

contract BamiHesmanPool2 {
    mapping(address => bool) public whitelistMap;
    mapping(address => uint256) public vestingMap;
}

contract BamiHesmanPool3 {
    mapping(address => bool) public whitelistMap;
    mapping(address => uint256) public vestingMap;
}

contract BamiHesmanIDO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Wallet
    address public idoOwner;

    // General
    bool public isPause;
    mapping(address => mapping(address => bool)) public whitelistMap;
    mapping(address => mapping(address => bool)) public blacklistMap;
    uint256 generalDec = 10 ** 18;

    // Pool
    address public pool1;
    address public pool2;
    address public pool3;

    // Token
    ERC20 public hesmanToken; // BUSD

    // Pool
    BamiHesmanPool1 hesmanPool1;
    BamiHesmanPool2 hesmanPool2;
    BamiHesmanPool3 hesmanPool3;

    // Vesting
    struct StageIdo {
        uint256 id;
        uint256 percent;
        uint256 startTime;
    }

    StageIdo[] public stageList; // 4 times vesting
    mapping(address => mapping(address => uint256)) public vestingMap;
    uint256 tokenPerSlotPool1 = 5000 * generalDec;
    uint256 tokenPerSlotPool2 = 2500 * generalDec;
    uint256 tokenPerSlotPool3 = 2500 * generalDec;

    // event
    event EventUserClaim(address user, uint256 amount, address pool, uint256 time);

    // modifier
    modifier isRun() {
        require(isPause == false, "Contract is paused");
        _;
    }

    constructor(
        address _BamiHesmanPool1,
        address _BamiHesmanPool2,
        address _BamiHesmanPool3,
        address _hesmanToken,
        address _idoOwner
    ) {
        pool1 = _BamiHesmanPool1;
        pool2 = _BamiHesmanPool2;
        pool3 = _BamiHesmanPool3;
        hesmanPool1 = BamiHesmanPool1(pool1);
        hesmanPool2 = BamiHesmanPool2(pool2);
        hesmanPool3 = BamiHesmanPool3(pool3);
        hesmanToken = ERC20(_hesmanToken);
        idoOwner = _idoOwner;
        isPause = true;
    }

    // set Wallet
    function setIdoOwner(address _idoOwner) public onlyOwner {
        idoOwner = _idoOwner;
    }

    function setPauseContract(bool _status) public onlyOwner {
        isPause = _status;
    }

    // claim
    function claimPool1() public nonReentrant isRun {
        require(blacklistMap[pool1][msg.sender] == false, "You are in Blacklist");
        require(whitelistMap[pool1][msg.sender], "Not whitelist");
        require(hesmanPool1.whitelistMap(msg.sender), "Not whitelist pool 1");
        
        if (vestingMap[pool1][msg.sender] == 0) {
            vestingMap[pool1][msg.sender] = hesmanPool1.vestingMap(msg.sender);
        }

        uint256 currentIndexVesting = vestingMap[pool1][msg.sender];

        StageIdo memory stageObject = stageList[currentIndexVesting];
        uint256 currentPercentVesting = stageObject.percent;
        uint256 currentTimeVesting = stageObject.startTime;

        require(currentIndexVesting < stageList.length, "Claim index is invalid");
        require(currentPercentVesting > 0, "Percent vesting is invalid");
        require(currentTimeVesting < block.timestamp, "Claim time is not started");

        vestingMap[pool1][msg.sender] = currentIndexVesting + 1;

        uint256 amountClaim = currentPercentVesting.mul(tokenPerSlotPool1).div(100);
        hesmanToken.safeTransfer(msg.sender, amountClaim);

        emit EventUserClaim(msg.sender, amountClaim, pool1, block.timestamp);
    }

    function claimPool2() public nonReentrant isRun {
        require(blacklistMap[pool2][msg.sender] == false, "You are in Blacklist");
        require(whitelistMap[pool2][msg.sender], "Not whitelist");
        require(hesmanPool2.whitelistMap(msg.sender), "Not whitelist pool 2");

        if (vestingMap[pool2][msg.sender] == 0) {
            vestingMap[pool2][msg.sender] = hesmanPool2.vestingMap(msg.sender);
        }

        uint256 currentIndexVesting = vestingMap[pool2][msg.sender];

        StageIdo memory stageObject = stageList[currentIndexVesting];
        uint256 currentPercentVesting = stageObject.percent;
        uint256 currentTimeVesting = stageObject.startTime;

        require(currentIndexVesting < stageList.length, "Claim index is invalid");
        require(currentPercentVesting > 0, "Percent vesting is invalid");
        require(currentTimeVesting < block.timestamp, "Claim time is not started");

        vestingMap[pool2][msg.sender] = currentIndexVesting + 1;

        uint256 amountClaim = currentPercentVesting.mul(tokenPerSlotPool2).div(100);
        hesmanToken.safeTransfer(msg.sender, amountClaim);

        emit EventUserClaim(msg.sender, amountClaim, pool2, block.timestamp);
    }

    function claimPool3() public nonReentrant isRun {
        require(blacklistMap[pool3][msg.sender] == false, "You are in Blacklist");
        require(whitelistMap[pool3][msg.sender], "Not whitelist");
        require(hesmanPool3.whitelistMap(msg.sender), "Not whitelist pool 3");

        if (vestingMap[pool3][msg.sender] == 0) {
            vestingMap[pool3][msg.sender] = hesmanPool3.vestingMap(msg.sender);
        }

        uint256 currentIndexVesting = vestingMap[pool3][msg.sender];

        StageIdo memory stageObject = stageList[currentIndexVesting];
        uint256 currentPercentVesting = stageObject.percent;
        uint256 currentTimeVesting = stageObject.startTime;

        require(currentIndexVesting < stageList.length, "Claim index is invalid");
        require(currentPercentVesting > 0, "Percent vesting is invalid");
        require(currentTimeVesting < block.timestamp, "Claim time is not started");

        vestingMap[pool3][msg.sender] = currentIndexVesting + 1;

        uint256 amountClaim = currentPercentVesting.mul(tokenPerSlotPool3).div(100);
        hesmanToken.safeTransfer(msg.sender, amountClaim);

        emit EventUserClaim(msg.sender, amountClaim, pool3, block.timestamp);
    }
    
    // Whitelist
    function setWhiteList(address[] calldata userListPool1, address[] calldata userListPool2, address[] calldata userListPool3) public onlyOwner {
        for (uint256 index = 0; index < userListPool1.length; index++) {
            whitelistMap[pool1][userListPool1[index]] = true;
        }
        for (uint256 index = 0; index < userListPool2.length; index++) {
            whitelistMap[pool2][userListPool2[index]] = true;
        }
        for (uint256 index = 0; index < userListPool3.length; index++) {
            whitelistMap[pool3][userListPool3[index]] = true;
        }
    }

    function removeWhiteList(address[] calldata userListPool1, address[] calldata userListPool2, address[] calldata userListPool3) public onlyOwner {
        for (uint256 index = 0; index < userListPool1.length; index++) {
            whitelistMap[pool1][userListPool1[index]] = false;
        }
        for (uint256 index = 0; index < userListPool2.length; index++) {
            whitelistMap[pool2][userListPool2[index]] = false;
        }
        for (uint256 index = 0; index < userListPool3.length; index++) {
            whitelistMap[pool3][userListPool3[index]] = false;
        }
    }

    // Blacklist
    function setBlackList(address[] calldata userListPool1, address[] calldata userListPool2, address[] calldata userListPool3) public onlyOwner {
        for (uint256 index = 0; index < userListPool1.length; index++) {
            blacklistMap[pool1][userListPool1[index]] = true;
        }
        for (uint256 index = 0; index < userListPool2.length; index++) {
            blacklistMap[pool2][userListPool2[index]] = true;
        }
        for (uint256 index = 0; index < userListPool3.length; index++) {
            blacklistMap[pool3][userListPool3[index]] = true;
        }
    }

    function removeBlackList(address[] calldata userListPool1, address[] calldata userListPool2, address[] calldata userListPool3) public onlyOwner {
        for (uint256 index = 0; index < userListPool1.length; index++) {
            blacklistMap[pool1][userListPool1[index]] = false;
        }
        for (uint256 index = 0; index < userListPool2.length; index++) {
            blacklistMap[pool2][userListPool2[index]] = false;
        }
        for (uint256 index = 0; index < userListPool3.length; index++) {
            blacklistMap[pool3][userListPool3[index]] = false;
        }
    }
    
    // config claim
    function setHesmanToken(address _hesmanToken) public onlyOwner {
        hesmanToken = ERC20(_hesmanToken);
    }

    function settokenPerSlot(uint256 _tokenPerSlotPool1, uint256 _tokenPerSlotPool2, uint256 _tokenPerSlotPool3) public onlyOwner {
        tokenPerSlotPool1 = _tokenPerSlotPool1;
        tokenPerSlotPool2 = _tokenPerSlotPool2;
        tokenPerSlotPool3 = _tokenPerSlotPool3;
    }

    function setPool(
        address _BamiHesmanPool1,
        address _BamiHesmanPool2,
        address _BamiHesmanPool3
    ) public onlyOwner {
        pool1 = _BamiHesmanPool1;
        pool2 = _BamiHesmanPool2;
        pool3 = _BamiHesmanPool3;
        hesmanPool1 = BamiHesmanPool1(pool1);
        hesmanPool2 = BamiHesmanPool2(pool2);
        hesmanPool3 = BamiHesmanPool3(pool3);
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
    // Withdraw all hesman token from contract to idoOwner
    function urgentWithdrawAllToken() public onlyOwner {
        uint256 hesmanTokenInContract = hesmanToken.balanceOf(address(this));
        if (hesmanTokenInContract > 0) {
            hesmanToken.safeTransfer(idoOwner, hesmanTokenInContract);
        }
    }
}
