pragma solidity 0.4.18;

import "oraclize/oraclizeAPI.sol";


contract EthUsdPrice is usingOraclize {

    uint256 public ethInCents;
    uint256 public lastOraclizeCallback;

    // Calls to oraclize generate a unique ID and the subsequent callback uses
    // that ID. We allow callbacks only if they have a valid ID.
    mapping(bytes32=>bool) private validIds;

    event LogOraclizeQuery(string description);
    event LogPriceUpdated(string price);

    // NB: ethInCents is not initialised until the first Oraclize callback comes
    // in.
    function EthUsdPrice() public payable {
        lastOraclizeCallback = 0;

        // For local Ethereum network, we need to supply our own OAR contract
        // address.
        /* if (_localOAR != address(0)) {
            OAR = OraclizeAddrResolverI(_localOAR);
        } */

        //update();
    }

    function update() public payable {
        require(hasEnoughFunds());

        LogOraclizeQuery("Requesting Oraclize to submit latest ETHUSD price");
        bytes32 qId = oraclize_query(600, "URL", "json(https://api.infura.io/v1/ticker/ethusd).ask");
        validIds[qId] = true;
    }

    function __callback(bytes32 cbId, string result) public {
        require(msg.sender == oraclize_cbAddress());
        require(validIds[cbId]);

        ethInCents = parseInt(result, 2);
        delete validIds[cbId];

        lastOraclizeCallback = block.number;

        LogPriceUpdated(result);

        update();
    }

    function hasEnoughFunds() internal returns (bool) {
        return oraclize_getPrice("URL") <= this.balance;
    }
}
