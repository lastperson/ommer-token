/**
 *   ___  _ __ ___  _ __ ___   ___ _ __
 *  / _ \| '_ ` _ \| '_ ` _ \ / _ \ '__|
 * | (_) | | | | | | | | | | |  __/ |
 *  \___/|_| |_| |_|_| |_| |_|\___|_|
 *
 * https://www.ommer.com
 */
pragma solidity 0.4.18;

import "oraclize/oraclizeAPI.sol";


/**
 * Contract which exposes `ethInCents` which is the Ether price in USD cents.
 * E.g. if 1 Ether is sold at 840.32 USD on the markets, the `ethInCents` will
 * be `84032`.
 *
 * This price is supplied by Oraclize callback, which sets the value. Currently
 * there is no proof provided for the callback, other then the value and the
 * corresponding ID which was generated when this contract called Oraclize.
 *
 * If this contract runs out of Ether, the callback cycle will interrupt until
 * the `update` function is called with a transaction which also replenishes the
 * balance of the contract.
 */
contract EthUsdPrice is usingOraclize {

    uint256 public ethInCents;
    uint256 public lastOraclizeCallback;

    // Calls to oraclize generate a unique ID and the subsequent callback uses
    // that ID. We allow callbacks only if they have a valid ID.
    mapping(bytes32 => bool) private validIds;
    
    // Allow only single auto update cycle, to prevent DOS attack.
    bytes32 private autoUpdateId;

    event LogOraclizeQuery(string description);
    event LogPriceUpdated(string price);

    // NB: ethInCents is not initialised until the first Oraclize callback comes
    // in.
    function EthUsdPrice() public {
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
        require(autoUpdateId == bytes32(0));

        LogOraclizeQuery("Requesting Oraclize to submit latest ETHUSD price");

        bytes32 qId = oraclize_query(3600, "URL", "json(https://api.infura.io/v1/ticker/ethusd).ask");
        validIds[qId] = true;
        autoUpdateId = qId;
    }
    
    function instantUpdate() public payable {
        require(hasEnoughFundsInThisCall());

        LogOraclizeQuery("Requesting Oraclize to submit latest ETHUSD price instantly");

        bytes32 qId = oraclize_query("URL", "json(https://api.infura.io/v1/ticker/ethusd).ask");
        validIds[qId] = true;
    }

    function __callback(bytes32 cbId, string result) public {
        require(msg.sender == oraclize_cbAddress());
        require(validIds[cbId]);

        ethInCents = parseInt(result, 2);
        delete validIds[cbId];

        lastOraclizeCallback = block.number;

        LogPriceUpdated(result);

        if (cbId == autoUpdateId) {
            autoUpdateId = bytes32(0);
        } else {
            // Don't auto update if it was instant update.
            return;
        }
        if (!hasEnoughFunds()) {
            // Exit to not revert received price.
            return;
        }
        update();
    }

    function hasEnoughFunds() internal view returns (bool) {
        return oraclize_getPrice("URL") <= this.balance;
    }

    function hasEnoughFundsInThisCall() internal view returns (bool) {
        return oraclize_getPrice("URL") <= msg.value;
    }
}
