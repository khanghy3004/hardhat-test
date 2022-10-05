// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";
contract FootEarnBamiINO is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for ERC20;
    using Counters for Counters.Counter;

    struct nftDetail{
        uint256 maxNumber;
        address nftAddress;
        uint256 price;
        uint256 tokenCount;
    }

    bool public isPause;
    uint256 public startTimeBuy;
    uint256 public endTimeBuy;
    uint256 public startTimeClaim;
    ERC20 public paymentToken;

    uint256[] nftTypeList;

    mapping(uint256 => nftDetail) nftTypeMap;
    mapping(uint256 => uint256) public nftCurrentNumber;
    mapping(address => bool) public inWhiteList;
    mapping(address => mapping(uint256 => uint256[])) public userBoughtNft;

    event BuyComplete(address user, uint256 _nftType, uint256 _nftPrice, uint256 _buyTime);
    event TransferComplete(address receiver, uint256 _nftType, uint256 _tokenId);
    event ClaimComplete(address receiver, uint256 _claimTime);

    constructor(
        address _paymentToken,
        address[] memory _nftAddress,
        uint256[] memory _maxNumber,
        uint256[] memory _price
    ){
        isPause = true;
        paymentToken = ERC20(_paymentToken);
        for(uint256 index = 0; index < _nftAddress.length; index++){
            nftTypeMap[index+1].nftAddress = _nftAddress[index];
            nftTypeMap[index+1].maxNumber = _maxNumber[index];
            nftTypeMap[index+1].price = _price[index];
            nftCurrentNumber[index+1] = _maxNumber[index];
            nftTypeList.push(index+1);
        }
    }

    modifier isRun() {
        require(isPause == false, "Contract is paused");
        _;
    }

    modifier validBuyTime(){
        require(block.timestamp >= startTimeBuy, "Buy time not started yet");
        require(block.timestamp <= endTimeBuy, "Buy time ended");
        _;
    }

    modifier validClaimTime(){
        require(block.timestamp >= startTimeClaim, "Claim time not started yet");
        _;
    }

    function setPauseContract(bool _status) public onlyOwner {
        isPause = _status;
    }

    function setMaxNumber(uint256[] calldata _maxNumber) public onlyOwner {
        for(uint256 index = 0; index < _maxNumber.length; index++){
            nftTypeMap[index+1].maxNumber = _maxNumber[index];
        }
    }

    function setNftaddress(address[] calldata _nftAddress) public onlyOwner {
        for(uint256 index = 0; index < _nftAddress.length; index++){
            nftTypeMap[index+1].nftAddress = _nftAddress[index];
        }
    }

    function setNftPrice(uint256[] calldata _price) public onlyOwner {
        for(uint256 index = 0; index < _price.length; index++){
            nftTypeMap[index+1].price = _price[index];
        }
    }

    function setPaymentToken(address _paymentToken) public onlyOwner{
        paymentToken = ERC20(_paymentToken);
    }

    function setTimeBuy(uint256 _startTimeBuy, uint256 _endTimeBuy) public onlyOwner{
        require(_endTimeBuy > _startTimeBuy, "Invalid time");

        startTimeBuy = _startTimeBuy;
        endTimeBuy = _endTimeBuy;
    }

    function setTimeClaim(uint256 _startTimeClaim) public onlyOwner{
        require(_startTimeClaim > endTimeBuy, "Invalid time");

        startTimeClaim = _startTimeClaim;
    }

    function getNftTypeList() public view returns(uint256[] memory){
        return nftTypeList;
    }

    function checkBalanceByType(uint256 _nftType) public view returns(uint256 _balance){
        _balance = ERC721(nftTypeMap[_nftType].nftAddress).balanceOf(address(this));
    }

    function buyNft(uint256 _nftType) public nonReentrant{
        require(paymentToken.balanceOf(msg.sender) > nftTypeMap[_nftType].price, "Not enough balance");
        require(nftCurrentNumber[_nftType] > 0, "NFT sold out");

        inWhiteList[msg.sender] = true;
        nftCurrentNumber[_nftType]--;
        paymentToken.safeTransferFrom(msg.sender, address(this), nftTypeMap[_nftType].price);
        userBoughtNft[msg.sender][_nftType].push(nftTypeMap[_nftType].tokenCount);
        nftTypeMap[_nftType].tokenCount++;

        emit BuyComplete(msg.sender, _nftType, nftTypeMap[_nftType].price, block.timestamp);
    }

    // function claimNft() public isRun validClaimTime nonReentrant{
    //     require(inWhiteList[msg.sender] == true, "You are not in whitelist or you have already claimed");

    //     for(uint256 index = 0; index < nftTypeList.length; index++){
    //         address nft = nftTypeMap[nftTypeList[index]].nftAddress;

    //         require(IERC721(nft).balanceOf(address(this)) >= userBoughtNft[msg.sender][nftTypeList[index]].length, "Not enough NFT");

            

    //         // uint256[] memory userNftList = new uint256[](userBoughtNft[msg.sender][nftTypeList[index]]);

    //         // for(uint jndex = 0; jndex < userNftList.length; jndex++){
    //         //     userNftList[jndex] = ERC721Enumerable(nft).tokenOfOwnerByIndex(address(this), jndex);
    //         // }

    //         // for(uint jndex = 0; jndex < userNftList.length; jndex++){
    //         //     IERC721(nft).transferFrom(address(this), msg.sender, userNftList[jndex]);

    //         //     emit TransferComplete(msg.sender, nftTypeList[index], userNftList[jndex]);
    //         // }

    //         for(uint256 jndex = 0; jndex < userBoughtNft[msg.sender][nftTypeList[index]].length; jndex++){
    //             uint256 tokenOwnerId = userBoughtNft[msg.sender][nftTypeList[index]][jndex];

    //             IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenOwnerId);

    //             emit TransferComplete(msg.sender, nftTypeList[index], tokenOwnerId);
    //         }
    //     }

    //     inWhiteList[msg.sender] = false;

    //     emit ClaimComplete(msg.sender, block.timestamp);
    // }

    function claim() public {
        address nft = nftTypeMap[1].nftAddress;
        uint256 tokenId = ERC721Enumerable(nft).tokenOfOwnerByIndex(address(this), 0);
        IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function emergencyWithdrawPaymentToken() external onlyOwner {
        uint256 withdrawAmount = paymentToken.balanceOf(address(this));
        paymentToken.transfer(msg.sender, withdrawAmount);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
