var OmmerToken = artifacts.require("./OmmerToken.sol");
var OmmerTeamVesting = artifacts.require("./OmmerTeamVesting.sol");

contract("OmmerTeamVesting", function(accounts) {
  let token, vesting;
 
  const creator = accounts[0];
  const joe = accounts[1];
  const vestingPeriodInDays = 180;

  beforeEach(async function () {
    token = await OmmerToken.new({ from: creator });
    vesting = await OmmerTeamVesting.new(vestingPeriodInDays, { from: creator });
  });

  it('sets the vesting date and the max vesting date', async function () {
    const vestingDate = await vesting.vestingDate();
    const maxVestingDate = await vesting.maxVestingDate();
    const now = 0;
    assert.isTrue(now < vestingDate);
    assert.isTrue(maxVestingDate > vestingDate);
  });

  it('should not extend the vesting if extension > 365 days', async function() {
    const vestingDate = await vesting.vestingDate();
    try {
      await vesting.extendVesting(366);
    } catch (err) {

    }
    const vestingDate2 = await vesting.vestingDate();
    assert.equal(vestingDate + 1, vestingDate2 + 1, 'the vesting date should stay the same');
  });

  it('extends the vesting by the set number of days', async function () {
    const oVestingDate = await vesting.vestingDate();
    const extension = 20;

    await vesting.extendVesting(extension);

    const newVestingDate = await vesting.vestingDate();
    assert.isTrue(newVestingDate.toNumber() > oVestingDate.toNumber());
    assert.equal(newVestingDate * 1, oVestingDate.toNumber() + (extension * 86400));
  });
}); 
