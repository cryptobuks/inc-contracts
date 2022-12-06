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
const fs = require('fs');

module.exports = async function (deployer, network, accounts) {
  //if (network == "development") return;

  try {
    fs.writeFileSync('.deploy/abis/INCToken.json', JSON.stringify(INCToken.abi));
    fs.writeFileSync('.deploy/abis/TokenOffer.json', JSON.stringify(TokenOffer.abi));
    fs.writeFileSync('.deploy/abis/SurveyConfig.json', JSON.stringify(SurveyConfig.abi));
    fs.writeFileSync('.deploy/abis/SurveyStorage.json', JSON.stringify(SurveyStorage.abi));
    fs.writeFileSync('.deploy/abis/SurveyFactory.json', JSON.stringify(SurveyFactory.abi));
    fs.writeFileSync('.deploy/abis/SurveyValidator.json', JSON.stringify(SurveyValidator.abi));
    fs.writeFileSync('.deploy/abis/INCForwarder.json', JSON.stringify(INCForwarder.abi));
    fs.writeFileSync('.deploy/abis/SurveyEngine.json', JSON.stringify(SurveyEngine.abi));
    fs.writeFileSync('.deploy/abis/TimelockController.json', JSON.stringify(TimelockController.abi));
    fs.writeFileSync('.deploy/abis/INCGovernor.json', JSON.stringify(INCGovernor.abi));
    fs.writeFileSync('.deploy/abis/TokenLock.json', JSON.stringify(TokenLock.abi));

    console.log("\nSuccess.");
  } catch (err) {
    console.error(err);
  }
};