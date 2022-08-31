// ################################################################################################################################################
// USING TEST SPECIFIC MNEMONIC: ganache-cli -m "icon odor witness lonely lesson ill paddle material wreck term illegal alone struggle beach mouse"
// ################################################################################################################################################

const impl = require("./shared/contracts-impl");
const cmn = require("./shared/common");
const time = require('./shared/time');
const sign = require("./shared/sign");
const { HOUR_SECONDS } = require("../constants");
const { bufferToHex, privateToAddress, toBuffer } = require('ethereumjs-util');
const { toChecksumAddress } = require('web3-utils');
const NewEngine = artifacts.require('NewEngine');

contract('SurveyEngine', accounts => {

    const signer1 = '0x0ea26ee7a2c7bf5cfdcaabb9b549af56dd33ddb98a71b1aab716c27a1b765a52'; // Account m/44'/0'/0'/0/3	0x658107C480289402dA768a22C80aD677563f19E7
    const signer2 = '0x39069cac982a295e9f5c22362afda02f992fc3fb4db9536fbfea7b197cd4c463'; // Account m/44'/0'/0'/0/4	0x5CCfb11bC0272a76561eDC6EbdCB6e26088a7aD1

    const partHashes = ['8e6e4f84', '075e4130'];
    const partKey1 = '41f61133-1ef0-45d3-ad25-79520feef388';
    const partKey2 = '03aedda1-5b0b-47a7-a043-05ce7c1ed11b';

    let savedSurvey;
    let txGas;
    let gasReserve;
    let secSnapshotId;

    before(async () => {
        savedSurvey = cmn.clone(impl.survey);

        // Reduce the number of participations to 2
        impl.survey.reward = cmn.toBN(impl.survey.budget).divn(2).toString();
        
        await impl.init(accounts);
    });

    after(async () => {
        await impl.revert();
        impl.survey = savedSurvey;
    });

    beforeEach(async () => {
        // Take a secondary snapshot
        const snapShot = await time.takeSnapshot();
        secSnapshotId = snapShot['result'];
    });

    afterEach(async () => {
        // Revert to secondary state
        await time.revertToSnapShot(secSnapshotId);
    });

    addSurvey = async () => {
        txGas = await impl.getAvgTxGas();
        gasReserve = impl.gasPrice.mul(txGas).muln(impl.maxParts);
        const weiForSurvey = gasReserve.add(impl.fee);// gas reserve + fee

        const result = await impl.engineInstance.addSurvey(impl.survey, impl.questions, impl.validators, partHashes, { from: impl.creator, value: weiForSurvey });

        // Advance the time for the survey to be open
        await time.increase(HOUR_SECONDS);

        return result;
    };

    it('Check signers', async () => {
        // Check private key 1
        const privateKey1 = toBuffer(signer1);
        assert(impl.user1 == toChecksumAddress(bufferToHex(privateToAddress(privateKey1))));

        // Check private key 2
        const privateKey2 = toBuffer(signer2);
        assert(impl.user2 == toChecksumAddress(bufferToHex(privateToAddress(privateKey2))));
    });

    it('Create survey', async () => {
        const result = await addSurvey();
        assert(result.receipt.status);

        // Get own survey
        const ownSurvey = (await impl.surveyInstance.getOwnSurveys(0, 1, { from: impl.creator }))[0];
        impl.checkSurvey(ownSurvey, 1);

        // Get survey by ID
        const mSurvey = await impl.surveyInstance.findSurvey(1);
        impl.checkSurvey(mSurvey, 1);

        // Get questions
        const mQuestions = await impl.surveyInstance.getQuestions(1, 0, impl.questions.length);
        for (let i = 0; i < impl.questions.length; i++) {
            impl.checkQuestion(mQuestions[i], i);
        }

        // Get first question validators
        const mValidators = await impl.surveyInstance.getValidators(1, 0);

        for (let i = 0, j = 0; i < impl.validators.length; i++) {
            let validator = impl.validators[i];

            if (validator.questionIndex == 0) {
                assert(mValidators[j].operator == validator.operator);
                assert(mValidators[j].expression == validator.expression);
                assert(mValidators[j].value == validator.value);
                j++;
            }
        }

        const creatorINCBalance = await impl.tokenInstance.balanceOf(impl.creator);
        const engineINCBalance = await impl.tokenInstance.balanceOf(impl.engineInstance.address);

        assert(cmn.toBN(creatorINCBalance).lt(cmn.toBN(cmn.toUnits(impl.incAmountForCreator))));
        assert(cmn.toBN(engineINCBalance).eq(cmn.toBN(impl.survey.budget)));
    });

    it('Add participation assuming the gas', async () => {
        await addSurvey();

        let result = await impl.engineInstance.addParticipation(1, impl.part1.responses, partKey1, { from: impl.user1 });
        assert(result.receipt.status);

        // Add participation 2. using new participant & new partKey
        result = await impl.engineInstance.addParticipation(1, impl.part2.responses, partKey2, { from: impl.user2 });
        assert(result.receipt.status);

        // Get participation
        let participation = (await impl.surveyInstance.getParticipations(1, 0, 1))[0];
        assert(participation.surveyId == 1);
        //cmn.log("Participation by survey ID and participation index: " + participation);

        let ownParticipation = (await impl.surveyInstance.getOwnParticipations(0, 1, { from: impl.user1 }))[0];
        assert(ownParticipation.surveyId == 1);
        //cmn.log("ownParticipation by index: " + ownParticipation);

        ownParticipation = await impl.surveyInstance.findOwnParticipation(1, { from: impl.user2 });
        assert(ownParticipation.surveyId == 1);
        //cmn.log("ownParticipation by survey ID: " + ownParticipation);
    });

    it('Add participation without paying gas', async () => {
        await addSurvey();

        const data = impl.engineInstance.contract.methods.addParticipationFromForwarder(1, impl.part1.responses, partKey1, txGas).encodeABI();
        const nonce = await impl.forwarderInstance.getNonce(impl.user1);
        const request = await sign.buildRequest(impl.user1, impl.engineInstance.address, data, txGas, nonce);
        const devChainId = 1;

        let signature = sign.signWithPk(signer1, impl.forwarderInstance.address, request, devChainId);
        //cmn.log('signature: ' + signature);

        // Execute meta-transaction
        let result = await impl.forwarderInstance.execute(request, signature, { from: impl.relayer });
        assert(result.receipt.status);

        // Add participation 2. using new participant & new partKey
        const nonce2 = await impl.forwarderInstance.getNonce(impl.user2);
        request.nonce = Number(nonce2);
        request.from = impl.user2;
        request.data = impl.engineInstance.contract.methods.addParticipationFromForwarder(1, impl.part2.responses, partKey2, txGas).encodeABI();
        signature = sign.signWithPk(signer2, impl.forwarderInstance.address, request, devChainId);

        result = await impl.forwarderInstance.execute(request, signature, { from: impl.relayer });
        assert(result.receipt.status);

        // Get participation
        let participation = (await impl.surveyInstance.getParticipations(1, 0, 1))[0];
        assert(participation.surveyId == 1);
        //cmn.log("Participation by survey ID and participation index: " + participation);

        let ownParticipation = (await impl.surveyInstance.getOwnParticipations(0, 1, { from: impl.user1 }))[0];
        assert(ownParticipation.surveyId == 1);
        //cmn.log("ownParticipation by index: " + ownParticipation);

        ownParticipation = await impl.surveyInstance.findOwnParticipation(1, { from: impl.user2 });
        assert(ownParticipation.surveyId == 1);
        //cmn.log("ownParticipation by survey ID: " + ownParticipation);

        // Check meta-transaction gas samples
        const samples = await impl.surveyInstance.txGasSamples(100);
        assert(samples.length == 2);

        const total = samples.reduce((a, b) => parseInt(a) + parseInt(b), 0);
        const avgTxGas = cmn.toBN(Math.round(total / samples.length));
        assert(avgTxGas.eq(txGas));
    });

    it('Add participation from No Forwarder', async () => {
        await addSurvey();

        try {
            await impl.engineInstance.addParticipationFromForwarder(1, impl.part1.responses, partKey1, txGas);
            assert.fail();
        } catch (e) {
            assert(e.message.indexOf('Forwardable: caller is not the forwarder') != -1);
        }
    });

    it('Execute meta-transaction from non-whitelisted address', async () => {
        await addSurvey();

        const data = impl.engineInstance.contract.methods.addParticipationFromForwarder(1, impl.part1.responses, partKey1, txGas).encodeABI();
        const nonce = await impl.forwarderInstance.getNonce(impl.user1);
        const request = await sign.buildRequest(impl.user1, impl.engineInstance.address, data, txGas, nonce);
        const devChainId = 1;

        let signature = sign.signWithPk(signer1, impl.forwarderInstance.address, request, devChainId);
        //cmn.log('signature: ' + signature);

        try {
            await impl.forwarderInstance.execute(request, signature);
            assert.fail();
        } catch (e) {
            assert(e.message.indexOf('INCForwarder: sender of meta-transaction is not whitelisted') != -1);
        }
    });

    it('Participate 2 times in the same survey', async () => {
        await addSurvey();

        const data = impl.engineInstance.contract.methods.addParticipationFromForwarder(1, impl.part1.responses, partKey1, txGas).encodeABI();
        const nonce = await impl.forwarderInstance.getNonce(impl.user1);
        const request = await sign.buildRequest(impl.user1, impl.engineInstance.address, data, txGas, nonce);
        const devChainId = 1;

        // Add participation 1
        let signature = sign.signWithPk(signer1, impl.forwarderInstance.address, request, devChainId);
        let result = await impl.forwarderInstance.execute(request, signature, { from: impl.relayer });
        assert(result.receipt.status);

        // Try add participation 2, using same participant
        const nonce2 = await impl.forwarderInstance.getNonce(impl.user1);
        request.nonce = Number(nonce2);
        signature = sign.signWithPk(signer1, impl.forwarderInstance.address, request, devChainId);

        try {
            await impl.forwarderInstance.execute(request, signature, { from: impl.relayer });
            assert.fail();
        } catch (e) {
            assert(e.message.indexOf('SurveyEngine: has already participated') != -1);
        }
    });

    it('Participate with invalid key', async () => {
        await addSurvey();

        const data = impl.engineInstance.contract.methods.addParticipationFromForwarder(1, impl.part1.responses, partKey1, txGas).encodeABI();
        const nonce = await impl.forwarderInstance.getNonce(impl.user1);
        const request = await sign.buildRequest(impl.user1, impl.engineInstance.address, data, txGas, nonce);
        const devChainId = 1;

        // Add participation 1
        let signature = sign.signWithPk(signer1, impl.forwarderInstance.address, request, devChainId);
        let result = await impl.forwarderInstance.execute(request, signature, { from: impl.relayer });
        assert(result.receipt.status);

        // Try add participation 2, using new participant & same partKey
        const nonce2 = await impl.forwarderInstance.getNonce(impl.user2);
        request.nonce = Number(nonce2);
        request.from = impl.user2;
        request.data = impl.engineInstance.contract.methods.addParticipationFromForwarder(1, impl.part2.responses, partKey1, txGas).encodeABI();
        signature = sign.signWithPk(signer2, impl.forwarderInstance.address, request, devChainId);

        try {
            await impl.forwarderInstance.execute(request, signature, { from: impl.relayer });
            assert.fail();
        } catch (e) {
            assert(e.message.indexOf('SurveyValidator: participation unauthorized') != -1);
        }

        // Try add participation 2, without partKey
        request.data = impl.engineInstance.contract.methods.addParticipationFromForwarder(1, impl.part2.responses, '', txGas).encodeABI();
        signature = sign.signWithPk(signer2, impl.forwarderInstance.address, request, devChainId);

        try {
            await impl.forwarderInstance.execute(request, signature, { from: impl.relayer });
            assert.fail();
        } catch (e) {
            assert(e.message.indexOf('SurveyValidator: participation unauthorized') != -1);
        }
    });

    it('Increase Gas Reserve', async () => {
        await addSurvey();

        // Check gas reserve
        const mGasReserve = await impl.surveyInstance.gasReserveOf(1);
        assert(cmn.toBN(mGasReserve).eq(gasReserve));

        // Increase gas reserve
        const extraGasReserve = cmn.toUnits(1);
        const result = await impl.engineInstance.increaseGasReserve(1, { from: impl.creator, value: extraGasReserve });
        assert(result.receipt.status);

        // Check the gas reserve again
        const newGasReserve = await impl.surveyInstance.gasReserveOf(1);
        assert(cmn.toBN(newGasReserve).eq(gasReserve.add(cmn.toBN(extraGasReserve))));
    });

    it('Solve survey', async () => {
        await addSurvey();

        const creatorETHBalanceBefore = await web3.eth.getBalance(impl.creator);
        const creatorINCBalanceBefore = await impl.tokenInstance.balanceOf(impl.creator);
        const engineINCBalanceBefore = await impl.tokenInstance.balanceOf(impl.engineInstance.address);

        // Check engine INC balance before solving the survey
        assert(cmn.toBN(engineINCBalanceBefore).eq(cmn.toBN(impl.survey.budget)));

        // Solve the survey
        const result = await impl.engineInstance.solveSurvey(1, { from: impl.creator });
        assert(result.receipt.status);

        const creatorETHBalanceAfter = await web3.eth.getBalance(impl.creator);
        const creatorINCBalanceAfter = await impl.tokenInstance.balanceOf(impl.creator);
        const engineINCBalanceAfter = await impl.tokenInstance.balanceOf(impl.engineInstance.address);

        // Check the ETH and INC balance of the creator after solving the survey
        const gasUsed = cmn.toBN(result.receipt.gasUsed).mul(impl.gasPrice);
        const ethDiff = cmn.toBN(creatorETHBalanceAfter).sub(cmn.toBN(creatorETHBalanceBefore)).add(gasUsed);
        assert(ethDiff.eq(cmn.toBN(gasReserve)));

        const incDiff = cmn.toBN(creatorINCBalanceAfter).sub(cmn.toBN(creatorINCBalanceBefore));
        assert(incDiff.eq(cmn.toBN(impl.survey.budget)));

        // Check engine INC balance after solving the survey
        assert(engineINCBalanceAfter == 0);

        // Check remaining budget
        const remainingBudget = await impl.surveyInstance.remainingBudgetOf(1);
        assert(remainingBudget == 0);

        // Check gas reserve
        const mGasReserve = await impl.surveyInstance.gasReserveOf(1);
        assert(mGasReserve == 0);
    });

    it('Migrate', async () => {
        await addSurvey();

        // Migrate to the new engine
        const newEngineInstance = await NewEngine.new(impl.tokenInstance.address, impl.currencyInstance.address, impl.surveyInstance.address);
        const result = await impl.engineInstance.migrate(newEngineInstance.address);
        assert(result.receipt.status);

        const newEngineBalance = await impl.tokenInstance.balanceOf(newEngineInstance.address);
        assert(newEngineBalance.eq(cmn.toBN(impl.survey.budget)));
    });

});
