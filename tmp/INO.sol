// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract LiveTradeINO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public addressPaymentToken;
    address public devWallet;
    address public addressNftClaim;
    address public addressStakingToken;
    uint256 public priceNft;
    uint256 public startTimeLock;
    uint256 public endTimeLock;
    uint256 public totalNftSupply;
    uint256 public amountStakingFCFS;
    uint256 public limitAmountBuyFCFS;
    uint256 public limitAmountBuyMembership;

    //mapping
    mapping(address => uint256) public amountNftClaimMap;
    mapping(address => bool) public userStakeMap;
    mapping(address => uint256) public userStakeNftIndexMap;
    mapping(address => bool) public userFCFSMap;
    mapping(address => bool) public userMembershipMap;
    mapping(address => bool) public userRegisBuyMap;
    mapping(address => uint256) public amountRegisBuyMap;
    mapping(address => bool) public userBuyCompleteMap;

    constructor()
    {

    }

    struct LevelBuyNft {
        uint256 levelIndex;
        uint256 amountClaimNft;
        address addressNftStake;
    }

    LevelBuyNft[] public listLevelBuyNft;

    function setupAddress(address _addressStakingToken, address _addressPaymentToken, address _addressNftClaim, address _devWallet) public onlyOwner {
        addressPaymentToken = _addressPaymentToken;
        devWallet = _devWallet;
        addressNftClaim = _addressNftClaim;
        addressStakingToken = _addressStakingToken;
    }

    function setPriceNft(uint256 _priceNft) public onlyOwner {
        priceNft = _priceNft;
    }

    function setLevelStake(uint256[] calldata _maxAmountBuyNft, address[] calldata _addressNftStake) public onlyOwner {
        delete listLevelBuyNft;
        LevelBuyNft memory levelBuyNft;
        for(uint256 index = 0; index < _maxAmountBuyNft.length; index++)
        {
            levelBuyNft.levelIndex;
            levelBuyNft.amountClaimNft =  _maxAmountBuyNft[index];
            levelBuyNft.addressNftStake = _addressNftStake[index];
            listLevelBuyNft.push(levelBuyNft);
        }
    }

    function setUpINO(uint256 _startTimeLock, uint256 _endTimeLock, uint256 _amountStakingFCFS, uint256 _priceNft, uint256 _limitAmountBuyFCFS, uint256 _limitAmountBuyMembership) public onlyOwner
    {
        totalNftSupply = ERC721(addressNftClaim).balanceOf(address(this));
        require(_limitAmountBuyFCFS + _limitAmountBuyMembership == totalNftSupply, "Invalid limit");
        startTimeLock = _startTimeLock;
        endTimeLock = _endTimeLock;
        amountStakingFCFS = _amountStakingFCFS;
        priceNft = _priceNft;
        limitAmountBuyFCFS = _limitAmountBuyFCFS;
        limitAmountBuyMembership = _limitAmountBuyMembership;
    }

    function setTimeINO(uint256 _startTimeLock, uint256 _endTimeLock) public onlyOwner
    {
        startTimeLock = _startTimeLock;
        endTimeLock = _endTimeLock;
    }

    function registerBuyForFCFS() public{
        require(userFCFSMap[msg.sender] == false, "You have staking as FCFS");
        require(userMembershipMap[msg.sender] == false, "You have staking as membership");
        require(userRegisBuyMap[msg.sender] == false, "You have regis before");
        require(limitAmountBuyFCFS - 1 >= 0, "Not enough balance to buy");
        ERC20(addressStakingToken).transferFrom(msg.sender, address(this), amountStakingFCFS);
        userFCFSMap[msg.sender] = true;
        userRegisBuyMap[msg.sender] = true;
        limitAmountBuyFCFS --;
    }

    function registerBuyForMembership(uint256 _levelIndex) public {
        require(userFCFSMap[msg.sender] == false, "You have staking as FCFS");
        require(userMembershipMap[msg.sender] == false, "You have staking as membership");
        require(userRegisBuyMap[msg.sender] == false, "You have regis before");

        LevelBuyNft storage levelBuyNft = listLevelBuyNft[_levelIndex];

        uint256 amountNftRegisBuy = levelBuyNft.amountClaimNft;

        require(limitAmountBuyMembership - amountNftRegisBuy >= 0, "Not enough balance to buy");

        address addressNftStake = levelBuyNft.addressNftStake;
        uint256 idNFTStake = ERC721Enumerable(addressNftStake).tokenOfOwnerByIndex(msg.sender, 0);
        ERC721(addressNftStake).safeTransferFrom(msg.sender, address(this), idNFTStake);

        amountNftClaimMap[msg.sender] = amountNftRegisBuy;
        userStakeNftIndexMap[msg.sender] = _levelIndex;
        if(_levelIndex == 0)
        {
            userFCFSMap[msg.sender] = true;
        }
        else
        {
            userMembershipMap[msg.sender] = true;
        }
        amountRegisBuyMap[msg.sender] = levelBuyNft.amountClaimNft;
        userRegisBuyMap[msg.sender] = true;
        limitAmountBuyMembership -= amountNftRegisBuy;
    }

    function buyNftOfFCFS() public nonReentrant {
        require(block.timestamp > endTimeLock, "In time lock");
        require(userRegisBuyMap[msg.sender] == true, "You must regis buy first");
        require(userFCFSMap[msg.sender] == true, "You are Membership");
        require(userBuyCompleteMap[msg.sender] == false, "You have bought");

        ERC20(addressPaymentToken).transferFrom(msg.sender, devWallet, priceNft);
        uint256 idNFTOfFCFS = ERC721Enumerable(addressNftClaim).tokenOfOwnerByIndex(address(this), 0);
        ERC721(addressNftClaim).safeTransferFrom(address(this), msg.sender, idNFTOfFCFS); 
        userBuyCompleteMap[msg.sender] = true;
    }

    function buyNftOfMembership(uint256 _amountNftToBuy) public {
        require(block.timestamp > endTimeLock, "In time lock");
        require(userRegisBuyMap[msg.sender] == true, "You must regis buy first");
        require(_amountNftToBuy <= amountRegisBuyMap[msg.sender], "Expected quantity exceeds max NFT");
        require(userMembershipMap[msg.sender] == true, "You are FCFS");

        uint256 totalPriceNft = _amountNftToBuy.mul(priceNft);
        ERC20(addressPaymentToken).transferFrom(msg.sender, devWallet, totalPriceNft);
        for(uint256 index = 0; index < _amountNftToBuy; index++)
        {
            uint256 idNFTOfWhitelist = ERC721Enumerable(addressNftClaim).tokenOfOwnerByIndex(address(this), 0);
            ERC721(addressNftClaim).safeTransferFrom(address(this), msg.sender, idNFTOfWhitelist);
        }
        amountRegisBuyMap[msg.sender] -= _amountNftToBuy;
    }

    function withDrawNftForUser() public nonReentrant {
        LevelBuyNft storage levelBuyNft = listLevelBuyNft[userStakeNftIndexMap[msg.sender]];
        address addressNftStake = levelBuyNft.addressNftStake;

        uint256 idNFTStake = ERC721Enumerable(addressNftStake).tokenOfOwnerByIndex(address(this), 0);
        ERC721(addressNftStake).safeTransferFrom(address(this), msg.sender, idNFTStake);
    }

    function withDrawNftForOwner() public onlyOwner {
        uint256 amountWithDraw = ERC721(addressNftClaim).balanceOf(address(this));
        for(uint256 index = 0; index < amountWithDraw; index++)
        {
            uint256 idNFTWithDraw = ERC721Enumerable(addressNftClaim).tokenOfOwnerByIndex(address(this), 0);
            ERC721(addressNftClaim).safeTransferFrom(address(this), msg.sender, idNFTWithDraw);
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}