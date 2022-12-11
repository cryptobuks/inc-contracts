// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts//security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../abstractions/Forwardable.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IWETH.sol";
import "./interfaces/ISurveyConfig.sol";
import "./interfaces/ISurveyStorage.sol";
import "./interfaces/ISurveyFactory.sol";
import "./interfaces/ISurveyValidator.sol";
import "./interfaces/ISurveyEngine.sol";
import "./interfaces/ISurveyImpl.sol";

contract SurveyEngine is ISurveyEngine, Forwardable, ReentrancyGuard {

    IWETH internal currencyCnt;// Wrapped native currency
    ISurveyConfig internal configCnt;
    ISurveyStorage internal storageCnt;

    constructor(address _currency, address _config, address _storage, address forwarder) Forwardable(forwarder) {
        require(_currency != address(0), "SurveyEngine: invalid wrapped currency address");
        require(_config != address(0), "SurveyEngine: invalid config address");
        require(_storage != address(0), "SurveyEngine: invalid storage address");

        currencyCnt = IWETH(_currency);
        configCnt = ISurveyConfig(_config);
        storageCnt = ISurveyStorage(_storage);
    }

    receive() external payable {
        require(_msgSender() == address(currencyCnt), 'Not WETH9');
    }

    function currency() external view virtual override returns (address) {
        return address(currencyCnt);
    }

    function surveyConfig() external view virtual override returns (address) {
        return address(configCnt);
    }

    function surveyStorage() external view virtual override returns (address) {
        return address(storageCnt);
    }

    function addSurvey(SurveyRequest memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) 
    external payable override nonReentrant {
        require(survey.token != address(0), "SurveyEngine: invalid token address");

        uint256 balance = IERC20(survey.token).balanceOf(_msgSender());
        require(balance >= survey.budget, "SurveyEngine: balance is less than the budget");

        uint256 allowance = IERC20(survey.token).allowance(_msgSender(), address(this));
        require(allowance >= survey.budget, "SurveyEngine: allowance is less than the budget");

        ISurveyValidator(configCnt.surveyValidator()).checkSurvey(survey, questions, validators, hashes);

        uint256 partsNum = survey.budget / survey.reward;
        uint256 totalFee = partsNum * configCnt.fee();
        require(msg.value >= totalFee, "SurveyEngine: wei amount is less than the fee");

        uint256 gasReserve = msg.value - totalFee;
        SurveyWrapper memory wrapper;
        wrapper.account = _msgSender();
        wrapper.survey = survey;
        wrapper.questions = questions;
        wrapper.validators = validators;
        wrapper.hashes = hashes;
        wrapper.gasReserve = gasReserve;
        
        address surveyAddr = ISurveyFactory(configCnt.surveyFactory()).createSurvey(wrapper, address(configCnt), address(storageCnt));
        storageCnt.saveSurvey(_msgSender(), surveyAddr, gasReserve);

        // Transfer tokens to this contract
        TransferHelper.safeTransferFrom(survey.token, _msgSender(), address(this), survey.budget);

        // Transfer fee to `feeTo`
        payable(configCnt.feeTo()).transfer(totalFee);

        // Transfer reserve to `forwarder custody address` to pay for participations
        // Transfer is done at WETH to facilitate returns
        currencyCnt.deposit{value: gasReserve}(); 
        currencyCnt.transfer(forwarderCnt.custody(), gasReserve);

        emit OnSurveyAdded(_msgSender(), surveyAddr);
    }

    function solveSurvey(address surveyAddr) external override nonReentrant {
        require(storageCnt.exists(surveyAddr), "SurveyEngine: survey not found");

        ISurveyImpl surveyImpl = ISurveyImpl(surveyAddr);
        Survey memory survey = surveyImpl.data();
        require(_msgSender() == survey.surveyOwner, "SurveyEngine: you are not the survey owner");

        uint256 remainingBudget = surveyImpl.remainingBudget();
        uint256 remainingGasReserve = surveyImpl.remainingGasReserve();
        require(remainingBudget > 0 || remainingGasReserve > 0, "SurveyEngine: survey already solved");

        storageCnt.solveSurvey(surveyAddr);

        if(remainingBudget > 0) {
            // Transfer the remaining budget to the survey owner
            TransferHelper.safeTransfer(survey.token, _msgSender(), remainingBudget);
        }

        if(remainingGasReserve > 0) {
            // Transfer the remaining gas reserve to the survey owner
            currencyCnt.transferFrom(forwarderCnt.custody(), address(this), remainingGasReserve);
            currencyCnt.withdraw(remainingGasReserve);
            TransferHelper.safeTransferETH(_msgSender(), remainingGasReserve);
        }

        emit OnSurveySolved(_msgSender(), surveyAddr, remainingBudget, remainingGasReserve);
    }

    function increaseGasReserve(address surveyAddr) external payable override nonReentrant {
        require(storageCnt.exists(surveyAddr), "SurveyEngine: survey not found");
        require(msg.value > 0, "SurveyEngine: Wei amount is zero");

        ISurveyImpl surveyImpl = ISurveyImpl(surveyAddr);
        Survey memory survey = surveyImpl.data();
        require(_msgSender() == survey.surveyOwner, "SurveyEngine: you are not the survey owner");

        uint256 remainingBudget = surveyImpl.remainingBudget();
        uint256 remainingGasReserve = surveyImpl.remainingGasReserve();
        require(remainingBudget > 0, "SurveyEngine: survey without budget");
        require(block.timestamp < survey.endTime, "SurveyEngine: survey closed");

        storageCnt.increaseGasReserve(surveyAddr, msg.value);

        // Transfer reserve to `forwarder custody address` as WETH
        currencyCnt.deposit{value: msg.value}(); 
        currencyCnt.transfer(forwarderCnt.custody(), msg.value);

        emit OnGasReserveIncreased(_msgSender(), surveyAddr, msg.value, remainingGasReserve + msg.value);
    }

    function addParticipation(address surveyAddr, string[] memory responses, string memory key) external override nonReentrant {
        _addParticipation(_msgSender(), surveyAddr, responses, key, 0);
    }

    function addParticipationFromForwarder(address surveyAddr, string[] memory responses, string memory key, uint256 txGas) 
    external override onlyTrustedForwarder nonReentrant {
        _addParticipation(_fwdSender(), surveyAddr, responses, key, txGas);
    }

    // ### Internal functions ###

    function _addParticipation(address account, address surveyAddr, string[] memory responses, string memory key, uint256 txGas) internal {
        require(account != address(0), "SurveyEngine: invalid account");
        require(storageCnt.exists(surveyAddr), "SurveyEngine: survey not found");

        ISurveyImpl surveyImpl = ISurveyImpl(surveyAddr);
        Survey memory survey = surveyImpl.data();
        require(block.timestamp >= survey.startTime, "SurveyEngine: survey not yet open");
        require(block.timestamp <= survey.endTime, "SurveyEngine: survey closed");

        uint256 remainingBudget = surveyImpl.remainingBudget();
        require(remainingBudget >= survey.reward, "SurveyEngine: survey without sufficient budget");

        uint256 remainingGasReserve = surveyImpl.remainingGasReserve();
        uint256 txPrice = tx.gasprice * txGas;
        require(remainingGasReserve >= txPrice, "SurveyEngine: survey without sufficient gas reserve");

        bool alreadyParticipated = surveyImpl.isParticipant(account);
        require(!alreadyParticipated, "SurveyEngine: has already participated");

        Participation memory participation;
        participation.surveyAddr = surveyAddr;
        participation.surveyOwner = survey.surveyOwner;
        participation.token = survey.token;
        participation.responses = responses;
        participation.reward = survey.reward;
        participation.txGas = txGas;
        participation.gasPrice = tx.gasprice;
        participation.partTime = block.timestamp;
        participation.partOwner = account;

        storageCnt.addParticipation(participation, key);

        // Transfer tokens from this contract to participant
        TransferHelper.safeTransfer(survey.token, account, survey.reward);
        
        emit OnParticipationAdded(account, surveyAddr, txGas);
    }
}