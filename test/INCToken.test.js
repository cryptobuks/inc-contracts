const cmn = require("./shared/common");
const time = require('./shared/time');
const config = require('../config');

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
        assert(cmn.toAmount(totalSupply) == config.TOTAL_SUPPLY);
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

});