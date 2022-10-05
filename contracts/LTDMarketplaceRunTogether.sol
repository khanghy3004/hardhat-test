// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract RunTogetherBoxNft {
    mapping(uint256 => uint256) private boxTypes;

    function getBoxType(uint256 tokenId) public view returns (uint256) {
        return boxTypes[tokenId];
    }
}

contract LTDMarketPlaceRunTogether is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private counter;
    // LiveTradeMembershipNft
    address[] public liveTradeMembership;
    mapping(address => IERC721) public liveTradeMembershipMap;
    // percent sale off Membership
    mapping(address => uint256) public percentSaleOffMembershipNftMap;
    // RunTogetherBoxNft
    RunTogetherBoxNft runTogetherBoxType;

    struct SaleItem {
        uint256 saleId;
        uint256 nftId;
        uint256 priceListing;
        bool isSold;
        address seller;
        address buyer;
        IERC20 currency;
        IERC721 nft;
        uint256 boxType;
    }

    SaleItem[] public saleItems;

    // Currency for trading
    mapping(address => bool) public currencyTradingList;
    mapping(address => bool) public sellerListMap;

    // Start accept user sale nft
    bool public isOpenMarket;

    uint256 public feeRate = 68;
    uint256 public baseRate = 1000;
    address public marketFeeWallet;

    // Event

    event EventNewSales(
        uint256 saleId,
        uint256 nftId,
        uint256 priceListing,
        bool isSold,
        address seller,
        address buyer,
        address currency,
        address nft,
        uint256 boxType
    );

    event EventSellerUpdateNewPrice(uint256 saleIndex, uint256 newPrice);

    event EventDelistItem(uint256 saleIndex, address seller);

    event EventBuyCompleted(
        uint256 saleIndex,
        uint256 nftId,
        address buyer,
        uint256 pricing
    );
    
    constructor(
        address _addressRunTogether,
        address _marketFeeWallet,
        uint256 _feeRate,
        address[] memory _currencyTradingList,
        address[] memory _liveTradeMembership,
        bool _isOpenMarket
    ) {
        marketFeeWallet = _marketFeeWallet;
        feeRate = _feeRate;
        isOpenMarket = _isOpenMarket;

        for (uint256 index = 0; index < _currencyTradingList.length; index++) {
            currencyTradingList[_currencyTradingList[index]] = true;
        }

        liveTradeMembership = _liveTradeMembership;
        for (uint256 index = 0; index < _liveTradeMembership.length; index++) {
            liveTradeMembershipMap[_liveTradeMembership[index]] = IERC721(_liveTradeMembership[index]);
        }

        runTogetherBoxType = RunTogetherBoxNft(_addressRunTogether);
    }

    // Internal function

    /**
     * check address
     */

    modifier validAddress(address addr) {
        require(addr != address(0x0), "Could not set burn wallet");
        _;
    }

    modifier validOpenMarket() {
        require(isOpenMarket == true, "Marketplace is closed");
        _;
    }

    modifier validSaleIndex(uint256 _index) {
        require(_index <= saleItems.length, "Sale index is invalid");
        _;
    }

    modifier validSaleItem(uint256 _saleIndex, address _sellerAddress) {
        require(_saleIndex <= saleItems.length, "Sale index is invalid");
        SaleItem storage saleItem = saleItems[_saleIndex];
        require(saleItem.seller == _sellerAddress, "You are not seller");
        require(saleItem.isSold == false, "Item is sold");
        _;
    }

    modifier validItemIsNotSold(uint256 _saleIndex) {
        require(_saleIndex <= saleItems.length, "Sale index is invalid");
        SaleItem storage saleItem = saleItems[_saleIndex];
        require(saleItem.isSold == false, "Item is sold");
        _;
    }

    // Main function
    //add user into seller list
    function addSellerList(address[] calldata _seller) public onlyOwner {
        for (uint256 index = 0; index < _seller.length; index++) {
            sellerListMap[_seller[index]] = true;
        }
    }

    //remove user out of seller list
    function removeSellerList(address[] calldata _seller) public onlyOwner {
        for (uint256 index = 0; index < _seller.length; index++) {
            sellerListMap[_seller[index]] = false;
        }
    }

    //get box type
    function getBoxTypeRunTogether(uint256 index)
        public
        view
        returns (uint256)
    {
        return runTogetherBoxType.getBoxType(index);
    }

    // Total of sale item
    function saleItemsCount() public view returns (uint256) {
        return saleItems.length;
    }

    //set run together box NFT address
    function setRunTogetherBoxNftAddress(address _runTogetherBoxAddress)
        public
        onlyOwner
    {
        runTogetherBoxType = RunTogetherBoxNft(_runTogetherBoxAddress);
    }

    // Clear market
    // Push NFT back to seller
    function cleanMarket() external onlyOwner {
        for (uint256 index = 0; index < saleItems.length; index++) {
            SaleItem storage saleItem = saleItems[index];
            if (saleItem.isSold == false) {
                saleItem.nft.safeTransferFrom(
                    address(this),
                    saleItem.seller,
                    saleItem.nftId
                );
                saleItem.isSold = true;
            }
        }
        isOpenMarket = false;
    }

    // Set Market Status
    function setMarketStatus(bool _newStatus) external onlyOwner {
        isOpenMarket = _newStatus;
    }

    // Set fee trading
    function setMarketFeeWallet(address _marketFeeWallet)
        external
        onlyOwner
        validAddress(_marketFeeWallet)
    {
        marketFeeWallet = _marketFeeWallet;
    }

    // Set fee token
    // tradingFee = _newRate / baseRate
    function setTradingFee(uint256 _newRate) external onlyOwner {
        feeRate = _newRate;
    }

    // Set currency support
    function setCurrencySupport(address[] memory _currencySupport)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < _currencySupport.length; index++) {
            currencyTradingList[_currencySupport[index]] = true;
        }
    }

    // Set liveTradeMembership
    function setLiveTradeMembership(address[] calldata _liveTradeMembership) public {
        liveTradeMembership = _liveTradeMembership;
        for (uint256 index = 0; index < _liveTradeMembership.length; index++) {
            liveTradeMembershipMap[_liveTradeMembership[index]] = IERC721(_liveTradeMembership[index]);
        }
    }
    // Set percent sale off for membership Nft
    function setPercentSaleOffMembershipNft(uint256[] calldata _percentSaleOffMembershipNftMap) public {
        for (uint256 index = 0; index < _percentSaleOffMembershipNftMap.length; index++) {
            percentSaleOffMembershipNftMap[liveTradeMembership[index]] = _percentSaleOffMembershipNftMap[index];
        }
    }

    function sellItem(
        address _nftAddress,
        uint256 _nftId,
        uint256 _price,
        address _currency
    ) external nonReentrant validOpenMarket validAddress(_currency) {
        // Check currency is whitelist
        require(
            sellerListMap[msg.sender] == true,
            "You are not in seller list"
        );
        require(
            currencyTradingList[_currency] == true,
            "Your currency is not in currencyTradingList"
        );

        // Check msg.sender is NFT owner
        IERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _nftId
        );
        // Create sale item

        // Prepare sale item
        SaleItem memory saleItem;

        saleItem.saleId = counter.current();
        saleItem.nft = IERC721(_nftAddress);
        saleItem.nftId = _nftId;
        saleItem.seller = msg.sender;
        saleItem.buyer = address(0);
        saleItem.priceListing = _price;
        saleItem.currency = IERC20(_currency);
        saleItem.isSold = false;
        saleItem.boxType = getBoxTypeRunTogether(_nftId);

        saleItems.push(saleItem);

        counter.increment();
        // Emit event
        emit EventNewSales(
            saleItem.saleId,
            saleItem.nftId,
            saleItem.priceListing,
            saleItem.isSold,
            saleItem.seller,
            address(0),
            _currency,
            _nftAddress,
            saleItem.boxType
        );
    }

    // Valid OpenMarket, OwnerItem, isSold Status before update seller update price
    function updateItemPrice(uint256 _saleIndex, uint256 _newPrice)
        external
        nonReentrant
        validOpenMarket
        validSaleItem(_saleIndex, msg.sender)
    {
        SaleItem storage saleItem = saleItems[_saleIndex];
        saleItem.priceListing = _newPrice;

        uint256 saleIndex = _saleIndex;

        emit EventSellerUpdateNewPrice(saleIndex, saleItem.priceListing);
    }

    function delistItem(uint256 _saleIndex)
        external
        nonReentrant
        validSaleItem(_saleIndex, msg.sender)
    {
        uint256 saleIndex = _saleIndex;
        SaleItem storage saleItem = saleItems[_saleIndex];

        address itemSeller = saleItem.seller;
        uint256 nftId = saleItem.nftId;
        IERC721 runTogetherBoxNft = saleItem.nft;

        runTogetherBoxNft.safeTransferFrom(address(this), itemSeller, nftId);

        saleItem.isSold = true;
        saleItem.seller = address(0);

        emit EventDelistItem(saleIndex, itemSeller);
    }

    function buyItem(uint256 _saleIndex)
        external
        nonReentrant
        validItemIsNotSold(_saleIndex)
    {
        uint256 saleIndex = _saleIndex;
        SaleItem storage saleItem = saleItems[_saleIndex];
        IERC20 currency = saleItem.currency;
        IERC721 runTogetherBoxNft = saleItem.nft;
        uint256 nftId = saleItem.nftId;
        address sellerAddress = saleItem.seller;
        uint256 pricing = saleItem.priceListing;

        for (uint256 index = 0; index < liveTradeMembership.length; index++) {
            if (liveTradeMembershipMap[liveTradeMembership[index]].balanceOf(msg.sender) > 0) {
                pricing = min(pricing, saleItem.priceListing - calPercentSaleOff(saleItem.priceListing, percentSaleOffMembershipNftMap[liveTradeMembership[index]]));
                console.log(saleItem.priceListing - calPercentSaleOff(saleItem.priceListing, percentSaleOffMembershipNftMap[liveTradeMembership[index]]));
            }
        }

        // Check currency balance
        require(
            currency.balanceOf(msg.sender) >= pricing,
            "Your balance is not enough for buying"
        );

        // Cal trading fee
        uint256 feeTrading = calTradingFee(pricing);
        uint256 sellerValueReceive = pricing - feeTrading;
        console.log(pricing);
        console.log(sellerValueReceive);
        
        // Update item
        saleItem.buyer = msg.sender;
        saleItem.isSold = true;

        // Trading action
        currency.safeTransferFrom(msg.sender, marketFeeWallet, feeTrading);
        currency.safeTransferFrom(
            msg.sender,
            sellerAddress,
            sellerValueReceive
        );
        runTogetherBoxNft.safeTransferFrom(address(this), msg.sender, nftId);

        emit EventBuyCompleted(saleIndex, nftId, msg.sender, pricing);
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a <= b ? a : b;
    }

    function calTradingFee(uint256 _pricing) public view returns (uint256 feeTrading) {
        feeTrading = (_pricing * feeRate) / baseRate;
    }

    function calPercentSaleOff(uint256 _pricing, uint256 _percentSaleOff) public view returns (uint256 saleOff) {
        saleOff = (_pricing * _percentSaleOff) / baseRate;
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
