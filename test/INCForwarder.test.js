// ################################################################################################################################################
// USING TEST SPECIFIC MNEMONIC: ganache-cli -m "icon odor witness lonely lesson ill paddle material wreck term illegal alone struggle beach mouse"
// ################################################################################################################################################

const cmn = require("./shared/common");
const sign = require("./shared/sign");
const { MAX_UINT256 } = require("../constants");
const { bufferToHex, privateToAddress, toBuffer } = require('ethereumjs-util');
const { toChecksumAddress } = require('web3-utils');
const ERC20Test = artifacts.require('ERC20Test');

contract('INCForwarder', (accounts) => {
  const owner = accounts[0];
  const relayer = accounts[1];
  const user1 = accounts[2];
  const user2 = accounts[3];
  const signer1 = '0x3577dedd8966ac2e3745ea1496eaa2df9c618768ad2d44e47fa99c0b62624d14'; // Account m/44'/0'/0'/0/2	1CmLW4nJrvFUxLbSmdvLBaMNiMg9qdG9ry
  const signer2 = '0x0ea26ee7a2c7bf5cfdcaabb9b549af56dd33ddb98a71b1aab716c27a1b765a52'; // Account m/44'/0'/0'/0/3	1LPRtikfQoMq7id1n48qF6XKJQPVGqLcoa

  let forwarderInstance;
  let tokenInstance;

  beforeEach(async () => {
    forwarderInstance = await cmn.newINCForwarder();
    tokenInstance = await ERC20Test.new(cmn.tokenName, cmn.tokenSymbol, cmn.tokenTotal);

    await forwarderInstance.setManager(relayer);
    await forwarderInstance.addSenderToWhitelist(relayer);
  });

  it('manager', async () => {
    const manager = await forwarderInstance.manager();
    assert(manager == relayer);
  });

  it('custody', async () => {
    const mRelayer = await forwarderInstance.custody();
    assert(mRelayer == relayer);
  });

  it('getNonce', async () => {
    const nonce = await forwarderInstance.getNonce(owner);
    assert(nonce == 0);
  });

  it('Check signers', async () => {
    // Check private key 1
    const privateKey1 = toBuffer(signer1);
    assert(user1 == toChecksumAddress(bufferToHex(privateToAddress(privateKey1))));

    // Check private key 2
    const privateKey2 = toBuffer(signer2);
    assert(user2 == toChecksumAddress(bufferToHex(privateToAddress(privateKey2))));
});

it('Check forwarder domain separator', async () => {
    const typeHash = web3.utils.keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    const nameHash = web3.utils.keccak256("INCForwarder");
    const versionHash = web3.utils.keccak256("0.0.1");
    const devChainId = 1;// On development network you should use 1

    const dm = await forwarderInstance.DOMAIN_SEPARATOR();

    // EIP712._buildDomainSeparator() return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    const dmCheck1 = web3.utils.keccak256(web3.eth.abi.encodeParameters(['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'], [typeHash, nameHash, versionHash, devChainId, forwarderInstance.address]));
    assert(dm == dmCheck1);

    const dmCheck2 = sign.domainSeparator('INCForwarder', '0.0.1', devChainId, forwarderInstance.address);
    assert(dm == dmCheck2);
});

  it('Execute meta-transaction', async () => {
    // The ´user1´ approves ´user2´ to send their tokens
    const txGas = await tokenInstance.approve.estimateGas(user2, MAX_UINT256, { from: user1 });
    const data = tokenInstance.contract.methods.approve(user2, MAX_UINT256).encodeABI();
    const nonce = await forwarderInstance.getNonce(user1);
    const request = await sign.buildRequest(user1, tokenInstance.address, data, txGas, nonce);
    const devChainId = 1;

    const signature = sign.signWithPk(signer1, forwarderInstance.address, request, devChainId);

    // Execute meta-transaction
    const result = await forwarderInstance.execute(request, signature, { from: relayer });
    assert(result.receipt.status);

    // Check allowance for ´user2´
    const user2Allowance = await tokenInstance.allowance(user1, user2);
    assert(cmn.toBN(user2Allowance).eq(MAX_UINT256));
  });

});