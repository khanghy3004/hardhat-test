// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HesmanPoolNft {
    mapping(address => bool) public whitelistMap;
    mapping(address => uint256) public vestingMap;
    mapping(address => uint256) public userBusdAllocationMap;
}

contract HemanRefundIDO is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    
    // Wallet
    address public refundOwner;

    // General
    bool public isPause;
    mapping(address => bool) public whitelistMap;
    mapping(address => bool) public blacklistMap;

    // Pool
    address public poolHesman;

    // Token
    ERC20 public refundToken; // BUSD

    // Pool
    HesmanPoolNft hesmanPoolNft;

    // Refund
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

    constructor(address _HesmanPoolNft, address _refundToken, address _refundOwner) {
        poolHesman = _HesmanPoolNft;
        hesmanPoolNft = HesmanPoolNft(poolHesman);
        refundToken = ERC20(_refundToken);
        refundOwner = _refundOwner;
        isPause = true;
    }

    // set Wallet
    function setRefundOwner(address _refundOwner) public onlyOwner {
        refundOwner = _refundOwner;
    }

    function setPauseContract(bool _status) public onlyOwner {
        isPause = _status;
    }

    function refund() public nonReentrant isRun validTimeRefund {
        require(blacklistMap[msg.sender] == false, "You are in Blacklist");
        require(whitelistMap[msg.sender], "Not whitelist");
        require(hesmanPoolNft.whitelistMap(msg.sender), "Not whitelist pool hesman");
        require(refundedMap[poolHesman][msg.sender] == false, "Already refunded");
        require(hesmanPoolNft.vestingMap(msg.sender) >= 1, "You have not claimed the first time");

        refundedMap[poolHesman][msg.sender] = true;
        uint256 amountRefundPoolHesman = hesmanPoolNft.userBusdAllocationMap(msg.sender) * 75 / 100;
        refundToken.safeTransfer(msg.sender, amountRefundPoolHesman);

        emit Refund(msg.sender, amountRefundPoolHesman, poolHesman);
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

    // config refund
    function setRefundToken(address _refundToken) public onlyOwner {
        refundToken = ERC20(_refundToken);
    }

    function setTimeRefund(uint256 _startTimeRefund, uint256 _endTimeRefund)
        public
        onlyOwner
    {
        startTimeRefund = _startTimeRefund;
        endTimeRefund = _endTimeRefund;
    }

    function setPool(address _HesmanPoolNft) public onlyOwner {
        poolHesman = _HesmanPoolNft;
        hesmanPoolNft = HesmanPoolNft(poolHesman);
    }

    // Withdraw all refund token from contract to refundOwner
    function urgentWithdrawAllToken() public onlyOwner {
        uint256 refundTokenInContract = refundToken.balanceOf(address(this));
        if (refundTokenInContract > 0) {
            refundToken.safeTransfer(refundOwner, refundTokenInContract);
        }
    }
}
