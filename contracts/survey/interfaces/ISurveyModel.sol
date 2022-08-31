// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @dev Interface containing the survey structure
 */
interface ISurveyModel {

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

    struct Survey {
        uint256 id;
        uint256 entryTime;
        string title;
        string description;
        string logoUrl;
        uint256 startTime;
        uint256 endTime;
        uint256 budget;// Total budget of INC tokens
        uint256 reward;// Reward amount for participation
    }

    struct Participation {
        uint256 surveyId;
        uint256 entryTime;
        string[] responses;
        uint256 txGas;// Only available for financed transactions
        uint256 gasPrice;
    }

    struct SurveyData {
        address owner;
        address[] participants;
        uint256 remainingBudget;
        uint256 gasReserve;// Remaining gas reserve to pay participations
        string[] hashes;// Available participation hashes (not used)
        bool keyRequired;
    }

    struct SurveyFilter {
        string search;// Search in title or description
        bool onlyPublic;// No coupon required
        bool withRmngBudget;// With budget greater than or equal to the reward
        uint256 minStartTime;
        uint256 maxStartTime;
        uint256 minEndTime;
        uint256 maxEndTime;
        uint256 minBudget;
        uint256 minReward;
        uint256 minGasReserve;
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
}
