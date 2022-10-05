// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract IRunTogetherPoolStore {
    function updatePool(uint256 _pid, address _user) public {}
    function poolLength() external view returns (uint256) {}
}

contract RunTogetherPoolProposal is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    IRunTogetherPoolStore runTogetherPoolStore;

    bool public isPause;
    uint256 public baseRate = 1000;
    uint256 public blockPerYear = 10512000; // 1 block per 3 seconds
    uint256 public rateReward = 200; // APY 20%
    uint256 public rateStakedToken = 100;
    uint256 public rateRewardToken = 1;
    uint256 public minBlock = 100;
    uint256 public lockStakeDuration = 0 * 60 * 60; // no lock after stake
    uint256[] public feeUnstake = [20]; // fee 2% unstake
    uint256[] public feeUnstakeDuration = [180 * 24 * 60 * 60]; // 180 days

    // Max amount stake
    uint256 public maxAmountStake = 2500000 ether;
    // Amount of staked token
    uint256 public amountStakedToken;
    // Start time of the pool
    uint256 public startTime;
    // End time of the pool
    uint256 public endTime;
    // Start block of the pool
    uint256 public startBlock;
    // End block of the pool
    uint256 public endBlock;

    address public feeWallet;
    address public devWallet;
  
    mapping(address => bool) public blacklistMap;

    // The reward token
    ERC20 public rewardToken;

    // The staked token
    ERC20 public stakedToken;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        address userAddress;
        uint256 amount; // How many staked tokens the user has provided
        uint256 stakeBlock; // stakeBlock
        uint256 unstakeLockTime; // unstakeBlock
        uint256[] feeUnstakeTime; // fee unstake in 30 days
    }

    UserInfo[] public userInfoArray;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Reward(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    
    constructor(
        address _stakedToken,
        address _rewardToken,
        address _devWallet,
        address _feeWallet
    ) {
        stakedToken = ERC20(_stakedToken);
        rewardToken = ERC20(_rewardToken);
        devWallet = _devWallet;
        feeWallet = _feeWallet;
        isPause = true;
    }

    modifier isRun() {
        require(isPause == false, "Contract is paused");
        _;
    }

    modifier isValidTime() {
        require(block.timestamp > startTime, "Pool is not started yet");
        require(block.timestamp <= endTime, "Pool is ended");
        _;
    }
    modifier isValidBlock() {
        require(block.number > startBlock, "Pool is not started yet");
        require(block.number <= endBlock, "Pool is ended");
        _;
    }

    function setRunTogetherPoolStore(address _runTogetherPoolStore) public onlyOwner {
        runTogetherPoolStore = IRunTogetherPoolStore(_runTogetherPoolStore);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount, address _user)
        external
        nonReentrant
        isRun
        isValidTime
        isValidBlock
    {   
        require(_user == msg.sender, "Invalid user");
        require(blacklistMap[_user] == false, "You are in Blacklist");
        require(_amount > 0, "Amount must be greater than 0");

        amountStakedToken = amountStakedToken.add(_amount);
        require(amountStakedToken <= maxAmountStake, "Pool is full");

        UserInfo storage user = userInfo[_user];
        
        bool isNewUser = false;
        if (user.userAddress == address(0)) {
            isNewUser = true;
        }

        if (user.amount > 0) {
            uint256 pending = pendingReward(_user);
            if (pending > 0) {
                rewardToken.safeTransfer(_user, pending);
                emit Reward(_user, pending);
            }
        }

        user.amount = user.amount.add(_amount);
        user.unstakeLockTime = block.timestamp.add(lockStakeDuration);
        user.feeUnstakeTime = new uint256[](feeUnstakeDuration.length);
        for (uint256 i = 0; i < feeUnstakeDuration.length; i++) {
            user.feeUnstakeTime[i] = block.timestamp.add(feeUnstakeDuration[i]);
        }
        stakedToken.safeTransferFrom(_user, address(this), _amount);
        user.stakeBlock = block.number;
        user.userAddress = _user;

        if (isNewUser) {
            userInfoArray.push(user);
        }
        
        runTogetherPoolStore.updatePool(runTogetherPoolStore.poolLength() - 1, _user);
        emit Deposit(_user, _amount);
    }

    //show user info array
    function getUserInfoArray(uint256 _index) public view returns(address) {
        return userInfoArray[_index].userAddress;
    }

    //show user info array length
    function getUserInfoArrayLength() public view returns(uint256) {
      return userInfoArray.length;
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount, address _user) external nonReentrant isRun {
        require(_user == msg.sender, "Invalid user");
        require(blacklistMap[_user] == false, "You are in Blacklist");
        UserInfo storage user = userInfo[_user];
        require(_amount <= user.amount, "Amount to withdraw not enough");

        uint256 pending = pendingReward(_user);

        if (_amount > 0) {
            require(user.unstakeLockTime < block.timestamp, "You can not unstake now");
            user.amount = user.amount.sub(_amount);
            uint256 amountWithdraw = _amount;
            for (uint256 i = 0; i < feeUnstakeDuration.length; i++) {
                if (user.feeUnstakeTime[i] > block.timestamp) {
                    uint256 fee = _amount.mul(feeUnstake[i]).div(baseRate);
                    amountWithdraw = amountWithdraw.sub(fee);
                    stakedToken.safeTransfer(feeWallet, fee);
                    break;
                }
            }
            stakedToken.safeTransfer(_user, amountWithdraw);
        }

        if (pending > 0) {
            rewardToken.safeTransfer(_user, pending);
            user.stakeBlock = block.number;
            emit Reward(_user, pending);
        }

        amountStakedToken -= _amount;
        
        runTogetherPoolStore.updatePool(runTogetherPoolStore.poolLength() - 1, _user);
        emit Withdraw(_user, _amount);
    }

    // Calculate benefit based on block number
    function pendingReward(address _user)
        public
        view
        returns (uint256 _totalGain)
    {
        UserInfo memory user = userInfo[_user];
        if (block.number - user.stakeBlock > minBlock) {
            uint256 currentBlock = Math.min(block.number, endBlock);
            uint256 totalBlock = currentBlock - user.stakeBlock;
            uint256 userAmount = user.amount;
            // Calculate reward for each block

            _totalGain = totalBlock
                .mul(userAmount)
                .mul(rateReward)
                .mul(rateRewardToken)
                .div(rateStakedToken)
                .div(baseRate)
                .div(blockPerYear);

            if (stakedToken == rewardToken) {
                _totalGain = _totalGain.mul(rateRewardToken).div(rateStakedToken);
            }
        } else {
            _totalGain = 0;
        }
    }

    function getUserInfoAmount(address _user) public view returns (uint256) {
        return userInfo[_user].amount;
    }

    function setPauseContract(bool _status) external onlyOwner {
        isPause = _status;
    }

    function setMaxAmountStake(uint256 _maxAmountStake) external onlyOwner {
        maxAmountStake = _maxAmountStake;
    }

    function setRate(
        uint256 _rateReward,
        uint256 _rateStakedToken,
        uint256 _rateRewardToken
    ) external onlyOwner {
        rateReward = _rateReward;
        rateStakedToken = _rateStakedToken;
        rateRewardToken = _rateRewardToken;
    }

    function setTimeDuration(
        uint256 _lockStakeDuration,
        uint256[] calldata _feeUnstakeDuration
    ) external onlyOwner {
        lockStakeDuration = _lockStakeDuration;
        feeUnstakeDuration = _feeUnstakeDuration;
    }

    function setMinBlock(uint256 _minBlock) external onlyOwner {
        minBlock = _minBlock;
    }

    function setFeeUnstake(uint256[] calldata _feeUnstake) external onlyOwner {
        feeUnstake = _feeUnstake;
    }

    function setStartEndTimePool(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        startTime = _startTime;
        endTime = _endTime;
    }

    function setStartEndBlockPool(uint256 _startBlock, uint256 _endBlock)
        external
        onlyOwner
    {
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function setToken(address _stakedToken, address _rewardToken)
        external
        onlyOwner
    {
        stakedToken = ERC20(_stakedToken);
        rewardToken = ERC20(_rewardToken);
    }

    function setBlockPerYear(uint256 _blockPerYear) external onlyOwner {
        blockPerYear = _blockPerYear;
    }

    function setBlackList(address[] calldata userList) external onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            blacklistMap[userList[index]] = true;
        }
    }

    function removeBlackList(address[] calldata userList) external onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            blacklistMap[userList[index]] = false;
        }
    }

    function setFeeWallet(address _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
    }

    /*
    * @notice Withdraw staked tokens without caring about rewards rewards
    * @dev Needs to be for emergency.
    */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw() external onlyOwner {
        uint256 withdrawAmount = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(devWallet, withdrawAmount);
    }
}