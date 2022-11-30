// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement the survey factory
 */
interface ISurveyFactory is ISurveyModel {

    // ### Manager functions `engine` ###

    function createSurvey(SurveyWrapper calldata wrapper, address configAddr, address storageAddr) external returns (address);
}