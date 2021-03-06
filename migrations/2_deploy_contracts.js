let OmmerToken = artifacts.require('./OmmerToken.sol')
let OmmerIco = artifacts.require('./OmmerIco.sol')
let OmmerTeamVesting = artifacts.require('./OmmerTeamVesting.sol')
let SafetyWallet = artifacts.require('./SafetyWallet.sol')
let EthUsdPrice = artifacts.require('./EthUsdPrice.sol')
let OmmerUtils = artifacts.require('./OmmerUtils.sol')

module.exports = function(deployer, network, accounts) {
    deployer.deploy(OmmerToken).then(function() {
      // deployer.link(OmmerToken, OmmerCrowdsale);

      const vestingPeriodInDays = 180;
      deployer.deploy(OmmerTeamVesting, vestingPeriodInDays);

      var exchangeRate = 400; // 1 OMR = 0.0025 ETH or 1 ETH = 400 OMR
      return deployer.deploy(OmmerIco, exchangeRate, accounts[0], OmmerToken.address, { gas: 5000000 });
    });

    deployer.deploy(SafetyWallet, "0x1234");

    deployer.deploy(EthUsdPrice, { gas: 5000000 });
    deployer.deploy(OmmerUtils);
};
