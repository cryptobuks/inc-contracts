// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @dev Interface for to draw a timeline of the balances through the transfers made.
 */
interface IMeasurement {

    struct Timeline {
        uint256[] times;// timestamp in seconds
        uint256[] balances;// balance at the time
    }
    
    /**
     * @dev Returns the maximum number per request for points or metrics.
     */
    function timelineMaxPerRequest() external view returns (uint256);

    /**
     * @dev Returns the number of records in the timeline.
     */
    function timelineLengthOf(address account) external view returns (uint256);

    /**
     * @dev Returns the point (time, balance) with the indicated index.
     */
    function timelinePointOf(address account, uint256 index) external view returns (uint256, uint256);

    /**
     * @dev Returns the points from the cursor to the indicated length.
     */
    function timelinePointsOf(address account, uint256 cursor, uint256 length) external view returns (Timeline memory);

    /**
     * @dev Returns the date of the first record from the timeline.
     */
    function timelineStartOf(address account) external view returns (uint256);

    /**
     * @dev Returns the date of the last record from the timeline.
     */
    function timelineEndOf(address account) external view returns (uint256);

    /**
     * @dev Returns the balance in the indicated time.
     */
    function timelineBalanceOf(address account, uint256 pointTime) external view returns (uint256);

    /**
     * @dev Returns the points within the indicated range.
     */
    function timelinePointRangeOf(address account, uint256 startTime, uint256 endTime) 
    external view returns (Timeline memory);

    /**
     * @dev Returns the metrics timeline by range and granularity.
     * If the range exceeds the current date, the last balance will be repeated.
     */
    function timelineMetricsOf(address account, uint256 startTime, uint256 endTime, uint256 granularity) 
    external view returns (Timeline memory);

    /**
     * @dev Returns the average balance by range and granularity.
     * If the range exceeds the current date, the last balance will 
     * be repeated so the average will be affected.
     */
    function timelineAvgOf(address account, uint256 startTime, uint256 endTime, uint256 granularity) 
    external view returns (uint256);
}
