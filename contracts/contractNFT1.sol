// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CreateNFTBronze is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;



    constructor() ERC721("FootEarnBronze", "FEB") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function safeMintWithAmount(address to, uint256 amount) public onlyOwner {
        for(uint i = 0;i < amount ;i++){
            safeMint(to);
        }
    }

    function tranferMulti(address to, uint256 totalTranfer) public{
        for(uint i = 0;i < totalTranfer ;i++){
            uint256 tokenID = ERC721Enumerable(address(this)).tokenOfOwnerByIndex(msg.sender,0);
            ERC721(address(this)).transferFrom(msg.sender,to,tokenID);
        }
    }

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