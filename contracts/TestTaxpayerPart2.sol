// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./Taxpayer.sol";

/// @title Echidna harness for Part 2 (tax allowance pooling)
contract TestTaxpayerPart2 {
    Taxpayer public alice;
    Taxpayer public bob;

    // Total allowance at the moment they are (first) observed married.
    uint public marriedTotal;
    bool public marriedTotalSet;

    constructor() {
        alice = new Taxpayer();
        bob   = new Taxpayer();
        marriedTotal = 0;
        marriedTotalSet = false;
    }

    function marryAB() public { alice.marry(address(bob)); _captureMarriedTotal(); }
    function marryBA() public { bob.marry(address(alice)); _captureMarriedTotal(); }
    function divorceA() public { alice.divorce(); marriedTotalSet = false; marriedTotal = 0;}
    function divorceB() public { bob.divorce(); marriedTotalSet = false; marriedTotal = 0; }

    function transferAtoB(uint change) public {
        uint c = change % 6000;
        alice.transferAllowance(c);
    }

    function transferBtoA(uint change) public {
        uint c = change % 6000;
        bob.transferAllowance(c);
    }

    function _baseAllowance(Taxpayer) internal pure returns (uint) {
        return 5000;
    }

    function _captureMarriedTotal() internal {
        if (alice.isMarried() && bob.isMarried() && !marriedTotalSet) {
            marriedTotal = alice.getTaxAllowance() + bob.getTaxAllowance();
            marriedTotalSet = true;
        }
    }

    // ========= Invariants =========

    /// @dev While married, total allowance is conserved. After divorce, both reset to base.
    function echidna_part2_pooling_and_divorce_reset() public view returns (bool) {
        bool marriedNow = (alice.isMarried() && bob.isMarried());

        if (marriedNow) {
            if (!marriedTotalSet) return true;
            uint total = alice.getTaxAllowance() + bob.getTaxAllowance();
            return total == marriedTotal;
        } else {
            return alice.getTaxAllowance() == _baseAllowance(alice) &&
                   bob.getTaxAllowance()   == _baseAllowance(bob);
        }
    }

    /// @dev No self-marriage.
    function echidna_no_self_marriage() public view returns (bool) {
        return alice.spouse() != address(alice) && bob.spouse() != address(bob);
    }

    /// @dev Symmetry.
    function echidna_symmetric_marriage() public view returns (bool) {
        bool aToB = (alice.spouse() == address(bob));
        bool bToA = (bob.spouse()   == address(alice));
        return (aToB == bToA);
    }

    /// @dev No half-married.
    function echidna_no_half_married() public view returns (bool) {
        bool okA = (!alice.isMarried() && alice.spouse() == address(0)) ||
                   ( alice.isMarried() && alice.spouse() == address(bob));

        bool okB = (!bob.isMarried() && bob.spouse() == address(0)) ||
                   ( bob.isMarried() && bob.spouse() == address(alice));

        return okA && okB;
    }

    /// @dev If isMarried is false then spouse must be zero address.
    function echidna_divorce_cleans_up() public view returns (bool) {
        if (!alice.isMarried() && alice.spouse() != address(0)) return false;
        if (!bob.isMarried()   && bob.spouse()   != address(0)) return false;
        return true;
    }
}
