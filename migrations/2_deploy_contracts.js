let OmmerToken = artifacts.require('./OmmerToken.sol')
let OmmerCrowdsale = artifacts.require('./OmmerCrowdsale.sol')
let OmmerTeamVesting = artifacts.require('./OmmerTeamVesting.sol')
let SafetyWallet = artifacts.require('./SafetyWallet.sol')

module.exports = function(deployer, network, accounts) {
    deployer.deploy(OmmerToken).then(function() {
      // deployer.link(OmmerToken, OmmerCrowdsale);

      const vestingPeriodInDays = 180;
      deployer.deploy(OmmerTeamVesting, vestingPeriodInDays);

      var exchangeRate = 400; // 1 OMR = 0.0025 ETH or 1 ETH = 400 OMR
      return deployer.deploy(OmmerCrowdsale, exchangeRate, accounts[0], OmmerToken.address);
    });

    deployer.deploy(SafetyWallet, "0x1234");
};
