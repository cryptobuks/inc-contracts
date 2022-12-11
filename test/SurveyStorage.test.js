const impl = require("./shared/contracts-impl");
const cmn = require("./shared/common");
const time = require('./shared/time');
const { HOUR_SECONDS } = require("../constants");

contract('SurveyStorage', (accounts) => {

  const numSurveys = 15;
  const numParts = 6;
  let addrs;
  let rmngParts;

  before(async () => {
    await impl.init(accounts);

    addrs = await impl.addDefaultSurveys(numSurveys);

    // Advance the time for the survey to be open
    await time.increase(HOUR_SECONDS);

    await impl.addDefaultParticipations(addrs[0], numParts);
    await impl.addDefaultParticipations(addrs[1], numParts);
    await impl.addDefaultParticipations(addrs[2], numParts);
    await impl.addDefaultParticipations(addrs[3], numParts);
    await impl.addDefaultParticipations(addrs[4], numParts);
    rmngParts = impl.maxParts - numParts;
  });

  after(async () => {
    await impl.revert();
  });

  it('exists', async () => {
    const exists = await impl.storageInstance.exists(addrs[0]);
    assert(exists === true);
  });

  it('txGasSamples', async () => {
    const samples = await impl.storageInstance.txGasSamples(100);
    assert(samples.length == 0);
  });

  it('remainingBudgetOf', async () => {
    const remainingBudget = await impl.storageInstance.remainingBudgetOf(addrs[0]);

    let currBudget = cmn.toBN(impl.survey.budget).sub(cmn.toBN(impl.survey.reward).muln(numParts));
    assert(cmn.toBN(remainingBudget).eq(currBudget));

    currBudget = cmn.toBN(impl.survey.reward).muln(rmngParts);
    assert(cmn.toBN(remainingBudget).eq(currBudget));
  });

  it('remainingGasReserveOf', async () => {
    // The gas reserve has not been spent, as there have been no financed participations.
    const gasReserve = await impl.storageInstance.remainingGasReserveOf(addrs[0]);
    const txGas = await impl.getAvgTxGas();
    const currReserve = impl.gasPrice.mul(txGas).muln(impl.maxParts);
    assert(cmn.toBN(gasReserve).eq(currReserve));
  });

  it('getSurveysLength', async () => {
    const surveysLength = await impl.storageInstance.getSurveysLength();
    assert(surveysLength == numSurveys);
  });

  it('getSurveys', async () => {
    let cursor = 0;
    let length = 5;
    let surveys = await impl.storageInstance.getSurveys(cursor, length);

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], addrs[cursor + i]);
    }

    cursor = 5;
    surveys = await impl.storageInstance.getSurveys(cursor, length);

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], addrs[cursor + i]);
    }

    cursor = 10;
    surveys = await impl.storageInstance.getSurveys(cursor, length);

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], addrs[cursor + i]);
    }
  });

  it('findSurvey', async () => {
    const survey = await impl.storageInstance.findSurvey(addrs[0]);
    assert(survey.surveyOwner == impl.creator);
    assert(!survey.keyRequired);
    impl.checkSurvey(survey, addrs[0]);
  });

  it('isOpenedSurvey', async () => {
    let isOpened = await impl.storageInstance.isOpenedSurvey(addrs[0], 0);
    assert(isOpened);

    let offset = impl.survey.endTime - impl.survey.startTime - HOUR_SECONDS;
    isOpened = await impl.storageInstance.isOpenedSurvey(addrs[0], offset);
    assert(isOpened);

    offset = impl.survey.endTime - impl.survey.startTime;
    isOpened = await impl.storageInstance.isOpenedSurvey(addrs[0], offset);
    assert(!isOpened);
  });

  it('getOwnSurveysLength', async () => {
    let surveysLength = await impl.storageInstance.getOwnSurveysLength({ from: impl.creator });
    assert(surveysLength == numSurveys);

    surveysLength = await impl.storageInstance.getOwnSurveysLength({ from: impl.user1 });
    assert(surveysLength == 0);
  });

  it('getOwnSurveys', async () => {
    let survey = (await impl.storageInstance.getOwnSurveys(0, 1, { from: impl.creator }))[0];
    impl.checkSurvey(survey, addrs[0]);

    survey = (await impl.storageInstance.getOwnSurveys(10, 1, { from: impl.creator }))[0];
    impl.checkSurvey(survey, addrs[10]);

    try {
      await impl.storageInstance.getOwnSurveys(0, 1, { from: impl.user1 });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyStorage: cursor out of range') != -1);
    }

    let cursor = 0;
    let length = 5;
    let surveys = await impl.storageInstance.getOwnSurveys(cursor, length, { from: impl.creator });

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], addrs[cursor + i]);
    }

    cursor = 5;
    surveys = await impl.storageInstance.getOwnSurveys(cursor, length, { from: impl.creator });

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], addrs[cursor + i]);
    }

    cursor = 10;
    surveys = await impl.storageInstance.getOwnSurveys(cursor, length, { from: impl.creator });

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], addrs[cursor + i]);
    }

    try {
      await impl.storageInstance.getOwnSurveys(0, 10, { from: impl.user1 });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyStorage: cursor out of range') != -1);
    }
  });

  it('getParticipantsLength', async () => {
    const participantsLength = await impl.storageInstance.getParticipantsLength(addrs[0]);
    assert(participantsLength == numParts);
  });

  it('getParticipants', async () => {
    let participant = (await impl.storageInstance.getParticipants(addrs[0], 0, 1))[0];
    assert(participant == impl.user1);

    participant = (await impl.storageInstance.getParticipants(addrs[0], 1, 1))[0];
    assert(participant == impl.user2);

    let cursor = 0;
    let length = 4;
    let participants = await impl.storageInstance.getParticipants(addrs[0], cursor, length);

    assert(participants.length == length);
    for (let i = 0; i < participants.length; i++) {
      assert(participants[i] == accounts[cursor + i + 3]);// the first 3 accounts are used for another purpose
    }

    cursor = 3;
    length = 3;
    participants = await impl.storageInstance.getParticipants(addrs[0], cursor, length);

    assert(participants.length == length);
    for (let i = 0; i < participants.length; i++) {
      assert(participants[i] == accounts[cursor + i + 3]);
    }
  });

  it('isParticipant', async () => {
    const isParticipant = await impl.storageInstance.isParticipant(addrs[0], impl.user1);
    assert(isParticipant);
  });

  it('getParticipationsTotal', async () => {
    const participantsTotal = await impl.storageInstance.getParticipationsTotal();
    assert(participantsTotal == numParts * 5);
  });

  it('getGlobalParticipations', async () => {
    let participation = (await impl.storageInstance.getGlobalParticipations(0, 1))[0];
    assert(participation.surveyAddr == addrs[0]);
    assert(participation.responses.length == impl.questions.length);

    participation = (await impl.storageInstance.getGlobalParticipations(numParts, 1))[0];
    assert(participation.surveyAddr == addrs[1]);
    assert(participation.responses.length == impl.questions.length);

    let cursor = 0;
    let length = numParts * 5;
    let participations = await impl.storageInstance.getGlobalParticipations(0, length);
    assert(participations.length == length);
    
    cursor = 0;
    length = 4;
    participations = await impl.storageInstance.getGlobalParticipations(cursor, length);

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyAddr == addrs[0]);
      assert(participations[i].responses.length == impl.questions.length);
    }

    cursor = 3;
    length = 3;
    participations = await impl.storageInstance.getGlobalParticipations(cursor, length);

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyAddr == addrs[0]);
      assert(participations[i].responses.length == impl.questions.length);
    }
  });

  it('getParticipations', async () => {
    let participation = (await impl.storageInstance.getParticipations(addrs[0], 0, 1))[0];
    assert(participation.surveyAddr == addrs[0]);
    assert(participation.responses.length == impl.questions.length);

    participation = (await impl.storageInstance.getParticipations(addrs[1], 1, 1))[0];
    assert(participation.surveyAddr == addrs[1]);
    assert(participation.responses.length == impl.questions.length);
    
    let cursor = 0;
    let length = numParts;
    let participations = await impl.storageInstance.getParticipations(addrs[0], cursor, length);
    assert(participations.length == length);

    cursor = 0;
    length = 4;
    participations = await impl.storageInstance.getParticipations(addrs[0], cursor, length);

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyAddr == addrs[0]);
      assert(participations[i].responses.length == impl.questions.length);
    }

    cursor = 3;
    length = 3;
    participations = await impl.storageInstance.getParticipations(addrs[2], cursor, length);

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyAddr == addrs[2]);
      assert(participations[i].responses.length == impl.questions.length);
    }
  });

  it('findParticipation', async () => {
    let participation = await impl.storageInstance.findParticipation(addrs[0], impl.user1);
    assert(participation.surveyAddr == addrs[0]);
    assert(participation.responses.length == impl.questions.length);

    participation = await impl.storageInstance.findParticipation(addrs[0], impl.user2);
    assert(participation.surveyAddr == addrs[0]);
    assert(participation.responses.length == impl.questions.length);
  });

  it('getOwnParticipationsLength', async () => {
    let participationsLength = await impl.storageInstance.getOwnParticipationsLength({ from: impl.user1 });
    assert(participationsLength == 5);

    participationsLength = await impl.storageInstance.getOwnParticipationsLength({ from: impl.owner });
    assert(participationsLength == 0);
  });

  it('getOwnParticipations', async () => {
    let participation = (await impl.storageInstance.getOwnParticipations(0, 1, { from: impl.user1 }))[0];
    assert(participation.surveyAddr == addrs[0]);

    participation = (await impl.storageInstance.getOwnParticipations(4, 1, { from: impl.user1 }))[0];
    assert(participation.surveyAddr == addrs[4]);

    try {
      await impl.storageInstance.getOwnParticipations(0, 1, { from: impl.owner });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyStorage: cursor out of range') != -1);
    }

    let cursor = 0;
    let length = 3;
    let participations = await impl.storageInstance.getOwnParticipations(cursor, length, { from: impl.user1 });

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyAddr == addrs[cursor + i]);
    }

    cursor = 3;
    length = 2;
    participations = await impl.storageInstance.getOwnParticipations(cursor, length, { from: impl.user1 });

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyAddr == addrs[cursor + i]);
    }

    try {
      await impl.storageInstance.getOwnParticipations(0, 10, { from: impl.owner });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyStorage: cursor out of range') != -1);
    }
  });

  it('findOwnParticipation', async () => {
    let participation = await impl.storageInstance.findOwnParticipation(addrs[0], { from: impl.user1 });
    assert(participation.surveyAddr == addrs[0]);
    assert(participation.responses.length == impl.questions.length);

    participation = await impl.storageInstance.findOwnParticipation(addrs[1], { from: impl.user2 });
    assert(participation.surveyAddr == addrs[1]);
    assert(participation.responses.length == impl.questions.length);
  });

  it('getQuestionsLength', async () => {
    const questionsLength = await impl.storageInstance.getQuestionsLength(addrs[0]);
    assert(questionsLength == impl.questions.length);
  });

  it('getQuestions', async () => {
    let question = (await impl.storageInstance.getQuestions(addrs[0], 0, 1))[0];
    impl.checkQuestion(question, 0);

    question = (await impl.storageInstance.getQuestions(addrs[0], 1, 1))[0];
    impl.checkQuestion(question, 1);

    let cursor = 0;
    let length = 2;
    let questions = await impl.storageInstance.getQuestions(addrs[0], cursor, length);

    assert(questions.length == length);
    for (let i = 0; i < questions.length; i++) {
      impl.checkQuestion(questions[i], (cursor + i));
    }

    cursor = 2;
    length = 1;
    questions = await impl.storageInstance.getQuestions(addrs[0], cursor, length);

    assert(questions.length == length);
    for (let i = 0; i < questions.length; i++) {
      impl.checkQuestion(questions[i], (cursor + i));
    }
  });

  it('getResponses', async () => {
    let cursor = 0;
    let length = 4;
    let responses = await impl.storageInstance.getResponses(addrs[0], 0, cursor, length);
    assert(responses.length == length);

    cursor = 4;
    length = 2;
    responses = await impl.storageInstance.getResponses(addrs[0], 0, cursor, length);
    assert(responses.length == length);
  });

  it('getResponseCounts', async () => {
    await impl.engineInstance.addParticipation(addrs[0], impl.part2.responses, '', { from: impl.accounts[9] });

    let responses = await impl.storageInstance.getResponseCounts(addrs[0], 0);
    assert(responses.length == 0);

    responses = await impl.storageInstance.getResponseCounts(addrs[0], 3);
    assert(responses.length == 2);
    assert(responses[0].count == numParts);
    assert(responses[1].count == 1);
  });

  it('getValidators', async () => {
    let validators = await impl.storageInstance.getValidators(addrs[0], 0);
    let filtered = impl.validators.filter(v => v.questionIndex === 0);
    assert(validators.length == filtered.length);
  });

});