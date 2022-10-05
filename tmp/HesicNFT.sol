// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract HesmanInvesmentCertificate is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, ReentrancyGuard, AccessControl {
    using Counters for Counters.Counter;
    using SafeERC20 for ERC20;

    Counters.Counter private _tokenIdCounter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public limitLevel1 = 4000;
    uint256 public limitLevel2 = 8000;
    uint256 public limitLevel3 = 10000;

    uint256 public amountLevel1 = 100 * 10 ** 18;
    uint256 public amountLevel2 = 120 * 10 ** 18;
    uint256 public amountLevel3 = 150 * 10 ** 18;

    ERC20 public paymentToken;
    address public devWallet;

    bool public isPauseBuy;
    mapping(address => bool) isBlacklistUserMap;
    mapping(uint256 => bool) isSpecialPriceMap;
    mapping(uint256 => uint256) specialPriceAmountMap;

    string public baseURI = "https://nft.hesman.net/info/token/";

    constructor(address _paymentToken, address _devWallet, address pauseRole, address mintRole) ERC721("Hesman Invesment Certificate", "HESIC") {
        paymentToken = ERC20(_paymentToken);
        devWallet = _devWallet;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, pauseRole);
        _grantRole(MINTER_ROLE, mintRole);

    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseUri;
    }

    modifier validSupply () {
        require(_tokenIdCounter.current() + 1 <= limitLevel3, "Limit supply");
        _;
    } 

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function pauseBuy(bool _status) public onlyRole(PAUSER_ROLE) {
        isPauseBuy = _status;
    }

    function setPaymentToken(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        paymentToken = ERC20(_token);
    }

    function setDevWallet(address _devWallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
        devWallet = _devWallet;
    }

    function setBlacklist(address[] calldata _users) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 index = 0; index < _users.length; index++) {
            isBlacklistUserMap[_users[index]] = true;
        }
    }

    function removeBlacklist(address[] calldata _users) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 index = 0; index < _users.length; index++) {
            isBlacklistUserMap[_users[index]] = false;
        }
    }

    function addSpecialPrice(uint256[] calldata tokens, uint256[] calldata amounts) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokens.length == amounts.length, "Input is invalid");
        for (uint256 index = 0; index < tokens.length; index++) {
            specialPriceAmountMap[tokens[index]] = amounts[index];
            isSpecialPriceMap[tokens[index]] = true;
        }
    }

    function removeSpecialPrice(uint256[] calldata tokens) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 index = 0; index < tokens.length; index++) {
            specialPriceAmountMap[tokens[index]] = 0;
            isSpecialPriceMap[tokens[index]] = false;
        }
    }

    function setLimitRange(uint256 _limit1, uint256 _limit2, uint256 _limit3) public onlyRole(DEFAULT_ADMIN_ROLE) {
        limitLevel1 = _limit1;
        limitLevel2 = _limit2;
        limitLevel3 = _limit3;
    }

    function setAmountBuyRange(uint256 _amount1, uint256 _amount2, uint256 _amount3) public onlyRole(DEFAULT_ADMIN_ROLE) {
        amountLevel1 = _amount1;
        amountLevel2 = _amount2;
        amountLevel3 = _amount3;
    }

    function nextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function safeMint(address to) public validSupply onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function safeMultiMint(address[] calldata _accounts) public onlyRole(MINTER_ROLE) {
        for (uint256 index = 0; index < _accounts.length; index++) {
            safeMint(_accounts[index]);
        }
    }

    function mintMultiNftPerUser(uint256 _number, address _accounts) public onlyRole(MINTER_ROLE) {
        for (uint256 index = 0; index < _number; index++) {
            safeMint(_accounts);
        }
    }

    function batchSafeMint(uint256[] calldata _numbers, address[] calldata _accounts) public onlyRole(MINTER_ROLE) {
        require(_numbers.length == _accounts.length, "Invalid input");
        for (uint256 index = 0; index < _accounts.length; index++) {
            for (uint256 jndex = 0; jndex < _numbers[index]; jndex++) {
                safeMint(_accounts[index]);
            }
        }
    }
    
    function batchTransfer(uint256[] calldata _tokenIds, address _account) public {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            transferFrom(msg.sender, _account, _tokenIds[index]);
        }
    }

    function getPriceTokenId(uint256 _tokenId) public view returns (uint256) {
        
        if (isSpecialPriceMap[_tokenId]) {
            return specialPriceAmountMap[_tokenId];
        }

        uint256 amount = 0;
        if (_tokenId < limitLevel1) {
            amount = amountLevel1;
        } else if (_tokenId >= limitLevel1 && _tokenId < limitLevel2) {
            amount = amountLevel2;
        } else if (_tokenId >= limitLevel2 && _tokenId < limitLevel3) {
            amount = amountLevel3;
        }
        return amount;
    }

    function buyNft() public validSupply nonReentrant {
        require(isPauseBuy == false, "Pause");
        require(isBlacklistUserMap[msg.sender] == false, "Blacklist");

        uint256 tokenId = _tokenIdCounter.current();
        uint256 amount = getPriceTokenId(tokenId);

        require(amount > 0, "Invalid check amount");
        require(paymentToken.balanceOf(msg.sender) >= amount, "Is not enough token");

        paymentToken.safeTransferFrom(msg.sender, devWallet, amount);
        
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function buyMultiNft(uint256 _number) public {
        for (uint256 index = 0; index < _number; index++) {
            buyNft();
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        require(!isBlacklistUserMap[from] && !isBlacklistUserMap[to], "Blacklist");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Required function to allow receiving ERC-721 - When safeTransferFrom called auto implement this func if (to) is contract address
    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}