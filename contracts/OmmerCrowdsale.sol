/**
 *   ___  _ __ ___  _ __ ___   ___ _ __
 *  / _ \| '_ ` _ \| '_ ` _ \ / _ \ '__|
 * | (_) | | | | | | | | | | |  __/ |
 *  \___/|_| |_| |_|_| |_| |_|\___|_|
 *
 *  ommer crowdsale
 *
 *  https://www.ommer.com
 *
 */
pragma solidity 0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./OmmerToken.sol";
import "./OmmerUtils.sol";
import "./EthUsdPrice.sol";


/**
 *  Ommer crowdsale accepts ETH contributions and controls and distributes 30M
 *  OMR Tokens.
 *
 *  Quick overview of this smart contract:
 *  - smart contract for receiving the contributions and automatically sending
 *    out OMR tokens
 *  - received funds are forwarded to a selected address (can be EOA)
 *  - built-in KYC process: purchased tokens are kept in the contract until the
 *    owner verifies the KYC documents and marks the buyer as verified
 */
contract OmmerCrowdsale is Ownable, Pausable {
    using SafeMath for uint256;

    // This is the address of the token that this crowdsale is selling
    OmmerToken public token;

    //
    // Funding variables:
    // weiRaised, weiCap, exchangeRate, fundSink
    //

    // Total raised amount in the crowdsale
    uint256 public weiRaised;

    // Cap in terms of wei
    //
    // this cap is actually constant so the variable could be made
    // a constant as well
    uint256 public weiCap;

    // How much wei is one token worth
    uint256 public exchangeRate;

    // Fund Sink is a EOA where the proceeds of the crowdsale are
    // forwarded to.
    address public fundSink;

    // Keeps the amounts of ether send by contributors
    // the amount = amount of OMR
    mapping(address => uint256) public lockedup;

    // Tokens can only be redeemed when the contributor is approved from the
    // KYC/AML standpoint
    // the amount = amount of OMR
    mapping(address => uint256) public verified;


    /** ######################################################################
     *
     *  E V E N T S
     *
     * ######################################################################
     */

    event TokensPurchased(
        address indexed _buyer,
        address indexed _beneficiary,
        uint256 _amountWei,
        uint256 _amountOmr
    );

    event TokensReleased(
        address indexed _beneficiary,
        uint256 _amountOmr
    );

    /** ######################################################################
     *
     *  F U N C T I O N S
     *
     * ######################################################################
     */
    function OmmerCrowdsale(
        uint256 _exchangeRate,
        address _fundSink,
        address _ommerTokenAddress
    ) public {
        require(_exchangeRate != 0);
        require(_fundSink != 0x0);
        require(_ommerTokenAddress != 0x0);

        paused = true;
        exchangeRate = _exchangeRate;
        fundSink = _fundSink;

        token = OmmerToken(_ommerTokenAddress);

        // at construction time the amount raised is set to 0 and the cap
        // is set to 0 as well.
        weiRaised = 0;
        weiCap = 0;
    }

    // incoming transfer: fallback function
    //
    // when someone just sends Ether to the contract address without
    // invoking the purchaseTokens() function, we trigger the purchaseTokens
    // function.
    // NB: as this is a standard transaction the purchaseTokens function
    // should not exceed the std. tx gas limit.
    function () public payable {
        purchaseTokens(msg.sender);
    }

    // 1 ETH buys X amount of OMR
    // OMR has same amount of decimals as ETH (18)
    // So 1 wei = X * exchangeRate OMR
    function purchaseTokens(address _beneficiary) public whenNotPaused payable {

        // sanity checks
        require(_beneficiary != 0x0);
        require(validPurchase());

        // set the amount of wei sent to the contract
        uint256 sentAmountWei = msg.value;
        // represent the sent amount in OMR tokens
        uint256 amountInOmr = sentAmountWei.mul(exchangeRate);

        // buyers can only buy until the hard cap is hit
        // this checks that there are enough tokens remaining
        // for the amount of wei
        require(weiRemaining() >= sentAmountWei);

        // increase the counter
        weiRaised = weiRaised.add(sentAmountWei);
        // and emit an event
        TokensPurchased(msg.sender, address(token), sentAmountWei, amountInOmr);

        // we now add the amount of OMR to the total balance that
        // this buyer has purchased.
        // this quantity is lockedup until the KYC/AML procedure
        // is successfully completed.
        lockedup[_beneficiary].add(amountInOmr);

        forwardFunds();
    }

    // If the contract is paused, the exchange rate can be updated
    function setExchangeRate(uint256 _exchangeRate) public whenPaused onlyOwner {
        assert(_exchangeRate > 0);
        exchangeRate = _exchangeRate;
    }

    function start() public onlyOwner {
        // figure out how many tokens has this contract left so that
        // we know when we have reached the hard cap and won't oversell
        // the token.
        //
        // the calculation works like this:
        //
        // Let S be the total available OMR to this smart contract
        // and r be the number of OMR that 1 ETH will buy.
        // Then the total wei that can be sent (ETH * 10^18) is
        // S/r. Simply because S is already the multiplied by 10^18.
        // Let's assume we have 100 OMR tokens available and the exchange
        // rate is 10 (1 ETH buys 10 OMR). Naturally, the cap is then
        // 10 ETH. In wei the cap is 10000000000000000000 (1 * 10^19 in
        // scientific notation). Because OMR is also denominated
        // with 18 decimals the 100 tokens supply is
        // 100000000000000000000 (1 * 10^20). Dividing the balance
        // by the exchange rate is then (1 * 10^20)/10 which is the
        // cap in wei. This cap divided by 10^18 gives the cap in ETH
        // which is 10.
        weiCap = token.balanceOf(this).div(exchangeRate);

        // if there are no tokens then throw error
        assert(weiCap > 0);

        unpause();
    }

    function stop() public onlyOwner {
        pause();
    }

    // When a contributor finishes their KYC and the result is OK, the owner
    // can verify the contributor by calling this function with the contributor's
    // address, thus enabling the contributor to receive their purchased tokens.
    function verify(address _contributor) public onlyOwner {
        // using require instead of assert because assert failure
        // would consume all the gas available to the function call
        require(lockedup[_contributor] > 0);
        verified[_contributor] = lockedup[_contributor];
        lockedup[_contributor] = 0;
    }

    // Owner can undo the KYC verification for a specified contributor
    function unverify(address _contributor) public onlyOwner {
        uint256 verifiedAmt = verified[_contributor];
        verified[_contributor] = 0;
        lockedup[_contributor].add(verifiedAmt);
    }

    // Sends OMR tokens to the contributor
    // Currenctly anyone can call this function for any contributor
    function release(address _contributor) public {
        require(verified[_contributor] > 0);
        uint256 amountInOmr = verified[_contributor];
        verified[_contributor] = 0;
        token.transfer(_contributor, amountInOmr);
    }

    // Sends Ether to the fund collection wallet
    function forwardFunds() internal {
        fundSink.transfer(msg.value);
    }

    // Returns number of bonus OMR based on the amount of wei contributed
    /* function getOmrWithBonusAmount(uint256 _weiSent) internal view returns (uint256) {
        uint256 _exchangeRate = exchangeRate;

        // No bonus for <= 1 ETH
        // 10% bonus for 1-5 ETH
        if (inInterval(_weiSent, 1 * 10 ** 18, 5 * 10 ** 18)) {
            _exchangeRate * 10 / 100;
        } else
        // 20% bonus for 5-20 ETH
        if (inInterval(_weiSent, 5 * 10 ** 18, 20 * 10 ** 18)) {
            _exchangeRate * 20 / 100;
        } else {
            // above 20 ETH give 30% bonus
            _exchangeRate * 30 / 100;
        }

        // represent the sent amount in OMR tokens
        uint256 withBonusInOmr = _weiSent.mul(_exchangeRate);
        return withBonusInOmr;
    } */

    // wei remaining represents how much Ether can be still sent to the contract
    // for OMR purchases. If sent Ether amount > weiRemaining, then the purchase
    // is cancelled as there would not be enough remaining OMR tokens to satisfy
    // the transaction.
    function weiRemaining() internal constant returns (uint256) {
        return weiCap - weiRaised;
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        return nonZeroPurchase;
    }
}
