// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IHolding.sol";
import "../interfaces/IMeasurement.sol";

/**
 * @dev It inherits the ERC20 implementation and implements the specific interfaces of the INC token.
 *
 * The interface {IHolding} has been implemented to keep track of token holders.
 *
 * The {IMeasurement} interface has also been implemented to draw a timeline with the balances through 
 * the transfers made.
 */
contract TokenBase is ERC20Votes, IHolding, IMeasurement {

    mapping(address => uint256) private _indices;
    address[] private _holders;
    mapping(address => Timeline) private _timelines;

    uint256 public override holderMaxPerRequest = 1000;
    uint256 public override timelineMaxPerRequest = 1000;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {
        _putHolder(address(0));// Occupy position 0 of holders
    }

    /**
     * @dev See {IHolding-holderPosition}.
     */
    function holderPosition(address account) public view virtual override returns (uint256) {
        return _indices[account];
    }

    /**
     * @dev See {IHolding-holdersLength}.
     */
    function holdersLength() public view virtual override returns (uint256) {
        return _holders.length;
    }

    /**
     * @dev See {IHolding-holders}.
     */
    function holders(uint256 cursor, uint256 length) public view virtual override returns (address[] memory) {
        require(cursor < _holders.length, "TokenBase: cursor out of range");
        require(length > 0 && cursor+length <= _holders.length, "TokenBase: invalid length from current position");
        require(length <= holderMaxPerRequest, "TokenBase: oversized length of holders");

        address[] memory array = new address[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = _holders[i];
        }
        return array;
    }

    /**
     * @dev See {IMeasurement-timelineLengthOf}.
     */
    function timelineLengthOf(address account) public view virtual override returns (uint256) {
        return _timelines[account].times.length;
    }

    /**
     * @dev See {IMeasurement-timelinePointOf}.
     */
    function timelinePointOf(address account, uint256 index) public view virtual override returns (uint256, uint256) {
        Timeline memory timeline = _timelines[account];
        require(index < timeline.times.length, "TokenBase: index out of range");
        return (timeline.times[index], timeline.balances[index]);
    }

    /**
     * @dev See {IMeasurement-timelinePointsOf}.
     */
    function timelinePointsOf(address account, uint256 cursor, uint256 length) public view virtual override returns (Timeline memory) {
        Timeline memory timeline = _timelines[account];
        
        require(cursor < timeline.times.length, "TokenBase: cursor out of range");
        require(length > 0 && cursor+length <= timeline.times.length, "TokenBase: invalid length from current position");
        require(length <= timelineMaxPerRequest, "TokenBase: oversized length of points");

        Timeline memory result;
        result.times = new uint256[](length);
        result.balances = new uint256[](length);

        for (uint i = cursor; i < cursor+length; i++) {
            result.times[i-cursor] = timeline.times[i];
            result.balances[i-cursor] = timeline.balances[i];
        }

        return result;
    }

    /**
    * @dev See {IMeasurement-timelineStartOf}.
    */
    function timelineStartOf(address account) public view virtual override returns (uint256) {
        require(account != address(0), "TokenBase: timeline start for the zero address");
        Timeline memory timeline = _timelines[account];
        if(timeline.times.length == 0) {
            return 0;
        }

        return timeline.times[0];
    }

    /**
    * @dev See {IMeasurement-timelineEndOf}.
    */
    function timelineEndOf(address account) public view virtual override returns (uint256) {
        require(account != address(0), "TokenBase: timeline end for the zero address");
        Timeline memory timeline = _timelines[account];
        uint256 length = timeline.times.length;

        if(length == 0) {
            return 0;
        }

        return timeline.times[length - 1];
    }

    /**
    * @dev See {IMeasurement-timelineBalanceOf}.
    */
    function timelineBalanceOf(address account, uint256 pointTime) public view virtual override returns (uint256) {
        require(account != address(0), "TokenBase: timeline balance for the zero address");
        Timeline memory timeline = _timelines[account];
        if(timeline.times.length == 0) {
            return 0;
        }

        return _timelineBalance(timeline, pointTime);
    }

    /**
     * @dev See {IMeasurement-timelinePointRangeOf}.
     */
    function timelinePointRangeOf(address account, uint256 startTime, uint256 endTime) 
    public view virtual override returns (Timeline memory) {
        return _timelinePointRangeOf(account, startTime, endTime);
    }

    /**
     * @dev See {IMeasurement-timelineMetricsOf}.
     */
    function timelineMetricsOf(address account, uint256 startTime, uint256 endTime, uint256 granularity) 
    public view virtual override returns (Timeline memory) {
        return _timelineMetricsOf(account, startTime, endTime, granularity);
    }

    /**
    * @dev See {IMeasurement-timelineAvgOf}.
    */
    function timelineAvgOf(address account, uint256 startTime, uint256 endTime, uint256 granularity) 
    public view virtual override returns (uint256) {
        Timeline memory timeline = _timelineMetricsOf(account, startTime, endTime, granularity);
        uint256 length = timeline.balances.length;

        if(length == 0) {
            return 0;
        }

        uint256 amount = 0;

        for(uint i = 0; i < length; i++) {
            amount += timeline.balances[i];
        }
        
        return Math.ceilDiv(amount, length);
    }

    /**
     * @dev See {IERC20-_afterTokenTransfer}.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        if(amount == 0) {
            return;
        }

        if(from != address(0)) {
            _updateTimeline(from);
        }

        if(to != address(0)) {
            _updateTimeline(to);
        }
    }

    /**
    * @dev Get balance from timeline on specified date
    */
    function _timelineBalance(Timeline memory timeline, uint256 pointTime) internal pure returns (uint256) {
        for(uint i = timeline.times.length; i > 0; i--) {
            uint256 index = i - 1;
            uint256 time = timeline.times[index];
            if(pointTime >= time) {
                return timeline.balances[index];
            }
        }

        return 0;
    }

    /**
     * @dev See {IMeasurement-timelinePointRangeOf}.
     */
    function _timelinePointRangeOf(address account, uint256 startTime, uint256 endTime) 
    internal view returns (Timeline memory) {
        require(account != address(0), "TokenBase: timeline for the zero address");
        require(startTime > 0 && startTime < endTime, "TokenBase: invalid date range");

        Timeline memory timeline = _timelines[account];
        uint256 length = timeline.times.length;
        require(length <= timelineMaxPerRequest, "TokenBase: excessive number of points");

        uint256[] memory times = new uint256[](length);
        uint256[] memory balances = new uint256[](length);
        uint256 count = 0;

        for(uint i = 0; i < length; i++) {
            uint256 time = timeline.times[i];

            if(time > endTime) {
                break;
            }

            if(time >= startTime) {
                times[count] = time;
                balances[count] = timeline.balances[i];
                count++;
            }
        }

        Timeline memory result;
        result.times = new uint256[](count);
        result.balances = new uint256[](count);

        for(uint i = 0; i < count; i++) {
            result.times[i] = times[i];
            result.balances[i] = balances[i];
        }

        return result;
    }

    /**
     * @dev See {IMeasurement-timelineMetricsOf}.
     */
    function _timelineMetricsOf(address account, uint256 startTime, uint256 endTime, uint256 granularity) 
    internal view returns (Timeline memory) {
        require(account != address(0), "TokenBase: timeline for the zero address");
        require(startTime > 0 && startTime < endTime, "TokenBase: invalid date range");
        require(granularity > 0, "TokenBase: invalid granularity");

        uint256 totalTime = endTime - startTime;
        uint256 length = Math.ceilDiv(totalTime, granularity);
        require(length <= timelineMaxPerRequest, "TokenBase: excessive number of metrics");

        Timeline memory timeline = _timelines[account];
        Timeline memory result;

        if(timeline.times.length == 0) {
            return result;
        }

        result.times = new uint256[](length + 1);
        result.balances = new uint256[](length + 1);
        uint256 balance;

        for(uint i = 0; i < length; i++) {
            uint256 pointTime = startTime + granularity * i;
            balance = _timelineBalance(timeline, pointTime);
            result.times[i] = pointTime;
            result.balances[i] = balance;
        }

        balance = _timelineBalance(timeline, endTime);
        result.times[length] = endTime;
        result.balances[length] = balance;
        
        return result;
    }

    /**
    * @dev Update timeline for indicated account
    */
    function _updateTimeline(address account) internal {
        require(account != address(0), "TokenBase: update timeline for the zero address");
        uint256 balance = balanceOf(account);
        Timeline storage timeline = _timelines[account];
        timeline.times.push(block.timestamp);
        timeline.balances.push(balance);

        _putHolder(account);
    }

    /**
    * @dev Save the indicated holder if it does not exist
    */
    function _putHolder(address account) internal {
        if(_indices[account] == 0) {
            _indices[account] = _holders.length;
            _holders.push(account);
        }
    }
}
