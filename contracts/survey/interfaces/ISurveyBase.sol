// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement a survey contract
 */
interface ISurveyBase is ISurveyModel {

    function currentCursor(uint256 surveyMaxDuration) external view returns (uint256);
    function txGasSamples(uint256 maxLength) external view returns (uint256[] memory);
    function remainingBudgetOf(uint256 surveyId) external view returns (uint256);
    function gasReserveOf(uint256 surveyId) external view returns (uint256);
	function keyRequiredOf(uint256 surveyId) external view returns (bool);
    function ownerOf(uint256 surveyId) external view returns (address);
    function findSurveyData(uint256 surveyId) external view returns (SurveyData memory);

    // ### Surveys ###

    function getSurveysLength() external view returns (uint256);
    function findSurvey(uint256 id) external view returns (Survey memory);
    function getSurveys(uint256 cursor, uint256 length) external view returns (Survey[] memory);
    function findSurveys(uint256 cursor, uint256 length, SurveyFilter memory filter) external view returns (Survey[] memory);
    function isOpenedSurvey(uint256 id, uint256 offset) external view returns (bool);

    // ### Own Surveys ###

    function getOwnSurveysLength() external view returns (uint256);
    function getOwnSurveys(uint256 cursor, uint256 length) external view returns (Survey[] memory);
    function findOwnSurveys(uint256 cursor, uint256 length, SurveyFilter memory filter) external view returns (Survey[] memory);

    // ### Participants ###
    
    function getParticipantsLength(uint256 surveyId) external view returns (uint256);
    function getParticipants(uint256 surveyId, uint256 cursor, uint256 length) external view returns (address[] memory);
    function isParticipant(uint256 surveyId, address account) external view returns (bool);

    // ### Participations ###

    function getParticipations(uint256 surveyId, uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function findParticipation(uint256 surveyId, address account) external view returns (Participation memory);

    // ### Own Participations ###

    function getOwnParticipationsLength() external view returns (uint256);
    function getOwnParticipations(uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function findOwnParticipation(uint256 surveyId) external view returns (Participation memory);

    // ### Questions ###

    function getQuestionsLength(uint256 surveyId) external view returns (uint256);
    function getQuestions(uint256 surveyId, uint256 cursor, uint256 length) external view returns (Question[] memory);

    // ### Responses ###

    function getResponses(uint256 surveyId, uint256 questionIndex, uint256 cursor, uint256 length) external view returns (string[] memory);

    // ### Validators ###

    function getValidators(uint256 surveyId, uint256 questionIndex) external view returns (Validator[] memory);
}
