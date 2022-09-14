const INCToken = artifacts.require("INCToken");
const SurveyStorage = artifacts.require("SurveyStorage");
const SurveyValidator = artifacts.require("SurveyValidator");
const SurveyEngine = artifacts.require("SurveyEngine");
const INCForwarder = artifacts.require("INCForwarder");
const IWETH = artifacts.require("IWETH");
const StringUtils = artifacts.require("StringUtils");
const IntUtils = artifacts.require("IntUtils");
const { MAX_UINT256, CURRENCY_ADDRESS } = require("../constants");

module.exports = async function (deployer, network, accounts) {
  //if (network == "development") return;

  let currencyAddress;

  if (network == "development") {
    const WETH = artifacts.require('WETH');
    await deployer.deploy(WETH);
    currencyAddress = (await WETH.deployed()).address;
  } else {
    currencyAddress = CURRENCY_ADDRESS[network];
  }

  const custody = accounts[1];
  const relayers = accounts.slice(2, accounts.length);

  await deployer.deploy(StringUtils);
  await deployer.link(StringUtils, [SurveyStorage, SurveyValidator]);

  await deployer.deploy(IntUtils);
  await deployer.link(IntUtils, SurveyValidator);

  const incToken = await INCToken.deployed();

  await deployer.deploy(SurveyStorage);
  const surveyImpl = await SurveyStorage.deployed();

  await deployer.deploy(SurveyValidator);
  const surveyValidator = await SurveyValidator.deployed();

  await deployer.deploy(INCForwarder);
  const forwarder = await INCForwarder.deployed();

  await deployer.deploy(SurveyEngine, incToken.address, currencyAddress, surveyImpl.address, surveyValidator.address, forwarder.address);
  const surveyEngine = await SurveyEngine.deployed();

  // set managers
  await surveyImpl.setManager(surveyEngine.address);
  await surveyValidator.setManager(surveyEngine.address);
  await forwarder.setManager(custody);// set custody address for the gas reserve

  for (let relayer of relayers) {
    // add relayers to white list
    await forwarder.addSenderToWhitelist(relayer);
  }

  // ´custody´ must approve wrapped tokens to SurveyEngine
  const currency = await IWETH.at(currencyAddress);
  await currency.approve(surveyEngine.address, MAX_UINT256, { from: custody });
};
