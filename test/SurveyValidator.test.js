const cmn = require("./shared/common");
const impl = require("./shared/contracts-impl");
const ERC20Test = artifacts.require('ERC20Test');

contract('SurveyValidator', (accounts) => {

  const partHashes = ['8e6e4f84', '075e4130'];

  let tokenInstance;
  let unsupTokenInstance1;
  let unsupTokenInstance2;
  let unsupTokenInstance3;
  let validatorInstance;

  before(async () => {
    tokenInstance = await cmn.newINCToken();
    unsupTokenInstance1 = await ERC20Test.new('', '', cmn.tokenTotal);
    unsupTokenInstance2 = await ERC20Test.new('token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name token name', 'token symbol', cmn.tokenTotal);
    unsupTokenInstance3 = await ERC20Test.new('token name', 'token symbol token symbol token symbol token symbol token symbol token symbol token symbol token symbol', cmn.tokenTotal);
    validatorInstance = await cmn.newSurveyValidator();
    // Set token address
    impl.survey.token = tokenInstance.address;
  });

  after(async () => {
    // Revert token address
    impl.survey.token = tokenInstance.address;
  });

  it('checkSurvey', async () => {
    await validatorInstance.checkSurvey(impl.survey, impl.questions, impl.validators, []);

    try {
      await validatorInstance.checkSurvey(impl.survey, impl.questions, impl.validators, partHashes);
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyValidator: incorrect number of hashes') != -1);
    }

    // Reduce the number of participations to 2
    const newSurvey = cmn.clone(impl.survey);
    newSurvey.reward = cmn.toBN(newSurvey.budget).divn(2).toString();
    await validatorInstance.checkSurvey(newSurvey, impl.questions, impl.validators, partHashes);
  });

  it('checkResponse', async () => {
    let validators = impl.validators.filter(v => v.questionIndex === 0);
    await validatorInstance.checkResponse(impl.questions[0], validators, impl.part1.responses[0]);

    validators = impl.validators.filter(v => v.questionIndex === 1);
    await validatorInstance.checkResponse(impl.questions[1], validators, impl.part1.responses[1]);

    validators = impl.validators.filter(v => v.questionIndex === 2);
    await validatorInstance.checkResponse(impl.questions[2], validators, impl.part1.responses[2]);

    try {
      validators = impl.validators.filter(v => v.questionIndex === 0);
      await validatorInstance.checkResponse(impl.questions[0], validators, '');
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyValidator: mandatory response empty') != -1);
    }

    try {
      validators = impl.validators.filter(v => v.questionIndex === 1);
      await validatorInstance.checkResponse(impl.questions[1], validators, 'xxx');// A number is required
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyValidator: invalid response type') != -1);
    }
  });

  it('checkSurvey with unsupported token', async () => {
    impl.survey.token = unsupTokenInstance1.address;

    try {
      await validatorInstance.checkSurvey(impl.survey, impl.questions, impl.validators, partHashes);
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyValidator: empty token symbol') != -1);
    }

    impl.survey.token = unsupTokenInstance2.address;

    try {
      await validatorInstance.checkSurvey(impl.survey, impl.questions, impl.validators, partHashes);
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyValidator: invalid token name') != -1);
    }

    impl.survey.token = unsupTokenInstance3.address;

    try {
      await validatorInstance.checkSurvey(impl.survey, impl.questions, impl.validators, partHashes);
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyValidator: invalid token symbol') != -1);
    }
  });

  it('checkSurvey with fake token', async () => {
    impl.survey.token = validatorInstance.address;

    try {
      await validatorInstance.checkSurvey(impl.survey, impl.questions, impl.validators, partHashes);
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyValidator: no token symbol') != -1);
    }
  });

});