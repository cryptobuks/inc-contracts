const INCToken = artifacts.require("INCToken");
const TokenOffer = artifacts.require("TokenOffer");
const TimelockController = artifacts.require("TimelockController");

module.exports = async function (deployer, network, accounts) {
    //if (network == "development") return;

    const incToken = await INCToken.deployed();
    const offer = await TokenOffer.deployed();
    const timelock = await TimelockController.deployed();

    // Transfer ownership of the token to the timelock controller
    await incToken.transferOwnership(timelock.address);

    // Transfer ownership of the offer to the timelock controller
    await offer.transferOwnership(timelock.address);
};