// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./Taxpayer.sol";

/// @title Echidna harness for Part 1 (marriage invariants)
contract TestTaxpayerPart1 {
    Taxpayer public alice;
    Taxpayer public bob;

    constructor() {
        alice = new Taxpayer();
        bob   = new Taxpayer();
    }

    

    function marryAB() public {
        alice.marry(address(bob));
    }

    function marryBA() public {
        bob.marry(address(alice));
    }

    function divorceA() public {
        alice.divorce();
    }

    function divorceB() public {
        bob.divorce();
    }

    /// @dev Nobody should be married to themselves.
    function echidna_no_self_marriage() public view returns (bool) {
        return
            alice.spouse() != address(alice) &&
            bob.spouse()   != address(bob);
    }

    /// @dev Marriage should be symmetric.
    function echidna_symmetric_marriage() public view returns (bool) {
        bool aToB = (alice.spouse() == address(bob));
        bool bToA = (bob.spouse()   == address(alice));
        
        return (aToB == bToA);
    }

    /// @dev No half-married state.
    function echidna_no_half_married() public view returns (bool) {
        bool aMarried = alice.isMarried();
        bool bMarried = bob.isMarried();

        bool aToB = (alice.spouse() == address(bob));
        bool bToA = (bob.spouse()   == address(alice));

        
        bool okA = (!aMarried && alice.spouse() == address(0)) ||
                   (aMarried  && aToB);
        bool okB = (!bMarried && bob.spouse() == address(0)) ||
                   (bMarried  && bToA);
        return okA && okB;
    }

    /// @dev Divorce must clean up all internal fields.
    function echidna_divorce_cleans_up() public view returns (bool) {
        bool okA = !alice.isMarried()
            ? (alice.spouse() == address(0))
            : true;

        bool okB = !bob.isMarried()
            ? (bob.spouse() == address(0))
            : true;

        return okA && okB;
    }
}
