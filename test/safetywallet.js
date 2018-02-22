var SafetyWallet = artifacts.require("./SafetyWallet.sol");

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


});
