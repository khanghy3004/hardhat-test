// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HesmanPoolNft {
    mapping(address => bool) public whitelistMap;
    mapping(address => uint256) public vestingMap;
    mapping(address => uint256) public userHesmanTokenRecMap;
    mapping(address => bool) public paidIdoMap;
}

contract HemanRefundIDOv1 {
    mapping(address => mapping(address => bool)) public refundedMap;
}

contract HemanNftIDO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Wallet
    address public idoOwner;

    // General
    bool public isPause;
    mapping(address => bool) public whitelistMap;
    mapping(address => bool) public blacklistMap;

    // Pool
    address public poolHesman;
    address public poolHesmanRefund;

    // Token
    ERC20 public hesmanToken; // HES

    // Contract
    HesmanPoolNft hesmanPoolNft;
    HemanRefundIDOv1 hemanRefundIDO;

    // Vesting
    struct StageIdo {
        uint256 id;
        uint256 percent;
        uint256 startTime;
    }

    StageIdo[] public stageList; // 4 times vesting
    mapping(address => uint256) public vestingMap;

    // event
    event EventUserClaim(address user, uint256 amount, uint256 time);

    // modifier
    modifier isRun() {
        require(isPause == false, "Contract is paused");
        _;
    }

    constructor(
        address _HesmanPoolNft,
        address _HemanRefundIDO,
        address _hesmanToken,
        address _idoOwner
    ) {
        poolHesman = _HesmanPoolNft;
        hesmanPoolNft = HesmanPoolNft(poolHesman);
        poolHesmanRefund = _HemanRefundIDO;
        hemanRefundIDO = HemanRefundIDOv1(poolHesmanRefund);
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

    function claimIdo() public nonReentrant isRun {
        require(blacklistMap[msg.sender] == false, "You are in Blacklist");
        require(whitelistMap[msg.sender], "Not whitelist");
        require(hesmanPoolNft.whitelistMap(msg.sender), "Not whitelist pool hesman");
        require(hesmanPoolNft.paidIdoMap(msg.sender), "Not paid IDO");
        require(hemanRefundIDO.refundedMap(poolHesman, msg.sender) == false, "You have refunded");

        if (vestingMap[msg.sender] == 0) {
            vestingMap[msg.sender] = hesmanPoolNft.vestingMap(msg.sender);
        }
        
        uint256 currentIndexVesting = vestingMap[msg.sender];

        StageIdo memory stageObject = stageList[currentIndexVesting];
        uint256 currentPercentVesting = stageObject.percent;
        uint256 currentTimeVesting = stageObject.startTime;

        require(currentIndexVesting < stageList.length, "Claim index is invalid");
        require(currentPercentVesting > 0, "Percent vesting is invalid");
        require(currentTimeVesting < block.timestamp, "Claim time is not started");

        vestingMap[msg.sender] = currentIndexVesting + 1;

        uint256 amountClaim = currentPercentVesting.mul(hesmanPoolNft.userHesmanTokenRecMap(msg.sender)).div(100);
        hesmanToken.safeTransfer(msg.sender, amountClaim);

        emit EventUserClaim(msg.sender, amountClaim, block.timestamp);
    }

    // Whitelist
    function setWhiteList(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            whitelistMap[userList[index]] = true;
        }
    }

    function removeWhiteList(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            whitelistMap[userList[index]] = false;
        }
    }

    // Blacklist
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

    // config claim
    function setHesmanToken(address _hesmanToken) public onlyOwner {
        hesmanToken = ERC20(_hesmanToken);
    }

    function setPool(address _HesmanPoolNft, address _HemanRefundIDO) public onlyOwner {
        poolHesman = _HesmanPoolNft;
        hesmanPoolNft = HesmanPoolNft(poolHesman);
        poolHesmanRefund = _HemanRefundIDO;
        hemanRefundIDO = HemanRefundIDOv1(poolHesmanRefund);
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

    // Set vesting per user
    function setVestingUser(address _user, uint256 _vesting) public onlyOwner {
        vestingMap[_user] = _vesting;
    }

    // Withdraw all HES token from contract to idoOwner
    function urgentWithdrawAllToken() public onlyOwner {
        uint256 hesmanTokenInContract = hesmanToken.balanceOf(address(this));
        if (hesmanTokenInContract > 0) {
            hesmanToken.safeTransfer(idoOwner, hesmanTokenInContract);
        }
    }
}
