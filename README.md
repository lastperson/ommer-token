# Ethereum Smart Contracts

Dependencies

- node.js
- npm
  * (global) truffle
  * zeppelin-solidity
  * Oraclize

Once you install node.js and npm, run `npm install` to install local node modules. You can optionally install truffle and ethereumjs-testrpc as a local module but these two are assumed to be installed globally in this README.

## Truffle workflow

```
# enter the truffle console
bash$> truffle develop
# run all tests
truffle(develop)> test
# exit
truffle(develop)> .exit
```

Alternatively, you can install `ethereumjs-testrpc` and run `truffle test`.

## Truffle debug

If migration throws an error during contract deployments then grab the TX ID
and run `truffle debug <TXID>` which can show more details about the problem.
