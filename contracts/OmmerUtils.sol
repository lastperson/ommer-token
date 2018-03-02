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


library OmmerUtils {

    /**
     * Checks if n is in the closed interval [a, b].
     */
    function inInterval(uint256 n, uint256 a, uint256 b) public pure returns (bool) {
        return n-a <= b-a;
    }
}
