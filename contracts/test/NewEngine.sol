// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../survey/interfaces/ISurveyStorage.sol";

contract NewEngine {

    IERC20 public tokenCnt;
    IWETH public currencyCnt;
    ISurveyStorage public surveyCnt;

    constructor(address _token, address _currency, address _survey) {
        require(_token != address(0), "SurveyEngine: invalid token address");
        require(_currency != address(0), "SurveyEngine: invalid wrapped currency address");
        require(_survey != address(0), "SurveyEngine: invalid survey address");

        tokenCnt = IERC20(_token);
        currencyCnt = IWETH(_currency);
        surveyCnt = ISurveyStorage(_survey);
    }

    receive() external payable {
    }
}
