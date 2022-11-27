const INCToken = artifacts.require('INCToken');
const SurveyValidator = artifacts.require('SurveyValidator');
const SurveyConfig = artifacts.require('SurveyConfig');
const SurveyStorage = artifacts.require('SurveyStorage');
const SurveyFactory = artifacts.require('SurveyFactory');
const SurveyEngine = artifacts.require('SurveyEngine');
const INCForwarder = artifacts.require('INCForwarder');
const WETH = artifacts.require('WETH');
const TokenOffer = artifacts.require('TokenOffer');
const TimelockController = artifacts.require('TimelockController');
const INCGovernor = artifacts.require('INCGovernor');
const TokenLock = artifacts.require('TokenLock');
const { BN, ONE_TOKEN, MONTH_SECONDS, HOUR_SECONDS, ZERO_ADDRESS } = require("../../constants");
const config = require('../../config');

class Common {

  tokenName = "Incentive";
  tokenSymbol = "INC";

  tokenTotal = new BN(config.TOTAL_SUPPLY).mul(ONE_TOKEN);
  initialOffer = new BN(config.INITIAL_OFFER_TOKENS).mul(ONE_TOKEN);
  openingTime = Math.round(new Date().getTime() / 1000) + HOUR_SECONDS;
  closingTime = this.openingTime + MONTH_SECONDS;
  initialRate = parseInt(config.OFFER_START_RATE);
  finalRate   = parseInt(config.OFFER_END_RATE);
  timelockMinDelay = parseInt(config.MIN_TIMELOCK_DELAY);
  unlockBegin = Math.floor(new Date(config.UNLOCK_BEGIN).getTime() / 1000);
  unlockCliff = Math.floor(new Date(config.UNLOCK_CLIFF).getTime() / 1000);
  unlockEnd = Math.floor(new Date(config.UNLOCK_END).getTime() / 1000);

  toBN = (value) => {
    return web3.utils.toBN(value + '');
  };

  toUnits = (value) => {
    return web3.utils.toWei(value + '');
  };

  toAmount = (value) => {
    return web3.utils.fromWei(value);
  };

  calcTokenRateByTime = (timestamp) => {
    let elapsedTime = timestamp - this.openingTime;
    let timeRange = this.closingTime - this.openingTime;
    let rateRange = this.initialRate - this.finalRate;
    return Math.floor(this.initialRate - elapsedTime * rateRange / timeRange);
  };

  calcTokenRate = () => {
    let timestamp = Math.round(new Date().getTime() / 1000);
    return this.calcTokenRateByTime(timestamp);
  };

  tokenPrice = (value) => {
    let tokenUnits = this.toUnits(value);
    let tokenRate = this.calcTokenRate();
    let weiAmount = Math.ceil(tokenUnits / tokenRate);
    return weiAmount;
  };

  newINCToken = () => {
    return INCToken.new(this.tokenTotal);
  };

  newSurveyFactory = () => {
    return SurveyFactory.new();
  };

  newSurveyValidator = () => {
    return SurveyValidator.new();
  };

  newSurveyConfig = (factoryAddr, validatorAddr) => {
    return SurveyConfig.new(factoryAddr, validatorAddr);
  };

  newSurveyStorage = (configAddr) => {
    return SurveyStorage.new(configAddr);
  };

  newINCForwarder = () => {
    return INCForwarder.new();
  };

  newSurveyEngine = (currencyAddr, configAddr, storageAddr, forwarderAddr) => {
    return SurveyEngine.new(currencyAddr, configAddr, storageAddr, forwarderAddr);
  };

  newWrappedToken = () => {
    return WETH.new();
  };

  newTokenOffer = (tokenAddr) => {
    return TokenOffer.new(tokenAddr, this.openingTime, this.closingTime, this.initialRate, this.finalRate);
  };

  newTimelockController = () => {
    return TimelockController.new(this.timelockMinDelay, [], [ZERO_ADDRESS]);
  };

  newINCGovernor = (tokenAddr, timelockAddr) => {
    return INCGovernor.new(tokenAddr, timelockAddr);
  };

  newTokenLock = (tokenAddr) => {
    return TokenLock.new(tokenAddr, this.unlockBegin, this.unlockCliff, this.unlockEnd);
  };

  clone = (objectToClone) => {
    return JSON.parse(JSON.stringify(objectToClone));
  };

  log = (message, ...optionalParams) => {
    console.log("    # " + message, ...optionalParams);
  };
}

module.exports = new Common();