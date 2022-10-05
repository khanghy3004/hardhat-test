// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract HesmanStakingV3 is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for ERC20; 

    mapping(address => uint256) public stakeBlock;
    mapping(address => uint256[]) public nftIdList;
    mapping(address => bool) public blacklistMap;
    mapping(address => bool) public isStaked;
    mapping(address => uint256) amountClaim;

    // General
    bool public isPause;
    uint256 generalDec = 10 ** 18;
    uint256 public nftToHes = 5000 * generalDec;  //  number of HES token equivalent 1 HESIC
    uint256 public minInterest = nftToHes.mul(15).div(100).div(10368000);   //calculate interest of 1 block
    bool isStopProfit;
    
    // Token
    ERC20 public hesmanToken; // HES
    address public hesicNftAddress;  // HESIC

    // Time
    // Stake: HESMAN 
    uint256 public startStakeTime;
    uint256 public endStakeTime;
    uint256 public unStakeTime; 
    uint256 public totalUserStaked;
    
    // Event
    event EventUserStake(address user, uint256 numberOfNft, uint256 blockNumber, uint256 amount);
    event EventUserStakeNFT(address indexed user, address nft, uint256 tokenId, uint256 blockNumber);
    event EventUserUnstake(address user, uint256 blockNumber, uint256 amount);
    event EventUserClaimNFT(address indexed user, address nft, uint256 tokenId, uint256 blockNumber);
    event EventUserClaim(address user, uint256 amount, uint256 blockNumber);

    constructor(
        address _hesmanToken,
        address _hesicNftAddress
    ) {
        hesmanToken = ERC20(_hesmanToken);
        hesicNftAddress = _hesicNftAddress;    

        isPause = true; // Mark pause if deploy
    }

    // Modifier
    modifier isRun() {
        require(isPause == false, "Contract is paused");
        _;
    }

    modifier validStakeTime() {
      require(startStakeTime < block.timestamp, "Time staking invalid");
      require(block.timestamp < endStakeTime, "Time staking invalid");
    _;
  }
    function setStopProfit(bool _status) public onlyOwner {
        isStopProfit = _status;
    }

    function setPauseContract(bool _status) public onlyOwner {
        isPause = _status;
    }

    function setToken(address _hesmanToken, address _hesicNftAddress) public onlyOwner {
        hesmanToken = ERC20(_hesmanToken);
        hesicNftAddress = _hesicNftAddress;
    }

        // set number of HES token equivalent 1 HESIC and re-calculate interest of 1 block
    function setNftToHes(uint256 _nftToHes) public onlyOwner{
        nftToHes = _nftToHes;
        minInterest = nftToHes.mul(15).div(100).div(10368000);
    }

    function setBlackList(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
        blacklistMap[userList[index]] = true;
        }
    }

    function removeBlackList(address[] calldata userList) public onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
        blacklistMap[userList[index]] = false;
        }
    }

    function setConfig(
            uint256 _startStakeTime,
            uint256 _endStakeTime
        ) public onlyOwner {
        
        require(_startStakeTime < _endStakeTime, "Input time staking invalid");

        startStakeTime = _startStakeTime;
        endStakeTime = _endStakeTime;
        unStakeTime = startStakeTime+1;
    }

    // Staking HESIC to get interest
    function stakeNft(uint256[] calldata _idNftList) public nonReentrant isRun {
        require(blacklistMap[msg.sender] == false, "You are in Blacklist");
        require(_idNftList.length > 0, "NFTs have to be greater than 0");
        require(_idNftList.length <= 50, "Max 50 NFTs");
        require(IERC721(hesicNftAddress).balanceOf(msg.sender) > 0, "No NFT");

        interestCalculate(block.number - stakeBlock[msg.sender]);
        stakeBlock[msg.sender] = block.number;   // reset stake block

        // get staked NFTs from user
        for(uint256 index = 0; index < _idNftList.length; index++){
            IERC721(hesicNftAddress).transferFrom(msg.sender, address(this), _idNftList[index]);
            nftIdList[msg.sender].push(_idNftList[index]);

            emit EventUserStakeNFT(msg.sender, hesicNftAddress, _idNftList[index], block.number);
        }

        // Increase total number of user staked if user stake for the first time
        if(isStaked[msg.sender] == false){
            totalUserStaked++;
        }

        isStaked[msg.sender] = true;

        // transfer interest to user
        hesmanToken.safeTransfer(msg.sender, amountClaim[msg.sender]);

        emit EventUserStake(msg.sender, _idNftList.length , block.number, amountClaim[msg.sender]);

    }

    function unstakeNft(uint256[] calldata _idNftList) public nonReentrant {
        require(blacklistMap[msg.sender] == false, "You are in Blacklist");
        require(_idNftList.length > 0, "Min 1 NFT");
        require(_idNftList.length <= 50, "Max 50 NFTs");
        require(_idNftList.length <= nftIdList[msg.sender].length,"Amount exceeded");
        
        uint256 userNft = nftIdList[msg.sender].length;
        interestCalculate(block.number - stakeBlock[msg.sender]);
        stakeBlock[msg.sender] = block.number;  // reset stake block
        
        for (uint256 index = 0; index < _idNftList.length; index++) {
            // Check if NFT exist in list
            require(checkExistNft(_idNftList[index]) == true, "NFT not exist in list");

            // Give back NFT
            IERC721(hesicNftAddress).transferFrom(address(this), msg.sender, _idNftList[index]);

            // swap NFT position in list
            nftIdList[msg.sender][findNftIndex(_idNftList[index])] = nftIdList[msg.sender][userNft-index-1];
            
            emit EventUserClaimNFT(msg.sender, hesicNftAddress, _idNftList[index], block.number); 
        }

        // Decrease total number of user staked if user unstake all NFT
        if(_idNftList.length == nftIdList[msg.sender].length){
            isStaked[msg.sender] = false;
            totalUserStaked--;
        }

        // remove staked NFTs of user
        for (uint256 index = 0; index < _idNftList.length; index++){
            nftIdList[msg.sender].pop();
        }

        // transfer interest to user
        hesmanToken.safeTransfer(msg.sender, amountClaim[msg.sender]);

        emit EventUserUnstake(msg.sender, block.number, amountClaim[msg.sender]);
    }

    // claim interest
    function claimToken() public nonReentrant isRun {
        require(blacklistMap[msg.sender] == false, "You are in Blacklist");
        
        interestCalculate(block.number - stakeBlock[msg.sender]);

        require(amountClaim[msg.sender] > 0, "No interest to claim");

        hesmanToken.safeTransfer(msg.sender, amountClaim[msg.sender]); // transfer interest to user
        stakeBlock[msg.sender] = block.number; // reset stake block

        emit EventUserClaim(msg.sender, amountClaim[msg.sender], block.number);
    }

    // get total number of staked NFT of user
    function getNftNumber(address user) public view returns(uint256){
        return nftIdList[user].length;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function emergencyWithdrawSaleToken() external onlyOwner {
        uint256 withdrawAmount = hesmanToken.balanceOf(address(this));
        hesmanToken.transfer(msg.sender, withdrawAmount);
    }

    function getInterest(address user) public view returns(uint256 nftTotalGain){ 
        nftTotalGain = (block.number - stakeBlock[user]).mul(nftIdList[user].length).mul(minInterest);
    }

    function getCurrentBlock() public view returns(uint256 blockNb){
        blockNb = block.number;
    }

    // Calculate benefit based on block number
    function interestCalculate(uint256 blockNumber) private {
        if (isStopProfit == false) {
            amountClaim[msg.sender] = blockNumber.mul(nftIdList[msg.sender].length).mul(minInterest);
        } else {
            amountClaim[msg.sender] = 0;
        }
    }

    function checkExistNft(uint256 nftId) private view returns(bool){
        for(uint256 index = 0; index < nftIdList[msg.sender].length; index++){
            if(nftId == nftIdList[msg.sender][index])
                return true;
        }
        return false;
    }

    function findNftIndex(uint256 nft) private view returns(uint256){
        for(uint256 index = 0; index < nftIdList[msg.sender].length; index++){
            if(nft == nftIdList[msg.sender][index])
                return index;
        }
        return 0;
    }


}
