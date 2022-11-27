const ethSigUtil = require('eth-sig-util');

const EIP712Domain = [
  { name: 'name', type: 'string' },
  { name: 'version', type: 'string' },
  { name: 'chainId', type: 'uint256' },
  { name: 'verifyingContract', type: 'address' }
];

const ForwardRequest = [
  { name: 'from', type: 'address' },
  { name: 'to', type: 'address' },
  { name: 'value', type: 'uint256' },
  { name: 'gas', type: 'uint256' },
  { name: 'nonce', type: 'uint256' },
  { name: 'data', type: 'bytes' }
];

function domainSeparator (name, version, chainId, verifyingContract) {
  return '0x' + ethSigUtil.TypedDataUtils.hashStruct(
    'EIP712Domain',
    { name, version, chainId, verifyingContract },
    { EIP712Domain },
  ).toString('hex');
}

function getMetaTxTypedData(chainId, verifyingContract) {
  return {
    types: {
      EIP712Domain,
      ForwardRequest
    },
    domain: {
      name: 'INCForwarder',
      version: '0.0.1',
      chainId,
      verifyingContract,
    },
    primaryType: 'ForwardRequest'
  }
}

async function buildRequest(from, to, data, gas, nonce = 0) {
  return {
    from,
    to,
    value: "0",
    gas: gas.toString(),
    nonce: nonce,
    data: data
  };
}

function signWithPk(signer, forwarder, request, chainId) {
  const privateKey = Buffer.from(signer.replace(/^0x/, ''), 'hex');
  const typedData = getMetaTxTypedData(chainId, forwarder);
  return ethSigUtil.signTypedMessage(privateKey, { data: { ...typedData, message: request } });
}

module.exports = {
    domainSeparator,
    getMetaTxTypedData,
    buildRequest,
    signWithPk
};