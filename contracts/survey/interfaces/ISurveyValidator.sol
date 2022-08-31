// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement a validable survey contract
 */
interface ISurveyValidator is ISurveyModel {

    // ### Validation functions ###

    function checkSurvey(Survey memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) external view;
    function checkResponse(Question memory question, Validator[] memory validators, string memory response) external view;

    // ### Manager functions `onlyManager` ###
    
    function checkAuthorization(string[] memory hashes, string memory key) external view returns (uint256);

    // ### Owner functions `onlyOwner` ###

    function setTitleMaxLength(uint256 titleMaxLength) external;
    function setDescriptionMaxLength(uint256 descriptionMaxLength) external;
    function setUrlMaxLength(uint256 urlMaxLength) external;
    function setStartMaxTime(uint256 startMaxTime) external;
    function setRangeMinTime(uint256 rangeMinTime) external;
    function setRangeMaxTime(uint256 rangeMaxTime) external;
    function setQuestionMaxPerSurvey(uint256 questionMaxPerSurvey) external;
    function setQuestionMaxLength(uint256 questionMaxLength) external;
    function setValidatorMaxPerQuestion(uint256 validatorMaxPerQuestion) external;
    function setValidatorValueMaxLength(uint256 validatorValueMaxLength) external;
    function setHashMaxPerSurvey(uint256 hashMaxPerSurvey) external;
    function setResponseMaxLength(uint256 responseMaxLength) external;
}
