// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyModel.sol";
import "./ISurveyConfig.sol";

/**
 * @dev Interface to implement a survey contract
 */
interface ISurveyBase is ISurveyModel {

    function config() external view returns (address);
    function data() external view returns (Survey memory);
    function remainingBudget() external view returns (uint256);
    function remainingGasReserve() external view returns (uint256);
    function amounts() external view returns (uint256, uint256, uint256);
    function isOpened(uint256 offset) external view returns (bool);

    // ### Questions ###

    function getQuestionsLength() external view returns (uint256);
    function getQuestions(uint256 cursor, uint256 length) external view returns (Question[] memory);

    // ### Validators ###

    function getValidatorsLength(uint256 questionIndex) external view returns (uint256);
    function getValidators(uint256 questionIndex) external view returns (Validator[] memory);

    // ### Participants ###
    
    function getParticipantsLength() external view returns (uint256);
    function getParticipants(uint256 cursor, uint256 length) external view returns (address[] memory);
    function isParticipant(address account) external view returns (bool);

    // ### Participations ###

    function getParticipations(uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function findParticipation(address account) external view returns (Participation memory);

    // ### Responses ###

    function getResponses(uint256 questionIndex, uint256 cursor, uint256 length) external view returns (string[] memory);
    function getResponseCounts(uint256 questionIndex) external view returns (ResponseCount[] memory);
}