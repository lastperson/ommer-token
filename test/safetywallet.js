const SafetyWallet = artifacts.require("./SafetyWallet.sol");
const EthereumTx = require('ethereumjs-tx')

const web3call = (fn) =>
  new Promise((resolve, reject) =>
    fn((err, res) => {
      if (err) { reject(err) }
      resolve(res);
  })
);

function getBalance(account, at) {
  return web3call(fn => web3.eth.getBalance(account, at, fn))
}

contract("SafetyWallet", function(accounts) {
  let safetyWallet;
  const creator = accounts[0];
  const joe = accounts[1];
  const ommer = accounts[2];

  beforeEach(async function () {
    safetyWallet = await SafetyWallet.new(ommer, { from: creator });
  });

  it('is owned by the creator', async function () {
    const owner = await safetyWallet.owner();
    assert.equal(owner, creator);
  });

  it('has ommer EOA/Contract address set', async function() {
    const ommerAddress = await safetyWallet.ommerAddress();
    assert.equal(ommerAddress, ommer);
  });

  it('throw an error if block number < safetyWallet block number', async function () {
    const blk = web3.eth.blockNumber;
    try {
      await safetyWallet.forward(blk + 1, { value: web3.toWei(0.5, "ether"), from: joe });
      assert.fail("should have thrown");
    } catch (e) {
      //
    }
  });

  it('should forward the value to ommer address', async function () {
    const blk = web3.eth.blockNumber;
    const oBalance = await getBalance(joe);
    const oBalanceOmmer = await getBalance(ommer);

    const amount = web3.toWei(0.5, "ether");

    try {
      await safetyWallet.forward(blk - 10, { value: amount, from: joe });
      const nBalance = await getBalance(joe);
      const nBalanceOmmer = await getBalance(ommer);
      // new balance is still less because of the gas consumed
      assert.isTrue(nBalance.toNumber() < oBalance.minus(amount));
      // ommer address gets the funds
      assert.equal(nBalanceOmmer.toNumber(), oBalanceOmmer.add(amount));
    } catch (e) {
      console.log(e);
      assert.fail("should have not thrown");
    }
  });


  it.only("should accept pre-signed tx after the blockNumber passes", async () => {
    const nonce = web3.eth.getTransactionCount(joe);
    console.log(nonce);
    const contract = web3.eth.contract(safetyWallet.abi);
    const instance = contract.at(safetyWallet.address);
    const fnCallHash = web3.sha3('forward(uint256 _blockNum)');
    const fnCallHash4bytes = fnCallHash.substr(0, 10);
    const argHash = web3.fromAscii(web3.eth.blockNumber + 2);
    const dataEnc = fnCallHash4bytes + argHash.substr(2);
    const rawTx = {
      to: safetyWallet.address,
      value: web3.toHex(web3.toWei(0.5, 'ether')),
      gasPrice: web3.toHex(web3.toWei(26, 'GWei')),
      gasLimit: web3.toHex(100000),
      nonce: nonce,
      data: dataEnc
    };
    const joePk = Buffer.from('ae6ae8e5ccbfb04590405997ee2d52d2b550726157b875055c56d94e974d162f', 'hex');
    const tx = new EthereumTx(rawTx);
    tx.sign(joePk);
    const serializedTx = tx.serialize();
    console.log(serializedTx);
    console.log(tx);
  });

});
