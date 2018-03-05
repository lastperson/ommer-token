var OmmerIco = artifacts.require("./OmmerIco.sol");
var OmmerToken = artifacts.require("./OmmerToken.sol");

contract("OmmerIco", function(accounts) {
  let ommmerIco;
  let omr;
  let omrDecimals;
  const creator = accounts[0];
  const joe = accounts[1];
  const fundSink = accounts[2];

  beforeEach(async () => {
    omr = await OmmerToken.new({ from: creator });
    omrDecimals = await omr.decimals();
    ommerIco = await OmmerIco.new(85025, omr.address, fundSink, { from: creator });
  });

  it("should start paused", async () => {
    const isPaused = await ommerIco.paused();
    assert.equal(isPaused, true, "ico should not be running");
  });

  it("should throw if unpausing ICO without tokens to sell", async () => {
    try {
      await ommerIco.unpause({ from: creator });
      assert.fail("unpausing should have thrown");
    } catch (err) {
    }
  });

  it("should unpause if ICO has tokens to sell", async () => {
    await omr.transfer(ommerIco.address, 10000 * 10 ** omrDecimals, { from: creator });
    await ommerIco.unpause({ from: creator });
  });

  it("should pause a running ICO if called by the owner", async () => {
    await omr.transfer(ommerIco.address, 10000 * 10 ** omrDecimals, { from: creator });
    await ommerIco.unpause({ from: creator });
    await ommerIco.pause({ from: creator });
    const isPaused = await ommerIco.paused();
    assert.isTrue(isPaused);
  });

  it("should throw if unpausing ICO with tokens to sell but called by non-owner", async () => {
    try {
      await omr.transfer(ommerIco.address, 10000 * 10 ** omrDecimals, { from: creator });
      await ommerIco.unpause({ from: joe });
      assert.fail("unpausing should have thrown");
    } catch (err) {
    }
  });

  it("should return 8502 cents for 0.1 ETH value", async () => {
    const cents = await ommerIco.getUsdCentValue(100000000000000000);
    assert.equal(cents, 8502);
  });

  it('should report 0.01 ETH as the minimum for contribution', async () => {
    const min = 10 ** 18 / 100;
    const minContribution = await ommerIco.getMinPossibleContribution();
    assert.equal(minContribution.toNumber(), min);
  });

  it("should forward the ICO proceeds to the fund sink address", async () => {
    await omr.transfer(ommerIco.address, 10000 * 10 ** omrDecimals, { from: creator });
    await ommerIco.unpause();
    const oBalance = await web3.eth.getBalance(fundSink);
    await web3.eth.sendTransaction({from: joe, to: ommerIco.address, value: web3.toWei(0.5, 'ether'), gas: 1000000 });
    const nBalance = await web3.eth.getBalance(fundSink).toNumber();
    assert.equal(nBalance, oBalance.add(web3.toWei(0.5, 'ether')).toNumber());
  });

  it("should accept value if value > minValue and ICO is running", async () => {
    await omr.transfer(ommerIco.address, 10000 * 10 ** omrDecimals, { from: creator });
    await ommerIco.unpause();
    await web3.eth.sendTransaction({from: joe, to: ommerIco.address, value: web3.toWei(0.5, 'ether'), gas: 1000000 });
    await web3.eth.sendTransaction({from: joe, to: ommerIco.address, value: web3.toWei(0.2, 'ether'), gas: 1000000 });
    const c = await ommerIco.contributions(joe);
    const unconfirmed = c[0].toNumber();
    const withdrawn = c[1].toNumber();
    assert.equal(unconfirmed, 595.17 * 10 ** omrDecimals);
    assert.equal(withdrawn, 0);
  });

  it("should throw if verify called by non-owner", async () => {
    try {
      await omr.transfer(ommerIco.address, 10000 * 10 ** omrDecimals, { from: creator });
      await ommerIco.unpause();
      await web3.eth.sendTransaction({from: joe, to: ommerIco.address, value: web3.toWei(0.5, 'ether'), gas: 1000000 });
      await ommerIco.verify(joe, { from: joe });
      assert.fail("should have thrown");
    } catch (err) {
      // all good if the correct error...
    }
  });

  it("should throw if contributor has no OMR in the ICO contract", async () => {
    await omr.transfer(ommerIco.address, 10000 * 10 ** omrDecimals, { from: creator });
    await ommerIco.unpause({ from: creator });
    try {
      await ommerIco.verify(joe, { from: creator });
      assert.fail("should have thrown");
    } catch (err) {
      //
      const joeOmr = await omr.balanceOf(joe);
      assert.equal(joeOmr, 0);
    }
  });

  it("should disperse the OMR to the contributor upon verifying them", async () => {
    await omr.transfer(ommerIco.address, 10000 * 10 ** omrDecimals, { from: creator });
    await ommerIco.unpause({ from: creator });
    await web3.eth.sendTransaction({from: joe, to: ommerIco.address, value: web3.toWei(0.5, 'ether'), gas: 1000000 });
    await ommerIco.verify(joe, { from: creator });
    const joeOmr = await omr.balanceOf(joe);
    assert.equal(joeOmr.toNumber(), 425.12 * 10 ** omrDecimals);
  });

  it("should throw if paused ICO is sent a contribution ", async () => {
    try {
      await omr.transfer(ommerIco.address, 10000 * 10 ** omrDecimals, { from: creator });
      await web3.eth.sendTransaction({from: joe, to: ommerIco.address, value: web3.toWei(0.5, 'ether'), gas: 1000000 });
      assert.fail("should have thrown");
    } catch (err) {
      // all good if the correct error...
    }
  });

  it("should throw if remaining OMR < contribution ", async () => {
    try {
      await omr.transfer(ommerIco.address, 100 * 10 ** omrDecimals, { from: creator });
      await ommerIco.unpause({ from: creator });
      await web3.eth.sendTransaction({from: joe, to: ommerIco.address, value: web3.toWei(0.5, 'ether'), gas: 1000000 });
      assert.fail("should have thrown");
    } catch (err) {
      // all good if the correct error...
    }
  });

});
