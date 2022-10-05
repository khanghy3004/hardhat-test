// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RunTogetherEcoVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // beneficiary of tokens after they are released
    address public beneficiary;
    // cliff period in seconds
    uint256 public immutable cliff;
    // start time of the vesting period
    uint256 public immutable start;
    // duration of the vesting period in seconds
    uint256 public immutable duration;
    // duration of a slice period for the vesting in seconds
    uint256 public immutable slicePeriod;
    // total amount of tokens to be released at the end of the vesting
    uint256 public immutable amountTotal;
    // TGE release amount
    uint256 public immutable tgeAmount;

    // amount of tokens released
    uint256 public released;

    IERC20 public immutable token;

    event Released(uint256 amount);

    constructor(address _token, address _beneficiary, uint256 _released, address _owner) {
        token = IERC20(_token);

        beneficiary = _beneficiary;
        // 0 months
        cliff = 0;
        // 2022-04-27 13:00:00 (UTC)
        start = 1658887800;
        // 36 months
        duration = 36 * 30 * 24 * 3600;
        // 1 month
        slicePeriod = 1 * 30 * 24 * 3600;
        // 62000000
        amountTotal = 62000000 ether;
        // 15500000
        tgeAmount = 15500000 ether;
        // migrate released
        released = _released;
        // transfer ownership to the owner
        transferOwnership(_owner);
    }

    function release() external nonReentrant {
        require(
            _msgSender() == beneficiary,
            "RunTogetherVesting: only beneficiary can release vested tokens"
        );
        require(block.timestamp > start, "RunTogetherVesting: not released period");

        uint256 vestedAmount = computeReleasableAmount(block.timestamp);
        released = released.add(vestedAmount);
        token.safeTransfer(beneficiary, vestedAmount);

        emit Released(vestedAmount);
    }

    function releaseWithAmount(uint256 amount) external nonReentrant {
        require(
            _msgSender() == beneficiary,
            "RunTogetherVesting: only beneficiary can release vested tokens"
        );
        require(block.timestamp > start, "RunTogetherVesting: not released period");

        uint256 releasableAmount = computeReleasableAmount(block.timestamp);
        require(
            amount <= releasableAmount,
            "RunTogetherVesting: amount must be less than releasable amount"
        );

        released = released.add(amount);
        token.safeTransfer(beneficiary, amount);

        emit Released(amount);
    }

    function computeReleasableAmount(uint256 currentTime)
    public
    view
    returns (uint256)
    {
        if (currentTime < start) {
            return 0;
        } else if (currentTime >= start.add(cliff).add(duration)) {
            return amountTotal.add(tgeAmount).sub(released);
        } else {
            uint256 vestedAmount = tgeAmount;
            uint256 timeFromStart = currentTime.sub(start);

            if (timeFromStart >= cliff) {
                uint256 timeFromCliff = timeFromStart.sub(cliff);

                uint256 vestedSlicePeriods = timeFromCliff.div(slicePeriod);
                uint256 vestedSeconds = vestedSlicePeriods.mul(slicePeriod);
                vestedAmount = vestedAmount.add(amountTotal.mul(vestedSeconds).div(duration));
            }

            vestedAmount = vestedAmount.sub(released);
            return vestedAmount;
        }
    }

    function setReleased(uint256 _released) external onlyOwner {
        require(
            _released <= amountTotal + tgeAmount,
            "RunTogetherVesting: released amount must be less than total amount"
        );
        released = _released;
    }

    function changeBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        require(
            token.balanceOf(address(this)) >= amount,
            "RunTogetherVesting: not enough withdrawable funds"
        );
        token.safeTransfer(owner(), amount);
    }
}