// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement the survey storage
 */
interface ISurveyStorage is ISurveyModel {

    struct PartID {
        address surveyAddr;
        address partOwner;
    }

    function surveyConfig() external view returns (address);
    function totalGasReserve() external view returns (uint256);
    function txGasSamples(uint256 maxLength) external view returns (uint256[] memory);
    function remainingBudgetOf(address surveyAddr) external view returns (uint256);
    function remainingGasReserveOf(address surveyAddr) external view returns (uint256);
    function amountsOf(address surveyAddr) external view returns (uint256, uint256, uint256);

    // ### Surveys ###

    function exists(address surveyAddr) external view returns (bool);
    function getSurveysLength() external view returns (uint256);
    function getAddresses(uint256 cursor, uint256 length) external view returns (address[] memory);
    function getSurveys(uint256 cursor, uint256 length) external view returns (Survey[] memory);
    function findSurvey(address surveyAddr) external view returns (Survey memory);
    function isOpenedSurvey(address surveyAddr, uint256 offset) external view returns (bool);

    // ### Own Surveys ###

    function getOwnSurveysLength() external view returns (uint256);
    function getOwnSurveys(uint256 cursor, uint256 length) external view returns (Survey[] memory);

    // ### Questions ###

    function getQuestionsLength(address surveyAddr) external view returns (uint256) ;
    function getQuestions(address surveyAddr, uint256 cursor, uint256 length) external view returns (Question[] memory);

    // ### Validators ###

    function getValidatorsLength(address surveyAddr, uint256 questionIndex) external view returns (uint256);
    function getValidators(address surveyAddr, uint256 questionIndex) external view returns (Validator[] memory);

    // ### Participants ###

    function getParticipantsLength(address surveyAddr) external view returns (uint256);
    function getParticipants(address surveyAddr, uint256 cursor, uint256 length) external view returns (address[] memory);
    function isParticipant(address surveyAddr, address account) external view returns (bool);

    // ### Participations ###

    function getParticipationsTotal() external view returns (uint256);
    function getGlobalParticipations(uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function getParticipations(address surveyAddr, uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function findParticipation(address surveyAddr, address account) external view returns (Participation memory);

    // ### Own Participations ###

    function getOwnParticipationsLength() external view returns (uint256);
    function getOwnParticipations(uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function findOwnParticipation(address surveyAddr) external view returns (Participation memory);

    // ### Responses ###

    function getResponses(address surveyAddr, uint256 questionIndex, uint256 cursor, uint256 length) external view returns (string[] memory);
    function getResponseCounts(address surveyAddr, uint256 questionIndex) external view returns (ResponseCount[] memory);

    // ### Manager functions ###

    function saveSurvey(address senderAddr, address surveyAddr, uint256 gasReserve) external returns (address);
    function addParticipation(Participation calldata participation, string calldata key) external;
    function solveSurvey(address surveyAddr) external;
    function increaseGasReserve(address surveyAddr, uint256 amount) external;
}