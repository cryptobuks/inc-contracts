// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../abstractions/Manageable.sol";
import "./interfaces/ISurveyFactory.sol";
import "./SurveyImpl.sol";

contract SurveyFactory is ISurveyFactory, Manageable {

    // ### Manager functions `engine` ###

    function createSurvey(SurveyWrapper calldata wrapper, address configAddr, address storageAddr) external override onlyManager returns (address) {
        Survey memory data;
        data.title = wrapper.survey.title;
        data.description = wrapper.survey.description;
        data.logoUrl = wrapper.survey.logoUrl;
        data.startTime = wrapper.survey.startTime;
        data.endTime = wrapper.survey.endTime;
        data.budget = wrapper.survey.budget;
        data.reward = wrapper.survey.reward;
        data.token = wrapper.survey.token;
        data.surveyTime = block.timestamp;
        data.surveyOwner = wrapper.account;
        data.keyRequired = wrapper.hashes.length > 0;
        
        SurveyImpl impl = new SurveyImpl(configAddr);
        data.surveyAddr = address(impl);

        impl.initialize(data, wrapper.questions, wrapper.validators, wrapper.hashes, wrapper.gasReserve);
        impl.setManager(storageAddr);

        return data.surveyAddr;
    }
}