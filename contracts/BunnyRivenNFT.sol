// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BunnyRivenNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    using ECDSA for bytes32;

    string private _baseTokenURI;
    address public validator;
    mapping(bytes32 => bool) public txHashExecuted;

    constructor() ERC721("BunnyRivenNFT", "BRVNFT") {
        _baseTokenURI = "https://api.bunnyriven.co/";
        validator = msg.sender;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata _base) external onlyOwner {
        _baseTokenURI = _base;
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string calldata uri
    ) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setValidator(address _validator) external onlyOwner {
        validator = _validator;
    }

    // ============ Helpers ============
    /**
     * @dev tx hash for buying egg
     * @param account sender
     * @param tokenId tokenId of nft
     * @param uri uri of nft
     */
    function getTxHash(
        address account,
        uint256 tokenId,
        string calldata uri
    ) public view returns (bytes32) {
        return
            keccak256(abi.encodePacked(address(this), account, tokenId, uri));
    }

    function _checkSig(bytes calldata _sig, bytes32 _txHash)
        private
        view
        returns (bool)
    {
        bytes32 ethSignedHash = _txHash.toEthSignedMessageHash();

        address signer = ethSignedHash.recover(_sig);
        bool valid = (signer == owner() || signer == validator);

        if (!valid) {
            return false;
        }

        return true;
    }

    // ============ End Helpers ============

    function mint(
        uint256 tokenId,
        string calldata uri,
        bytes calldata _sig
    ) external {
        require(!_exists(tokenId), "NFT already exists");
        bytes32 txHash = getTxHash(msg.sender, tokenId, uri);
        require(!txHashExecuted[txHash], "NFT has been received");
        require(_checkSig(_sig, txHash), "Invalid signature");

        txHashExecuted[txHash] = true;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }
}
