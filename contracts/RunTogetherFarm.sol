// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// RUNToken Chef is the one who bakes Banh Mi and bring you the most delicious RUNToken
// We believe that everyone should be able to enjoy this kind of yummy food
// This is a reattempt to make a new Masterchef who named RUNToken Chef and will make RUNToken
// for all of us
// God bless this contract
contract ChefRUNToken is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        address fundedBy; // Funded by address()
        //
        // We do some fancy math here. Basically, any point in time, the amount of RUNTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRUNTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRUNTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User's `amount` gets updated.
        //   3. User's `rewardDebt` gets updated.
        //   4. User's `fundedBy` updated by User address
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. RUNTokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that RUNTokens distribution occurs.
        uint256 accRUNTokenPerShare; // Accumulated RUNTokens per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
    }

    // The RUNToken TOKEN!
    IERC20 public RUNToken;
    // Dev address.
    address public devaddr;
    address public fundingaddr;
    // RUNToken tokens created per block.
    uint256 public RUNTokenPerBlock;
    // Bonus muliplier for early RUNToken makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when RUNToken rewarding starts.
    uint256 public startBlock;
    // The block number when RUNToken rewarding has to end.
    uint256 public finalRewardBlock;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 goosePerBlock);
    event UpdateFinalBlock(address indexed user, uint256 newFinalBlock);

    constructor(
        IERC20 _RUNToken,
        address _devaddr,
        address _feeAddress,
        address _fundingaddr,
        uint256 _RUNTokenPerBlock,
        uint256 _startBlock,
        uint256 _finalRewardBlock
    ) {
        fundingaddr = _fundingaddr;
        RUNToken = _RUNToken;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        startBlock= _startBlock;
        RUNTokenPerBlock = _RUNTokenPerBlock;
        finalRewardBlock = _finalRewardBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner nonDuplicated(_lpToken) {
        require(
            _depositFeeBP <= 10000,
            "add: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRUNTokenPerShare: 0,
                depositFeeBP: _depositFeeBP
            })
        );
    }

    // Update the given pool's RUNToken allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "set: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to, uint256 _finalRewardBlock) public pure returns (uint256) {
        if( _to > _finalRewardBlock)
        {
            return _finalRewardBlock.sub(_from).mul(BONUS_MULTIPLIER);
        }
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending RUNTokens on frontend.
    function pendingRUNToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRUNTokenPerShare = pool.accRUNTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && finalRewardBlock > pool.lastRewardBlock  && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, finalRewardBlock);
            uint256 RUNTokenReward = multiplier.mul(RUNTokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRUNTokenPerShare = accRUNTokenPerShare.add(
                RUNTokenReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accRUNTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock || finalRewardBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, finalRewardBlock);
        uint256 RUNTokenReward =
            multiplier.mul(RUNTokenPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accRUNTokenPerShare = pool.accRUNTokenPerShare.add(
            RUNTokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for RUNToken allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        // Harvest the remaining token before calculate new amount
        _harvest(msg.sender, _pid);
        if (_amount > 0) {
            pool.lpToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.transfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
            if (user.fundedBy == address(0)) user.fundedBy = msg.sender;
        }
        user.rewardDebt = user.amount.mul(pool.accRUNTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(user.fundedBy == msg.sender, "withdraw:: only funder");
        updatePool(_pid);
        // Effects
        _harvest(msg.sender, _pid);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.transfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRUNTokenPerShare).div(1e12);
        if (user.amount == 0) user.fundedBy = address(0);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Harvest RUNToken earn from the pool.
    function harvest(uint256 _pid) public {
        updatePool(_pid);
        _harvest(msg.sender, _pid);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of RUNToken rewards.
    function _harvest(address to, uint256 pid)
        internal
    {
        PoolInfo memory pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][to];
        uint256 accumulatedRUNToken =
            user.amount.mul(pool.accRUNTokenPerShare).div(1e12);

        uint256 _pendingRUNToken = accumulatedRUNToken.sub(user.rewardDebt);
        if (_pendingRUNToken == 0) {
            return;
        }


        require(
            _pendingRUNToken <= RUNToken.balanceOf(fundingaddr),
            "ChefRUNToken::_harvest:: wtf not enough RUNToken"
        );

        // Effects
        user.rewardDebt = accumulatedRUNToken;

        safeRUNTokenTransfer(to, _pendingRUNToken);

        emit Harvest(msg.sender, pid, _pendingRUNToken);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe RUNToken transfer function, just in case if rounding error causes pool to not have enough RUNTokens.
    function safeRUNTokenTransfer(address _to, uint256 _amount) internal {
        uint256 RUNTokenBal = RUNToken.balanceOf(fundingaddr);
        bool transferSuccess = false;
        if (_amount > RUNTokenBal) {
            transferSuccess = RUNToken.transferFrom(fundingaddr, _to, RUNTokenBal);
        } else {
            transferSuccess = RUNToken.transferFrom(fundingaddr, _to, _amount);
        }
        require(transferSuccess, "safeRUNTokenTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _RUNTokenPerBlock) public onlyOwner {
        massUpdatePools();
        RUNTokenPerBlock = _RUNTokenPerBlock;
        emit UpdateEmissionRate(msg.sender, _RUNTokenPerBlock);
    }
    
    function updateFinalBlockReward(uint256 _newFinalBlock) public onlyOwner {
        finalRewardBlock = _newFinalBlock;
        emit UpdateEmissionRate(msg.sender, _newFinalBlock);
    }
    
}