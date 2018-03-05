var OmmerToken = artifacts.require("./OmmerToken.sol");

contract("OmmerToken", function(accounts) {
  let token;
  const creator = accounts[0];
  const joe = accounts[1];

  beforeEach(async function () {
    token = await OmmerToken.new({ from: creator });
  });

  it('has the correct symbol', async function () {
    const symbol = await token.symbol();
    assert.equal(symbol, 'OMR');
  });

  it('has the correct name', async function () {
    const name = await token.name();
    assert.equal(name, 'ommer');
  });

  it('has the correct number of decimals', async function () {
    const decimals = await token.decimals();
    assert.equal(decimals, 18);
  });

  it('has the correct total supply', async function () {
    const totalSupply = await token.totalSupply();
    assert.equal(totalSupply, 1 * 10**8 * 10**18);
  });

  it("assigns all of the supply to the creator", async () => {
    const creatorBalance = await token.balanceOf(creator);
    const totalSupply = await token.totalSupply();
    assert.equal(creatorBalance.toNumber(), totalSupply);
  })

});
