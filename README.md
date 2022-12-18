> **Note**
> ## [The Initial offer of the INC Token](https://survey.inctoken.org/token-sale) begins January 1, 2023 and ends March 31, 2023.

# INC Contracts

This repository contains the smart contracts for the INC token, governance, and survey protocol.

## INC Routes

- Website: [inctoken.org](https://inctoken.org)
- Survey Interface: [survey.inctoken.org](https://survey.inctoken.org)
- Docs: [docs.inctoken.org](https://docs.inctoken.org)
- Contracts: [docs.inctoken.org/contracts](https://docs.inctoken.org/contracts)
- Whitepaper:[docs.inctoken.org/whitepaper.pdf](https://docs.inctoken.org/whitepaper.pdf)
- Twitter: [@incentivetoken](https://twitter.com/incentivetoken)
- Discord: [INC Token Community](https://discord.com/invite/fFzDHMKhcN)
- Email: [contact@inctoken.org](mailto:contact@inctoken.org)

## Governance Routes

- [Snapshot](https://snapshot.org/#/inctoken.eth): For off-chain voting on proposals.
- [Tally](https://www.tally.xyz/gov/eip155:137:0x9a342e71abEab4B9F47Daf520D4C8df3bE938153): View INC DAO information on proposals, Delegates, and delegate your voting power.

## Local tests

You must first install [Node.js](https://nodejs.org/) >= v12.0.0 and npm >= 6.12.0.

Next, use NPM to install [Ganache](https://github.com/trufflesuite/ganache) globally:

```console
$ npm install ganache --global
```

Finally, [install Truffle](https://trufflesuite.com/docs/truffle/getting-started/installation) globally:

```console
$ npm install -g truffle
```

Some scripts require a specific MNEMONIC as they use private keys for testing:

```console
ganache-cli -m "icon odor witness lonely lesson ill paddle material wreck term illegal alone struggle beach mouse"
```

Open a new terminal to run the test scripts:

```console
truffle test
truffle test ./test/INCToken.test.js
truffle test ./test/TokenOffer.test.js
truffle test ./test/INCGovernor.test.js
truffle test ./test/SurveyEngine.test.js
truffle test ./test/SurveyStorage.test.js
truffle test ./test/SurveyValidator.test.js
truffle test ./test/INCForwarder.test.js
..
```

For more information, see the [Truffle Documentation](https://trufflesuite.com/docs/truffle/testing/testing-your-contracts).

## Licensing

The primary license for `INC Contracts` is the Business Source License 1.1 (`BUSL-1.1`), see [`LICENSE`](./LICENSE). However, some files are licensed under `MIT` or `GPL-2.0-or-later`.
