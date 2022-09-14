const INCToken = artifacts.require("INCToken");
const MathSol = artifacts.require("Math");

const { BN, ONE_TOKEN } = require("../constants");
const config = require('../config');

const tokenTotal = new BN(config.TOTAL_SUPPLY).mul(ONE_TOKEN);

module.exports = async function (deployer, network, accounts) {
  //if (network == "development") return;

  await deployer.deploy(MathSol);
  await deployer.link(MathSol, [INCToken]);
  await deployer.deploy(INCToken, tokenTotal);
};
