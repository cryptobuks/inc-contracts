const INCToken = artifacts.require("INCToken");
const TokenOffer = artifacts.require("TokenOffer");
const SurveyStorage = artifacts.require("SurveyStorage");
const SurveyValidator = artifacts.require("SurveyValidator");
const SurveyEngine = artifacts.require("SurveyEngine");
const INCForwarder = artifacts.require("INCForwarder");
const TimelockController = artifacts.require("TimelockController");
const INCGovernor = artifacts.require("INCGovernor");
const TokenLock = artifacts.require("TokenLock");
const fs = require('fs');

module.exports = async function (deployer, network, accounts) {
  //if (network == "development") return;

  const owner = accounts[0];
  const custody = accounts[1];
  const relayers = accounts.slice(2, accounts.length);

  const incToken = await INCToken.deployed();
  const offer = await TokenOffer.deployed();
  const surveyImpl = await SurveyStorage.deployed();
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
  console.log('  survey: ' + surveyImpl.address);
  console.log('  validator: ' + surveyValidator.address);
  console.log('  forwarder: ' + forwarder.address);
  console.log('  engine: ' + surveyEngine.address);
  console.log('  timelock: ' + timelock.address);
  console.log('  governor: ' + governor.address);
  console.log('  tokenLock: ' + tokenLock.address);

  try {
    fs.writeFileSync('.deploy/abis/INCToken.json', JSON.stringify(INCToken.abi));
    fs.writeFileSync('.deploy/abis/TokenOffer.json', JSON.stringify(TokenOffer.abi));
    fs.writeFileSync('.deploy/abis/SurveyValidator.json', JSON.stringify(SurveyValidator.abi));
    fs.writeFileSync('.deploy/abis/SurveyStorage.json', JSON.stringify(SurveyStorage.abi));
    fs.writeFileSync('.deploy/abis/SurveyEngine.json', JSON.stringify(SurveyEngine.abi));
    fs.writeFileSync('.deploy/abis/INCForwarder.json', JSON.stringify(INCForwarder.abi));
    fs.writeFileSync('.deploy/abis/TimelockController.json', JSON.stringify(TimelockController.abi));
    fs.writeFileSync('.deploy/abis/INCGovernor.json', JSON.stringify(INCGovernor.abi));
    fs.writeFileSync('.deploy/abis/TokenLock.json', JSON.stringify(TokenLock.abi));

    console.log("\nSuccess.");
  } catch (err) {
    console.error(err);
  }
};
