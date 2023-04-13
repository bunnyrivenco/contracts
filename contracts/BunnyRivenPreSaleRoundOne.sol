// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BunnyRivenPreSaleRoundOne is Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    uint256 public constant NUM = 10000 ether;
    AggregatorV3Interface internal bnbPriceFeed;
    uint32 public immutable startTime;
    uint32 public endTime;
    IERC20 public immutable token;
    IERC20 public immutable bunnyRivenToken;
    address public validator;
    bool public unLockWithdraw = false;
    uint256 public usdtPerToken;
    uint256 public totalSell;
    uint256 public limitTicket;

    mapping(bytes32 => bool) public txHashWithdrawExecuted;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(string => uint256)) private _ticketBalances;

    event BuyToken(address indexed buyer, uint256 amount, uint256 usdtPerToken);
    event Withdraw(address indexed account, uint256 amount);
    event WithdrawBunnyRiven(address indexed account, uint256 amount);
    event WithdrawToken(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    constructor(
        address _bnbPriceFeed,
        address _token,
        address _bunnyRivenToken,
        uint256 _usdtPerToken,
        uint256 _limitTicket,
        uint32 _startTime,
        uint32 _endTime
    ) {
        token = IERC20(_token);
        bunnyRivenToken = IERC20(_bunnyRivenToken);
        usdtPerToken = _usdtPerToken;
        limitTicket = _limitTicket;
        validator = msg.sender;
        bnbPriceFeed = AggregatorV3Interface(_bnbPriceFeed);
        startTime = _startTime;
        endTime = _startTime + _endTime * 1 days;
    }

    // ============ Helpers ============
    /**
     * @dev tx hash for validate ticket
     * @param account buyer
     * @param ticket ticket
     */
    function getTxHash(address account, string calldata ticket)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(address(this), account, ticket));
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
     * @dev get current bnb price
     */
    function getLatestBnbUsdPrice() public view returns (uint256) {
        (, int256 price, , , ) = bnbPriceFeed.latestRoundData();
        return (uint256(price) / (10**8)) * (10**18);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev get usdt can buy remain token
     */
    function usdtNeedToBuyRemainOf(address account, string calldata ticket)
        external
        view
        returns (uint256)
    {
        if (_ticketBalances[account][ticket] < limitTicket) {
            return limitTicket.sub(_ticketBalances[account][ticket]);
        }

        return 0;
    }

    function transferToken(
        address account,
        string calldata ticket,
        uint256 amount,
        uint256 amountToken
    ) private {
        _ticketBalances[account][ticket] += amount;
        _balances[account] += amountToken;
        totalSell += amountToken;

        emit BuyToken(account, amountToken, usdtPerToken);
    }

    // ============ End Helpers ============

    // ============ Ownable ============

    /**
     * @dev set validator to validate sig
     * @param _validator address of validator
     */
    function setValidator(address _validator) external onlyOwner {
        validator = _validator;
    }

    /**
     * @dev set usdtPerToken
     * @param _usdtPerToken usdtPerToken
     */
    function setUsdtPerToken(uint256 _usdtPerToken) external onlyOwner {
        usdtPerToken = _usdtPerToken;
    }

    /**
     * @dev set limitTicket
     * @param _limitTicket limitTicket
     */
    function setLimitTicket(uint256 _limitTicket) external onlyOwner {
        limitTicket = _limitTicket;
    }

    /**
     * @dev allow user can withdraw token
     * @param _unLockWithdraw can or not withdraw token
     */
    function setUnLockWithdraw(bool _unLockWithdraw) external onlyOwner {
        unLockWithdraw = _unLockWithdraw;
    }

    function setEndTime(uint32 _endTime) external onlyOwner {
        endTime = startTime + _endTime * 1 days;
    }

    function withdrawBnbOwner(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function withdrawTokenOwner(address _token, uint256 amount)
        external
        onlyOwner
    {
        IERC20(_token).safeTransfer(msg.sender, amount);
        emit WithdrawToken(msg.sender, _token, amount);
    }

    // ============ End Ownable ============

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

    function withdrawBunnyRiven(uint256 amount) external {
        if (!unLockWithdraw) revert("You can't withdraw yet");
        uint256 balance = _balances[msg.sender];
        if (balance < amount) revert("Exceed balance");

        bunnyRivenToken.safeTransfer(msg.sender, amount);
        balance -= amount;
        _balances[msg.sender] = balance;

        emit WithdrawBunnyRiven(msg.sender, amount);
    }

    /**
     * @dev buy token using usdt token
     * @param amount amount buy
     * @param ticket ticket
     * @param sig signature for validation
     */
    function buyTokenByUsdt(
        uint256 amount,
        string calldata ticket,
        bytes calldata sig
    ) external {
        if (block.timestamp < startTime) revert("PreSale hasn't started yet");
        if (block.timestamp > endTime) revert("PreSale has ended");

        uint256 perToken = usdtPerToken;
        uint256 amountToken = amount.mul(1 ether).div(perToken);
        if (_ticketBalances[msg.sender][ticket].add(amount) > limitTicket) {
            revert("Maximum value of ticket");
        }

        bytes32 txHash = getTxHash(msg.sender, ticket);
        if (!_checkSig(sig, txHash)) revert("Invalid signature");

        token.safeTransferFrom(msg.sender, address(this), amount);
        transferToken(msg.sender, ticket, amount, amountToken);
    }

    /**
     * @dev buy token using bnb
     * @param ticket ticket
     * @param sig signature for validation
     */
    function buyTokenByBnb(string calldata ticket, bytes calldata sig)
        external
        payable
    {
        if (block.timestamp < startTime) revert("PreSale hasn't started yet");
        if (block.timestamp > endTime) revert("PreSale has ended");

        bytes32 txHash = getTxHash(msg.sender, ticket);
        if (!_checkSig(sig, txHash)) revert("Invalid signature");

        uint256 perToken = usdtPerToken;
        uint256 price = getLatestBnbUsdPrice();
        uint256 amount = msg.value.mul(NUM).mul(price).div(1 ether).div(NUM);
        uint256 amountToken = amount.mul(NUM).mul(1 ether).div(perToken).div(
            NUM
        );
        if (_ticketBalances[msg.sender][ticket].add(amount) > limitTicket)
            revert("Maximum value of ticket");

        transferToken(msg.sender, ticket, amount, amountToken);
    }
}
