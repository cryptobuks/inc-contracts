const cmn = require("./shared/common");
const time = require('./shared/time');
const { DAY_SECONDS, ZERO_ADDRESS } = require("../constants");

contract('INCGovernor', accounts => {

    let snapshotId;
    let tokenInstance;
    let timelockInstance;
    let governorInstance;

    beforeEach(async () => {
        // Take a snapshot
        const snapShot = await time.takeSnapshot();
        snapshotId = snapShot['result'];

        tokenInstance = await cmn.newINCToken();
        timelockInstance = await cmn.newTimelockController();
        governorInstance = await cmn.newINCGovernor(tokenInstance.address, timelockInstance.address);
    });

    afterEach(async () => {
        // Revert to original state
        await time.revertToSnapShot(snapshotId);
    });

    it('Check governor properties', async () => {
        const votingDelay = await governorInstance.votingDelay();
        assert.equal(votingDelay, 1);

        const votingPeriod = await governorInstance.votingPeriod();
        assert.equal(votingPeriod, 50400);

        // Increase time (1 day)
        await time.increase(DAY_SECONDS);

        const blockNumber = parseInt(await time.latestBlock()) - 1;
        const quorum = cmn.toBN(await governorInstance.quorum(blockNumber));
        const supply = cmn.toBN(await tokenInstance.getPastTotalSupply(blockNumber));
        const numerator = cmn.toBN(await governorInstance.quorumNumerator(blockNumber));
        const denominator = cmn.toBN(await governorInstance.quorumDenominator());
        const amount = supply.mul(numerator).div(denominator);
        assert(quorum.eq(amount));
        assert(quorum.eq(cmn.tokenTotal.mul(cmn.toBN(5)).div(cmn.toBN(100))));

        const proposalThreshold = cmn.toBN(await governorInstance.proposalThreshold());
        assert(proposalThreshold.eq(cmn.tokenTotal.div(cmn.toBN(1000))));

        cmn.log('totalSupply       :: ' + cmn.toAmount(cmn.tokenTotal));
        cmn.log('quorum            :: ' + cmn.toAmount(quorum));
        cmn.log('proposalThreshold :: ' + cmn.toAmount(proposalThreshold));
    });

    it('Check execute role', async () => {
        const executeRole = await timelockInstance.EXECUTOR_ROLE();
        const hasExecuteRole = await timelockInstance.hasRole(executeRole, ZERO_ADDRESS);
        assert(hasExecuteRole);
    });

});