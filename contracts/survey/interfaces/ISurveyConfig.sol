// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @dev Interface to implement the survey config
 */
 interface ISurveyConfig {

   event SurveyFactoryChanged(address indexed previousFactory, address indexed newFactory);
   event SurveyValidatorChanged(address indexed previousValidator, address indexed newValidator);

   function surveyFactory() external view returns (address);
   function surveyValidator() external view returns (address);

   // Storage settings
   function surveyMaxPerRequest() external view returns (uint256);
   function questionMaxPerRequest() external view returns (uint256);
   function responseMaxPerRequest() external view returns (uint256);
   function participantMaxPerRequest() external view returns (uint256);
   function participationMaxPerRequest() external view returns (uint256);
   function txGasMaxPerRequest() external view returns (uint256);

   // Engine settings
   function fee() external view returns (uint256);
   function feeTo() external view returns (address);

    // ### Owner functions ###

    function setSurveyFactory(address _factory) external;
    function setSurveyValidator(address _validator) external;
    function setSurveyMaxPerRequest(uint256 _surveyMaxPerRequest) external;
    function setQuestionMaxPerRequest(uint256 _questionMaxPerRequest) external;
    function setResponseMaxPerRequest(uint256 _responseMaxPerRequest) external;
    function setParticipantMaxPerRequest(uint256 _participantMaxPerRequest) external;
    function setParticipationMaxPerRequest(uint256 _participationMaxPerRequest) external;
    function setTxGasMaxPerRequest(uint256 _txGasMaxPerRequest) external;
    function setFee(uint256 _fee) external;
    function setFeeTo(address _feeTo) external;
 }