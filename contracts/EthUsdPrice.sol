pragma solidity 0.4.18;

import "oraclize/oraclizeAPI.sol";


contract EthUsdPrice is usingOraclize {

    uint256 public ethInCents;

    // Calls to oraclize generat a unique ID and the subsequent callback uses
    // that ID. We allow callbacks only if they have a valid ID.
    mapping(bytes32=>bool) private validIds;

    event LogOraclizeQuery(string description);
    event LogPriceUpdated(string price);

    // Update on construction ensures that the price of ETH is always
    // initialised.
    function EthUsdPrice() public payable {
        update();
    }

    function update() public payable {
        require(hasEnoughFunds());

        LogOraclizeQuery("Requesting Oraclize to submit latest ETHUSD price");
        bytes32 qId = oraclize_query(60, "URL", "json(https://api.infura.io/v1/ticker/ethusd).ask");
        validIds[qId] = true;
    }

    function __callback(bytes32 cbId, string result) public {
        require(msg.sender == oraclize_cbAddress());
        require(validIds[cbId]);
        ethInCents = parseInt(result, 2);
        delete validIds[cbId];
        LogPriceUpdated(result);
        update();
    }

    function hasEnoughFunds() internal returns (bool) {
        return oraclize_getPrice("URL") <= this.balance;
    }
}
