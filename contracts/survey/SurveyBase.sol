// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/ISurveyBase.sol";
import "./interfaces/ISurveyConfig.sol";

abstract contract SurveyBase is Context, ISurveyBase {
    
    uint256 public override remainingBudget;// Remaining incentive tokens
    uint256 public override remainingGasReserve;// Remaining gas reserve to pay participations

    ISurveyConfig internal configCnt;

    Survey internal _data;
    Question[] internal _questions;
    address[] internal _participants;

    mapping(uint256 => Validator[]) internal _validators;// Using question index
    mapping(address => Participation) internal _participations;// Using participant address
    mapping(string => bool) internal _availableHashes;// Available participation hashes
    mapping(uint256 => mapping(string => uint256)) internal _responseCounts;// Using question index & response
    mapping(uint256 => string[]) internal _repetitiveResponses;// Using question index

    constructor(address _config) {
        require(_config != address(0), "SurveyBase: invalid config address");
        configCnt = ISurveyConfig(_config);
    }

    function config() external view virtual override returns (address) {
        return address(configCnt);
    }

    function data() external view virtual override returns (Survey memory) {
        return _data;
    }

    function amounts() external view override returns (uint256, uint256, uint256) {
        return (remainingBudget, remainingGasReserve, _participants.length);
    }

    function isOpened(uint256 offset) external view override returns (bool) {
        return block.timestamp >= _data.startTime && block.timestamp <= _data.endTime && _data.endTime - block.timestamp >= offset;
    }

    // ### Questions ###

    function getQuestionsLength() external view virtual override returns (uint256) {
        return _questions.length;
    }

    function getQuestions(uint256 cursor, uint256 length) external view virtual override returns (Question[] memory) {
        require(cursor < _questions.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= _questions.length, "SurveyBase: invalid length from current position");
        require(length <= configCnt.questionMaxPerRequest(), "SurveyBase: oversized length of questions");

        Question[] memory array = new Question[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = _questions[i];
        }
        return array;
    }

    // ### Validators ###

    function getValidatorsLength(uint256 questionIndex) external view virtual override returns (uint256) {
        require(questionIndex < _questions.length, "SurveyBase: question index out of range");
        return _validators[questionIndex].length;
    }

    function getValidators(uint256 questionIndex) external view virtual override returns (Validator[] memory) {
        require(questionIndex < _questions.length, "SurveyBase: question index out of range");
       return _validators[questionIndex];
    }

    // ### Participants ###

    function getParticipantsLength() external view virtual override returns (uint256) {
        return _participants.length;
    }

    function getParticipants(uint256 cursor, uint256 length) external view virtual override returns (address[] memory) {
        require(length > 0 && cursor+length <= _participants.length, "SurveyBase: invalid length from current position");
        require(length <= configCnt.participantMaxPerRequest(), "SurveyBase: oversized length of survey participants");

        address[] memory array = new address[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = _participants[i];
        }
        return array;
    }

    function isParticipant(address account) external view virtual override returns (bool) {
        require(account != address(0), "SurveyBase: invalid participant address");
        return _participations[account].partTime != 0;
    }

    // ### Participations ###

    function getParticipations(uint256 cursor, uint256 length) external view virtual override returns (Participation[] memory) {
        require(cursor < _participants.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= _participants.length, "SurveyBase: invalid length from current position");
        require(length <= configCnt.participationMaxPerRequest(), "SurveyBase: oversized length of survey participations");

        Participation[] memory array = new Participation[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = _participations[_participants[i]];
        }
        return array;
    }

    function findParticipation(address account) external view virtual override returns (Participation memory) {
        require(account != address(0), "SurveyBase: invalid participant address");
        return _participations[account];
    }

    // ### Responses ###

    function getResponses(uint256 questionIndex, uint256 cursor, uint256 length) external view virtual override returns (string[] memory) {
        require(questionIndex < _questions.length, "SurveyBase: question index out of range");
        require(cursor < _participants.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= _participants.length, "SurveyBase: invalid length from current position");
        require(length <= configCnt.responseMaxPerRequest(), "SurveyBase: oversized length of survey participations");

        string[] memory array = new string[](length);
        string[] memory responses;

        for (uint i = cursor; i < cursor+length; i++) {
            responses = _participations[_participants[i]].responses;
            array[i-cursor] = responses[questionIndex];
        }
        return array;
    }

    function getResponseCounts(uint256 questionIndex) external view virtual override returns (ResponseCount[] memory) {
        require(questionIndex < _questions.length, "SurveyBase: question index out of range");
        require(_participants.length > 0, "SurveyBase: no responses");

        ResponseCount[] memory array = new ResponseCount[](_repetitiveResponses[questionIndex].length);

        for (uint i = 0; i < array.length; i++) {
            ResponseCount memory rc;
            rc.value = _repetitiveResponses[questionIndex][i];
            rc.count = _responseCounts[questionIndex][rc.value];
            array[i] = rc;
        }
        return array;
    }
}