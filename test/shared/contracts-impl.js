const cmn = require("./common");
const time = require('./time');
const { MAX_UINT256, DAY_SECONDS, HOUR_SECONDS } = require("../../constants");

class ContractsImpl {

    incAmountForCreator = 10000;
    wethAmountForRelayer = 10;

    snapshotId;
    owner;
    relayer;
    creator;
    user1;
    user2;
    accounts;

    tokenInstance;
    currencyInstance;
    offerInstance;
    factoryInstance;
    validatorInstance;
    configInstance;
    storageInstance;
    engineInstance;
    forwarderInstance;

    gasPrice;
    maxParts;
    fee;

    survey = {
        title: 'Survey on the blockchain',
        description: 'Welcome to our survey on the blockchain. This allows the creation of a safe and transparent market with original products sold at fair prices.',
        logoUrl: '',
        startTime: cmn.openingTime + HOUR_SECONDS,
        endTime: cmn.openingTime + HOUR_SECONDS + DAY_SECONDS * 7,
        budget: cmn.toUnits(100),
        reward: cmn.toUnits(10),
        token: undefined
    };

    questions = [
        {
            content: "Hello what is your name?",// is json with component details
            mandatory: true,
            responseType: 1// Text
        },
        {
            content: "How old are you?",
            mandatory: true,
            responseType: 2// Number
        },
        {
            content: "Tell us something about yourself?",
            mandatory: true,
            responseType: 1// Text
        },
        {
            content: "You like sports?",
            mandatory: true,
            responseType: 0// Bool
        }
    ];

    validators = [
        {
            questionIndex: 0,
            operator: 0,// None
            expression: 10,// NotContainsIgnoreCase
            value: 'hitler'
        },
        {
            questionIndex: 0,
            operator: 1,// And
            expression: 16,// NotContainsDigits
            value: ''
        },
        {
            questionIndex: 1,
            operator: 0,// None
            expression: 12,// GreaterEquals
            value: '18'
        },
        {
            questionIndex: 1,
            operator: 1,// And
            expression: 14,// LessEquals
            value: '120'
        },
        {
            questionIndex: 2,
            operator: 0,// None
            expression: 17,// MinLength
            value: '100'
        },
        {
            questionIndex: 2,
            operator: 1,// And
            expression: 18,// MaxLength
            value: '1000'
        }
    ];

    part1 = {
        responses: [
            'David',
            '35',
            'I consider myself a cheerful, hard-working person, I like to work in a team, formal, responsible, I like to help my colleagues.',
            'true'
        ]
    };

    part2 = {
        responses: [
            'Alyson',
            '28',
            'I am a cheerful and hard-working person, I like punctuality and I am responsible. I love to read, travel, go to the movies, do crafts and I always try to do some sport.',
            'false'
        ]
    };

