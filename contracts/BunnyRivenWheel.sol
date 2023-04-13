// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BunnyRivenWheel is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    address public validator;

    mapping(address => uint256) private _totalClaim;
    mapping(address => bool) public tokens;
    mapping(bytes32 => bool) public txHashExecuted;

    event ClaimPrize(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    event WithdrawToken(address indexed token, uint256 amount);

    constructor(address _bunnyRivenToken, address _usdtToken) {
        tokens[_usdtToken] = true;
        tokens[_bunnyRivenToken] = true;
        validator = msg.sender;
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
     * @dev set token prize
     * @param _token token prize
     * @param _valid valid or not
     */
    function setToken(address _token, bool _valid) external onlyOwner {
        tokens[_token] = _valid;
    }

    // ============ Helpers ============
    /**
     * @dev tx hash for validate ticket
     * @param account winner
     * @param token token address
     * @param prize prize will claim
     */
    function getTxHash(
        address account,
        address token,
        uint256 prize
    ) public view returns (bytes32) {
        return
            keccak256(abi.encodePacked(address(this), account, token, prize));
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

    function totalClaimOf(address account) public view returns (uint256) {
        return _totalClaim[account];
    }

    // ============ End Helpers ============

    function withdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
        emit WithdrawToken(token, amount);
    }

    function claim(
        address token,
        uint256 amount,
        bytes calldata _sig
    ) external {
        bytes32 txHash = getTxHash(msg.sender, token, amount);
        require(!txHashExecuted[txHash], "Prize has been received");
        require(_checkSig(_sig, txHash), "Invalid signature");
        require(tokens[token], "Invalid token");

        txHashExecuted[txHash] = true;

        IERC20(token).safeTransfer(msg.sender, amount);
        _totalClaim[msg.sender] += amount;

        emit ClaimPrize(msg.sender, token, amount);
    }
}
