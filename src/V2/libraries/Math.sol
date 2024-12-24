// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    /**
     * @dev Calculates the square root of a number using the Babylonian method
     * @param y The number to calculate the square root of
     * @return z The square root of y (rounded down to the nearest integer)
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        // For inputs greater than 3
        if (y > 3) {
            // Initialize z with y as the first upper bound
            z = y;

            // Initial guess: y/2 + 1
            // This is guaranteed to be larger than the square root
            // but smaller than y for all values of y > 3
            uint256 x = y / 2 + 1;

            // The Babylonian method loop
            // Continue until the new estimate (x) is not less than the previous estimate (z)
            // This means we've converged to the largest integer below the actual square root
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            // Special case for y = 1,2,3
            // Their square roots rounded down are all 1
            z = 1;
        }
    }
}
