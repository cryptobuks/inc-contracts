// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyBase.sol";

/**
 * @dev Interface to implement a survey contract
 */
interface ISurveyImpl is ISurveyBase {

    // ### Owner functions `factory` ###

    function initialize(Survey calldata survey, Question[] calldata questions, Validator[] calldata validators, string[] calldata hashes, uint256 gasReserve) external;

    // ### Manager functions `storage` ###

    function addParticipation(Participation calldata participation, string calldata key) external returns (uint256);
    function solveSurvey() external returns (uint256);
    function increaseGasReserve(uint256 amount) external;
}