# Ethereum Smart Contracts

Dependencies

- node.js
- npm
  * (global) truffle
  * (global) ethereumjs-testrpc
  * zeppelin-solidity

Once you install node.js and npm, run `npm install` to install local node modules. You can optionally install truffle and ethereumjs-testrpc as a local module but these two are assumed to be installed globally in this README.

## Truffle workflow

```
# compile the code
truffle compile
# start the dummy ethereum node
testrpc
# once rpc running, you can migrate the latest code changes
# this deploys the code to the local Ethereum node
truffle migrate
# run tests
truffle test
# launch truffle console for interactive shell
truffle console
```

Testing needs the `testrpc` running and then you issue `truffle test` command.

## Truffle debug

If migration throws an error during contract deployments then grab the TX ID
and run `truffle debug <TXID>` which can show more details about the problem.
