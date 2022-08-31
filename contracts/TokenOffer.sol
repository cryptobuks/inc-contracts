// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts//security/ReentrancyGuard.sol";

/**
 * @dev Initial offer contract. Managed by the government of the DAO ´owner´.
 */
contract TokenOffer is Ownable, ReentrancyGuard {

    event OnBought(
        address indexed sender,
        address indexed recipient,
        uint256 weiAmount,
        uint256 tokenAmount
    );

    // Token to offer
    IERC20 public tokenCnt;
    // Offer opening time
    uint256 public openingTime;
    // Offer closing time
    uint256 public closingTime;
    // Initial rate of the offer (Token units/TKNbits per 1 wei)
    uint256 public initialRate;
    // Final rate of the offer
    uint256 public finalRate;
    // Total tokens sold
    uint256 public totalSold;
    // Amount native wei raised
    uint256 public totalRaised;

    constructor(address _token, uint256 _openingTime, uint256 _closingTime,
        uint256 _initialRate, uint256 _finalRate) {
        require(_token != address(0), "TokenOffer: invalid token address");

        require(_openingTime >= block.timestamp, "TokenOffer: opening time is before current time");
        require(_closingTime > _openingTime, "TokenOffer: opening time is not before closing time");

        require(_finalRate > 0, "TokenOffer: final rate is 0");
        require(_initialRate > _finalRate, "TokenOffer: initial rate is not greater than final rate");

        tokenCnt = IERC20(_token);
        openingTime = _openingTime;
        closingTime = _closingTime;
        initialRate = _initialRate;
        finalRate = _finalRate;
    }

    // -----------------------------------------
    // Public implementation
    // -----------------------------------------

    /**
     * @dev For empty calldata (and any value), backup function that can only receive native currency.
     */
    receive() external payable {
        _buyTokens(_msgSender(), block.timestamp, 0);
    }

    /**
     * @dev When no other function matches (not even the receive function), optionally payable.
     */
    fallback() external payable {
        _buyTokens(_msgSender(), block.timestamp, 0);
    }

    /**
     * @dev See {TokenOffer-_buyTokens}
     */
    function buy(uint256 deadline, uint256 minAmount) public payable returns (bool) {
        return _buyTokens(_msgSender(), deadline, minAmount);
    }

    /**
     * @dev See {TokenOffer-_buyTokens}
     */
    function buyTo(address recipient, uint256 deadline, uint256 minAmount) public payable returns (bool) {
        return _buyTokens(recipient, deadline, minAmount);
    }

    /**
     * @dev Check if the offer is open.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= openingTime && block.timestamp <= closingTime;
    }

    /**
     * @dev Get the current rate of tokens per wei.
     * Note that, as price _increases_ with time, the rate _decreases_.
     * @return The number of units/TKNbits a buyer gets per wei at a given time.
     */
    function currentRate() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - openingTime;
        uint256 timeRange = closingTime - openingTime;
        uint256 rateRange = initialRate - finalRate;
        return initialRate - elapsedTime * rateRange / timeRange;
    }

    // -----------------------------------------
    // Internal implementation
    // -----------------------------------------

    /**
     * @dev Send tokens to the recipient
     */
    function _deliverTokens(address recipient, uint256 tokenAmount) internal {
        require(tokenAmount > 0, "TokenOffer: invalid token amount");
        tokenCnt.transferFrom(owner(), recipient, tokenAmount);
    }

    /**
     * @dev Send funds to token contract
     */
    function _forwardFunds() internal {
        payable(owner()).transfer(msg.value);
    }

    /**
     * @dev Convert Wei to tokens, return the number of tokens that can be purchased with the specified weiAmount.
     */
    function _calcTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * currentRate();
    }

    /**
     * Sender needs to send enough native currency to buy the tokens at a price of amount * rate
     */
    function _buyTokens(address recipient, uint256 deadline, uint256 minAmount) internal nonReentrant returns (bool) {
        require(deadline >= block.timestamp, 'TokenOffer: expired transaction');
        require(isOpen(), "TokenOffer: offer closed");
        require(recipient != address(0), "TokenOffer: transfer to the zero address");

        uint256 weiAmount = msg.value;
        require(weiAmount > 0, "TokenOffer: Wei amount is zero");

        // calculate token amount to be created
        uint256 tokenAmount = _calcTokenAmount(weiAmount);
        require(tokenAmount >= minAmount, 'TokenOffer: minimum amount not reached');

        // update state
        totalSold += tokenAmount;
        totalRaised += weiAmount;

        // transfer tokens to sender and native currency to owner
        _deliverTokens(recipient, tokenAmount);
        _forwardFunds();
        emit OnBought(_msgSender(), recipient, weiAmount, tokenAmount);

        return true;
    }
}
