// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IBunnyRivenNFT {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BunnyRivenMarket is Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IBunnyRivenNFT public bunnyRivenNFT;
    address public token;

    uint256 minimumPrice = 50 ether;

    mapping(address => mapping(uint256 => uint256)) public tokenOnSellBySeller;
    mapping(uint256 => address) public tokenSeller;
    mapping(uint256 => uint256) public tokenSellPrice;

    mapping(address => uint256) public tokenBalanceOf;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    event BuyToken(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 price
    );

    constructor(address _bunnyRivenNFT, address _token) {
        bunnyRivenNFT = IBunnyRivenNFT(_bunnyRivenNFT);
        token = _token;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // ============ Modifiers ============

    modifier onlyOwnerOfToken(address owner, uint256 _tokenId) {
        require(
            bunnyRivenNFT.ownerOf(_tokenId) == owner,
            "Not owner of this token"
        );
        _;
    }

    modifier isOnSell(uint256 _tokenId) {
        require(
            bunnyRivenNFT.ownerOf(_tokenId) == address(this),
            "This token is not on sell"
        );
        _;
    }

    modifier onlySeller(address seller, uint256 _tokenId) {
        require(tokenSeller[_tokenId] == msg.sender, "Not owner of this token");
        _;
    }

    function tokenOnSell(uint256 _tokenId) public view returns (bool) {
        return bunnyRivenNFT.ownerOf(_tokenId) == address(this);
    }

    // ============ Private ============

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokens[to][tokenBalanceOf[to]] = tokenId;
        _ownedTokensIndex[tokenId] = tokenBalanceOf[to];
        tokenBalanceOf[to] += 1;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = tokenBalanceOf[from] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
        tokenBalanceOf[from] -= 1;
    }

    // ============ Owner ============

    function setMinimumPrice(uint256 _minimumPrice) external onlyOwner {
        minimumPrice = _minimumPrice;
    }

    // ============ End Owner ============

    // ============ Helper ============

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        require(index < tokenBalanceOf[owner], "owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    // ============ End Helper ============

    // ============ Market ============

    function sellToken(uint256 _tokenId, uint256 _price)
        public
        onlyOwnerOfToken(msg.sender, _tokenId)
    {
        require(
            _price >= minimumPrice,
            "Price must greater than or equal minimum price"
        );

        bunnyRivenNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        _addTokenToOwnerEnumeration(msg.sender, _tokenId);
        tokenSeller[_tokenId] = msg.sender;
        tokenSellPrice[_tokenId] = _price;
    }

    function cancelSellToken(uint256 _tokenId)
        public
        isOnSell(_tokenId)
        onlySeller(msg.sender, _tokenId)
    {
        bunnyRivenNFT.safeTransferFrom(address(this), msg.sender, _tokenId);

        _removeTokenFromOwnerEnumeration(msg.sender, _tokenId);
        delete tokenSeller[_tokenId];
        delete tokenSellPrice[_tokenId];
    }

    function buyToken(uint256 _tokenId) public isOnSell(_tokenId) {
        address seller = tokenSeller[_tokenId];
        uint256 price = tokenSellPrice[_tokenId];

        IERC20(token).safeTransferFrom(msg.sender, seller, price);
        bunnyRivenNFT.safeTransferFrom(address(this), msg.sender, _tokenId);

        _removeTokenFromOwnerEnumeration(seller, _tokenId);

        delete tokenSeller[_tokenId];
        delete tokenSellPrice[_tokenId];

        emit BuyToken(_tokenId, seller, msg.sender, price);
    }
}
