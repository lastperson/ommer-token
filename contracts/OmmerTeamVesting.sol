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
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./OmmerToken.sol";


contract OmmerTeamVesting is Ownable {

    using SafeMath for uint256;

    uint256 public vestingDate;
    uint256 public maxVestingDate;

    OmmerToken public token;

    // allocated tokens to team members
    //
    // each team member supplies their own EOA and this mapping
    // keeps the number of tokens allocated to that EOA
    mapping(address => uint256) public allocations;

    function OmmerTeamVesting(uint256 vestingPeriodInDays) public {
        // not using safemath here
        vestingDate = now + vestingPeriodInDays * 1 days;
        maxVestingDate = vestingDate + 3 years;
    }

    // extends the vesting period which is the time when withdrawals
    // become activated.
    // @param uint256 noDays number of days which extend the current
    //                vesting end
    // DANGER: if called with a big number the risk would be that the
    // vesting end would become some date in the very distant future.
    // for this reason, the maximum extension is 1 year.
    // DANGER2: repeated extension by one year would also move the
    // vesting date into some distant future. Therefore, the maximum
    // possible vesting is 3 years from the original vesting date.
    function extendVesting(uint256 noDays) public onlyOwner {
        require(noDays > 0);
        require(noDays <= 365);
        uint256 newVestingDate = vestingDate.add(noDays.mul(1 days));

        // check that the new vesting is not beyond the maximal allowed
        // vesting date
        require(maxVestingDate >= newVestingDate);

        vestingDate = newVestingDate;
    }

    function addMember(address memberAddress, uint256 allocation) public onlyOwner {
        require(allocation > 0);
        uint256 original = allocations[memberAddress];
        allocations[memberAddress] = original + allocation;
    }

    // this function is callable by public
    // HOWEVER: only the whitelisted member can withdraw to itself
    // or the contract owner can do that
    function withdraw(address memberAddress, uint256 amount) public {
        // only member or the owner can initiate the transfer
        require(memberAddress == msg.sender || msg.sender == owner);

        uint256 original = allocations[memberAddress];

        // if no balance, then throw
        require(original > 0);
        // if not enough balance, then throw
        require(amount <= allocations[memberAddress]);

        allocations[memberAddress] = original.sub(amount);

        token.transfer(memberAddress, amount);
    }

    function getMemberAllocation(address memberAddress) public constant returns (uint256) {
        return allocations[memberAddress];
    }
}
