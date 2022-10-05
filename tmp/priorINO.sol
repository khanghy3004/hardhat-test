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

contract BamiINOPrior is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct LevelStake {
        uint256 levelStakeId;
        uint256 amountOfLevelStake;
        uint256 maxNumberOfNftToBuy;
    }

    LevelStake[] public levelStakeList;

    uint256 public priceNft;
    uint256 public amountNftToDraw; 
    uint256 public startTimeBuy;
    uint256 public endTimeBuy;
    uint256 public startTimeClaim;
    uint256 public endTimeClaim;
    uint256 public startTimeLock;
    uint256 public endTimeLock;
    address public nftAddess;
    address public devWallet;
    address public tokenAddress;
    
    //mapping
    mapping(address => bool) public whiteListMap;
    mapping(address => uint256) public userStakeLevelMap;
    mapping(address => uint256) public NftQuantityPerUserMap;
    mapping(address => bool) public isClaimedMap;
    mapping(address => bool) public userIsBoughtMap;
    mapping(address => uint256) public userTotalPriceMap;

    //event
    event SetNewLevelStake(
        uint256 levelStakeId,
        uint256 amountOfLevelStake,
        uint256 maxNumberOfNftToBuy
    );
    event SetNewPrice(
        uint256 Price
    );
    event BuyNftComplete(
        uint256 purchaseQuantity,
        address buyer,
        uint256 userTotalPriceMap, 
        uint256 amountNftToDraw
    );
    event claimNftComplete(
        address claimer, 
        bool isClaim, 
        address devWallet,
        bool priorWhiteListMap
    );
    event SetNewTime(
        uint256 startTimeBuy, 
        uint256 endTimeBuy, 
        uint256 startTimeClaim, 
        uint256 endTimeClaim, 
        uint256 startTimeLock, 
        uint256 endTimeLock
    );
    event stakingComplete(
        uint256 levelStakeId,
        uint256 amountOfLevelStake,
        uint256 maxNumberOfNftToBuy,
        address priorStaker
    );
    event WithDrawNftComplete(
        uint256 amountNft,
        uint256 arrayNftId
    );
    event WithDrawTokenComplete(
        uint256 userStakeLevelMap, 
        uint256 amountWithDraw
    );

    constructor(address _devWallet, address _nftAddress, address _tokenAddress, uint256 _priceNft){
        devWallet = _devWallet;
        nftAddess = _nftAddress;
        tokenAddress = _tokenAddress;
        priceNft = _priceNft;
    }

    //set staking level for priority user
    function setStakeLevel(uint256[] calldata _amountOfLevelStake, uint256[] calldata _maxNumberOfNftToBuy) public onlyOwner {
        delete levelStakeList;
        LevelStake memory levelStake;
        amountNftToDraw = IERC721(nftAddess).balanceOf(address(this));
        for (uint256 index = 0; index < _amountOfLevelStake.length; index++){
            uint256 amountOfLevelStake = _amountOfLevelStake[index];
            uint256 maxNumberOfNftToBuy = _maxNumberOfNftToBuy[index];
            levelStake.levelStakeId = index;
            levelStake.amountOfLevelStake = amountOfLevelStake;
            levelStake.maxNumberOfNftToBuy = maxNumberOfNftToBuy;
            levelStakeList.push(levelStake);
        }
        emit SetNewLevelStake (levelStake.levelStakeId, levelStake.amountOfLevelStake, levelStake.maxNumberOfNftToBuy);
    }

    //set price of nft
    function setPriceNft(uint256 _priceNft) public {
        priceNft = _priceNft;
        emit SetNewPrice(priceNft);
    }
    
    //buy nft
    function registerToBuyNft(uint256 purchaseQuantity) public {
        uint256 checkQuantity = NftQuantityPerUserMap[msg.sender];
        require(block.timestamp >= startTimeBuy,"NFT is not open for sale yet");
        require(block.timestamp <= endTimeBuy,"Time ended");
        require(whiteListMap[msg.sender] == true, "You not in whitelist, please staking NFT for joined whitelist");

        LevelStake storage levelStake = levelStakeList[userStakeLevelMap[msg.sender]];

        require(amountNftToDraw > 0, "Out of stock");
        require((checkQuantity+purchaseQuantity) <= levelStake.maxNumberOfNftToBuy, "Expected quantity exceeds max NFT");
        
        NftQuantityPerUserMap[msg.sender] += purchaseQuantity;
        userTotalPriceMap[msg.sender] = NftQuantityPerUserMap[msg.sender] * priceNft;
        amountNftToDraw-=purchaseQuantity;
        userIsBoughtMap[msg.sender] = true;
        
        emit BuyNftComplete(purchaseQuantity, msg.sender, userTotalPriceMap[msg.sender], amountNftToDraw);
    }

    //payment to claim
    function NftPayment() private{
        require(userIsBoughtMap[msg.sender] == true, "You must buy first");
        require(whiteListMap[msg.sender]==true, "You are not in white list");
        require(IERC20(tokenAddress).balanceOf(msg.sender)>=userTotalPriceMap[msg.sender], "Not enough balance to pay");
        IERC20(tokenAddress).safeTransferFrom(msg.sender,devWallet,userTotalPriceMap[msg.sender]);
    }

    //Prior claim
    function claimNft() external nonReentrant{
        require(block.timestamp >= startTimeClaim, "Claim time is not started yet");
        require(block.timestamp <= endTimeClaim,"Claim time ended");
        require(isClaimedMap[msg.sender]==false, "You have claimed");

        NftPayment();

        for(uint256 index = 0; index < NftQuantityPerUserMap[msg.sender]; index++)
        {
            uint256 priorNftId = ERC721Enumerable(nftAddess).tokenOfOwnerByIndex(address(this), 0);
            IERC721(nftAddess).transferFrom(address(this),msg.sender,priorNftId);
        }
        isClaimedMap[msg.sender] = true;
        
        emit claimNftComplete(msg.sender, isClaimedMap[msg.sender], devWallet, whiteListMap[msg.sender]);
    }

    //setup time: buy, claim, lock.
    function setTime(uint256 _startTimeBuy, uint256 _endTimeBuy, uint256 _startTimeClaim, uint256 _endTimeClaim, uint256 _startTimeLock, uint256 _endTimeLock) public onlyOwner{
        require(_startTimeBuy < _endTimeBuy, "Time Invalid");
        require(_startTimeClaim < _endTimeClaim, "Time Invalid");
        require(_startTimeClaim >= _endTimeBuy, "Time Invalid");
        require(_startTimeLock < _endTimeLock, "Time Invalid");
        require(_startTimeLock >= _endTimeClaim, "Time Invalid");
        
        startTimeBuy = _startTimeBuy;
        endTimeBuy = _endTimeBuy;
        startTimeClaim = _startTimeClaim;
        endTimeClaim = _endTimeClaim;
        startTimeLock = _startTimeLock;
        endTimeLock = _endTimeLock;
        
        emit SetNewTime(startTimeBuy, endTimeBuy, startTimeClaim, endTimeClaim, startTimeLock, endTimeLock);
    }

    //set time buy
    function setTimeBuy(uint256 _startTimeBuy, uint256 _endTimeBuy) public onlyOwner{
        require(_startTimeBuy < _endTimeBuy, "Time Invalid");

        startTimeBuy = _startTimeBuy;
        endTimeBuy = _endTimeBuy;
    }

    //set time claim
    function setTimeClaim(uint256 _startTimeClaim, uint256 _endTimeClaim) public onlyOwner{
        require(_startTimeClaim < _endTimeClaim, "Time Invalid");
        require(_startTimeClaim >= endTimeBuy, "Time Invalid");
        
        startTimeClaim = _startTimeClaim;
        endTimeClaim = _endTimeClaim;
    }

    //set time lock
    function setTimeLock(uint256 _startTimeLock, uint256 _endTimeLock) public onlyOwner{
        require(_startTimeLock < _endTimeLock, "Time Invalid");
        require(_startTimeLock >= endTimeClaim, "Time Invalid");
        
        startTimeLock = _startTimeLock;
        endTimeLock = _endTimeLock;
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

    //prior staking
    function stake(uint256 _levelStakeId) external nonReentrant{
        require(whiteListMap[msg.sender] == false, "You are already on the Prior whitelist");

        LevelStake storage levelStake = levelStakeList[_levelStakeId];
        uint256 amountOfLevelStake = levelStake.amountOfLevelStake;
        uint256 maxNumberOfNftToBuy = levelStake.maxNumberOfNftToBuy;

        require(IERC20(tokenAddress).balanceOf(msg.sender) >= amountOfLevelStake, "Not enough balance");
        
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amountOfLevelStake);
        userStakeLevelMap[msg.sender] = _levelStakeId;
        whiteListMap[msg.sender] = true;
        
        emit stakingComplete(_levelStakeId, amountOfLevelStake, maxNumberOfNftToBuy, msg.sender);
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

    //withdraw staking token for prior user
    function withdrawStakingToken() public nonReentrant {
        require(block.timestamp > endTimeLock, "INO is locking");
        
        LevelStake storage levelStake = levelStakeList[userStakeLevelMap[msg.sender]]; 
        uint256 amountWithDraw = levelStake.amountOfLevelStake;
        IERC20(tokenAddress).safeTransfer(msg.sender, amountWithDraw);
        
        emit WithDrawTokenComplete(userStakeLevelMap[msg.sender], amountWithDraw);
    }

    //view token amount can be withdrawn
    function viewStakingTokenAmount() public view returns(uint256 _amountWithDraw)
    {
        LevelStake storage levelStake = levelStakeList[userStakeLevelMap[msg.sender]]; 
        _amountWithDraw = levelStake.amountOfLevelStake;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}