// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../abstractions/Manageable.sol";
import "./interfaces/ISurveyStorage.sol";
import "./SurveyBase.sol";

contract SurveyStorage is ISurveyStorage, SurveyBase, Manageable {

    // ### Manager functions ###

    function getAllHashes(uint256 surveyId) external override view onlyManager returns (string[] memory) {
        return _surveyData[surveyId].hashes;
    }

    function getAllQuestions(uint256 surveyId) external override view onlyManager returns (Question[] memory) {
        return _questions[surveyId];
    }

    function saveSurvey(address account, Survey memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes, uint256 gasReserve) 
    external override onlyManager returns (uint256) {
        uint256 surveyId = ++_surveyLastId;
        survey.id = surveyId;
        survey.entryTime = block.timestamp;

        _surveys[account].push(survey);

        for(uint i = 0; i < questions.length; i++) {
            _questions[surveyId].push(questions[i]);
        }

        for(uint i = 0; i < validators.length; i++) {
            Validator memory validator = validators[i];
            _validators[surveyId][validator.questionIndex].push(validator);
        }

        SurveyData storage surveyData = _surveyData[surveyId];
        surveyData.owner = account;
        surveyData.remainingBudget = survey.budget;
        surveyData.gasReserve = gasReserve;
        surveyData.hashes = hashes;
        surveyData.keyRequired = hashes.length > 0;
        totalGasReserve += gasReserve;

        return surveyId;
    }

    function saveParticipation(address account, uint256 surveyId, string[] memory responses, uint256 reward, uint256 txGas, uint256 hashIndex) 
    external override onlyManager {
        Participation memory participation;
        participation.surveyId = surveyId;
        participation.responses = responses;
        participation.entryTime = block.timestamp;
        participation.txGas = txGas;
        participation.gasPrice = tx.gasprice;

        _participations[account].push(participation);

        SurveyData storage surveyData = _surveyData[surveyId];
        surveyData.participants.push(account);
        surveyData.remainingBudget -= reward;

        uint256 txPrice = tx.gasprice * txGas;
        surveyData.gasReserve -= txPrice;

        if(hashIndex < surveyData.hashes.length) {
            surveyData.hashes[hashIndex] = surveyData.hashes[surveyData.hashes.length-1];
            surveyData.hashes.pop();
        }

        totalGasReserve -= txPrice;

        // Save sample to calculate the following costs
        if(txGas > 0) {
            _txGasSamples.push(txGas);
        }
    }

    function solveSurvey(uint256 surveyId) external override onlyManager {
        SurveyData storage surveyData = _surveyData[surveyId];
        totalGasReserve -= surveyData.gasReserve;
        surveyData.remainingBudget = 0;
        surveyData.gasReserve = 0;
        delete surveyData.hashes;
    }

    function increaseGasReserve(uint256 surveyId, uint256 amount) external override onlyManager {
        SurveyData storage surveyData = _surveyData[surveyId];
        surveyData.gasReserve += amount;
        totalGasReserve += amount;
    }

    // ### Owner functions ###

    function setSurveyMaxPerRequest(uint256 _surveyMaxPerRequest) external override onlyOwner {
        surveyMaxPerRequest = _surveyMaxPerRequest;
    }

    function setParticipantMaxPerRequest(uint256 _participantMaxPerRequest) external override onlyOwner {
        participantMaxPerRequest = _participantMaxPerRequest;
    }

    function setParticipationMaxPerRequest(uint256 _participationMaxPerRequest) external override onlyOwner {
        participationMaxPerRequest = _participationMaxPerRequest;
    }

    function setQuestionMaxPerRequest(uint256 _questionMaxPerRequest) external override onlyOwner {
        questionMaxPerRequest = _questionMaxPerRequest;
    }

    function setResponseMaxPerRequest(uint256 _responseMaxPerRequest) external override onlyOwner {
        responseMaxPerRequest = _responseMaxPerRequest;
    }

    function setTxGasMaxPerRequest(uint256 _txGasMaxPerRequest) external override onlyOwner {
        txGasMaxPerRequest = _txGasMaxPerRequest;
    }
}
