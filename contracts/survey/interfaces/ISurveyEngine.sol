// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IWETH.sol";
import "./ISurveyStorage.sol";
import "./ISurveyValidator.sol";
import "./ISurveyModel.sol";

/**
 * @dev Interface to implement the survey engine
 */
 interface ISurveyEngine is ISurveyModel {

    function tokenCnt() external view returns (IERC20);
    function currencyCnt() external view returns (IWETH);
    function surveyCnt() external view returns (ISurveyStorage);
    function validatorCnt() external view returns (ISurveyValidator);

    function addSurvey(Survey memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) external payable returns (uint256);
    function solveSurvey(uint256 surveyId) external returns (bool);
    function increaseGasReserve(uint256 surveyId) external payable returns (bool);
    function addParticipation(uint256 surveyId, string[] memory responses, string memory key) external;
    function addParticipationFromForwarder(uint256 surveyId, string[] memory responses, string memory key, uint256 txGas) external;
 }
