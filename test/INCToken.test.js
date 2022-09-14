const cmn = require("./shared/common");
const time = require('./shared/time');
const { DAY_SECONDS } = require("../constants");

contract('INCToken', accounts => {

    const tokenUnits = cmn.toBN(cmn.toUnits(100));

    let snapshotId;
    let tokenInstance;
    let owner;
    let user1;
    let user2;
    let user3;

    beforeEach(async () => {
        // Take a snapshot
        const snapShot = await time.takeSnapshot();
        snapshotId = snapShot['result'];

        tokenInstance = await cmn.newINCToken();

        owner = accounts[0];
        user1 = accounts[1];
        user2 = accounts[2];
        user3 = accounts[3];
    });

    afterEach(async () => {
        // Revert to original state
        await time.revertToSnapShot(snapshotId);
    });

    it('Check token properties', async () => {
        let name = await tokenInstance.name();
        assert.equal(name, cmn.tokenName);

        let symbol = await tokenInstance.symbol();
        assert.equal(symbol, cmn.tokenSymbol);

        let totalSupply = cmn.toBN(await tokenInstance.totalSupply());
        assert(totalSupply.eq(cmn.tokenTotal));

        let tokenBalance = cmn.toBN(await tokenInstance.balanceOf(owner));
        assert(tokenBalance.eq(totalSupply));
    });

    it('Check token transfers', async () => {
        // Transfer ´tokenUnits´ from ´owner´ to ´user1´
        await tokenInstance.transfer(user1, tokenUnits, { from : owner });

        // Check ´user1´ balance
        let user1Balance = await tokenInstance.balanceOf(user1);
        assert(cmn.toBN(user1Balance).eq(tokenUnits));

        // The ´user1´ sends half of the tokens to ´user2´
        await tokenInstance.transfer(user2, cmn.toBN(tokenUnits).divn(2), { from: user1 });

        // Check ´user1´ remaining balance
        user1Balance = await tokenInstance.balanceOf(user1);
        assert(cmn.toBN(user1Balance).eq(tokenUnits.divn(2)));

        // Check ´user2´ balance
        let user2Balance = await tokenInstance.balanceOf(user2);
        assert(cmn.toBN(user2Balance).eq(tokenUnits.divn(2)));

        // The ´user1´ approves ´user2´ to send their tokens
        await tokenInstance.approve(user2, user1Balance, { from: user1 });

        // Check allowance for ´user2´
        let user2Allowance = await tokenInstance.allowance(user1, user2);
        assert(cmn.toBN(user2Allowance).eq(cmn.toBN(user1Balance)));

        // The ´user2´ send tokens of ´user1´ to ´user3´
        await tokenInstance.transferFrom(user1, user3, user2Allowance, { from: user2 });

        // Check ´user1´ remaining balance
        user1Balance = await tokenInstance.balanceOf(user1);
        assert(cmn.toBN(user1Balance).isZero());

        // Check ´user3´ remaining balance
        let user3Balance = await tokenInstance.balanceOf(user3);
        assert(cmn.toBN(user3Balance).eq(cmn.toBN(user2Allowance)));

        // The ´user2´ approves ´user3´ to send their tokens
        await tokenInstance.approve(user3, user2Balance, { from: user2 });

        // Check allowance for ´user3´
        let user3Allowance = await tokenInstance.allowance(user2, user3);
        assert(cmn.toBN(user3Allowance).eq(cmn.toBN(user2Balance)));

        // The ´user2´ disapproves ´user3´
        await tokenInstance.approve(user3, 0, { from: user2 });

        // Check again allowance for ´user3´
        user3Allowance = await tokenInstance.allowance(user2, user3);
        assert(cmn.toBN(user3Allowance).isZero());
    });

    it('Check token timeline', async () => {
        // Transfer ´tokenUnits´ from ´owner´ to ´user1´
        await tokenInstance.transfer(user1, tokenUnits, { from : owner });
        let user1Balance = await tokenInstance.balanceOf(user1);

        // Check timeline start (Corresponds to the first deposit)
        let timelineStart = await tokenInstance.timelineStartOf(user1);
        assert(cmn.toBN(timelineStart).gt(0));// The start time is greater than 0, so there is a record

        // Increase time (10 days)
        await time.increase(DAY_SECONDS * 10);

        // The ´user1´ sends half of the tokens to another user
        await tokenInstance.transfer(user2, cmn.toBN(user1Balance).divn(2), { from: user1 });
        user1Balance = await tokenInstance.balanceOf(user1);

        // Increase time (another 10 days)
        await time.increase(DAY_SECONDS * 10);

        // Again, the ´user1´ sends half of the tokens (25% of the initial balance) to another user
        await tokenInstance.transfer(user2, cmn.toBN(user1Balance).divn(2), { from: user1 });
        user1Balance = await tokenInstance.balanceOf(user1);

        // Get 30-day timeline
        let startTime = parseInt(timelineStart);
        let endTime = startTime + DAY_SECONDS * 30;
        let granularity = DAY_SECONDS;
        let timeline = await tokenInstance.timelineMetricsOf(user1, startTime, endTime, granularity);

        // Check the number of metrics
        assert(timeline.times.length == timeline.balances.length);
        assert(timeline.times.length == Math.ceil((endTime - startTime) / granularity) + 1);

        // Check first balance in timeline
        assert(cmn.toBN(timeline.balances[0]).eq(tokenUnits));

        // Check balance of day 15 in timeline
        assert(cmn.toBN(timeline.balances[14]).eq(tokenUnits.divn(2)));

        // Check last balance in timeline
        assert(cmn.toBN(timeline.balances[timeline.balances.length - 1]).eq(tokenUnits.divn(4)));

        //cmn.log("Timeline times:: " + timeline.times);
        //cmn.log("Timeline balances:: " + timeline.balances);
    });

    it('Check timeline avg', async () => {
        // Transfer ´tokenUnits´ from ´owner´ to ´user1´
        await tokenInstance.transfer(user1, tokenUnits, { from : owner });

        // Check avg 1 day later
        let startTime = (await time.latest()).toNumber();
        let endTime = startTime + DAY_SECONDS;
        let granularity = DAY_SECONDS;
        let timelineAvg = await tokenInstance.timelineAvgOf(user1, startTime, endTime, granularity);
        assert(cmn.toBN(timelineAvg).eq(tokenUnits));
        //cmn.log("Timeline avg:: " + timelineAvg + " => " + cmn.toAmount(timelineAvg));

        // Without further movement, check avg 30 days later
        endTime = startTime + DAY_SECONDS * 30;
        let timelineAvg2 = await tokenInstance.timelineAvgOf(user1, startTime, endTime, granularity);
        assert(cmn.toBN(timelineAvg2).eq(cmn.toBN(timelineAvg)));

        // Increase time (15 days)
        await time.increase(DAY_SECONDS * 15);

        // The ´user1´ sends half of the tokens to another user
        await tokenInstance.transfer(user2, tokenUnits.divn(2), { from: user1 });

        // Check avg after disbursement
        endTime = startTime + DAY_SECONDS * 16;
        timelineAvg2 = await tokenInstance.timelineAvgOf(user1, startTime, endTime, granularity);
        assert(cmn.toBN(timelineAvg2).lt(cmn.toBN(timelineAvg)));
        //cmn.log("Timeline avg 1 day after disbursement made at 15 days:: " + timelineAvg2 + " => " + cmn.toAmount(timelineAvg2));

        // Check avg 30 days later
        endTime = startTime + DAY_SECONDS * 30;
        let timelineAvg3 = await tokenInstance.timelineAvgOf(user1, startTime, endTime, granularity);
        assert(cmn.toBN(timelineAvg3).lt(cmn.toBN(timelineAvg2)));
        //cmn.log("Timeline avg 30 days after the 1nd transfer:: " + timelineAvg3 + " => " + cmn.toAmount(timelineAvg3));

        // Check avg 365 days later
        endTime = startTime + DAY_SECONDS * 365;
        let timelineAvg4 = await tokenInstance.timelineAvgOf(user1, startTime, endTime, granularity);
        assert(cmn.toBN(timelineAvg4).lt(cmn.toBN(timelineAvg3)));
        //cmn.log("Timeline avg 365 days after the 1nd transfer:: " + timelineAvg4 + " => " + cmn.toAmount(timelineAvg4));
    });

});