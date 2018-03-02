var OmmerUtils = artifacts.require("./OmmerUtils.sol");

contract("OmmerUtils", function(accounts) {
  let ommmerUtils;
  const creator = accounts[0];
  const joe = accounts[1];

  beforeEach(async () => {
    ommerUtils = await OmmerUtils.new({ from: creator });
  });

  it('should return true if n is in interval (lower bound)', async () => {
    const result = await ommerUtils.inInterval(5, 5, 10);
    assert.isTrue(result);
  });

  it('should return true if n is in interval (inside the bounds)', async () => {
    const result = await ommerUtils.inInterval(5, 3, 10);
    assert.isTrue(result);
  });

  it('should return true if n is in interval (upper bound)', async () => {
    const result = await ommerUtils.inInterval(5, 2, 5);
    assert.isTrue(result);
  });

  it('should return false if n is outside the interval (below the lower bound)', async () => {
    const result = await ommerUtils.inInterval(5, 6, 10);
    assert.isFalse(result);
  });

  it('should return false if n is outside the interval (above the upper bound)', async () => {
    const result = await ommerUtils.inInterval(5, 1, 4);
    assert.isFalse(result);
  });

});
