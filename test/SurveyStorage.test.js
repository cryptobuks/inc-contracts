const impl = require("./shared/contracts-impl");
const cmn = require("./shared/common");
const time = require('./shared/time');
const { HOUR_SECONDS } = require("../constants");

contract('SurveyStorage', (accounts) => {

  const numSurveys = 15;
  const numParts = 7;
  let rmngParts;
  let secSnapshotId;

  before(async () => {
    await impl.init(accounts);

    await impl.addDefaultSurveys(numSurveys);

    // Advance the time for the survey to be open
    await time.increase(HOUR_SECONDS);

    await impl.addDefaultParticipations(1, numParts);
    await impl.addDefaultParticipations(2, numParts);
    await impl.addDefaultParticipations(3, numParts);
    await impl.addDefaultParticipations(4, numParts);
    await impl.addDefaultParticipations(5, numParts);
    rmngParts = impl.maxParts - numParts;
  });

  after(async () => {
    await impl.revert();
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

  it('currentCursor', async () => {
    const rangeMaxTime = await impl.validatorInstance.rangeMaxTime();
    let cursor = await impl.surveyInstance.currentCursor(rangeMaxTime);
    assert(cursor == 0);

    // Advance the time to close all surveys
    // Time has already advanced an hour after creating the surveys
    const duration = impl.survey.endTime - impl.survey.startTime;
    await time.increase(duration);

    cursor = await impl.surveyInstance.currentCursor(duration);
    assert(cursor == numSurveys);
  });

  it('txGasSamples', async () => {
    const samples = await impl.surveyInstance.txGasSamples(100);
    assert(samples.length == 0);
  });

  it('remainingBudgetOf', async () => {
    const remainingBudget = await impl.surveyInstance.remainingBudgetOf(1);

    let currBudget = cmn.toBN(impl.survey.budget).sub(cmn.toBN(impl.survey.reward).muln(numParts));
    assert(cmn.toBN(remainingBudget).eq(currBudget));

    currBudget = cmn.toBN(impl.survey.reward).muln(rmngParts);
    assert(cmn.toBN(remainingBudget).eq(currBudget));
  });

  it('gasReserveOf', async () => {
    // The gas reserve has not been spent, as there have been no financed participations.
    const gasReserve = await impl.surveyInstance.gasReserveOf(1);
    const txGas = await impl.getAvgTxGas();
    const currReserve = impl.gasPrice.mul(txGas).muln(impl.maxParts);
    assert(cmn.toBN(gasReserve).eq(currReserve));
  });

  it('keyRequiredOf', async () => {
    const keyRequired = await impl.surveyInstance.keyRequiredOf(1);
    assert(!keyRequired);
  });

  it('ownerOf', async () => {
    const surveyOwner = await impl.surveyInstance.ownerOf(1);
    assert(surveyOwner == impl.creator);
  });

  it('findSurveyData', async () => {
    const surveyData = await impl.surveyInstance.findSurveyData(1);
    assert(surveyData.owner == impl.creator);
    assert(!surveyData.keyRequired);

    const currBudget = cmn.toBN(impl.survey.reward).muln(rmngParts);
    assert(cmn.toBN(surveyData.remainingBudget).eq(currBudget));

    const txGas = await impl.getAvgTxGas();
    const currReserve = impl.gasPrice.mul(txGas).muln(impl.maxParts);
    assert(cmn.toBN(surveyData.gasReserve).eq(currReserve));
  });

  it('getSurveysLength', async () => {
    const surveysLength = await impl.surveyInstance.getSurveysLength();
    assert(surveysLength == numSurveys);
  });

  it('findSurvey', async () => {
    const survey = await impl.surveyInstance.findSurvey(1);
    impl.checkSurvey(survey, 1);
  });

  it('getSurveys', async () => {
    let cursor = 0;
    let length = 5;
    let surveys = await impl.surveyInstance.getSurveys(cursor, length);

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], (cursor + i + 1));
    }

    cursor = 5;
    surveys = await impl.surveyInstance.getSurveys(cursor, length);

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], (cursor + i + 1));
    }

    cursor = 10;
    surveys = await impl.surveyInstance.getSurveys(cursor, length);

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], (cursor + i + 1));
    }
  });

  it('findSurveys', async () => {
    let titleIndex = Math.round(impl.survey.title.length / 3);
    let textToSearch = impl.survey.title.substring(titleIndex, titleIndex * 2);

    let cursor = 10;
    let length = 5;
    let filter = {
      search: textToSearch,
      onlyPublic: true,
      withRmngBudget: true,
      minStartTime: 0,
      maxStartTime: 0,
      minEndTime: 0,
      maxEndTime: 0,
      minBudget: '0',
      minReward: '0',
      minGasReserve: '0'
    };

    let surveys = await impl.surveyInstance.findSurveys(cursor, length, filter);
    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], (cursor + i + 1));
    }
  });

  it('isOpenedSurvey', async () => {
    let isOpened = await impl.surveyInstance.isOpenedSurvey(1, 0);
    assert(isOpened);

    let offset = impl.survey.endTime - impl.survey.startTime - HOUR_SECONDS;
    isOpened = await impl.surveyInstance.isOpenedSurvey(1, offset);
    assert(isOpened);

    offset = impl.survey.endTime - impl.survey.startTime;
    isOpened = await impl.surveyInstance.isOpenedSurvey(1, offset);
    assert(!isOpened);
  });

  it('getOwnSurveysLength', async () => {
    let surveysLength = await impl.surveyInstance.getOwnSurveysLength({ from: impl.creator });
    assert(surveysLength == numSurveys);

    surveysLength = await impl.surveyInstance.getOwnSurveysLength({ from: impl.user1 });
    assert(surveysLength == 0);
  });

  it('getOwnSurveys', async () => {
    let survey = (await impl.surveyInstance.getOwnSurveys(0, 1, { from: impl.creator }))[0];
    impl.checkSurvey(survey, 1);

    survey = (await impl.surveyInstance.getOwnSurveys(10, 1, { from: impl.creator }))[0];
    impl.checkSurvey(survey, 11);

    try {
      await impl.surveyInstance.getOwnSurveys(0, 1, { from: impl.user1 });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyBase: cursor out of range') != -1);
    }

    let cursor = 0;
    let length = 5;
    let surveys = await impl.surveyInstance.getOwnSurveys(cursor, length, { from: impl.creator });

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], (cursor + i + 1));
    }

    cursor = 5;
    surveys = await impl.surveyInstance.getOwnSurveys(cursor, length, { from: impl.creator });

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], (cursor + i + 1));
    }

    cursor = 10;
    surveys = await impl.surveyInstance.getOwnSurveys(cursor, length, { from: impl.creator });

    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], (cursor + i + 1));
    }

    try {
      await impl.surveyInstance.getOwnSurveys(0, 10, { from: impl.user1 });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyBase: cursor out of range') != -1);
    }
  });

  it('findOwnSurveys', async () => {
    let cursor = 10;
    let length = 5;
    let filter = {
      search: impl.survey.title,
      onlyPublic: true,
      withRmngBudget: true,
      minStartTime: 0,
      maxStartTime: 0,
      minEndTime: 0,
      maxEndTime: 0,
      minBudget: '0',
      minReward: '0',
      minGasReserve: '0'
    };

    let surveys = await impl.surveyInstance.findOwnSurveys(cursor, length, filter, { from: impl.creator });
    assert(surveys.length == length);
    for (let i = 0; i < surveys.length; i++) {
      impl.checkSurvey(surveys[i], (cursor + i + 1));
    }

    try {
      await impl.surveyInstance.findOwnSurveys(0, 10, filter, { from: impl.user1 });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyBase: cursor out of range') != -1);
    }
  });

  it('getParticipantsLength', async () => {
    const participantsLength = await impl.surveyInstance.getParticipantsLength(1);
    assert(participantsLength == numParts);
  });

  it('getParticipants', async () => {
    let participant = (await impl.surveyInstance.getParticipants(1, 0, 1))[0];
    assert(participant == impl.user1);

    participant = (await impl.surveyInstance.getParticipants(1, 1, 1))[0];
    assert(participant == impl.user2);

    let cursor = 0;
    let length = 4;
    let participants = await impl.surveyInstance.getParticipants(1, cursor, length);

    assert(participants.length == length);
    for (let i = 0; i < participants.length; i++) {
      assert(participants[i] == accounts[cursor + i + 3]);// the first 3 accounts are used for another purpose
    }

    cursor = 3;
    participants = await impl.surveyInstance.getParticipants(1, cursor, length);

    assert(participants.length == length);
    for (let i = 0; i < participants.length; i++) {
      assert(participants[i] == accounts[cursor + i + 3]);
    }
  });

  it('isParticipant', async () => {
    const isParticipant = await impl.surveyInstance.isParticipant(1, impl.user1);
    assert(isParticipant);
  });

  it('getParticipations', async () => {
    let participation = (await impl.surveyInstance.getParticipations(1, 0, 1))[0];
    assert(participation.surveyId == 1);
    assert(participation.responses.length == impl.questions.length);

    participation = (await impl.surveyInstance.getParticipations(1, 1, 1))[0];
    assert(participation.surveyId == 1);
    assert(participation.responses.length == impl.questions.length);
    
    let cursor = 0;
    let length = 4;
    let participations = await impl.surveyInstance.getParticipations(1, cursor, length);

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyId == 1);
      assert(participations[i].responses.length == impl.questions.length);
    }

    cursor = 3;
    participations = await impl.surveyInstance.getParticipations(1, cursor, length);

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyId == 1);
      assert(participations[i].responses.length == impl.questions.length);
    }
  });

  it('findParticipation', async () => {
    let participation = await impl.surveyInstance.findParticipation(1, impl.user1);
    assert(participation.surveyId == 1);
    assert(participation.responses.length == impl.questions.length);

    participation = await impl.surveyInstance.findParticipation(1, impl.user2);
    assert(participation.surveyId == 1);
    assert(participation.responses.length == impl.questions.length);
  });

  it('getOwnParticipationsLength', async () => {
    let participationsLength = await impl.surveyInstance.getOwnParticipationsLength({ from: impl.user1 });
    assert(participationsLength == 5);

    participationsLength = await impl.surveyInstance.getOwnParticipationsLength({ from: impl.owner });
    assert(participationsLength == 0);
  });

  it('getOwnParticipations', async () => {
    let participation = (await impl.surveyInstance.getOwnParticipations(0, 1, { from: impl.user1 }))[0];
    assert(participation.surveyId == 1);

    participation = (await impl.surveyInstance.getOwnParticipations(4, 1, { from: impl.user1 }))[0];
    assert(participation.surveyId == 5);

    try {
      await impl.surveyInstance.getOwnParticipations(0, 1, { from: impl.owner });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyBase: cursor out of range') != -1);
    }

    let cursor = 0;
    let length = 3;
    let participations = await impl.surveyInstance.getOwnParticipations(cursor, length, { from: impl.user1 });

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyId == (cursor + i + 1));
    }

    cursor = 3;
    length = 2;
    participations = await impl.surveyInstance.getOwnParticipations(cursor, length, { from: impl.user1 });

    assert(participations.length == length);
    for (let i = 0; i < participations.length; i++) {
      assert(participations[i].surveyId == (cursor + i + 1));
    }

    try {
      await impl.surveyInstance.getOwnParticipations(0, 10, { from: impl.owner });
      assert.fail();
    } catch (e) {
      assert(e.message.indexOf('SurveyBase: cursor out of range') != -1);
    }
  });

  it('findOwnParticipation', async () => {
    let participation = await impl.surveyInstance.findOwnParticipation(1, { from: impl.user1 });
    assert(participation.surveyId == 1);
    assert(participation.responses.length == impl.questions.length);

    participation = await impl.surveyInstance.findOwnParticipation(2, { from: impl.user2 });
    assert(participation.surveyId == 2);
    assert(participation.responses.length == impl.questions.length);
  });

  it('getQuestionsLength', async () => {
    const questionsLength = await impl.surveyInstance.getQuestionsLength(1);
    assert(questionsLength == impl.questions.length);
  });

  it('getQuestions', async () => {
    let question = (await impl.surveyInstance.getQuestions(1, 0, 1))[0];
    impl.checkQuestion(question, 0);

    question = (await impl.surveyInstance.getQuestions(1, 1, 1))[0];
    impl.checkQuestion(question, 1);

    let cursor = 0;
    let length = 2;
    let questions = await impl.surveyInstance.getQuestions(1, cursor, length);

    assert(questions.length == length);
    for (let i = 0; i < questions.length; i++) {
      impl.checkQuestion(questions[i], (cursor + i));
    }

    cursor = 2;
    length = 1;
    questions = await impl.surveyInstance.getQuestions(1, cursor, length);

    assert(questions.length == length);
    for (let i = 0; i < questions.length; i++) {
      impl.checkQuestion(questions[i], (cursor + i));
    }
  });

  it('getResponses', async () => {
    let cursor = 0;
    let length = 4;
    let responses = await impl.surveyInstance.getResponses(1, 0, cursor, length);
    assert(responses.length == length);

    cursor = 3;
    responses = await impl.surveyInstance.getResponses(1, 0, cursor, length);
    assert(responses.length == length);
  });

  it('getValidators', async () => {
    let validators = await impl.surveyInstance.getValidators(1, 0);
    let filtered = impl.validators.filter(v => v.questionIndex === 0);
    assert(validators.length == filtered.length);
  });

});
