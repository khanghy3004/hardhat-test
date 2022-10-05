// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
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

contract BamiRefundIDO is Ownable, ReentrancyGuard {
    // General
    bool public isPause;
    uint256 generalDec = 10**18;
    mapping(address => mapping(address => bool)) public whitelistMap;

    // Pool
    address public pool1;
    address public pool2;
    address public pool3;

    // Token
    ERC20 public refundToken; // HES

    // Pool
    BamiHesmanPool1 hesmanPool1;
    BamiHesmanPool2 hesmanPool2;
    BamiHesmanPool3 hesmanPool3;

    // Refund
    uint256 public amountRefundPool1 = 75000000000000000000;
    uint256 public amountRefundPool2 = 37500000000000000000;
    uint256 public amountRefundPool3 = 37500000000000000000;
    mapping(address => mapping(address => bool)) public refundedMap;
    uint256 public startTimeRefund;
    uint256 public endTimeRefund;

    // event
    event Refund(address user, uint256 amount, address pool);

    // modifier
    modifier isRun() {
        require(isPause == false, "Contract is paused");
        _;
    }

    modifier validTimeRefund() {
        require(startTimeRefund < block.timestamp, "Time refund invalid");
        require(block.timestamp < endTimeRefund, "Time refund invalid");
        _;
    }

    constructor(
        address _BamiHesmanPool1,
        address _BamiHesmanPool2,
        address _BamiHesmanPool3,
        address _refundToken
    ) {
        pool1 = _BamiHesmanPool1;
        pool2 = _BamiHesmanPool2;
        pool3 = _BamiHesmanPool3;
        hesmanPool1 = BamiHesmanPool1(pool1);
        hesmanPool2 = BamiHesmanPool2(pool2);
        hesmanPool3 = BamiHesmanPool3(pool3);
        refundToken = ERC20(_refundToken);
        isPause = true;
    }

    function setPauseContract(bool _status) public onlyOwner {
        isPause = _status;
    }

    function refundPool1() public nonReentrant isRun validTimeRefund {
        require(whitelistMap[pool1][msg.sender], "Not whitelist");
        require(hesmanPool1.whitelistMap(msg.sender), "Not whitelist pool 1");
        require(refundedMap[pool1][msg.sender] == false, "Already refunded");
        require(hesmanPool1.vestingMap(msg.sender) >= 1, "You have not claimed the first time");
        
        refundedMap[pool1][msg.sender] = true;
        refundToken.transfer(msg.sender, amountRefundPool1);

        emit Refund(msg.sender, amountRefundPool1, pool1);
    }

    function refundPool2() public nonReentrant isRun validTimeRefund {
        require(whitelistMap[pool2][msg.sender], "Not whitelist");
        require(hesmanPool2.whitelistMap(msg.sender), "Not whitelist pool 2");
        require(refundedMap[pool2][msg.sender] == false, "Already refunded");
        require(hesmanPool2.vestingMap(msg.sender) >= 1, "You have not claimed the first time");

        refundedMap[pool2][msg.sender] = true;
        refundToken.transfer(msg.sender, amountRefundPool2);

        emit Refund(msg.sender, amountRefundPool2, pool2);
    }

    function refundPool3() public nonReentrant isRun validTimeRefund {
        require(whitelistMap[pool3][msg.sender], "Not whitelist");
        require(hesmanPool3.whitelistMap(msg.sender), "Not whitelist pool 3");
        require(refundedMap[pool3][msg.sender] == false, "Already refunded");
        require(hesmanPool3.vestingMap(msg.sender) >= 1, "You have not claimed the first time");

        refundedMap[pool3][msg.sender] = true;
        refundToken.transfer(msg.sender, amountRefundPool3);

        emit Refund(msg.sender, amountRefundPool3, pool3);
    }

    function setWhiteListPool1(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            whitelistMap[pool1][userList[index]] = true;
        }
    }

    function setWhiteListPool2(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            whitelistMap[pool2][userList[index]] = true;
        }
    }

    function setWhiteListPool3(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            whitelistMap[pool3][userList[index]] = true;
        }
    }

    function removeWhiteListPool1(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            whitelistMap[pool1][userList[index]] = false;
        }
    }

    function removeWhiteListPool2(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            whitelistMap[pool2][userList[index]] = false;
        }
    }

    function removeWhiteListPool3(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            whitelistMap[pool3][userList[index]] = false;
        }
    }

    function setRefundToken(address _refundToken) public onlyOwner {
        refundToken = ERC20(_refundToken);
    }

    function setAmountRefund(
        uint256 _amountRefundPool1,
        uint256 _amountRefundPool2,
        uint256 _amountRefundPool3
    ) public onlyOwner {
        amountRefundPool1 = _amountRefundPool1;
        amountRefundPool2 = _amountRefundPool2;
        amountRefundPool3 = _amountRefundPool3;
    }

    function setTimeRefund(uint256 _startTimeRefund, uint256 _endTimeRefund)
        public
        onlyOwner
    {
        startTimeRefund = _startTimeRefund;
        endTimeRefund = _endTimeRefund;
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
}
