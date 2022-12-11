// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISurveyConfig.sol";

contract SurveyConfig is ISurveyConfig, Ownable {

    address public override surveyFactory;
    address public override surveyValidator;

    // Storage settings
    uint256 public override surveyMaxPerRequest = 100;
    uint256 public override questionMaxPerRequest = 100;
    uint256 public override responseMaxPerRequest = 100;
    uint256 public override participantMaxPerRequest = 100;
    uint256 public override participationMaxPerRequest = 100;
    uint256 public override txGasMaxPerRequest = 100;

    // Engine settings
    uint256 public override fee = 10000000000000000; // 0.01 per participation during survey creation
    address public override feeTo;

    constructor(address _factory, address _validator) {
        require(_factory != address(0), "SurveyEngine: invalid factory address");
        require(_validator != address(0), "SurveyEngine: invalid validator address");

        surveyFactory = _factory;
        surveyValidator = _validator;
        feeTo = _msgSender();
    }

    // ### Owner functions ###

    function setSurveyFactory(address newFactory) external override onlyOwner {
        address oldFactory = surveyFactory;
        surveyFactory = newFactory;
        emit SurveyFactoryChanged(oldFactory, newFactory);
    }

    function setSurveyValidator(address newValidator) external override onlyOwner {
        address oldValidator = surveyValidator;
        surveyValidator = newValidator;
        emit SurveyValidatorChanged(oldValidator, newValidator);
    }

    function setSurveyMaxPerRequest(uint256 _surveyMaxPerRequest) external override onlyOwner {
        surveyMaxPerRequest = _surveyMaxPerRequest;
    }

    function setQuestionMaxPerRequest(uint256 _questionMaxPerRequest) external override onlyOwner {
        questionMaxPerRequest = _questionMaxPerRequest;
    }

    function setResponseMaxPerRequest(uint256 _responseMaxPerRequest) external override onlyOwner {
        responseMaxPerRequest = _responseMaxPerRequest;
    }

    function setParticipantMaxPerRequest(uint256 _participantMaxPerRequest) external override onlyOwner {
        participantMaxPerRequest = _participantMaxPerRequest;
    }

    function setParticipationMaxPerRequest(uint256 _participationMaxPerRequest) external override onlyOwner {
        participationMaxPerRequest = _participationMaxPerRequest;
    }

    function setTxGasMaxPerRequest(uint256 _txGasMaxPerRequest) external override onlyOwner {
        txGasMaxPerRequest = _txGasMaxPerRequest;
    }

    function setFee(uint256 _fee) external override onlyOwner {
        fee = _fee;
    }

    function setFeeTo(address _feeTo) external override onlyOwner {
        feeTo = _feeTo;
    }
}