const { promisify } = require('util');
const BN = web3.utils.BN;

advanceBlock = () => {
    return promisify(web3.currentProvider.send.bind(web3.currentProvider))({
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: new Date().getTime(),
    });
};

// Advance the block to the passed height
advanceBlockTo = async (target) => {
    if (!BN.isBN(target)) {
        target = new BN(target);
    }

    const currentBlock = (await latestBlock());
    const start = Date.now();
    let notified;
    if (target.lt(currentBlock)) throw Error(`Target block #(${target}) is lower than current block #(${currentBlock})`);
    while ((await latestBlock()).lt(target)) {
        if (!notified && Date.now() - start >= 5000) {
            notified = true;
            console.warn('advanceBlockTo: Advancing too many blocks is causing this test to be slow.');
        }
        await advanceBlock();
    }
};

// Returns the time of the last mined block in seconds
latest = async () => {
    const block = await web3.eth.getBlock('latest');
    return new BN(block.timestamp);
};

latestBlock = async () => {
    const block = await web3.eth.getBlock('latest');
    return new BN(block.number);
};

// Increases ganache time by the passed duration in seconds
increase = async (duration) => {
    if (!BN.isBN(duration)) {
        duration = new BN(duration);
    }

    if (duration.isNeg()) throw Error(`Cannot increase time by a negative amount (${duration})`);

    await promisify(web3.currentProvider.send.bind(web3.currentProvider))({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [duration.toNumber()],
        id: new Date().getTime(),
    });

    await advanceBlock();
};

/**
 * Beware that due to the need of calling two separate ganache methods and rpc calls overhead
 * it's hard to increase time precisely to a target point so design your test to tolerate
 * small fluctuations from time to time.
 *
 * @param target time in seconds
 */
increaseTo = async (target) => {
    if (!BN.isBN(target)) {
        target = new BN(target);
    }

    const now = (await latest());

    if (target.lt(now)) return;//throw Error(`Cannot increase current time (${now}) to a moment in the past (${target})`);
    const diff = target.sub(now);
    return increase(diff);
};

takeSnapshot = async () => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_snapshot',
      id: new Date().getTime()
    }, (err, snapshotId) => {
      if (err) { return reject(err) }
      return resolve(snapshotId)
    });
  });
};

revertToSnapShot = async (id) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_revert',
      params: [id],
      id: new Date().getTime()
    }, (err, result) => {
      if (err) { return reject(err) }
      return resolve(result)
    });
  });
};

const duration = {
    seconds: function (val) { return new BN(val); },
    minutes: function (val) { return new BN(val).mul(this.seconds('60')); },
    hours: function (val) { return new BN(val).mul(this.minutes('60')); },
    days: function (val) { return new BN(val).mul(this.hours('24')); },
    weeks: function (val) { return new BN(val).mul(this.days('7')); },
    years: function (val) { return new BN(val).mul(this.days('365')); },
};

module.exports = {
    advanceBlock,
    advanceBlockTo,
    latest,
    latestBlock,
    increase,
    increaseTo,
    takeSnapshot,
    revertToSnapShot,
    duration,
};