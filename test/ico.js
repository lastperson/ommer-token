var OmmerToken = artifacts.require("./OmmerToken.sol");
var OmmerCrowdsale = artifacts.require("./OmmerCrowdsale.sol")

contract("OmmerCrowdsale", function(accounts) {
  let token, ico;
  const creator = accounts[0];
  const joe = accounts[1];

  beforeEach(async function () {
    token = await OmmerToken.new({ from: creator });
    ico = await OmmerCrowdsale.new(400, creator, token.address, { from: creator });
  });

  it('has a symbol', async function () {
    const symbol = await token.symbol();
    assert.equal(symbol, 'OMR');
  });

  it("should start not running", async function() {
    const isPaused = await ico.paused();
    assert.equal(isPaused, true, "ico should not be running");
  });

  it("should throw if non-owner calls start()", async function() {
    try {
      const result = await ico.start({from: joe});
      assert.fail("should have thrown");
    } catch (err) {

    }
  });

  it("should throw if owner calls start() but ico has no tokens", async function() {
    try {
      const result = await ico.start({from: creator});
      assert.fail("should have thrown");
    } catch (err) {
      const isPaused = await ico.paused();
      assert.equal(isPaused, true, "ICO should not be running");
    }
  });

  it("should throw if non-owner calls start() even though the ico has tokens", async function() {
    await token.transfer(ico.address, 1000000000, { from: creator });
    try {
      const result = await ico.start({from: joe});
      assert.fail("should have thrown");
    } catch (err) {
      const isPaused = await ico.paused();
      assert.equal(isPaused, true, "ICO should not be running");
    }
  });

  it("should start the ico if ico has tokens and owner calls start()", async function() {
      await token.transfer(ico.address, 100000000, { from: creator});
      await ico.start({from: creator});
      const isPaused = await ico.paused();
      assert.equal(isPaused, false, "ICO should be running now");
  });

  it("should stop the ico if the owner calls stop()", async function() {
    await token.transfer(ico.address, 100000000, { from: creator});
    await ico.start({from: creator });
    await ico.stop({from: creator });
    const isPaused = await ico.paused();
    assert.equal(isPaused, true, "ICO should be stopped now");
  });

  it("should not stop a running ico if a non-owner calls stop()", async function() {
    await token.transfer(ico.address, 100000000, { from: creator});
    await ico.start({from: creator });
    try {
      await ico.stop({from: joe });
      assert.fail("should have thrown");
    } catch (err) {
      const isPaused = await ico.paused();
      assert.equal(isPaused, false, "ICO should still be running");
    }
  });

  it("should not let people contribute to a non-running ico", async function() {
    try {
      const amount = web3.toWei(1, 'ether');
      await web3.eth.sendTransaction({from: joe, to: ico.address, value: amount });
    } catch (err) {
    }
  });

  it("should let people contribute to a running ico if contribution < remaining tokens", async function() {
    // start the ico
    // and make 1000 omr tokens available
    // here we use 'ether' in the conversion because OMR and ETH have the same
    // amount of decimals.
    const omrAvailable = web3.toWei(1000, 'ether');
    await token.transfer(ico.address, omrAvailable, { from: creator });
    await ico.start({ from: creator });

    // send contribution
    const amount = web3.toWei(1, 'ether'); // buying 1 * exchangeRate OMR (400 OMR)
    await web3.eth.sendTransaction({ from: joe, to: ico.address, value: amount });

    // check that contract holds 400 omr for joe
  });

});
