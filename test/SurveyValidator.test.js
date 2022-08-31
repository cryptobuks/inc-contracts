const cmn = require("./shared/common");
const impl = require("./shared/contracts-impl");

contract('SurveyValidator', (accounts) => {

  const user1 = accounts[1];
  const partHashes = ['8e6e4f84', '075e4130'];
  const partKey1 = '41f61133-1ef0-45d3-ad25-79520feef388';
  const partKey2 = '03aedda1-5b0b-47a7-a043-05ce7c1ed11b';

  let validatorInstance;

  beforeEach(async () => {
    validatorInstance = await cmn.newSurveyValidator();
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

  it('checkAuthorization', async () => {
    const manager = await validatorInstance.manager();
    await validatorInstance.checkAuthorization(partHashes, partKey1, { from: manager });
    await validatorInstance.checkAuthorization(partHashes, partKey2, { from: manager });

    try {
      await validatorInstance.checkAuthorization(partHashes, partKey1, { from: user1 });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('Manageable: caller is not the manager') != -1);
    }
  });

});
