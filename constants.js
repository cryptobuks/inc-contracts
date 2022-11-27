const web3 = require('web3');
const BN = web3.utils.BN;

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const ZERO_BYTES32 = '0x0000000000000000000000000000000000000000000000000000000000000000';

const ONE_TOKEN = new BN('10').pow(new BN('18'));
const MAX_UINT256 = new BN('2').pow(new BN('256')).sub(new BN('1'));

const HOUR_SECONDS = 60 * 60;
const DAY_SECONDS = HOUR_SECONDS * 24;
const MONTH_SECONDS = DAY_SECONDS * 30;
const YEAR_SECONDS = DAY_SECONDS * 365;

const CURRENCY_ADDRESS = {
  ["mumbai"]: "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889", // WMATIC testnet
  ["matic"]: "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270" // WMATIC mainnet
};

module.exports = {
    BN,
    ZERO_ADDRESS,
    ZERO_BYTES32,
    ONE_TOKEN,
    MAX_UINT256,
    HOUR_SECONDS,
    DAY_SECONDS,
    MONTH_SECONDS,
    YEAR_SECONDS,
    CURRENCY_ADDRESS
};