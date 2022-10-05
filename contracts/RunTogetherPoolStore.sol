// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract IRunTogetherPool {
    // show user info array
    function getUserInfoArray(uint256 _index) public view returns(address) {}
    // show user info array length
    function getUserInfoArrayLength() public view returns(uint256) {}
    // show user info amount
    function getUserInfoAmount(address _user) public view returns (uint256) {}
}


contract RunTogetherPoolStore is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    
    IRunTogetherPool runTogetherPoolInfo;

    bool public isPause;

    address public runTogetherPoolAddress; //address of run together pool
    address public devWallet; // dev wallet address
    
    mapping(address => uint256) public userDebtMap; // user debt
    mapping(uint256 => mapping(address => uint256)) public snapshotStakedAmountMap;
    mapping(address => uint256) public checkpointStakedAmountMap;
    mapping(uint256 => mapping (address => bool)) public withdrawStatusByBlockMap;

    struct PoolInfo {
      ERC20 tokenStaked; // Address of staked token contract.
      ERC20 tokenReward; // Address of reward token contract.
      uint256 lastRewardBlock; // Last block number that reward distribution occurs.
      uint256 lastTimestamp; // Last timestamp that reward distribution occurs.
      uint256 totalTokenStakedPool; // Total amount of token staked in the pool.
      uint256 totalProfitAmount; //the amount of profit the owner transfers to the contract to share profit for users
      bool isStopPool; // Stop this pool
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;
  
    //events
    event withdrawComplete (
      uint256 poolId,
      address withdrawerAddress,
      uint256 withdrawAmount
    );

    event snapshotComplete (
      uint256 poolId,
      address userAdrress
    );

    constructor (address _runTogetherPoolAddress, address _devWallet) {
        runTogetherPoolAddress = _runTogetherPoolAddress;
        runTogetherPoolInfo = IRunTogetherPool(_runTogetherPoolAddress);
        devWallet = _devWallet;
        isPause = true;
    }

    modifier isRun() {
        require(isPause == false, "Contract is paused");
        _;
    }

    function poolLength() external view returns (uint256) {
      return poolInfo.length;
    }

    function setPauseContract(bool _status) external onlyOwner {
        isPause = _status;
    }

    function setDevWallet(address _devWallet) public onlyOwner {
      devWallet = _devWallet;
    }
   
    function setRunTogetherPoolAddress(address _runTogetherPoolAddress) public onlyOwner {
      runTogetherPoolAddress = _runTogetherPoolAddress;
      runTogetherPoolInfo = IRunTogetherPool(_runTogetherPoolAddress);
    }

    function addPool(ERC20 _tokenStaked, ERC20 _tokenReward) public onlyOwner {
      poolInfo.push(
        PoolInfo({
          tokenStaked: _tokenStaked,
          tokenReward: _tokenReward,
          lastRewardBlock: block.number,
          lastTimestamp: block.timestamp,
          totalTokenStakedPool: 0,
          totalProfitAmount: 0,
          isStopPool: false
        })
      );
    }

    function updatePool(uint256 _pid, address _user) public {
      PoolInfo storage pool = poolInfo[_pid];
      require(pool.isStopPool == false, "Pool is stopped");
      uint256 totalTokenStakedPool = pool.tokenStaked.balanceOf(runTogetherPoolAddress);
      if (totalTokenStakedPool == 0) {
        pool.lastRewardBlock = block.number;
        pool.lastTimestamp = block.timestamp;
        return;
      }
      pool.totalTokenStakedPool = totalTokenStakedPool;
      pool.lastRewardBlock = block.number;
      pool.lastTimestamp = block.timestamp;


      if (checkpointStakedAmountMap[_user] != 0) {
        for (uint256 index = checkpointStakedAmountMap[_user] + 1; index < _pid + 1; index++) {
          snapshotStakedAmountMap[index-1][_user] = userDebtMap[_user];
        }
      }

      // snapshot staked amount per user
      snapshotStakedAmountMap[_pid][_user] = runTogetherPoolInfo.getUserInfoAmount(_user);
      userDebtMap[_user] = runTogetherPoolInfo.getUserInfoAmount(_user);
      
      checkpointStakedAmountMap[_user] = _pid + 1;
    }

    function pendingReward(uint256 _pid, address _user) public view returns (uint256) {
      PoolInfo storage pool = poolInfo[_pid];
      uint256 totalTokenStakedPool = pool.totalTokenStakedPool;
      if (totalTokenStakedPool == 0) {
        return 0;
      }
      uint256 totalProfitAmount = pool.totalProfitAmount;
      uint256 userStakedAmount = snapshotStakedAmountMap[_pid][_user];

      if (userStakedAmount == 0 && _pid + 1 >= checkpointStakedAmountMap[_user]) {
        userStakedAmount = userDebtMap[_user];
      }
      return userStakedAmount.mul(totalProfitAmount).div(totalTokenStakedPool);
    }

    function pendingRewardAll(address _user) public view returns (uint256) {
      uint256 totalPendingReward = 0;
      for (uint256 index = 0; index < poolInfo.length; index++) {
        totalPendingReward = totalPendingReward.add(pendingReward(index, _user));
      }
      return totalPendingReward;
    }

    function snapshot(uint256 _pid, uint256 _totalProfitAmount) public isRun onlyOwner {
      PoolInfo storage pool = poolInfo[_pid];
      uint256 totalTokenStakedPool = pool.tokenStaked.balanceOf(runTogetherPoolAddress);
      require(totalTokenStakedPool > 0, "totalTokenStakedPool must be greater than 0");
      pool.totalTokenStakedPool = totalTokenStakedPool;
      pool.isStopPool = true;
      pool.totalProfitAmount = _totalProfitAmount;
      pool.lastRewardBlock = block.number;
      pool.lastTimestamp = block.timestamp; 
      
      emit snapshotComplete(_pid, msg.sender);
    }

    function withdraw(uint256 _pid) public isRun {
      PoolInfo storage pool = poolInfo[_pid];
      require(pool.isStopPool == true, 'Pool has not snapshot');
      require(withdrawStatusByBlockMap[_pid][msg.sender] == false, "Withdrawed");
      uint256 userProfitAmount = pendingReward(_pid, msg.sender);
      pool.tokenReward.safeTransfer(msg.sender, userProfitAmount);
      withdrawStatusByBlockMap[_pid][msg.sender] = true;

      emit withdrawComplete(_pid, msg.sender, userProfitAmount);
    }

    function withdrawAll() public isRun {
      for (uint256 index = 0; index < poolInfo.length; index++) {
        PoolInfo storage pool = poolInfo[index];
        if (pool.isStopPool == true && withdrawStatusByBlockMap[index][msg.sender] == false) {
          uint256 userProfitAmount = pendingReward(index, msg.sender);
          pool.tokenReward.safeTransfer(msg.sender, userProfitAmount);
          withdrawStatusByBlockMap[index][msg.sender] = true;

          emit withdrawComplete(index, msg.sender, userProfitAmount);
        }
      }
    }

    function emergencyWithdraw(address _tokenAddress) external onlyOwner {
        uint256 withdrawAmount = ERC20(_tokenAddress).balanceOf(address(this));
        ERC20(_tokenAddress).safeTransfer(devWallet, withdrawAmount);
    }
}