    init = async (accounts) => {
        // Take a snapshot
        const snapShot = await time.takeSnapshot();
        this.snapshotId = snapShot['result'];

        this.owner = accounts[0];
        this.relayer = accounts[1];
        this.creator = accounts[2];
        this.user1 = accounts[3];
        this.user2 = accounts[4];
        this.accounts = accounts;

        // Create contract instances
        this.tokenInstance = await cmn.newINCToken();
        this.currencyInstance = await cmn.newWrappedToken();
        this.offerInstance = await cmn.newTokenOffer(this.tokenInstance.address);
        this.factoryInstance = await cmn.newSurveyFactory();
        this.validatorInstance = await cmn.newSurveyValidator();
        this.configInstance = await cmn.newSurveyConfig(this.factoryInstance.address, this.validatorInstance.address);
        this.storageInstance = await cmn.newSurveyStorage(this.configInstance.address);
        this.forwarderInstance = await cmn.newINCForwarder();
        this.engineInstance = await cmn.newSurveyEngine(this.currencyInstance.address, this.configInstance.address, this.storageInstance.address, this.forwarderInstance.address);

        // assign manager for contracts
        await this.storageInstance.setManager(this.engineInstance.address);
        await this.factoryInstance.setManager(this.storageInstance.address);
        await this.forwarderInstance.setManager(this.relayer);

        // set token to survey
        this.survey.token = this.tokenInstance.address;

        // add relayer to white list
        await this.forwarderInstance.addSenderToWhitelist(this.relayer);

        // approve tokens for offer contract
        await this.tokenInstance.approve(this.offerInstance.address, cmn.initialOffer, { from: this.owner });

        // relayer approvation for SurveyEngine to send WETH
        await this.currencyInstance.approve(this.engineInstance.address, MAX_UINT256, { from: this.relayer });

        // creator approvation for SurveyEngine to send tokens
        await this.tokenInstance.approve(this.engineInstance.address, MAX_UINT256, { from: this.creator });

        // Advance the time for the offer to be open
        await time.increaseTo(cmn.openingTime);

        // get tokens for survey creator
        let weiAmount = cmn.tokenPrice(this.incAmountForCreator);// initial INC approximately
        await this.offerInstance.sendTransaction({ from: this.creator, value: weiAmount });

        // get WETH for relayer
        weiAmount = cmn.toUnits(this.wethAmountForRelayer);// initial WETH
        await this.currencyInstance.deposit({ from: this.relayer, value: weiAmount });

        // set parameters to calculate survey wei
        this.gasPrice = cmn.toBN(await web3.eth.getGasPrice());
        this.maxParts = cmn.toBN(this.survey.budget).div(cmn.toBN(this.survey.reward)).toNumber();
        this.fee = cmn.toBN(await this.configInstance.fee()).muln(this.maxParts);
    };

    revert = async () => {
        // Revert to original state
        await time.revertToSnapShot(this.snapshotId);
    };

    addDefaultSurvey = async () => {
        const txGas = await this.getAvgTxGas();
        const gasReserve = this.gasPrice.mul(txGas).muln(this.maxParts);
        const weiForSurvey = gasReserve.add(this.fee);// gas reserve + fee

        const result = await this.engineInstance.addSurvey(this.survey, this.questions, this.validators, [], { from: this.creator, value: weiForSurvey });
        return result.logs[1].args.surveyAddr;
    }

    addDefaultSurveys = async (num) => {
        const addrs = [];
        for (let i = 0; i < num; i++) {
            let addr = await this.addDefaultSurvey();
            addrs.push(addr);
        }
        return addrs;
    };

    addDefaultParticipation = async (surveyAddr, participant) => {
        return await this.engineInstance.addParticipation(surveyAddr, this.part1.responses, '', { from: participant });
    }

    addDefaultParticipations = async (surveyAddr, num) => {
        if (num > 7) {
            throw new Error('There are only 10 accounts, the first 3 are used for another purpose');
        }

        for (let i = 0; i < num; i++) {
            await this.addDefaultParticipation(surveyAddr, this.accounts[i + 3]);
        }
    };

    getAvgTxGas = async () => {
        const samples = await this.storageInstance.txGasSamples(100);
        if (samples.length == 0)
          return cmn.toBN(3000000);// Default value

        const total = samples.reduce((a, b) => parseInt(a) + parseInt(b), 0);
        return cmn.toBN(Math.round(total / samples.length));
    };

    checkSurvey = (survey, surveyAddr) => {
        assert(survey.addr == surveyAddr);
        assert(survey.title == this.survey.title);
        assert(survey.description == this.survey.description);
        assert(survey.startTime == this.survey.startTime);
        assert(survey.endTime == this.survey.endTime);
        assert(cmn.toBN(survey.budget).eq(cmn.toBN(this.survey.budget)));
        assert(cmn.toBN(survey.reward).eq(cmn.toBN(this.survey.reward)));
        assert(survey.token == this.survey.token);
    };

    checkQuestion = (question, index) => {
        assert(question.content == this.questions[index].content);
        assert(question.mandatory == this.questions[index].mandatory);
        assert(question.responseType == this.questions[index].responseType);
    };
}

module.exports = new ContractsImpl();