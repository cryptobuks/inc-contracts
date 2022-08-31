// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../abstractions/Manageable.sol";
import "./interfaces/ISurveyValidator.sol";
import {StringUtils} from "../libraries/StringUtils.sol";
import {IntUtils} from "../libraries/IntUtils.sol";

contract SurveyValidator is ISurveyValidator, Manageable {

    using StringUtils for *;
    using IntUtils for *;

    uint256 public titleMaxLength = 255;
    uint256 public descriptionMaxLength = 4096;
    uint256 public urlMaxLength = 2048;
    uint256 public startMaxTime = 2629743;// maximum time to start the survey
    uint256 public rangeMinTime = 86400;// minimum duration time
    uint256 public rangeMaxTime = 31536000;// maximum duration time
    uint256 public questionMaxPerSurvey = 100;
    uint256 public questionMaxLength = 4096;
    uint256 public validatorMaxPerQuestion = 10;
    uint256 public validatorValueMaxLength = 255;
    uint256 public hashMaxPerSurvey = 10000;
    uint256 public responseMaxLength = 4096;

    // ### Validation functions ###

    function checkSurvey(Survey memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) external view virtual override {
        // Validate title
        uint256 titleLength = survey.title.toSlice().len();
        require(titleLength > 0, "SurveyValidator: no survey title");
        require(titleLength <= titleMaxLength, "SurveyValidator: very long survey title");

        // Validate description
        require(survey.description.toSlice().len() <= descriptionMaxLength, "SurveyValidator: very long survey description");

        // Validate logo URL
        require(bytes(survey.logoUrl).length <= urlMaxLength, "SurveyValidator: very long survey logo URL");

        // Validate date range
        require(survey.startTime >= block.timestamp && survey.startTime < survey.endTime, "SurveyValidator: invalid date range");
        require(survey.startTime <= block.timestamp + startMaxTime, "SurveyValidator: distant start date");
        require(survey.endTime - survey.startTime >= rangeMinTime, "SurveyValidator: date range too small");
        require(survey.endTime - survey.startTime <= rangeMaxTime, "SurveyValidator: date range too large");

        // Validate budget
        require(survey.budget > 0, "SurveyValidator: budget is zero");

        // Validate reward
        require(survey.reward > 0, "SurveyValidator: reward is zero");
        require(survey.reward <= survey.budget, "SurveyValidator: reward exceeds budget");

        // Validate participations number
        require(survey.budget%survey.reward == 0, "SurveyValidator: incorrect number of participations");
        
        // Validate number of questions
        require(questions.length > 0, "SurveyValidator: no questions");
        require(questions.length <= questionMaxPerSurvey, "SurveyValidator: exceeded number of questions");

        // Check hashes
        uint256 partsNum = survey.budget / survey.reward;
        require(hashes.length == 0 || (hashes.length == partsNum && hashes.length <= hashMaxPerSurvey), "SurveyValidator: incorrect number of hashes");

        for(uint i = 0; i < hashes.length; i++) {
            require(bytes(hashes[i]).length == 8, "SurveyValidator: invalid hash");
        }

        uint256 validatorsTotal = 0;

        // Check questions
        for(uint i = 0; i < questions.length; i++) {
            uint256 count = 0;
            for(uint j = 0; j < validators.length; j++) {
                if(validators[j].questionIndex == i) {
                    count++;
                }
            }

            require(count <= validatorMaxPerQuestion, "SurveyValidator: exceeded number of validators per question");
            _checkQuestion(questions[i]);
            validatorsTotal += count;
        }
        
        // Check validators
        require(validators.length == validatorsTotal, "SurveyValidator: incorrect number of validators");

        for(uint i = 0; i < validators.length; i++) {
            Validator memory validator = validators[i];
            _checkValidator(questions[validator.questionIndex], validator);
        }
    }

    function checkResponse(Question memory question, Validator[] memory validators, string memory response) external view virtual override {
        uint256 responseLength = response.toSlice().len();

        if(responseLength == 0) {
            require(!question.mandatory, "SurveyValidator: mandatory response empty");
			return;
        }

        require(responseLength <= responseMaxLength, "SurveyValidator: response too long");
        require(_checkResponseType(question.responseType, response), "SurveyValidator: invalid response type");
        
        // Apply validators, there can be multiple values, each value must pass the validators.
        string[] memory values = _parseResponse(question.responseType, response);

        for(uint i = 0; i < values.length; i++) {
            string memory value = values[i];
            bool valid = true;

            for(uint j = 0; j < validators.length; j++) {
               Validator memory validator = validators[j];

               if(j == 0) {
                   valid = _checkExpression(validator, value);
               } else if(validators[j - 1].operator == Operator.Or) {
                    valid = valid || _checkExpression(validator, value);
                } else {// operator == None or And
                    valid = valid && _checkExpression(validator, value);
                }
            }

            require(valid, "SurveyValidator: invalid response");
        }
    }

    // ### Manager functions ###

    function checkAuthorization(string[] memory hashes, string memory key) external view override onlyManager returns (uint256) {
        bool authorized = false;
        uint256 hashIndex;

        if(hashes.length > 0) {
            bytes32 hash = keccak256(abi.encodePacked(key));
            string memory hashStr = uint256(hash).toHexString(32);
            uint256 length = hashStr.toSlice().len();
            StringUtils.slice memory result = hashStr.substring(2, 6).toSlice().concat(hashStr.substring(length-4, length).toSlice()).toSlice();

            for(uint i = 0; i < hashes.length; i++) {
                if(hashes[i].toSlice().equals(result)) {
                    authorized = true;
                    hashIndex = i;
                    break;
                }
            }
        }

        require(authorized, "SurveyValidator: participation unauthorized");
        return hashIndex;
    }

    // ### Owner functions ###

    function setTitleMaxLength(uint256 _titleMaxLength) external override onlyOwner {
        titleMaxLength = _titleMaxLength;
    }

    function setDescriptionMaxLength(uint256 _descriptionMaxLength) external override onlyOwner {
        descriptionMaxLength = _descriptionMaxLength;
    }

    function setUrlMaxLength(uint256 _urlMaxLength) external override onlyOwner {
        urlMaxLength = _urlMaxLength;
    }

    function setStartMaxTime(uint256 _startMaxTime) external override onlyOwner {
        startMaxTime = _startMaxTime;
    }

    function setRangeMinTime(uint256 _rangeMinTime) external override onlyOwner {
        rangeMinTime = _rangeMinTime;
    }

    function setRangeMaxTime(uint256 _rangeMaxTime) external override onlyOwner {
        rangeMaxTime = _rangeMaxTime;
    }

    function setQuestionMaxPerSurvey(uint256 _questionMaxPerSurvey) external override onlyOwner {
        questionMaxPerSurvey = _questionMaxPerSurvey;
    }

    function setQuestionMaxLength(uint256 _questionMaxLength) external override onlyOwner {
        questionMaxLength = _questionMaxLength;
    }

    function setValidatorMaxPerQuestion(uint256 _validatorMaxPerQuestion) external override onlyOwner {
        validatorMaxPerQuestion = _validatorMaxPerQuestion;
    }

    function setValidatorValueMaxLength(uint256 _validatorValueMaxLength) external override onlyOwner {
        validatorValueMaxLength = _validatorValueMaxLength;
    }

    function setHashMaxPerSurvey(uint256 _hashMaxPerSurvey) external override onlyOwner {
        hashMaxPerSurvey = _hashMaxPerSurvey;
    }

    function setResponseMaxLength(uint256 _responseMaxLength) external override onlyOwner {
        responseMaxLength = _responseMaxLength;
    }

    // ### Internal functions ###

    function _checkQuestion(Question memory question) internal view {
        uint256 length = question.content.toSlice().len();
        require(length > 0, "SurveyValidator: unspecified question content");
        require(length <= questionMaxLength, "SurveyValidator: very long question content");
    }

    function _checkValidator(Question memory question, Validator memory validator) internal view {
        uint256 validatorValueLength = validator.value.toSlice().len();

        if(validator.expression != Expression.Empty && validator.expression != Expression.NotEmpty && 
           validator.expression != Expression.ContainsDigits && validator.expression != Expression.NotContainsDigits) {
                require(validatorValueLength > 0 && validatorValueLength <= validatorValueMaxLength, "SurveyValidator: invalid validator value");

                if(validator.expression == Expression.Greater || validator.expression == Expression.GreaterEquals || 
                   validator.expression == Expression.Less || validator.expression == Expression.LessEquals || 
                   question.responseType == ResponseType.Number || question.responseType == ResponseType.ArrayNumber || 
                   question.responseType == ResponseType.Range) {
                      require(validator.value.isDigit(), "SurveyValidator: validator value must be an integer");
                }
                
                if(validator.expression == Expression.MinLength || validator.expression == Expression.MaxLength || 
                   question.responseType == ResponseType.Percent || question.responseType == ResponseType.Rating || 
                   question.responseType == ResponseType.Date || question.responseType == ResponseType.DateRange || 
                   question.responseType == ResponseType.ArrayDate) {
                      require(validator.value.isUDigit(), "SurveyValidator: validator value must be a positive integer");
                }
        } else {
            require(validatorValueLength == 0, "SurveyValidator: the validator does not require any value");
        }
    }

    function _parseResponse(ResponseType responseType, string memory response) internal pure returns (string[] memory) {
        string[] memory values;

        if(_isArray(responseType)) {
            values = response.split(";");
        } else {
            values = new string[](1);
            values[0] = response;
        }

        return values;
    }

    function _isArray(ResponseType responseType) internal pure returns (bool) {
        return responseType == ResponseType.ManyOptions || 
        responseType == ResponseType.Range || 
        responseType == ResponseType.DateRange || 
        responseType == ResponseType.ArrayBool || 
        responseType == ResponseType.ArrayText || 
        responseType == ResponseType.ArrayNumber || 
        responseType == ResponseType.ArrayDate;
    }

    function _checkResponseType(ResponseType responseType, string memory value) internal pure returns (bool) {
        if(responseType == ResponseType.Bool) {
            return value.toSlice().equals("true".toSlice()) || value.toSlice().equals("false".toSlice());
        } else if(responseType == ResponseType.Text) {
            return true;
        } else if(responseType == ResponseType.Number) {
            return value.isDigit();
        } else if(responseType == ResponseType.Percent) {
            if(!value.isUDigit()) {
                return false;
            }
			
			uint256 num = value.parseUInt();
            return num > 0 && num <= 100;
        } else if(responseType == ResponseType.Date) {
            return value.isUDigit();
        } else if(responseType == ResponseType.Rating) {
            if(!value.isUDigit()) {
                return false;
            }

            uint256 num = value.parseUInt();
            return num > 0 && num <= 5;
        } else if(responseType == ResponseType.OneOption) {
            return value.isUDigit();
        } else if(responseType == ResponseType.ManyOptions) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!array[i].isUDigit()) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.Range) {
            string[] memory array = value.split(";");
            if(array.length != 2) {
                return false;
            }

            for(uint i = 0; i < array.length; i++) {
                if(!array[i].isDigit()) {
                    return false;
                }

                if(i == 1 && array[i].parseInt() <= array[i-1].parseInt()) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.DateRange) {
            string[] memory array = value.split(";");
            if(array.length != 2) {
                return false;
            }

            for(uint i = 0; i < array.length; i++) {
                if(!array[i].isUDigit()) {
                    return false;
                }

                if(i == 1 && array[i].parseUInt() <= array[i-1].parseUInt()) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.ArrayBool) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.Bool, array[i])) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.ArrayText) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.Text, array[i])) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.ArrayNumber) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.Number, array[i])) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.ArrayDate) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.Date, array[i])) {
                    return false;
                }
            }

            return true;
        }

        revert("Unknown response type.");
    }

    function _checkExpression(Validator memory validator, string memory value) internal pure returns (bool) {
        if(validator.expression == Expression.Empty) {
            return value.toSlice().empty();
        } else if(validator.expression == Expression.NotEmpty) {
            return !value.toSlice().empty();
        } else if(validator.expression == Expression.Equals) {
            return value.toSlice().equals(validator.value.toSlice());
        } else if(validator.expression == Expression.NotEquals) {
            return !value.toSlice().equals(validator.value.toSlice());
        } else if(validator.expression == Expression.Contains) {
            return value.toSlice().contains(validator.value.toSlice());
        } else if(validator.expression == Expression.NotContains) {
            return !value.toSlice().contains(validator.value.toSlice());
        } else if(validator.expression == Expression.EqualsIgnoreCase) {
            return value.equalsIgnoreCase(validator.value);
        } else if(validator.expression == Expression.NotEqualsIgnoreCase) {
            return !value.equalsIgnoreCase(validator.value);
        } else if(validator.expression == Expression.ContainsIgnoreCase) {
            return value.containsIgnoreCase(validator.value);
        } else if(validator.expression == Expression.NotContainsIgnoreCase) {
            return !value.containsIgnoreCase(validator.value);
        } else if(validator.expression == Expression.Greater) {
            return value.parseInt() > validator.value.parseInt();
        } else if(validator.expression == Expression.GreaterEquals) {
            return value.parseInt() >= validator.value.parseInt();
        } else if(validator.expression == Expression.Less) {
            return value.parseInt() < validator.value.parseInt();
        } else if(validator.expression == Expression.LessEquals) {
            return value.parseInt() <= validator.value.parseInt();
        } else if(validator.expression == Expression.ContainsDigits) {
            return value.containsDigits();
        } else if(validator.expression == Expression.NotContainsDigits) {
            return !value.containsDigits();
        } else if(validator.expression == Expression.MinLength) {
            return value.toSlice().len() >= validator.value.parseUInt();
        } else if(validator.expression == Expression.MaxLength) {
            return value.toSlice().len() <= validator.value.parseUInt();
        }

        revert("Unknown expression.");
    }
}
