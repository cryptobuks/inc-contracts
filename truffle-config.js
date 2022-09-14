const HDWalletProvider = require('@truffle/hdwallet-provider');
const isProduction = process.env.NODE_ENV?.trim() === 'prod';

if (isProduction) {
  console.log('⚠ Loading mainnet data');
  require('dotenv').config({ path: '.env.mainnet' });
} else {
  console.log('⚠ Loading testnet data');
  require('dotenv').config({ path: '.env.testnet' });
}

// Account credentials from which our contract will be deployed
const MNEMONIC = process.env.MNEMONIC;
// API key of PolygonScan
const POLYGONSCAN_APIKEY = process.env.POLYGONSCAN_APIKEY;
const ALCHEMY_APIKEY = process.env.ALCHEMY_APIKEY;

module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*',
      gas: 6721975
    },
    mumbai: {
      //provider: () => new HDWalletProvider(MNEMONIC, `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_APIKEY}`, 0, 10),
      provider: () => new HDWalletProvider(MNEMONIC, `https://matic-mumbai.chainstacklabs.com`, 0, 10),
      network_id: 80001,
      //confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    matic: {
      provider: () => new HDWalletProvider(MNEMONIC, `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_APIKEY}`, 0, 10),
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: "0.8.7",
      settings: {
       optimizer: {
         enabled: true,
         runs: 200
       }
      }
    }
  },
  plugins: [
    "truffle-contract-size",
    "truffle-plugin-debugger",
    "truffle-plugin-verify"
  ],
  api_keys: {
    polygonscan: POLYGONSCAN_APIKEY
  }
}
