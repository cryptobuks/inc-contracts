// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement the survey engine
 */
 interface ISurveyEngine is ISurveyModel {

   event OnSurveyAdded(
        address indexed owner,
        address surveyAddr
    );

    event OnSurveySolved(
        address indexed owner,
        address surveyAddr,
        uint256 budgetRefund,
        uint256 gasRefund
    );

    event OnGasReserveIncreased(
        address indexed owner,
        address surveyAddr,
        uint256 gasAdded,
        uint256 gasReserve
    );

    event OnParticipationAdded(
        address indexed participant,
        address surveyAddr,
        uint256 txGas
    );

    function currency() external view returns (address);
    function surveyConfig() external view returns (address);
    function surveyStorage() external view returns (address);

    function addSurvey(SurveyRequest memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) external payable;
    function solveSurvey(address surveyAddr) external;
    function increaseGasReserve(address surveyAddr) external payable;
    function addParticipation(address surveyAddr, string[] memory responses, string memory key) external;
    function addParticipationFromForwarder(address surveyAddr, string[] memory responses, string memory key, uint256 txGas) external;
 }