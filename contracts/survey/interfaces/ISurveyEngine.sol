// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/IWETH.sol";
import "./ISurveyStorage.sol";
import "./ISurveyConfig.sol";
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

    function currencyCnt() external view returns (IWETH);
    function storageCnt() external view returns (ISurveyStorage);
    function configCnt() external view returns (ISurveyConfig);

    function addSurvey(SurveyRequest memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) external payable;
    function solveSurvey(address surveyAddr) external;
    function increaseGasReserve(address surveyAddr) external payable;
    function addParticipation(address surveyAddr, string[] memory responses, string memory key) external;
    function addParticipationFromForwarder(address surveyAddr, string[] memory responses, string memory key, uint256 txGas) external;
 }