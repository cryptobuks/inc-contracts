// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts//security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISurveyValidator.sol";
import {StringUtils} from "../libraries/StringUtils.sol";
import {IntUtils} from "../libraries/IntUtils.sol";

contract SurveyValidator is ISurveyValidator, Ownable, ReentrancyGuard {

    using StringUtils for *;
    using IntUtils for *;

    uint256 public tknSymbolMaxLength = 64;
    uint256 public tknNameMaxLength = 128;
    uint256 public titleMaxLength = 128;
    uint256 public descriptionMaxLength = 512;
    uint256 public urlMaxLength = 2048;
    uint256 public startMaxTime = 2629743;// maximum time to start the survey
    uint256 public rangeMinTime = 86400;// minimum duration time
    uint256 public rangeMaxTime = 31536000;// maximum duration time
    uint256 public questionMaxPerSurvey = 100;
    uint256 public questionMaxLength = 4096;
    uint256 public validatorMaxPerQuestion = 10;
    uint256 public validatorValueMaxLength = 128;
    uint256 public hashMaxPerSurvey = 1000;
    uint256 public responseMaxLength = 2048;

    // ### Validation functions ###

    function checkSurvey(SurveyRequest memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) 
    external override nonReentrant {
        // Validate token metadata
        try IERC20Metadata(survey.token).symbol() returns (string memory symbol) {
            uint256 symbolLength = symbol.toSlice().len();
            require(symbolLength == symbol.trim().toSlice().len(), "SurveyValidator: token symbol with leading or trailing spaces");
            require(symbolLength > 0, "SurveyValidator: empty token symbol");
            require(symbolLength <= tknSymbolMaxLength, "SurveyValidator: invalid token symbol");
        } catch {
            revert("SurveyValidator: no token symbol");
        }

        try IERC20Metadata(survey.token).name() returns (string memory name) {
            uint256 nameLength = name.toSlice().len();
            require(nameLength == name.trim().toSlice().len(), "SurveyValidator: token name with leading or trailing spaces");
            require(nameLength > 0, "SurveyValidator: empty token name");
            require(nameLength <= tknNameMaxLength, "SurveyValidator: invalid token name");
        } catch {
            revert("SurveyValidator: no token name");
        }
        
        // Validate title
        uint256 titleLength = survey.title.toSlice().len();
        require(titleLength == survey.title.trim().toSlice().len(), "SurveyValidator: title with leading or trailing spaces");
        require(titleLength > 0, "SurveyValidator: no survey title");
        require(titleLength <= titleMaxLength, "SurveyValidator: very long survey title");

        // Validate description
        uint256 descLength = survey.description.toSlice().len();
        require(descLength == survey.description.trim().toSlice().len(), "SurveyValidator: description with leading or trailing spaces");
        require(descLength <= descriptionMaxLength, "SurveyValidator: very long survey description");

        // Validate logo URL
        StringUtils.slice memory logoUrlSlice = survey.logoUrl.toSlice();
        uint256 logoUrlLength = logoUrlSlice.len();
        require(logoUrlLength == survey.logoUrl.trim().toSlice().len(), "SurveyValidator: logo URL with leading or trailing spaces");
        require(logoUrlLength <= urlMaxLength, "SurveyValidator: very long survey logo URL");
        if(logoUrlLength > 0) {
            require(logoUrlSlice.startsWith("http://".toSlice()) || logoUrlSlice.startsWith("https://".toSlice()) || logoUrlSlice.startsWith("ipfs://".toSlice()), 
            "SurveyValidator: invalid logo URL");
        }

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
            _checkValidator(questions[validators[i].questionIndex], validators[i]);
        }
    }

    function checkResponse(Question memory question, Validator[] memory validators, string memory response) external view override {
        uint256 responseLength = response.toSlice().len();

        if(responseLength == 0) {
            require(!question.mandatory, "SurveyValidator: mandatory response empty");
			return;
        }

        require(responseLength == response.trim().toSlice().len(), "SurveyValidator: response with leading or trailing spaces");
        require(responseLength <= responseMaxLength, "SurveyValidator: response too long");
        require(_checkResponseType(question.responseType, response), "SurveyValidator: invalid response type");
        
        // Apply validators, there can be multiple values, each value must pass the validators.
        string[] memory values = _parseResponse(question.responseType, response);

        for(uint i = 0; i < values.length; i++) {
            require(values[i].toSlice().len() == values[i].trim().toSlice().len(), "SurveyValidator: value with leading or trailing spaces");
            bool valid = true;

            for(uint j = 0; j < validators.length; j++) {
               if(j == 0) {
                   valid = _checkExpression(validators[j], values[i]);
               } else if(validators[j - 1].operator == Operator.Or) {
                    valid = valid || _checkExpression(validators[j], values[i]);
                } else {// operator == None or And
                    valid = valid && _checkExpression(validators[j], values[i]);
                }
            }

            require(valid, "SurveyValidator: invalid response");
        }
    }

    function isLimited(ResponseType responseType) external pure override returns (bool) {
        return _isLimited(responseType);
    }

    function isArray(ResponseType responseType) external pure override returns (bool) {
        return _isArray(responseType);
    }

    // ### Owner functions ###

    function setTknSymbolMaxLength(uint256 _tknSymbolMaxLength) external override onlyOwner {
        tknSymbolMaxLength = _tknSymbolMaxLength;
    }

    function setTknNameMaxLength(uint256 _tknNameMaxLength) external override onlyOwner {
        tknNameMaxLength = _tknNameMaxLength;
    }

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
        uint256 contentLength = question.content.toSlice().len();
        require(contentLength == question.content.trim().toSlice().len(), "SurveyValidator: question content with leading or trailing spaces");
        require(contentLength > 0, "SurveyValidator: unspecified question content");
        require(contentLength <= questionMaxLength, "SurveyValidator: very long question content");
    }

    function _checkValidator(Question memory question, Validator memory validator) internal view {
        uint256 validatorValueLength = validator.value.toSlice().len();

        if(validator.expression != Expression.Empty && validator.expression != Expression.NotEmpty && 
           validator.expression != Expression.ContainsDigits && validator.expression != Expression.NotContainsDigits) {
                require(validatorValueLength == validator.value.trim().toSlice().len(), "SurveyValidator: validator value with leading or trailing spaces");
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

                if(validator.expression == Expression.MinLength || validator.expression == Expression.MaxLength) {
                    require(validator.value.parseUInt() <= responseMaxLength, "SurveyValidator: validator value exceeds response limit");
                }
                
                if(question.responseType == ResponseType.Bool || question.responseType == ResponseType.ArrayBool) {
                    require(validator.value.toSlice().equals("true".toSlice()) || validator.value.toSlice().equals("false".toSlice()), 
                    "SurveyValidator: validator value must be a boolean");
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

    function _isLimited(ResponseType responseType) internal pure returns (bool) {
        return responseType == ResponseType.Bool || 
        responseType == ResponseType.Percent || 
        responseType == ResponseType.Rating || 
        responseType == ResponseType.OneOption || 
        responseType == ResponseType.ManyOptions || 
        responseType == ResponseType.ArrayBool;
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
            if(!value.isUDigit()) {
                return false;
            }

            return value.parseUInt() <= 100;
        } else if(responseType == ResponseType.ManyOptions) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.OneOption, array[i])) {
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