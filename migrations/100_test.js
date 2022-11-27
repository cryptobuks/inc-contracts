const SurveyConfig = artifacts.require("SurveyConfig");
const SurveyStorage = artifacts.require("SurveyStorage");
const SurveyFactory = artifacts.require("SurveyFactory");

module.exports = async function (deployer, network, accounts) {
  //if (network == "development") return;

  /*const surveyConfig = await SurveyConfig.at("0x06d63EE6891aCb679FACc87b6A559D4bE9c24820");
  const surveyStorage = await SurveyStorage.at("0x483567B064d82840F155c2356433A84Ca04431eB");

  await deployer.deploy(SurveyFactory);
  const surveyFactory = await SurveyFactory.deployed();

  await surveyConfig.setSurveyFactory(surveyFactory.address);
  await surveyFactory.setManager(surveyStorage.address);*/
};