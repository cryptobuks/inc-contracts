const ethers = require('ethers');
const SafeERC20NamerTest = artifacts.require('SafeERC20NamerTest');
const NamerTestFakeCompliantERC20 = artifacts.require('NamerTestFakeCompliantERC20');
const NamerTestFakeNoncompliantERC20 = artifacts.require('NamerTestFakeNoncompliantERC20');
const NamerTestFakeOptionalERC20 = artifacts.require('NamerTestFakeOptionalERC20');
const { ZERO_ADDRESS } = require("../constants");

const fullBytes32Name = 'NAME'.repeat(8).substr(0, 31);
const fullBytes32Symbol = 'SYMB'.repeat(8).substr(0, 31);

contract('SafeERC20Namer', (accounts) => {

  let safeNamer;

  before(async () => {
    safeNamer = await SafeERC20NamerTest.new();
  });

  function deployCompliant(data) {
    return NamerTestFakeCompliantERC20.new(data.name, data.symbol);
  }

  function deployNoncompliant(data) {
    return NamerTestFakeNoncompliantERC20.new(ethers.utils.formatBytes32String(data.name), ethers.utils.formatBytes32String(data.symbol));
  }

  function deployOptional() {
    return NamerTestFakeOptionalERC20.new();
  }

  async function getName(tokenAddress) {
    return safeNamer.tokenName(tokenAddress)
  }

  async function getSymbol(tokenAddress) {
    return safeNamer.tokenSymbol(tokenAddress)
  }

  // #tokenName
  it('works with compliant', async () => {
    const token = await deployCompliant({name: 'token name', symbol: 'tn'})
    expect(await getName(token.address)).to.eq('token name')
  });

  it('works with noncompliant', async () => {
    const token = await deployNoncompliant({name: 'token name', symbol: 'tn'})
    expect(await getName(token.address)).to.eq('token name')
  });

  it('works with empty bytes32', async () => {
    const token = await deployNoncompliant({name: '', symbol: ''})
    expect(await getName(token.address)).to.eq(token.address.toUpperCase().substr(2))
  });

  it('works with noncompliant full bytes32', async () => {
    const token = await deployNoncompliant({name: fullBytes32Name, symbol: fullBytes32Symbol})
    expect(await getName(token.address)).to.eq(fullBytes32Name)
  });
  
  it('works with optional', async () => {
    const token = await deployOptional()
    expect(await getName(token.address)).to.eq(token.address.toUpperCase().substr(2))
  });

  it('works with non-code address', async () => {
    expect(await getName(ZERO_ADDRESS)).to.eq(ZERO_ADDRESS.substr(2))
  });

  it('works with really long strings', async () => {
    const token = await deployCompliant({name: 'token name'.repeat(32), symbol: 'tn'.repeat(32)})
    expect(await getName(token.address)).to.eq('token name'.repeat(32))
  });

  it('falls back to address with empty strings', async () => {
    const token = await deployCompliant({name: '', symbol: ''})
    expect(await getName(token.address)).to.eq(token.address.toUpperCase().substr(2))
  });

  // #tokenSymbol
  it('works with compliant', async () => {
    const token = await deployCompliant({name: 'token name', symbol: 'tn'})
    expect(await getSymbol(token.address)).to.eq('tn')
  });

  it('works with noncompliant', async () => {
    const token = await deployNoncompliant({name: 'token name', symbol: 'tn'})
    expect(await getSymbol(token.address)).to.eq('tn')
  });

  it('works with empty bytes32', async () => {
    const token = await deployNoncompliant({name: '', symbol: ''})
    expect(await getSymbol(token.address)).to.eq(token.address.substr(2, 6).toUpperCase())
  });

  it('works with noncompliant full bytes32', async () => {
    const token = await deployNoncompliant({name: fullBytes32Name, symbol: fullBytes32Symbol})
    expect(await getSymbol(token.address)).to.eq(fullBytes32Symbol)
  });

  it('works with optional', async () => {
    const token = await deployOptional()
    expect(await getSymbol(token.address)).to.eq(token.address.substr(2, 6).toUpperCase())
  });

  it('works with non-code address', async () => {
    expect(await getSymbol(ZERO_ADDRESS)).to.eq(ZERO_ADDRESS.substr(2, 6))
  });

  it('works with really long strings', async () => {
    const token = await deployCompliant({name: 'token name'.repeat(32), symbol: 'tn'.repeat(32)})
    expect(await getSymbol(token.address)).to.eq('tn'.repeat(32))
  });

  it('falls back to address with empty strings', async () => {
    const token = await deployCompliant({name: '', symbol: ''})
    expect(await getSymbol(token.address)).to.eq(token.address.substr(2, 6).toUpperCase())
  });

});