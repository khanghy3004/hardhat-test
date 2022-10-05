// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RunTogetherBoxNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("RunTogetherBoxNFT", "RTB") {}

    mapping(uint256 => uint256) private boxTypes;

    function getBoxType(uint256 tokenId) public view returns (uint256) {
        return boxTypes[tokenId];
    }

    function setBoxType(uint256 tokenId, uint256 boxType) public {
        boxTypes[tokenId] = boxType;
    }

    function safeMint(address to, uint256 boxType) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        setBoxType(tokenId, boxType);
    }

    function superMint(address to, uint256 boxType) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        setBoxType(tokenId, boxType);
    }

    function multiMint(address toAddress, uint256 amount, uint256 boxType) public  {
        for (uint256 index = 0; index < amount; index++) {
            superMint(toAddress, boxType);
        }
    }
    
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
