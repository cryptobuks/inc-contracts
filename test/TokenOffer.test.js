const cmn = require("./shared/common");
const time = require('./shared/time');
const { ZERO_ADDRESS } = require("../constants");
const config = require('../config');
const offerPhase = parseInt(config.OFFER_PHASE);

contract('TokenOffer', accounts => {

    // Deadline = Opening Time + Limit Time
    const deadline = cmn.openingTime + 1800;
    const allowanceAmount = cmn.initialOffer;
    
    let snapshotId;
    let tokenInstance;
    let offerInstance;
    let owner;
    let user1;
    let user2;

    beforeEach(async () => {
        // Take a snapshot
        const snapShot = await time.takeSnapshot();
        snapshotId = snapShot['result'];

        tokenInstance = await cmn.newINCToken();
        offerInstance = await cmn.newTokenOffer(tokenInstance.address);

        owner = accounts[0];
        user1 = accounts[1];
        user2 = accounts[2];

        // Approve offer contract to send tokens
        await tokenInstance.approve(offerInstance.address, allowanceAmount, { from: owner });
        
        // Advance the time for the offer to be open
        await time.increaseTo(cmn.openingTime);
    });

    afterEach(async () => {
        // Revert to original state
        await time.revertToSnapShot(snapshotId);
    });

    function getMinAmount(weiAmount) {
        let futureRate = cmn.calcTokenRateByTime(deadline);
        return cmn.toBN(weiAmount).mul(cmn.toBN(futureRate));
    }

    it('check phase', async () => {
        let phase = await offerInstance.phase();
        assert(parseInt(phase) == offerPhase);
    });

    it('should have crowdsale opening time', async () => {
        let openingTime = await offerInstance.openingTime();
        let closingTime = await offerInstance.closingTime();
        assert(cmn.openingTime == openingTime);
        assert(cmn.closingTime == closingTime);
    });

    it('should have token price', async () => {
        let initialRate = await offerInstance.initialRate();
        let finalRate = await offerInstance.finalRate();
        assert(cmn.initialRate == initialRate);
        assert(cmn.finalRate == finalRate);
    });

    it('should have available allowance', async () => {
        let offerAllowance = await tokenInstance.allowance(owner, offerInstance.address);
        assert(allowanceAmount.eq(cmn.toBN(offerAllowance)));
    });

    it('buy tokens', async () => {
        let ownerCcyBalance = await web3.eth.getBalance(owner);
        let userCcyBalance = await web3.eth.getBalance(user1);

        let weiAmount = cmn.tokenPrice(1000);
        let minAmount = getMinAmount(weiAmount);

        // Buy tokens for ´user1´
        await offerInstance.buy(deadline, minAmount, { from: user1, value: weiAmount });

        // The new user's balance is the same as the old balance minus the amount of wei sent and gas spent
        // So the new balance is less than the old balance minus the amount of wei sent
        let newUserCcyBalance = await web3.eth.getBalance(user1);
        assert(cmn.toBN(newUserCcyBalance).lt(cmn.toBN(userCcyBalance).sub(cmn.toBN(weiAmount))));

        // The owner's new balance is the same as the previous balance plus the amount of wei sent
        let newOwnerCcyBalance = await web3.eth.getBalance(owner);
        assert(cmn.toBN(newOwnerCcyBalance).eq(cmn.toBN(ownerCcyBalance).add(cmn.toBN(weiAmount))));

        let tokens = await tokenInstance.balanceOf(user1);
        assert(cmn.toBN(tokens).gte(cmn.toBN(minAmount)));
        //cmn.log("tokens:: " + tokens);

        // the allowance should go down
        let newOfferAllowance = await tokenInstance.allowance(owner, offerInstance.address);
        assert(cmn.toBN(newOfferAllowance).eq(allowanceAmount.sub(cmn.toBN(tokens))));
    });

    it('buy tokens to', async () => {
        let weiAmount = 10 ** 18;
        let minAmount = getMinAmount(weiAmount);

        // buy tokens from ´user1´ to ´user2´
        await offerInstance.buyTo(user2, deadline, minAmount, { from: user1, value: weiAmount });

        let buyerTokens = await tokenInstance.balanceOf(user1);
        assert(buyerTokens == 0);

        let recipientTokens = await tokenInstance.balanceOf(user2);
        assert(cmn.toBN(recipientTokens).gte(cmn.toBN(minAmount)));
    });

    it('buy tokens to ZERO_ADDRESS', async () => {
        let weiAmount = 10 ** 18;
        let minAmount = getMinAmount(weiAmount);

        try {
            await offerInstance.buyTo(ZERO_ADDRESS, deadline, minAmount, { value: weiAmount });
            assert.fail();
        } catch (e) {
            assert(e.message.indexOf('TokenOffer: transfer to the zero address') != -1);
        }

        let zeroAddrTokens = await tokenInstance.balanceOf(ZERO_ADDRESS);
        assert(zeroAddrTokens == 0);
    });

    it('send transaction to buy tokens', async () => {
        let weiAmount = cmn.tokenPrice(0.5);
        let minAmount = getMinAmount(weiAmount);

        // await offerInstance.buy(deadline, minAmount, { from: user1, value: weiAmount });
        // Alternatively you can call the function as follows:
        await offerInstance.sendTransaction({ from: user1, value: weiAmount });

        let tokens = await tokenInstance.balanceOf(user1);
        assert(cmn.toBN(tokens).gte(cmn.toBN(minAmount)));
    });

});