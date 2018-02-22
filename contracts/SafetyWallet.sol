/**
 *   ___  _ __ ___  _ __ ___   ___ _ __
 *  / _ \| '_ ` _ \| '_ ` _ \ / _ \ '__|
 * | (_) | | | | | | | | | | |  __/ |
 *  \___/|_| |_| |_|_| |_| |_|\___|_|
 *
 * https://www.ommer.com
 */

pragma solidity 0.4.18;


import "zeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * SafetyWallet
 *
 * Allows to create pre-signed transactions that are mineable only after
 * a specified block number.
 *
 * Generate a transaction which calls `forward(blockNum)` and sends some
 * Ether and sign it. If the nonce does not change, when the block number
 * has been mined, you can broadcast the transaction and the sent Ether
 * will be forwarded to Ommer.
 *
 * If you sent another transaction, you will need to generate a new 
 * transaction which calls `forward` and update the nonce in that raw
 * transaction.
 */
contract SafetyWallet is Ownable {

    address public ommerAddress;

    function SafetyWallet(address _ommerAddress) public {
        ommerAddress = _ommerAddress;
    }

    function forward(uint256 _blockNum) public payable {
        require(_blockNum > block.number);
        assert(ommerAddress != address(0));
        assert(msg.value > 0);

        forwardFunds();
    }

    function forwardFunds() internal {
        ommerAddress.transfer(msg.value);
    }
}
