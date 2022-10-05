// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PiBridgeTessaractNFTs is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    uint256 public constant maxSupply = 5000;

    string private _baseTokenURI = "";

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    Counters.Counter private _tokenIdCounter;

    uint256 public startTime;
    uint256 public whitelistCount;
    uint256 public whitelistMintedCount;

    event WhitelistMinted(address indexed to, uint256 indexed tokenId);

    constructor() ERC721("PiBridgeTessaractNFTs", "PiNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier validTime() {
        require(block.timestamp >= startTime, "Whitelist airdrop not start");
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseTokenURI;
    }

    function setStartTime(uint256 _startTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        startTime = _startTime;
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        require (totalSupply() < maxSupply);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function safeMintWhiteList() public onlyRole(WHITELIST_ROLE) validTime {
        require (totalSupply() < maxSupply);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        whitelistMintedCount++;
        _revokeRole(WHITELIST_ROLE, msg.sender);

        emit WhitelistMinted(msg.sender, tokenId);
    }

    function setupMinterRole(address[] memory account, bool _enable) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < account.length; i++) {
            require(account[i] != address(0), "account must be not equal address 0x");
            if (_enable) {
                _grantRole(MINTER_ROLE, account[i]);
            } else {
                _revokeRole(MINTER_ROLE, account[i]);
            }
        }
    }

    function setupWhitelistRole(address[] memory account, bool _enable) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < account.length; i++) {
            require(account[i] != address(0), "account must be not equal address 0x");
            if (_enable) {
                _grantRole(WHITELIST_ROLE, account[i]);
                whitelistCount++;
            } else {
                _revokeRole(WHITELIST_ROLE, account[i]);
                whitelistCount--;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
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
        string memory currentBaseUri = _baseURI();
        return bytes(currentBaseUri).length > 0 ? string(abi.encodePacked(currentBaseUri, Strings.toString(tokenId), '.json')) : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}