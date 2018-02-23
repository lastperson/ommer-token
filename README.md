# Ethereum Smart Contracts

Dependencies

- node.js
- npm
  * (global) truffle
  * zeppelin-solidity
- git
  * https://github.com/oraclize/ethereum-api

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

## Oraclize on a local test network

Locally you're running essentially a private Ethereum network, so you first 
need to deploy the Oraclize Address Resolver (OAR) and then point to its address
all contracts then use Oraclize.

### Dependencies

- npm
    * (global) ethereumjs-testrpc
- git
    * https://github.com/oraclize/ethereum-bridge

Start `testrpc` and then run `node bridge.js` in the `ethereum-bridge` project.
This will deploy the OAR and give you the address of it, together with a sample
code that needs to be inserted into the constructor of any contract that uses
Oraclize and you want to test it locally.


## Truffle debug

If migration throws an error during contract deployments then grab the TX ID
and run `truffle debug <TXID>` which can show more details about the problem.
