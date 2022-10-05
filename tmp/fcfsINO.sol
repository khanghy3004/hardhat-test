// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

contract BamiINOFCFS is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    uint256 public priceNft;
    uint256 public startTimeClaim;
    uint256 public endTimeClaim;
    uint256 public amountStaking;
    address public nftAddess;
    address public devWallet;
    address public tokenAddress;
    
    //mapping
    mapping(address => bool) public whiteListMap;
    mapping(address => uint256) public userStakeLevelMap;
    mapping(address => uint256) public NftQuantityPerUserMap;
    mapping(address => bool) public isClaimedMap;

    //event
    event SetNewPrice(
        uint256 Price
    );
    event claimNftComplete(
        address claimer, 
        bool isClaim, 
        address devWallet,
        bool whiteListMap
    );
    event WithDrawNftComplete(
        uint256 amountNft,
        uint256 arrayNftId
    );

    constructor(address _devWallet, address _nftAddress, address _tokenAddress, uint256 _priceNft) {
        devWallet = _devWallet;
        nftAddess = _nftAddress;
        tokenAddress = _tokenAddress;
        priceNft = _priceNft;
    }

    //set price of nft
    function setPriceNft(uint256 _priceNft) public {
        priceNft = _priceNft;
        emit SetNewPrice(priceNft);
    }

    //FCFS claim
    function claimNft() external nonReentrant{
        // require(block.timestamp >= startTimeClaim, "Claim time is not started yet");
        // require(block.timestamp <= endTimeClaim,"Claim time ended");
        require(whiteListMap[msg.sender]==true, "You are not in white list");
        require(isClaimedMap[msg.sender]==false, "You have claimed");
        require(IERC721(nftAddess).balanceOf(address(this)) > 0, "Out of stock");
        require(IERC20(tokenAddress).balanceOf(msg.sender)>=priceNft, "Not enough balance to pay");

        IERC20(tokenAddress).safeTransferFrom(msg.sender,devWallet,priceNft);
        uint256 tokenOwnerId = ERC721Enumerable(nftAddess).tokenOfOwnerByIndex(address(this), 0);
        IERC721(nftAddess).transferFrom(address(this),msg.sender,tokenOwnerId);
        isClaimedMap[msg.sender] = true; 

        emit claimNftComplete(msg.sender, isClaimedMap[msg.sender], devWallet, whiteListMap[msg.sender]);
    }

    //set time claim
    function setTimeClaim(uint256 _startTimeClaim, uint256 _endTimeClaim) public onlyOwner{
        require(_startTimeClaim < _endTimeClaim, "Time Invalid");
        
        startTimeClaim = _startTimeClaim;
        endTimeClaim = _endTimeClaim;
    }

    //set dev wallet
    function setDevWallet(address _devWallet) public onlyOwner{
        devWallet = _devWallet;
    }

    //set nft address
    function setNftAddress(address _nftAddress) public onlyOwner {
      nftAddess = _nftAddress;
    }

    //set token address
    function setTokenAddress(address _tokenAddress) public onlyOwner {
      tokenAddress = _tokenAddress;
    }

    //set amount to stake per FCFS user
    function setAmountStaking (uint256 _amountStaking) public onlyOwner {
        amountStaking = _amountStaking;
    }

    //FCFS staking
    function stake() external nonReentrant {
        require(whiteListMap[msg.sender] == false, "You are already on the FCFS whitelist");
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= amountStaking, "Not enough balance");

        console.log(msg.sender);
        console.log(IERC20(tokenAddress).balanceOf(msg.sender));
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amountStaking);
        console.log(IERC20(tokenAddress).balanceOf(msg.sender));

        whiteListMap[msg.sender] = true;
    }
    
    //withdraw remaining NFT 
    function withdrawRemainingNft() public onlyOwner nonReentrant {
        uint256 amountNft = IERC721(nftAddess).balanceOf(address(this));

        require(amountNft > 0, "You have withdraw all NFT");

        uint256[] memory arrayNftId = new uint256[](amountNft);
        
        for(uint256 index = 0; index < amountNft; index++)
        {
            arrayNftId[index]= ERC721Enumerable(nftAddess).tokenOfOwnerByIndex(address(this), index);
        }
        for(uint256 index = 0; index < arrayNftId.length; index++)
        {
            IERC721(nftAddess).transferFrom(address(this), devWallet, arrayNftId[index]);
            emit WithDrawNftComplete(amountNft, arrayNftId[index]);
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}