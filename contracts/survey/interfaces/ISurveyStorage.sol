// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ISurveyBase.sol";

/**
 * @dev Interface to implement a survey contract
 */
interface ISurveyStorage is ISurveyBase {

    // ### Manager functions `onlyManager` ###

    function getAllHashes(uint256 surveyId) external view returns (string[] memory);
    function getAllQuestions(uint256 surveyId) external view returns (Question[] memory);
    function saveSurvey(address account, Survey memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes, uint256 gasReserve) external returns (uint256);
    function saveParticipation(address account, uint256 surveyId, string[] memory responses, uint256 reward, uint256 txGas, uint256 hashIndex) external;
    function solveSurvey(uint256 surveyId) external;
    function increaseGasReserve(uint256 surveyId, uint256 amount) external;

    // ### Owner functions `onlyOwner` ###

    function setSurveyMaxPerRequest(uint256 surveyMaxPerRequest) external;
    function setParticipantMaxPerRequest(uint256 participantMaxPerRequest) external;
    function setParticipationMaxPerRequest(uint256 participationMaxPerRequest) external;
    function setQuestionMaxPerRequest(uint256 questionMaxPerRequest) external;
    function setResponseMaxPerRequest(uint256 responseMaxPerRequest) external;
    function setTxGasMaxPerRequest(uint256 txGasMaxPerRequest) external;
}
