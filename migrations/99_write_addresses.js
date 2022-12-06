const INCToken = artifacts.require("INCToken");
const TokenOffer = artifacts.require("TokenOffer");
const SurveyConfig = artifacts.require("SurveyConfig");
const SurveyStorage = artifacts.require("SurveyStorage");
const SurveyFactory = artifacts.require("SurveyFactory");
const SurveyValidator = artifacts.require("SurveyValidator");
const SurveyEngine = artifacts.require("SurveyEngine");
const INCForwarder = artifacts.require("INCForwarder");
const TimelockController = artifacts.require("TimelockController");
const INCGovernor = artifacts.require("INCGovernor");
const TokenLock = artifacts.require("TokenLock");

module.exports = async function (deployer, network, accounts) {
  //if (network == "development") return;

  const owner = accounts[0];
  const custody = accounts[1];
  const relayers = accounts.slice(2, accounts.length);

  const incToken = await INCToken.deployed();
  const offer = await TokenOffer.deployed();
  const surveyConfig = await SurveyConfig.deployed();
  const surveyStorage = await SurveyStorage.deployed();
  const surveyFactory = await SurveyFactory.deployed();
  const surveyValidator = await SurveyValidator.deployed();
  const forwarder = await INCForwarder.deployed();
  const surveyEngine = await SurveyEngine.deployed();
  const timelock = await TimelockController.deployed();
  const governor = await INCGovernor.deployed();
  const tokenLock = await TokenLock.deployed();

  console.log('\nAddresses:');
  console.log('  owner: ' + owner);
  console.log('  custody: ' + custody);
  console.log('  relayers: ' + relayers);
  console.log('  token: ' + incToken.address);
  console.log('  offer: ' + offer.address);
  console.log('  config: ' + surveyConfig.address);
  console.log('  storage: ' + surveyStorage.address);
  console.log('  factory: ' + surveyFactory.address);
  console.log('  validator: ' + surveyValidator.address);
  console.log('  forwarder: ' + forwarder.address);
  console.log('  engine: ' + surveyEngine.address);
  console.log('  timelock: ' + timelock.address);
  console.log('  governor: ' + governor.address);
  console.log('  tokenLock: ' + tokenLock.address);
};