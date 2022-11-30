const INCToken = artifacts.require("INCToken");
const TimelockController = artifacts.require("TimelockController");
const INCGovernor = artifacts.require("INCGovernor");
const { ZERO_ADDRESS } = require("../constants");
const config = require('../config');

const minDelay = parseInt(config.MIN_TIMELOCK_DELAY);

module.exports = async function (deployer, network, accounts) {
    //if (network == "development") return;

    const owner = accounts[0];
    const incToken = await INCToken.deployed();

    await deployer.deploy(TimelockController, minDelay, [], [ZERO_ADDRESS]);
    const timelock = await TimelockController.deployed();

    await deployer.deploy(INCGovernor, incToken.address, timelock.address);
    const governor = await INCGovernor.deployed();

    await timelock.grantRole(await timelock.PROPOSER_ROLE(), governor.address);
    await timelock.revokeRole(await timelock.TIMELOCK_ADMIN_ROLE(), owner);
};