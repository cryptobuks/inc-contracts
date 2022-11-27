// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/ISurveyStorage.sol";
import "./interfaces/ISurveyImpl.sol";
import "./interfaces/ISurveyConfig.sol";
import "./interfaces/ISurveyFactory.sol";
import "../abstractions/Manageable.sol";

contract SurveyStorage is ISurveyStorage, Manageable {

    uint256 public override totalGasReserve;// total gas reserve for all surveys
    ISurveyConfig internal configCnt;
    
    address[] internal _surveys;
    uint256[] internal _txGasSamples;// samples to calculate the average meta-transaction gas

    mapping(address => bool) internal _surveyFlags;// survey address => flag
    mapping(address => address[]) internal _ownSurveys;// account => survey addresses
    mapping(address => address[]) internal _ownParticipations;// account => survey addresses

    constructor(address _config) {
        require(_config != address(0), "SurveyStorage: invalid config address");
        configCnt = ISurveyConfig(_config);
    }

    function surveyConfig() external view virtual override returns (address) {
        return address(configCnt);
    }

    function txGasSamples(uint256 maxLength) external view override returns (uint256[] memory) {
        require(maxLength <= configCnt.txGasMaxPerRequest(), "SurveyStorage: oversized length of tx gas samples");
        uint256 length = (maxLength <= _txGasSamples.length)? maxLength: _txGasSamples.length;
        uint256[] memory array = new uint256[](length);
        uint256 cursor = _txGasSamples.length - length;

        for(uint i = cursor; i < _txGasSamples.length; i++) {
            array[i-cursor] = _txGasSamples[i];
        }

        return array;
    }

    function remainingBudgetOf(address surveyAddr) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).remainingBudget();
    }

    function remainingGasReserveOf(address surveyAddr) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).remainingGasReserve();
    }

    function amountsOf(address surveyAddr) external view override returns (uint256, uint256, uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).amounts();
    }

    // ### Surveys ###

    function exists(address surveyAddr) external view override returns (bool) {
        require(surveyAddr != address(0), "SurveyStorage: invalid survey address");
        return _surveyFlags[surveyAddr];
    }

    function getSurveysLength() external view override returns (uint256) {
        return _surveys.length;
    }

    function getAddresses(uint256 cursor, uint256 length) external view override returns (address[] memory) {
        require(cursor < _surveys.length, "SurveyStorage: cursor out of range");
        require(length > 0 && cursor+length <= _surveys.length, "SurveyStorage: invalid length from current position");
        require(length <= configCnt.surveyMaxPerRequest(), "SurveyStorage: oversized length of surveys");

        address[] memory array = new address[](length);

        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = _surveys[i];
        }

        return array;
    }

    function getSurveys(uint256 cursor, uint256 length) external view override returns (Survey[] memory) {
        require(cursor < _surveys.length, "SurveyStorage: cursor out of range");
        require(length > 0 && cursor+length <= _surveys.length, "SurveyStorage: invalid length from current position");
        require(length <= configCnt.surveyMaxPerRequest(), "SurveyStorage: oversized length of surveys");

        Survey[] memory array = new Survey[](length);

        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = ISurveyImpl(_surveys[i]).data();
        }

        return array;
    }

    function findSurvey(address surveyAddr) external view override returns (Survey memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).data();
    }

    function isOpenedSurvey(address surveyAddr, uint256 offset) external view override returns (bool) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).isOpened(offset);
    }

    // ### Own Surveys ###

    function getOwnSurveysLength() external view override returns (uint256) {
        return _ownSurveys[_msgSender()].length;
    }

    function getOwnSurveys(uint256 cursor, uint256 length) external view override returns (Survey[] memory) {
        address[] memory senderSurveys = _ownSurveys[_msgSender()];
        require(cursor < senderSurveys.length, "SurveyStorage: cursor out of range");
        require(length > 0 && cursor+length <= senderSurveys.length, "SurveyStorage: invalid length from current position");
        require(length <= configCnt.surveyMaxPerRequest(), "SurveyStorage: oversized length of surveys");

        Survey[] memory array = new Survey[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = ISurveyImpl(senderSurveys[i]).data();
        }
        return array;
    }

    // ### Questions ###

    function getQuestionsLength(address surveyAddr) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getQuestionsLength();
    }

    function getQuestions(address surveyAddr, uint256 cursor, uint256 length) external view override returns (Question[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getQuestions(cursor, length);
    }

    // ### Validators ###

    function getValidatorsLength(address surveyAddr, uint256 questionIndex) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getValidatorsLength(questionIndex);
    }

    function getValidators(address surveyAddr, uint256 questionIndex) external view override returns (Validator[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getValidators(questionIndex);
    }

    // ### Participants ###

    function getParticipantsLength(address surveyAddr) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getParticipantsLength();
    }

    function getParticipants(address surveyAddr, uint256 cursor, uint256 length) external view override returns (address[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getParticipants(cursor, length);
    }

    function isParticipant(address surveyAddr, address account) external view override returns (bool) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).isParticipant(account);
    }

    // ### Participations ###

    function getParticipations(address surveyAddr, uint256 cursor, uint256 length) external view override returns (Participation[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getParticipations(cursor, length);
    }

    function findParticipation(address surveyAddr, address account) external view override returns (Participation memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).findParticipation(account);
    }

    // ### Own Participations ###

    function getOwnParticipationsLength() external view override returns (uint256) {
        return _ownParticipations[_msgSender()].length;
    }

    function getOwnParticipations(uint256 cursor, uint256 length) external view override returns (Participation[] memory) {
        address[] memory senderParticipations = _ownParticipations[_msgSender()];
        require(cursor < senderParticipations.length, "SurveyStorage: cursor out of range");
        require(length > 0 && cursor+length <= senderParticipations.length, "SurveyStorage: invalid length from current position");
        require(length <= configCnt.participationMaxPerRequest(), "SurveyStorage: oversized length of participations");

        Participation[] memory array = new Participation[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = ISurveyImpl(senderParticipations[i]).findParticipation(_msgSender());
        }
        return array;
    }

    function findOwnParticipation(address surveyAddr) external view override returns (Participation memory) {
        verify(surveyAddr);
       return ISurveyImpl(surveyAddr).findParticipation(_msgSender());
    }

    // ### Responses ###

    function getResponses(address surveyAddr, uint256 questionIndex, uint256 cursor, uint256 length) external view override returns (string[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getResponses(questionIndex, cursor, length);
    }

    function getResponseCounts(address surveyAddr, uint256 questionIndex) external view override returns (ResponseCount[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getResponseCounts(questionIndex);
    }

    // ### Manager functions ###

    function addSurvey(SurveyWrapper calldata wrapper) external override onlyManager returns (address) {
        address surveyAddr = ISurveyFactory(configCnt.surveyFactory()).createSurvey(wrapper, address(configCnt));
        _surveys.push(surveyAddr);
        _surveyFlags[surveyAddr] = true;
        _ownSurveys[wrapper.account].push(surveyAddr);
        totalGasReserve += wrapper.gasReserve;
        return surveyAddr;
    }

    function addParticipation(Participation calldata participation, string calldata key) external override onlyManager {
        ISurveyImpl(participation.surveyAddr).addParticipation(participation, key);
        _ownParticipations[participation.account].push(participation.surveyAddr);

        if(participation.txGas > 0) {
            uint256 txPrice = tx.gasprice * participation.txGas;
            totalGasReserve -= txPrice;
            // Save sample to calculate the following costs
            _txGasSamples.push(participation.txGas);
        }
    }

    function solveSurvey(address surveyAddr) external override onlyManager {
        uint256 gasReserve = ISurveyImpl(surveyAddr).solveSurvey();
        totalGasReserve -= gasReserve;
    }

    function increaseGasReserve(address surveyAddr, uint256 amount) external override onlyManager {
        ISurveyImpl(surveyAddr).increaseGasReserve(amount);
        totalGasReserve += amount;
    }

    // ### Internal functions ###

    function verify(address surveyAddr) internal view  {
        require(_surveyFlags[surveyAddr], "SurveyStorage: survey not found");
    }
}