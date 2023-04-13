// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BunnyRivenEgg is Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    uint256 public constant TOTAL_SUPPLY = 5000;
    IERC20 public immutable token;
    address public validator;
    uint256 public eggPrice = 80 ether;
    uint256 public totalSell = 0;

    mapping(bytes32 => bool) public txHashWithdrawExecuted;
    mapping(string => bool) public eggKeys;
    mapping(address => mapping(string => uint256)) private _eggs;

    event BuyEgg(
        address indexed sender,
        string key,
        uint256 quantity,
        uint256 price
    );
    event Withdraw(address indexed sender, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
        validator = msg.sender;
        eggKeys["0"] = true;
        eggKeys["1"] = true;
        eggKeys["2"] = true;
        eggKeys["3"] = true;
        eggKeys["4"] = true;
        eggKeys["5"] = true;
    }

    modifier onlyOwnerOrSender(address account) {
        if (
            !(msg.sender == owner() ||
                msg.sender == validator ||
                msg.sender == account)
        ) revert("Caller is not the owner");
        _;
    }

    // ============ Ownable ============

    /**
     * @dev set validator to validate sig
     * @param _validator address of validator
     */
    function setValidator(address _validator) external onlyOwner {
        validator = _validator;
    }

    /**
     * @dev set egg price
     * @param _eggPrice egg price
     */
    function setEggPrice(uint256 _eggPrice) external onlyOwner {
        eggPrice = _eggPrice;
    }

    /**
     * @dev set egg key
     * @param _key key of egg
     * @param _active use or unuse egg
     */
    function setEggKey(string calldata _key, bool _active) external onlyOwner {
        eggKeys[_key] = _active;
    }

    function withdrawOwner(uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    function withdraw(
        uint256 amount,
        string calldata secret,
        bytes calldata sig
    ) external {
        bytes32 txHash = getTxHashWithdraw(msg.sender, amount, secret);
        if (txHashWithdrawExecuted[txHash]) revert("Invalid hash");
        if (!_checkSig(sig, txHash)) revert("Invalid signature");

        txHashWithdrawExecuted[txHash] = true;

        token.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    // ============ End Ownable ============

    // ============ Helpers ============
    /**
     * @dev tx hash for special request
     * @param account sender
     * @param secret secret of system
     */
    function getTxHashRequest(address account, string calldata secret)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(address(this), account, secret));
    }

    /**
     * @dev tx hash for withdraw
     * @param account sender
     * @param secret secret of system
     */
    function getTxHashWithdraw(
        address account,
        uint256 amount,
        string calldata secret
    ) public view returns (bytes32) {
        return
            keccak256(abi.encodePacked(address(this), account, amount, secret));
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

    /**
     * @dev for owner and sender
     */
    function eggOf(address account, string calldata key)
        public
        view
        onlyOwnerOrSender(account)
        returns (uint256)
    {
        return _eggs[account][key];
    }

    /**
     * @dev for special request
     */
    function eggOf(
        address account,
        string calldata secret,
        string calldata key,
        bytes calldata sig
    ) public view returns (uint256) {
        bytes32 txHash = getTxHashRequest(msg.sender, secret);
        if (!_checkSig(sig, txHash)) revert("Invalid signature");

        return _eggs[account][key];
    }

    // ============ End Helpers ============

    /**
     * @dev buy eggs
     * @param quantity quantity eggs
     * @param key key of egg
     */
    function buyEgg(uint256 quantity, string calldata key) external {
        if (!eggKeys[key]) revert("Invalid egg");
        uint256 newTotalSell = totalSell + quantity;
        if (newTotalSell > TOTAL_SUPPLY) revert("Maximum limited");

        token.safeTransferFrom(
            msg.sender,
            address(this),
            quantity.mul(eggPrice)
        );
        _eggs[msg.sender][key] += quantity;
        totalSell = newTotalSell;

        emit BuyEgg(msg.sender, key, quantity, eggPrice);
    }
}
