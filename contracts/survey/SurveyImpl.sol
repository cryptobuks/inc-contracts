// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../abstractions/Manageable.sol";
import "../libraries/StringUtils.sol";
import "./interfaces/ISurveyImpl.sol";
import "./interfaces/ISurveyValidator.sol";
import "./SurveyBase.sol";

contract SurveyImpl is ISurveyImpl, SurveyBase, Manageable {

    using StringUtils for *;

    constructor(address _config) SurveyBase(_config) {
    }

    // ### Owner functions `factory` ###

    // Called once by the factory at time of deployment
    function initialize(Survey calldata survey, Question[] calldata questions, Validator[] calldata validators, string[] calldata hashes, uint256 gasReserve) 
    external override onlyOwner {
        _data = survey;
        remainingBudget = survey.budget;
        remainingGasReserve = gasReserve;

        for(uint i = 0; i < questions.length; i++) {
            _questions.push(questions[i]);
        }

        for(uint i = 0; i < validators.length; i++) {
            _validators[validators[i].questionIndex].push(validators[i]);
        }

        for(uint i = 0; i < hashes.length; i++) {
            _availableHashes[hashes[i]] = true;
        }
    }

    // ### Manager functions `storage` ###

    function addParticipation(Participation calldata participation, string calldata key) external override onlyManager returns (uint256) {
        string memory hashStr;

        if(_data.keyRequired) {
            bytes32 hash = keccak256(abi.encodePacked(key));
            hashStr = uint256(hash).toHexString(32);
            uint256 length = hashStr.toSlice().len();
            hashStr = hashStr.substring(2, 6).toSlice().concat(hashStr.substring(length-4, length).toSlice());
            require(_availableHashes[hashStr], "SurveyImpl: participation unauthorized");
        }

        ISurveyValidator validatorCnt = ISurveyValidator(configCnt.surveyValidator());
        string[] memory values;

        for(uint i = 0; i < _questions.length; i++) {
            validatorCnt.checkResponse(_questions[i], _validators[i], participation.responses[i]);
            if(!validatorCnt.isLimited(_questions[i].responseType)) {
                continue;
            }

            // There is no need to check the response type ´isArray´ since limited elements 
            // cannot contain repeated delimiter ´;´
            values = participation.responses[i].split(";");

            for(uint j = 0; j < values.length; j++) {
                if(_responseCounts[i][values[j]] == 0) {
                    _repetitiveResponses[i].push(values[j]);
                }
                _responseCounts[i][values[j]]++;
            }
        }

        _participations[participation.account] = participation;
        _participants.push(participation.account);

        remainingBudget -= _data.reward;

        uint256 txPrice = participation.gasPrice * participation.txGas;
        remainingGasReserve -= txPrice;

        if(_availableHashes[hashStr]) {
            _availableHashes[hashStr] = false;
        }

        return txPrice;
    }

    function solveSurvey() external override onlyManager returns (uint256) {
        uint256 gasReserve = remainingGasReserve;
        remainingBudget = 0;
        remainingGasReserve = 0;
        return gasReserve;
    }

    function increaseGasReserve(uint256 amount) external override onlyManager {
        remainingGasReserve += amount;
    }
}