// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @dev Interface containing the survey structure
 */
interface ISurveyModel {

    // ArrayText elements should not contain the separator (;)
    enum ResponseType {
        Bool, Text, Number, Percent, Date, Rating, OneOption, 
        ManyOptions, Range, DateRange,
        ArrayBool, ArrayText, ArrayNumber, ArrayDate
    }

    struct Question {
        string content;// json that represents the content of the question
        bool mandatory;
        ResponseType responseType;
    }

    struct SurveyRequest {
        string title;
        string description;
        string logoUrl;
        uint256 startTime;
        uint256 endTime;
        uint256 budget;// Total budget of INC tokens
        uint256 reward;// Reward amount for participation
        address token;// Incentive token
    }

    struct SurveyWrapper {
        address account;
        SurveyRequest survey;
        Question[] questions;
        Validator[] validators;
        string[] hashes;
        uint256 gasReserve;
    }

    struct Survey {
        string title;
        string description;
        string logoUrl;
        uint256 startTime;
        uint256 endTime;
        uint256 budget;
        uint256 reward;
        address token;
        bool keyRequired;
        uint256 surveyTime;
        address surveyOwner;
        address surveyAddr;
    }

    struct Participation {
        address surveyAddr;
        string[] responses;
        uint256 txGas;
        uint256 gasPrice;
        uint256 partTime;
        address partOwner;
    }

    enum Operator {
        None, And, Or
    }

    enum Expression {
        None,
        Empty,
        NotEmpty,
        Equals,
        NotEquals,
        Contains,
        NotContains,
        EqualsIgnoreCase,
        NotEqualsIgnoreCase,
        ContainsIgnoreCase,
        NotContainsIgnoreCase,
        Greater,
        GreaterEquals,
        Less,
        LessEquals,
        ContainsDigits,
        NotContainsDigits,
        MinLength,
        MaxLength
    }

    struct Validator {
        uint256 questionIndex;
        Operator operator;
        Expression expression;
        string value;
    }

    struct ResponseCount {
        string value;
        uint256 count;
    }
}