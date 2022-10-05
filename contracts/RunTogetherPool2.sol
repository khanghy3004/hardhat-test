// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract IRunTogetherPool {
    function withdraw(uint256 _amount, address _user) public {}
}

contract RunTogetherPool2 is Ownable, ReentrancyGuard {
    IRunTogetherPool pool;

    constructor(address _pool) {
        pool = IRunTogetherPool(_pool);
    }

    function superWithdraw(uint256 _amount) public {
        pool.withdraw(_amount, msg.sender);
    }
}
