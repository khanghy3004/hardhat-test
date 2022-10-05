// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BinanceCoin is ERC20, Ownable {
    constructor() ERC20("BinanceCoin", "BUSD") {
        _mint(address(this), 1000000000*1e18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}