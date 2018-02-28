var EthUsdPrice = artifacts.require("./EthUsdPrice.sol");

contract("EthUsdPrice", function(accounts) {
  let token;
  const creator = accounts[0];
  const joe = accounts[1];

  beforeEach(async function () {
    ethUsdPrice = await EthUsdPrice.new({ from: creator });
  });

  it('can tell that Oraclize has not called back', async function () {
    const lastCb = await ethUsdPrice.lastOraclizeCallback();
    assert.equal(lastCb, 0);
  });

  it('starts with price 0', async function () {
    const cents = await ethUsdPrice.ethInCents();
    assert.equal(cents, 0);
  });

  it.skip('should issue new request to oraclize', async function () {
    try {
      await ethUsdPrice.update({ value: web3.toWei(1, 'ether') });
    } catch (e) {
      assert.fail(e);
    }
  });

});
