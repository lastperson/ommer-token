module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  //
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*"
        }
    }
    // live public Ethereum network
    // ,live: {
    //     host: <some-ethereum-node>
    //     port: 80,
    //     network_id: 1 // mainnet
    //     gas: Gas limit used for deploys. Default is 4712388.
    //     gasPrice: Gas price used for deploys. Default is 100000000000 (100 Shannon).
    //     }
};
