const INCToken = artifacts.require("INCToken");
const TimelockController = artifacts.require("TimelockController");
const TokenLock = artifacts.require("TokenLock");
const { BN, ONE_TOKEN } = require("../constants");
const config = require('../config');

const lockedDAOTokens = ONE_TOKEN.mul(new BN(config.LOCKED_DAO_TOKENS));
const totalContributorTokens = ONE_TOKEN.mul(new BN(config.TOTAL_CONTRIBUTOR_TOKENS));

module.exports = async function (deployer, network, accounts) {
    //if (network == "development") return;

    const owner = accounts[0];
    const incToken = await INCToken.deployed();
    const timelock = await TimelockController.deployed();
    const tokenLock = await TokenLock.deployed();

    // Transfer locked tokens to the tokenlock
    if ((await tokenLock.lockedAmounts(timelock.address)).eq(new BN('0'))) {
        await incToken.approve(tokenLock.address, lockedDAOTokens);
        await tokenLock.lock(timelock.address, lockedDAOTokens);
    }

    // Transfer free tokens to the timelock controller
    const balance = await incToken.balanceOf(owner);
    if (balance.gt(totalContributorTokens)) {
        await incToken.transfer(timelock.address, balance.sub(totalContributorTokens));
    }

    // Print balances
    const daoBalance = await incToken.balanceOf(timelock.address);
    console.log(`Token balances:`);
    console.log(`  DAO: ${daoBalance.div(ONE_TOKEN).toString()}`);
    const contributorBalance = await incToken.balanceOf(owner);
    console.log(`  Contributors: ${contributorBalance.div(ONE_TOKEN).toString()}`);
    const tokenlockBalance = await incToken.balanceOf(tokenLock.address);
    console.log(`  TokenLock: ${tokenlockBalance.div(ONE_TOKEN).toString()}`);
    const lockedDaoBalance = await tokenLock.lockedAmounts(timelock.address);
    console.log(`    Locked DAO: ${lockedDaoBalance.div(ONE_TOKEN).toString()}`);
    const total = daoBalance.add(contributorBalance).add(tokenlockBalance);
    console.log(`  TOTAL: ${total.div(ONE_TOKEN).toString()}`);
};
