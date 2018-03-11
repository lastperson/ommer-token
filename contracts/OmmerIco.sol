/**
 *   ___  _ __ ___  _ __ ___   ___ _ __
 *  / _ \| '_ ` _ \| '_ ` _ \ / _ \ '__|
 * | (_) | | | | | | | | | | |  __/ |
 *  \___/|_| |_| |_|_| |_| |_|\___|_|
 *
 * https://www.ommer.com
 */
pragma solidity 0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./EthUsdPrice.sol";
import "./OmmerToken.sol";


contract OmmerIco is EthUsdPrice, Pausable {

    /** ######################################################################
     *
     *  A T T A C H   L I B R A R Y   F U N C T I O N S
     *
     * ######################################################################
     */
    using SafeMath for uint256;


    /** ######################################################################
     *
     *  S T O R A G E
     *
     * ######################################################################
     */

    /**
     * This is the token being sold in this ICO
     */
    OmmerToken public omr;

    /**
     * Number of remaining OMR tokens for sale
     *
     * Note: The number is in OMR which has 10 ** 18 decimals.
     */
    uint256 private _remainingOmr;

    /**
     * Fund Sink is a EOA where the proceeds of the crowdsale are
     * forwarded to.
     */
    address private _fundSink;

    /**
     * Contribution tracks individual address' value (in OMR) sent to this
     * contract. All OMR are tracked as unconfirmed first. Only after the owner
     * of this ICO contract verifies that the KYC requirements have been met for
     * the particular address, then the owner calls a function which transfers
     * the unconfirmed balance to the address.
     *
     * Both numbers are in OMR which has 10 ** 18 decimals.
     */
    struct Contribution {
        uint256 unconfirmed;
        uint256 withdrawn;
    }

    /**
     * Tracks contribution for each address
     */
    mapping(address => Contribution) public contributions;


    /** ######################################################################
    *
    *  E V E N T S
    *
    * ######################################################################
    */


    /** ######################################################################
     *
     *  F U N C T I O N S
     *
     * ######################################################################
     */

    function OmmerIco(uint256 _initialEthUsdCentsPrice, address _omr, address _ommerEOA) public {
        ethInCents = _initialEthUsdCentsPrice;
        paused = true;
        omr = OmmerToken(_omr);
        _fundSink = _ommerEOA;
    }

    /**
     * incoming transfer: fallback function
     *
     * when someone just sends Ether to the contract address without
     * invoking the purchaseTokens() function, we trigger the purchaseTokens
     * function.
     * NB: as this is a standard transaction the purchaseTokens function
     * should not exceed the std. tx gas limit.
     */
    function () public payable {
        purchaseTokens(msg.sender);
    }

    /**
     * Purchasing means allocating a portion of the unsold OMR tokens to the
     * _beneficiary (which is the sending address).
     *
     *  1) 1 OMR = 1 USD, so we first convert the sent wei into USD
     *  2) Then check if the needed number of OMR is still available
     *  3) Add the OMR number to the contribution list under the sender's address
     *  4) Deduct the OMR number from the available OMR for sale
     */
    function purchaseTokens(address _beneficiary) public whenNotPaused payable {
        require(getMinPossibleContribution() <= msg.value);

        uint256 omrTokens = getUsdCentValue(msg.value) * 10 ** omr.decimals() / 100;

        require(getRemainingTokensForSale() >= omrTokens);

        Contribution storage c = contributions[_beneficiary];

        c.unconfirmed = c.unconfirmed.add(omrTokens);

        _remainingOmr = _remainingOmr.sub(omrTokens);

        forwardFunds();
    }

    /**
     * When starting the sale, the contract checks how many tokens have been
     * allocated for this contract to sell.
     */
    function unpause() public onlyOwner whenPaused {
        _remainingOmr = omr.balanceOf(this);
        assert(_remainingOmr > 0);

        super.unpause();
    }

    function verify(address _beneficiary) public onlyOwner {
        Contribution storage c = contributions[_beneficiary];

        uint256 omrToSend = c.unconfirmed;

        require(omrToSend > 0);

        c.unconfirmed = 0;
        c.withdrawn = c.withdrawn.add(omrToSend);

        omr.transfer(_beneficiary, omrToSend);
    }

    /**
     * Returns the equivalent value in USD cents for the value of wei sent.
     *
     * E.g. if 1 ETH = 825.25 USD which is 82,525 cents then 0.1 ETH which is
     * 100000000000000000 wei will be worth 82.52 USD or 8252 cents.
     *
     * NOTE: there's no rounding!
     */
    function getUsdCentValue(uint256 _wei) public view returns (uint256) {
        return (_wei * ethInCents) / 1 ether;
    }

    function getRemainingTokensForSale() public view returns (uint256) {
        return _remainingOmr;
    }

    /**
     * Returns the minimum possible contribution in wei.
     * The minimum is 0.01 ETH ().
     */
    function getMinPossibleContribution() public pure returns (uint256) {
        return 0.01 ether;
    }

    /**
     * Because this is a non-EOA contract, we need to pass on the contributed
     * funds to an address where Ommer can control them.
     */
    function forwardFunds() internal {
        _fundSink.transfer(msg.value);
    }
}
