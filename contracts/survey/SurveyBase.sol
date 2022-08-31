// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/ISurveyBase.sol";
import "../libraries/StringUtils.sol";

abstract contract SurveyBase is Context, ISurveyBase {

    using StringUtils for *;

    uint256 public surveyMaxPerRequest = 100;
    uint256 public participantMaxPerRequest = 100;
    uint256 public participationMaxPerRequest = 100;
    uint256 public questionMaxPerRequest = 100;
    uint256 public responseMaxPerRequest = 1000;
    uint256 public txGasMaxPerRequest = 1000;
    uint256 public totalGasReserve;// total gas reserve for all surveys

    mapping(address => Survey[]) internal _surveys;// using survey owner address
    mapping(uint256 => Question[]) internal _questions;// using surveyId
    mapping(address => Participation[]) internal _participations;// using participant address
    mapping(uint256 => SurveyData) internal _surveyData;// using surveyId
    mapping(uint256 => mapping(uint256 => Validator[])) internal _validators;// using surveyId & questionIndex
    uint256[] internal _txGasSamples;// samples to calculate the average meta-transaction gas

    uint256 internal _surveyLastId;

    function currentCursor(uint256 surveyMaxDuration) external view virtual override returns (uint256) {
        uint256 firstTime = block.timestamp - surveyMaxDuration;

        for(uint id = _surveyLastId; id > 0; id--) {
            Survey memory survey = _findSurvey(id);
            if(survey.entryTime < firstTime) {
                // Return id as index to reference the next survey
                return survey.id;
            }
        }

        return 0;
    }

    function txGasSamples(uint256 maxLength) external view virtual override returns (uint256[] memory) {
        require(maxLength <= txGasMaxPerRequest, "SurveyBase: oversized length of tx gas samples");
        uint256 length = (maxLength <= _txGasSamples.length)? maxLength: _txGasSamples.length;
        uint256[] memory array = new uint256[](length);
        uint256 cursor = _txGasSamples.length - length;

        for(uint i = cursor; i < _txGasSamples.length; i++) {
            array[i-cursor] = _txGasSamples[i];
        }

        return array;
    }

    function remainingBudgetOf(uint256 surveyId) external view virtual override returns (uint256) {
        require(surveyId > 0 && surveyId <= _surveyLastId, "SurveyBase: invalid survey id");
        return _surveyData[surveyId].remainingBudget;
    }

    function gasReserveOf(uint256 surveyId) external view virtual override returns (uint256) {
        require(surveyId > 0 && surveyId <= _surveyLastId, "SurveyBase: invalid survey id");
        return _surveyData[surveyId].gasReserve;
    }
	
	function keyRequiredOf(uint256 surveyId) external view virtual override returns (bool) {
        require(surveyId > 0 && surveyId <= _surveyLastId, "SurveyBase: invalid survey id");
        return _surveyData[surveyId].keyRequired;
    }

    function ownerOf(uint256 surveyId) external view virtual override returns (address) {
        require(surveyId > 0 && surveyId <= _surveyLastId, "SurveyBase: invalid survey id");
        return _surveyData[surveyId].owner;
    }

    function findSurveyData(uint256 surveyId) external view virtual override returns (SurveyData memory) {
        SurveyData memory surveyData = _surveyData[surveyId];
        require(surveyData.owner != address(0), "SurveyBase: survey not found");
        surveyData.participants = new address[](0);// We cannot return all participants at once
        surveyData.hashes = new string[](0);// It will not be necessary outside the blockchain
        return surveyData;
    }

    // ### Surveys ###

    function getSurveysLength() external view virtual override returns (uint256) {
        return _surveyLastId;
    }

    function findSurvey(uint256 id) external view virtual override returns (Survey memory) {
	    require(id > 0 && id <= _surveyLastId, "SurveyBase: invalid survey id");
        return _findSurvey(id);
    }

    function getSurveys(uint256 cursor, uint256 length) external view virtual override returns (Survey[] memory) {
        require(cursor < _surveyLastId, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= _surveyLastId, "SurveyBase: invalid length from current position");
        require(length <= surveyMaxPerRequest, "SurveyBase: oversized length of surveys");

        Survey[] memory array = new Survey[](length);
        uint256 id;

        for (uint i = cursor; i < cursor+length; i++) {
            id = i + 1;
            array[i-cursor] = _findSurvey(id);
        }

        return array;
    }

    function findSurveys(uint256 cursor, uint256 length, SurveyFilter memory filter) external view virtual override returns (Survey[] memory) {
        require(cursor < _surveyLastId, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= _surveyLastId, "SurveyBase: invalid length from current position");
        require(length <= surveyMaxPerRequest, "SurveyBase: oversized length of surveys");

        Survey[] memory array = new Survey[](length);
        Survey memory survey;
        uint256 count = 0;
        uint256 id;

        for (uint i = cursor; i < _surveyLastId && count < length; i++) {
            id = i + 1;
            survey = _findSurvey(id);

            if(_checkSurvey(survey, filter)) {
                array[count++] = survey;
            }
        }

        if(count == length) {
            return array;
        }

        Survey[] memory result = new Survey[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = array[i];
        }
        return result;
    }

    function isOpenedSurvey(uint256 id, uint256 offset) external view virtual override returns (bool) {
	    require(id > 0 && id <= _surveyLastId, "SurveyBase: invalid survey id");
        Survey memory survey = _findSurvey(id);
        return block.timestamp >= survey.startTime && block.timestamp <= survey.endTime && survey.endTime - block.timestamp >= offset;
    }

    // ### Own Surveys ###

    function getOwnSurveysLength() external view virtual override returns (uint256) {
        return _surveys[_msgSender()].length;
    }

    function getOwnSurveys(uint256 cursor, uint256 length) external view virtual override returns (Survey[] memory) {
        Survey[] memory senderSurveys = _surveys[_msgSender()];
        require(cursor < senderSurveys.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= senderSurveys.length, "SurveyBase: invalid length from current position");
        require(length <= surveyMaxPerRequest, "SurveyBase: oversized length of surveys");

        Survey[] memory array = new Survey[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = senderSurveys[i];
        }
        return array;
    }

    function findOwnSurveys(uint256 cursor, uint256 length, SurveyFilter memory filter) external view virtual override returns (Survey[] memory) {
        Survey[] memory senderSurveys = _surveys[_msgSender()];
        require(cursor < senderSurveys.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= senderSurveys.length, "SurveyBase: invalid length from current position");
        require(length <= surveyMaxPerRequest, "SurveyBase: oversized length of surveys");

        Survey[] memory array = new Survey[](length);
        Survey memory survey;
        uint256 count = 0;

        for (uint i = cursor; i < senderSurveys.length && count < length; i++) {
            survey = senderSurveys[i];

            if(_checkSurvey(survey, filter)) {
                array[count++] = survey;
            }
        }

        if(count == length) {
            return array;
        }

        Survey[] memory result = new Survey[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = array[i];
        }
        return result;
    }

    // ### Participants ###

    function getParticipantsLength(uint256 surveyId) external view virtual override returns (uint256) {
        SurveyData memory surveyData = _surveyData[surveyId];
        require(surveyData.owner != address(0), "SurveyBase: survey not found");
        return surveyData.participants.length;
    }

    function getParticipants(uint256 surveyId, uint256 cursor, uint256 length) external view virtual override returns (address[] memory) {
        SurveyData memory surveyData = _surveyData[surveyId];
        require(surveyData.owner != address(0), "SurveyBase: survey not found");

        address[] memory accounts = surveyData.participants;
        require(cursor < accounts.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= accounts.length, "SurveyBase: invalid length from current position");
        require(length <= participantMaxPerRequest, "SurveyBase: oversized length of survey participants");

        address[] memory array = new address[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = accounts[i];
        }
        return array;
    }

    function isParticipant(uint256 surveyId, address account) external view virtual override returns (bool) {
       return _findParticipation(account, surveyId).surveyId != 0;
    }

    // ### Participations ###

    function getParticipations(uint256 surveyId, uint256 cursor, uint256 length) external view virtual override returns (Participation[] memory) {
        SurveyData memory surveyData = _surveyData[surveyId];
        require(surveyData.owner != address(0), "SurveyBase: survey not found");

        address[] memory accounts = surveyData.participants;
        require(cursor < accounts.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= accounts.length, "SurveyBase: invalid length from current position");
        require(length <= participationMaxPerRequest, "SurveyBase: oversized length of survey participations");

        Participation[] memory array = new Participation[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = _findParticipation(accounts[i], surveyId);
        }
        return array;
    }

    function findParticipation(uint256 surveyId, address account) external view virtual override returns (Participation memory) {
       return _findParticipation(account, surveyId);
    }

    // ### Own Participations ###

    function getOwnParticipationsLength() external view virtual override returns (uint256) {
        return _participations[_msgSender()].length;
    }

    function getOwnParticipations(uint256 cursor, uint256 length) external view virtual override returns (Participation[] memory) {
        Participation[] memory senderParticipations = _participations[_msgSender()];
        require(cursor < senderParticipations.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= senderParticipations.length, "SurveyBase: invalid length from current position");
        require(length <= participationMaxPerRequest, "SurveyBase: oversized length of participations");

        Participation[] memory array = new Participation[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = senderParticipations[i];
        }
        return array;
    }

    function findOwnParticipation(uint256 surveyId) external view virtual override returns (Participation memory) {
       return _findParticipation(_msgSender(), surveyId);
    }

    // ### Questions ###

    function getQuestionsLength(uint256 surveyId) external view virtual override returns (uint256) {
        return _questions[surveyId].length;
    }

    function getQuestions(uint256 surveyId, uint256 cursor, uint256 length) external view virtual override returns (Question[] memory) {
        Question[] memory questions = _questions[surveyId];
        require(cursor < questions.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= questions.length, "SurveyBase: invalid length from current position");
        require(length <= questionMaxPerRequest, "SurveyBase: oversized length of questions");

        Question[] memory array = new Question[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = questions[i];
        }
        return array;
    }

    // ### Responses ###

    function getResponses(uint256 surveyId, uint256 questionIndex, uint256 cursor, uint256 length) external view virtual override returns (string[] memory) {
        SurveyData memory surveyData = _surveyData[surveyId];
        require(surveyData.owner != address(0), "SurveyBase: survey not found");

        address[] memory accounts = surveyData.participants;
        require(cursor < accounts.length, "SurveyBase: cursor out of range");
        require(length > 0 && cursor+length <= accounts.length, "SurveyBase: invalid length from current position");
        require(length <= responseMaxPerRequest, "SurveyBase: oversized length of survey participations");

        string[] memory array = new string[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            string[] memory accountResponses = _findParticipation(accounts[i], surveyId).responses;
            require(questionIndex < accountResponses.length, "SurveyBase: index out of range");
            array[i-cursor] = accountResponses[questionIndex];
        }
        return array;
    }

    // ### Validators ###

    function getValidators(uint256 surveyId, uint256 questionIndex) external view virtual override returns (Validator[] memory) {
       return _validators[surveyId][questionIndex];
    }

    // ### Internal functions ###

    function _findSurvey(uint256 surveyId) internal view returns (Survey memory) {
        address account = _surveyData[surveyId].owner;
        Survey[] memory surveys = _surveys[account];
        Survey memory result;

        for(uint i = 0; i < surveys.length; i++) {
            Survey memory survey = surveys[i];
            if(survey.id == surveyId) {
                result = survey;
                break;
            }
        }

        return result;
    }
    
    function _findParticipation(address account, uint256 surveyId) internal view returns (Participation memory) {
        Participation[] memory participations = _participations[account];
        Participation memory result;

        for(uint i = 0; i < participations.length; i++) {
            Participation memory participation = participations[i];
            if(participation.surveyId == surveyId) {
                result = participation;
                break;
            }
        }

        return result;
    }

    function _checkSurvey(Survey memory survey, SurveyFilter memory filter) internal view returns (bool) {
        return (
                (filter.search.toSlice().empty() || survey.title.containsIgnoreCase(filter.search) || survey.description.containsIgnoreCase(filter.search)) &&
                (!filter.onlyPublic || !_surveyData[survey.id].keyRequired) &&
                (!filter.withRmngBudget || _surveyData[survey.id].remainingBudget >= survey.reward) &&
                (filter.minStartTime == 0 || survey.startTime >= filter.minStartTime) &&
                (filter.maxStartTime == 0 || survey.startTime <= filter.maxStartTime) &&
                (filter.minEndTime == 0 || survey.endTime >= filter.minEndTime) &&
                (filter.maxEndTime == 0 || survey.endTime <= filter.maxEndTime) &&
                (filter.minBudget == 0 || survey.budget >= filter.minBudget) &&
                (filter.minReward == 0 || survey.reward >= filter.minReward) &&
                (filter.minGasReserve == 0 || _surveyData[survey.id].gasReserve >= filter.minGasReserve)
            );
    }
}
