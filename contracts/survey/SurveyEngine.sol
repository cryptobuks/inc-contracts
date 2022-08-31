// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts//security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../abstractions/Forwardable.sol";
import "../interfaces/IWETH.sol";
import "./interfaces/ISurveyStorage.sol";
import "./interfaces/ISurveyValidator.sol";
import "./interfaces/ISurveyEngine.sol";

contract SurveyEngine is ISurveyEngine, Forwardable, ReentrancyGuard {

    IERC20 public override tokenCnt;// INC token
    IWETH public override currencyCnt;// Wrapped native currency
    ISurveyStorage public override surveyCnt;
    ISurveyValidator public override validatorCnt;

    uint256 public fee = 1000000000000000; // 0.001 per participation during survey creation
    address public feeTo;

    event OnSurveyAdded(
        address indexed owner,
        uint256 surveyId
    );

    event OnSurveySolved(
        address indexed owner,
        uint256 surveyId,
        uint256 budgetRefund,
        uint256 gasRefund
    );

    event OnGasReserveIncreased(
        address indexed owner,
        uint256 surveyId,
        uint256 gasAdded,
        uint256 gasReserve
    );

    event OnParticipationAdded(
        address indexed participant,
        uint256 surveyId,
        uint256 txGas
    );

    constructor(address _token, address _currency, address _survey, address _validator, address forwarder) Forwardable(forwarder) {
        require(_token != address(0), "SurveyEngine: invalid token address");
        require(_currency != address(0), "SurveyEngine: invalid wrapped currency address");
        require(_survey != address(0), "SurveyEngine: invalid survey address");
        require(_validator != address(0), "SurveyEngine: invalid validator address");

        tokenCnt = IERC20(_token);
        currencyCnt = IWETH(_currency);
        surveyCnt = ISurveyStorage(_survey);
        validatorCnt = ISurveyValidator(_validator);

        feeTo = _msgSender();
    }

    receive() external payable {
        require(_msgSender() == address(currencyCnt), 'Not WETH9');
    }

    function addSurvey(Survey memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) 
    external payable override nonReentrant returns (uint256) {
        uint256 balance = tokenCnt.balanceOf(_msgSender());
        require(balance >= survey.budget, "SurveyEngine: balance is less than the budget");

        uint256 allowance = tokenCnt.allowance(_msgSender(), address(this));
        require(allowance >= survey.budget, "SurveyEngine: allowance is less than the budget");

        validatorCnt.checkSurvey(survey, questions, validators, hashes);

        uint256 partsNum = survey.budget / survey.reward;
        uint256 totalFee = partsNum * fee;
        require(msg.value >= totalFee, "SurveyEngine: wei amount is less than the fee");

        uint256 gasReserve = msg.value - totalFee;
        uint256 surveyId = surveyCnt.saveSurvey(_msgSender(), survey, questions, validators, hashes, gasReserve);

        // Transfer tokens to this contract
        tokenCnt.transferFrom(_msgSender(), address(this), survey.budget);

        // Transfer fee to `feeTo`
        payable(feeTo).transfer(totalFee);

        // Transfer reserve to `forwarder custody address` to pay for participations
        // Transfer is done at WETH to facilitate returns
        currencyCnt.deposit{value: gasReserve}(); 
        currencyCnt.transfer(forwarderCnt.custody(), gasReserve);

        emit OnSurveyAdded(_msgSender(), surveyId);

        return surveyId;
    }

    function solveSurvey(uint256 surveyId) external override nonReentrant returns (bool) {
        SurveyData memory surveyData = surveyCnt.findSurveyData(surveyId);
        require(_msgSender() == surveyData.owner, "SurveyEngine: you are not the survey owner");
        require(surveyData.remainingBudget > 0 || surveyData.gasReserve > 0, "SurveyEngine: survey already solved");

        surveyCnt.solveSurvey(surveyId);

        if(surveyData.remainingBudget > 0) {
            // Transfer the remaining budget to the survey owner
            tokenCnt.transfer(_msgSender(), surveyData.remainingBudget);
        }

        if(surveyData.gasReserve > 0) {
            // Transfer the remaining gas reserve to the survey owner
            currencyCnt.transferFrom(forwarderCnt.custody(), address(this), surveyData.gasReserve);
            currencyCnt.withdraw(surveyData.gasReserve);
            payable(_msgSender()).transfer(surveyData.gasReserve);
        }

        emit OnSurveySolved(_msgSender(), surveyId, surveyData.remainingBudget, surveyData.gasReserve);
        
        return true;
    }

    function increaseGasReserve(uint256 surveyId) external payable override nonReentrant returns (bool) {
        require(msg.value > 0, "SurveyEngine: Wei amount is zero");

        SurveyData memory surveyData = surveyCnt.findSurveyData(surveyId);
        require(_msgSender() == surveyData.owner, "SurveyEngine: you are not the survey owner");
        require(surveyData.remainingBudget > 0, "SurveyEngine: survey without budget");

        Survey memory survey = surveyCnt.findSurvey(surveyId);
        require(block.timestamp < survey.endTime, "SurveyEngine: survey closed");

        surveyCnt.increaseGasReserve(surveyId, msg.value);

        // Transfer reserve to `forwarder custody address` as WETH
        currencyCnt.deposit{value: msg.value}(); 
        currencyCnt.transfer(forwarderCnt.custody(), msg.value);

        emit OnGasReserveIncreased(_msgSender(), surveyId, msg.value, surveyData.gasReserve + msg.value);
        
        return true;
    }

    function addParticipation(uint256 surveyId, string[] memory responses, string memory key) external override nonReentrant {
        _addParticipation(_msgSender(), surveyId, responses, key, 0);
    }

    function addParticipationFromForwarder(uint256 surveyId, string[] memory responses, string memory key, uint256 txGas) 
    external override onlyTrustedForwarder nonReentrant {
        _addParticipation(_fwdSender(), surveyId, responses, key, txGas);
    }

    // ### Owner functions ###

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function setValidator(address _validator) external onlyOwner {
        validatorCnt = ISurveyValidator(_validator);
    }

    function migrate(address _newEngine) external onlyOwner {
        require(_newEngine != address(0), "SurveyEngine: invalid engine address");

        ISurveyEngine newEngineCnt = ISurveyEngine(_newEngine);
        require(address(newEngineCnt.tokenCnt()) == address(tokenCnt), "SurveyEngine: invalid engine token");
        require(address(newEngineCnt.currencyCnt()) == address(currencyCnt), "SurveyEngine: invalid engine currency");
        require(address(newEngineCnt.surveyCnt()) == address(surveyCnt), "SurveyEngine: invalid engine storage");
        
        // Transfer escrow tokens to the new engine
        uint256 balance = tokenCnt.balanceOf(address(this));
        tokenCnt.transfer(_newEngine, balance);
        
        // Destroy this contract
        selfdestruct(payable(_newEngine));
    }

    // ### Internal functions ###

    function _addParticipation(address account, uint256 surveyId, string[] memory responses, string memory key, uint256 txGas) internal {
        require(account != address(0), "SurveyEngine: invalid address");
        
        Survey memory survey = surveyCnt.findSurvey(surveyId);
        require(survey.id != 0, "SurveyEngine: survey not found");
        require(block.timestamp >= survey.startTime, "SurveyEngine: survey not yet open");
        require(block.timestamp <= survey.endTime, "SurveyEngine: survey closed");

        SurveyData memory surveyData = surveyCnt.findSurveyData(surveyId);
        require(surveyData.remainingBudget >= survey.reward, "SurveyEngine: survey without sufficient budget");

        uint256 txPrice = tx.gasprice * txGas;
        require(surveyData.gasReserve >= txPrice, "SurveyEngine: survey without sufficient gas reserve");

        bool alreadyParticipated = surveyCnt.isParticipant(surveyId, account);
        require(!alreadyParticipated, "SurveyEngine: has already participated");

        uint256 hashIndex;

        if(surveyData.keyRequired) {
            string[] memory hashes = surveyCnt.getAllHashes(surveyId);
            hashIndex = validatorCnt.checkAuthorization(hashes, key);
        }

        Question[] memory questions = surveyCnt.getAllQuestions(surveyId);

        for(uint i = 0; i < questions.length; i++) {
            Validator[] memory validators = surveyCnt.getValidators(surveyId, i);
            validatorCnt.checkResponse(questions[i], validators, responses[i]);
        }

        surveyCnt.saveParticipation(account, surveyId, responses, survey.reward, txGas, hashIndex);

        // Transfer tokens from this contract to participant
        tokenCnt.transfer(account, survey.reward);
        
        emit OnParticipationAdded(account, surveyId, txGas);
    }
}
