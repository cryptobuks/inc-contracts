const INCToken = artifacts.require("INCToken");
const TokenLock = artifacts.require("TokenLock");
const config = require('../config');

const unlockBegin = Math.floor(new Date(config.UNLOCK_BEGIN).getTime() / 1000);
const unlockCliff = Math.floor(new Date(config.UNLOCK_CLIFF).getTime() / 1000);
const unlockEnd = Math.floor(new Date(config.UNLOCK_END).getTime() / 1000);

module.exports = async function (deployer, network, accounts) {
    //if (network == "development") return;

    const incToken = await INCToken.deployed();
    await deployer.deploy(TokenLock, incToken.address, unlockBegin, unlockCliff, unlockEnd);
};