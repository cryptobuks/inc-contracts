const INCToken = artifacts.require("INCToken");
const TokenOffer = artifacts.require("TokenOffer");
const config = require('../config');

const openingTime = Math.round(new Date(config.OFFER_START_DATE).getTime() / 1000);
const closingTime = Math.round(new Date(config.OFFER_END_DATE).getTime() / 1000);
const initialRate = parseInt(config.OFFER_START_RATE);
const finalRate = parseInt(config.OFFER_END_RATE);

module.exports = async function (deployer, network, accounts) {
  //if (network == "development") return;

  const incToken = await INCToken.deployed();
  await deployer.deploy(TokenOffer, incToken.address, openingTime, closingTime, initialRate, finalRate);

  // It is necessary to create a proposal to launch the initial offer.
  // The tokens must be approved by the owner ´TimelockController´.
};
