// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "hardhat/console.sol";

contract RunTogetherBoxNft {
    mapping(uint256 => uint256) private boxTypes;

    function getBoxType(uint256 tokenId) public view returns (uint256) {
        return boxTypes[tokenId];
    }
}

contract RunTogetherMarketplaceAdmin is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for ERC20;
    using Counters for Counters.Counter;

    Counters.Counter private counter;

    // Kho
    uint256[] public Kho;
    // percent sale off Kho
    mapping(uint256 => uint256) public percentSaleOffKhoMap;
    // RunTogetherBoxNft Type
    RunTogetherBoxNft runTogetherBoxType;
    
    address public runTogetherBoxNft;
    mapping(uint256 => uint256[]) public runTogetherBoxNftMap;
    mapping(uint256 => uint256) public runTogetherBoxNftTypePriceMap;
    mapping(uint256 => uint256) public runTogetherBoxNftTypeCountMap;

    mapping(address => mapping(uint256 => uint256)) public userBoxTypeMap;
    mapping(address => uint256) public totalBoxOfUser;

    uint256 public totalBoxType = 4;

    mapping(uint256 => address) public tokenIdToAddressMap;

    mapping(address => bool) public blacklistMap;
    mapping(address => bool) public sellerListMap;

    // Currency for trading
    address paymentToken;

    // Start accept user sale nft
    bool public isOpenMarket;

    // Fee
    uint256 public feeRate = 200;
    uint256 public baseRate = 1000;

    // Pool
    address public poolReward;
    address public poolAdmin;
    address public devWallet;

    // max nft in transfer
    mapping(uint256 => uint256) public maxNftInTransfer;

    // Event
    event EventUpdateBoxPrice(
        uint256[] boxTypes,
        uint256[] price,
        uint256 from,
        uint256 to
    );

    event EventBuyCompleted(
        address buyer,
        uint256[] numOfboxTypes,
        uint256 totalPrice
    );

    event EventClaimCompleted(
        address buyer,
        uint256 nftId
    );
    
    constructor(
        address _addressRunTogether,
        address _paymentToken,
        address _poolReward,
        address _poolAdmin,
        uint256 _feeRate,
        bool _isOpenMarket
    ) {
        isOpenMarket = _isOpenMarket;
        paymentToken = _paymentToken;
        feeRate = _feeRate;
        poolReward = _poolReward;
        poolAdmin = _poolAdmin;
        runTogetherBoxNft = _addressRunTogether;
        runTogetherBoxType = RunTogetherBoxNft(_addressRunTogether);
    }

    // Internal function

    /**
     * check address
     */

    modifier validOpenMarket() {
        require(isOpenMarket == true, "Marketplace is closed");
        _;
    }

    // Main function
    //add user into seller list
    function addSellerList(address[] calldata _seller) external onlyOwner {
        for (uint256 index = 0; index < _seller.length; index++) {
            sellerListMap[_seller[index]] = true;
        }
    }

    //remove user out of seller list
    function removeSellerList(address[] calldata _seller) external onlyOwner {
        for (uint256 index = 0; index < _seller.length; index++) {
            sellerListMap[_seller[index]] = false;
        }
    }

    //get box type
    function getBoxTypeRunTogether(uint256 index) public view returns (uint256) {
        return runTogetherBoxType.getBoxType(index);
    }


    // Set percent sale off for Kho Nft
    function setPercentSaleOffKho(uint256[] calldata _Kho, uint256[] calldata _percentSaleOffKhoMap) external onlyOwner {
        Kho = _Kho;
        for (uint256 index = 0; index < _percentSaleOffKhoMap.length; index++) {
            percentSaleOffKhoMap[Kho[index]] = _percentSaleOffKhoMap[index];
        }
    }

    function resetNft(uint256[] calldata _boxTypes) external onlyOwner {
        for (uint256 index = 0; index < _boxTypes.length; index++) {
            delete runTogetherBoxNftMap[_boxTypes[index]];
            runTogetherBoxNftTypeCountMap[_boxTypes[index]] = 0;
        }
    }

    function updateBoxPrice(uint256[] calldata _boxTypes, uint256[] calldata _price, uint256 _from, uint256 _to) external nonReentrant {
        require(
            sellerListMap[msg.sender] == true,
            "You are not in seller list"
        );

        for (uint256 index = 0; index < _boxTypes.length; index++) {
            runTogetherBoxNftTypePriceMap[_boxTypes[index]] = _price[index];
        }

        for (uint256 index = _from; index < _to; index++) {
            uint256 tokenId = ERC721Enumerable(runTogetherBoxNft).tokenOfOwnerByIndex(address(this), index);
            uint256 boxType = getBoxTypeRunTogether(tokenId);
            runTogetherBoxNftMap[boxType].push(tokenId);
            runTogetherBoxNftTypeCountMap[boxType]++;
        }

        emit EventUpdateBoxPrice(_boxTypes, _price, _from, _to);
    }

    function buyItem(uint256[] calldata _numOfboxTypes) external validOpenMarket nonReentrant {
        require(blacklistMap[msg.sender] == false, "You are in Blacklist");
        require(_numOfboxTypes.length == totalBoxType, "Invalid number of box type");

        uint256 totalPrice = 0;

        for (uint256 index = 1; index <= totalBoxType; index++) {
            console.log("index", index);
            console.log("runTogetherBoxNftTypeCountMap[index]", runTogetherBoxNftTypeCountMap[index]);

            require(_numOfboxTypes[index-1] < runTogetherBoxNftTypeCountMap[index], "Not enough box");
            userBoxTypeMap[msg.sender][index] = _numOfboxTypes[index-1];
            totalPrice += _numOfboxTypes[index-1] * runTogetherBoxNftTypePriceMap[index];

            // setup for claim
            uint256 numOfBox = userBoxTypeMap[msg.sender][index];
            runTogetherBoxNftTypeCountMap[index] -= numOfBox;
            totalBoxOfUser[msg.sender] += numOfBox;

            console.log("numOfBox", numOfBox);
        }
        
        uint256 newPrice = totalPrice;
        for (uint256 index = 0; index < Kho.length; index++) {
            if (totalBoxOfUser[msg.sender] >= Kho[index]) {
                newPrice = min(
                    newPrice,
                    totalPrice - calPercentSaleOff(totalPrice, percentSaleOffKhoMap[Kho[index]])
                );
            }
        }

        console.log("totalPrice", totalPrice);
        console.log("newPrice", newPrice);
        // Cal trading fee
        uint256 feeTrading = callTradingFee(newPrice);
        uint256 sellerValueReceive = newPrice - feeTrading;

        // Trading action
        ERC20(paymentToken).safeTransferFrom(msg.sender, poolReward, feeTrading);
        ERC20(paymentToken).safeTransferFrom(msg.sender, poolAdmin, sellerValueReceive);

        emit EventBuyCompleted(msg.sender, _numOfboxTypes, newPrice);
    }

    function claimItem() external validOpenMarket nonReentrant {
        require(blacklistMap[msg.sender] == false, "You are in Blacklist");
        require(totalBoxOfUser[msg.sender] > 0, "You have no item to claim");

        for (uint256 index = 1; index <= totalBoxType; index++) {    
            uint256 totalNft = 0;

            if (userBoxTypeMap[msg.sender][index] <= maxNftInTransfer[index]) {
                totalNft = userBoxTypeMap[msg.sender][index];
            } else {
                totalNft = maxNftInTransfer[index];
            }

            console.log("totalNft", totalNft);

            userBoxTypeMap[msg.sender][index] -= totalNft;
            totalBoxOfUser[msg.sender] -= totalNft;

            for (uint256 j = 0; j < totalNft; j++) {
                uint256 tokenId = runTogetherBoxNftMap[index][runTogetherBoxNftMap[index].length - 1];
                IERC721(runTogetherBoxNft).safeTransferFrom(address(this), msg.sender, tokenId);
                // console.log("tokenId", tokenId);
                tokenIdToAddressMap[tokenId] = msg.sender;
                runTogetherBoxNftMap[index].pop();

                emit EventClaimCompleted(msg.sender, tokenId);
            }
        }
    }

    // Total of Nfts of each box in marketplace
    function CountNftInMarket(uint256 _boxType) public view returns (uint256) {
        return runTogetherBoxNftMap[_boxType].length;
    }

    function setMaxNftInTransfer(uint256[] calldata _boxTypes, uint256[] calldata _maxNftInTransfer) external onlyOwner {
        for (uint256 index = 0; index < _maxNftInTransfer.length; index++) {
            maxNftInTransfer[_boxTypes[index]] = _maxNftInTransfer[index];
        }
    }

    // Set fee token
    // tradingFee = _newRate / baseRate
    function setTradingFee(uint256 _newRate) external onlyOwner {
        feeRate = _newRate;
    }

    // Set pool admin and pool reward
    function setPool(address _poolAdmin, address _poolReward) external onlyOwner {
        poolAdmin = _poolAdmin;
        poolReward = _poolReward;
    }

    function setBlackList(address[] calldata userList) external onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            blacklistMap[userList[index]] = true;
        }
    }

    function removeBlackList(address[] calldata userList) external onlyOwner {
        for (uint256 index = 0; index < userList.length; index++) {
            blacklistMap[userList[index]] = false;
        }
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a <= b ? a : b;
    }

    function callTradingFee(uint256 _pricing) public view returns (uint256 feeTrading) {   
        feeTrading = _pricing * feeRate / baseRate;
    }

    function calPercentSaleOff(uint256 _pricing, uint256 _percentSaleOff) public view returns (uint256 saleOff){
        saleOff = (_pricing * _percentSaleOff) / baseRate;
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
    }

    function setTotalBoxType(uint256 _totalBoxType) external onlyOwner {
        totalBoxType = _totalBoxType;
    }

    function setTokenIdToAddressZero(uint256 _tokenId) external {
        tokenIdToAddressMap[_tokenId] = address(0);
    }

    // Clear market
    // Push NFT back to seller
    function cleanMarket(uint256 _numOfNfts) external onlyOwner {
        for (uint256 index = 0; index < _numOfNfts; index++) {
            uint256 tokenId = ERC721Enumerable(runTogetherBoxNft).tokenOfOwnerByIndex(address(this), index);
            IERC721(runTogetherBoxNft).safeTransferFrom(address(this), devWallet, tokenId);
        }
        isOpenMarket = false;
    }

    // Required function to allow receiving ERC-721 - When safeTransferFrom called auto implement this func if (to) is contract address
    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
