// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract RunTogetherMigration is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;

    bool public isPause;
    address public devWallet;

    ERC20 public runTogetherToken;
    ERC20 public runTogetherTokenV2;

    mapping (address => uint256) public userSwapMap; // user -> total swap

    constructor(address _runTogetherToken, address _runTogetherTokenV2, address _devWallet) {
        runTogetherToken = ERC20(_runTogetherToken);
        runTogetherTokenV2 = ERC20(_runTogetherTokenV2);
        devWallet = _devWallet;
    }

    event EventSwap(
        address indexed account,
        uint256 amount
    );

    modifier isRun() {
        require(isPause == false, "Pause");
        _;
    }

    // swap token v1 and v2
    function swap() public nonReentrant isRun {
        // get balance of v1
        uint256 balance = runTogetherToken.balanceOf(msg.sender);
        console.log("balance: ", balance);
        require(balance > 0, "You don't have token v1 to swap");
        require(runTogetherTokenV2.balanceOf(address(this)) >= balance, "Contract doesn't have enough token v2 to swap");

        // transfer all tokenV1 from user to contract
        runTogetherToken.safeTransferFrom(msg.sender, address(this), balance);
        // transfer all tokenV2 from contract to user
        runTogetherTokenV2.safeTransfer(msg.sender, balance);
        // Add swap to map
        userSwapMap[msg.sender] += balance;

        emit EventSwap(msg.sender, balance);
    }

    // set token
    function setToken(address _runTogetherToken, address _runTogetherTokenV2) public onlyOwner {
        runTogetherToken = ERC20(_runTogetherToken);
        runTogetherTokenV2 = ERC20(_runTogetherTokenV2);
    }

    // set pause
    function setPause(bool _isPause) public onlyOwner {
        isPause = _isPause;
    }

    // set dev wallet
    function setdevWallet(address _devWallet) public onlyOwner {
        devWallet = _devWallet;
    }

    // withdraw all token v1 and v2
    function emergencyWithdrawToken() external onlyOwner {
        uint256 withdrawAmountV1 = runTogetherToken.balanceOf(address(this));
        runTogetherToken.safeTransfer(devWallet, withdrawAmountV1);

        uint256 withdrawAmountV2 = runTogetherTokenV2.balanceOf(address(this));
        runTogetherToken.safeTransfer(devWallet, withdrawAmountV2);
    }
}
