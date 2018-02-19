pragma solidity 0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract OmmerToken is StandardToken, Ownable {

    using SafeMath for uint256;

    // Constants for the ERC20 interface
    //
    string public constant name = "ommer";
    string public constant symbol = "OMR";
    uint256 public constant decimals = 18;
    // Our supply is 100 million OMR
    uint256 public constant INITIAL_SUPPLY = 1 * (10 ** 8) * (10 ** decimals);

    // Constructor
    //
    function OmmerToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

}
