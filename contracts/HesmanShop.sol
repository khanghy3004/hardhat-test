// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HesmanShop is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20; 

    address paymentToken;

    // struct voucherDetail{
    //     uint256 voucherId;
    //     uint256 voucherPrice;
    // }

    mapping(uint256 => bool) public idExistedMap;
    mapping(uint256 => bool) public voucherSoldOutMap;
    mapping(uint256 => uint256) public idToPriceMap;
    //mapping(address => voucherDetail[]) public userVouchersMap;            //if necessary

    event EventBuyVoucher(address _user, uint256 _voucherId, uint256 _voucherPrice);

    constructor(address _paymentToken) {
        paymentToken = _paymentToken;
    }

    function setPaymentToken(address _paymentToken) public onlyOwner {
        paymentToken = _paymentToken;
    }

    function setVoucherForSell(uint256[] calldata _idList, uint256[] calldata _priceList) public onlyOwner {
        require (_idList.length == _priceList.length, "Number of id should equal number of price");

        for(uint256 index = 0; index < _idList.length; index++){
            // set voucher for sell
            voucherSoldOutMap[_idList[index]] = false;

            // add voucher 
            idExistedMap[_idList[index]] = true;
            idToPriceMap[_idList[index]] = _priceList[index];
        }  
    }

    function setVoucherSoldOut(uint256[] calldata _idList) public onlyOwner {

        for(uint256 index = 0; index < _idList.length; index++){
            voucherSoldOutMap[_idList[index]] = true;
        }  
    }

    function buyVoucher(uint256 _voucherId) public nonReentrant {
        require(idExistedMap[_voucherId] == true, "Voucher id not existed");
        require(voucherSoldOutMap[_voucherId] == false, "Voucher sold out");
        require(ERC20(paymentToken).balanceOf(msg.sender) >= idToPriceMap[_voucherId], "Not enough balance");

        ERC20(paymentToken).transferFrom(msg.sender, address(this), idToPriceMap[_voucherId]);
        voucherSoldOutMap[_voucherId] = true;

        emit EventBuyVoucher(msg.sender, _voucherId, idToPriceMap[_voucherId]);
    }

    function withdrawPaymentToken() external onlyOwner {
        uint256 withdrawAmount = ERC20(paymentToken).balanceOf(address(this));
        ERC20(paymentToken).transfer(msg.sender, withdrawAmount);
    }
}