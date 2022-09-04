const INCToken = artifacts.require("INCToken");
const TokenOffer = artifacts.require("TokenOffer");
const SurveyStorage = artifacts.require("SurveyStorage");
const SurveyValidator = artifacts.require("SurveyValidator");
const SurveyEngine = artifacts.require("SurveyEngine");
const INCForwarder = artifacts.require("INCForwarder");
const IWETH = artifacts.require("IWETH");
const StringUtils = artifacts.require("StringUtils");
const IntUtils = artifacts.require("IntUtils");
const MathSol = artifacts.require("Math");

const { BN, ONE_TOKEN, MAX_UINT256, CURRENCY_ADDRESS } = require("../constants");
const config = require('../config');
const fs = require('fs');

const tokenTotal = new BN(config.TOTAL_SUPPLY).mul(ONE_TOKEN);
const initialOffer = new BN(config.INITIAL_OFFER_TOKENS).mul(ONE_TOKEN);
const openingTime = Math.round(new Date(config.OFFER_START_DATE).getTime() / 1000);
const closingTime = Math.round(new Date(config.OFFER_END_DATE).getTime() / 1000);
const initialRate = parseInt(config.OFFER_START_RATE);
const finalRate = parseInt(config.OFFER_END_RATE);

module.exports = async function (deployer, network, accounts) {
  //if (network == "development") return; // test maintains own contracts

  let currencyAddress;

  if (network == "development") {
    const WETH = artifacts.require('WETH');
    await deployer.deploy(WETH);
    currencyAddress = (await WETH.deployed()).address;
  } else {
    currencyAddress = CURRENCY_ADDRESS[network];
  }

  const owner = accounts[0];
  const custody = accounts[1];
  const relayers = accounts.slice(2, accounts.length);

  console.log('owner:: ' + owner);
  console.log('custody:: ' + custody);
  console.log('relayers:: ' + relayers);

  await deployer.deploy(StringUtils);
  await deployer.link(StringUtils, [SurveyStorage, SurveyValidator]);

  await deployer.deploy(IntUtils);
  await deployer.link(IntUtils, SurveyValidator);

  await deployer.deploy(MathSol);
  await deployer.link(MathSol, [INCToken]);

  await deployer.deploy(INCToken, tokenTotal);
  const token = await INCToken.deployed();

  await deployer.deploy(TokenOffer, token.address, openingTime, closingTime, initialRate, finalRate);
  const offer = await TokenOffer.deployed();

  await deployer.deploy(SurveyStorage);
  const surveyImpl = await SurveyStorage.deployed();

  await deployer.deploy(SurveyValidator);
  const surveyValidator = await SurveyValidator.deployed();

  await deployer.deploy(INCForwarder);
  const forwarder = await INCForwarder.deployed();

  await deployer.deploy(SurveyEngine, token.address, currencyAddress, surveyImpl.address, surveyValidator.address, forwarder.address);
  const surveyEngine = await SurveyEngine.deployed();

  // set manager
  await surveyImpl.setManager(surveyEngine.address);
  await surveyValidator.setManager(surveyEngine.address);
  await forwarder.setManager(custody);// set custody address of the gas reserve

  for(let relayer of relayers) {
    // add relayers to white list
    await forwarder.addSenderToWhitelist(relayer);
  }

  // approve tokens for offer contract
  await token.approve(offer.address, initialOffer, { from: owner });

  // ´custody´ must approve wrapped tokens to SurveyEngine
  const currency = await IWETH.at(currencyAddress);
  await currency.approve(surveyEngine.address, MAX_UINT256, { from: custody });

  console.log('token:: ' + token.address);
  console.log('offer:: ' + offer.address);
  console.log('survey:: ' + surveyImpl.address);
  console.log('validator:: ' + surveyValidator.address);
  console.log('forwarder:: ' + forwarder.address);
  console.log('engine:: ' + surveyEngine.address);

  try {
    fs.writeFileSync('.deploy/abis/INCToken.json', JSON.stringify(INCToken.abi));
    fs.writeFileSync('.deploy/abis/TokenOffer.json', JSON.stringify(TokenOffer.abi));
    fs.writeFileSync('.deploy/abis/SurveyValidator.json', JSON.stringify(SurveyValidator.abi));
    fs.writeFileSync('.deploy/abis/SurveyStorage.json', JSON.stringify(SurveyStorage.abi));
    fs.writeFileSync('.deploy/abis/SurveyEngine.json', JSON.stringify(SurveyEngine.abi));
    fs.writeFileSync('.deploy/abis/INCForwarder.json', JSON.stringify(INCForwarder.abi));

    console.log("Success.");
  } catch (err) {
    console.error(err);
  }
};
