pragma solidity 0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./OmmerToken.sol";


contract OmmerCrowdsale is Ownable {
    using SafeMath for uint256;

    OmmerToken public token;

    //
    // ico can be open or closed
    //
    bool public running;

    //
    // funding variables
    //
    // total raised amount in the crowdsale
    uint256 public weiRaised;
    // cap in terms of wei
    //
    // this cap is actually constant so the variable could be made
    // a constant as well
    uint256 public weiCap;
    // how much wei is one token worth
    uint256 public exchangeRate;

    // Fund Sink is a EOA where the proceeds of the crowdsale are
    // forwarded to.
    address public fundSink;

    //
    // keeps the amounts of ether send by contributors
    // the amount = amount of OMR
    mapping(address => uint256) public lockedup;

    // tokens can only be redeemed when the contributor is approved from the
    // KYC/AML standpoint
    // the amount = amount of OMR
    mapping(address => uint256) public verified;

    //
    event TokensPurchased(
        address indexed _buyer,
        address indexed _beneficiary,
        uint256 _amountWei,
        uint256 _amountOmr
    );

    //
    event TokensReleased(
        address indexed _beneficiary,
        uint256 _amountOmr
    );

    //
    // Crowdsale Constructor
    //
    function OmmerCrowdsale(
        uint256 _exchangeRate,
        address _fundSink,
        address _ommerTokenAddress
    ) public {
        require(_exchangeRate != 0);
        require(_fundSink != 0x0);
        require(_ommerTokenAddress != 0x0);

        running = false;
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
    function purchaseTokens(address _beneficiary) public payable {

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

        running = true;
    }

    function stop() public onlyOwner {
        running = false;
    }

    function verify(address _contributor) public onlyOwner {
        // using require instead of assert because assert failure
        // would consume all the gas available to the function call
        require(lockedup[_contributor] > 0);
        verified[_contributor] = lockedup[_contributor];
        lockedup[_contributor] = 0;
    }

    function unverify(address _contributor) public onlyOwner {
        uint256 verifiedAmt = verified[_contributor];
        verified[_contributor] = 0;
        lockedup[_contributor].add(verifiedAmt);
    }

    function release(address _contributor) public {
        require(verified[_contributor] > 0);
        uint256 amountInOmr = verified[_contributor];
        token.transfer(_contributor, amountInOmr);
        verified[_contributor] = 0;
    }

    // @return true if crowdsale event is running, else otherwise
    function isRunning() public constant returns (bool) {
        return running;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        fundSink.transfer(msg.value);
    }

    function weiRemaining() internal constant returns (uint256) {
        return weiCap - weiRaised;
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        return running && nonZeroPurchase;
    }
}
