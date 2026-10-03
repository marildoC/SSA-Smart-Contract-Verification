// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./Taxpayer.sol";

/// @title Echidna harness for Part 3 (age-dependent allowances + pooling invariants)
contract TestTaxpayerPart3 {
    Taxpayer public alice;
    Taxpayer public bob;

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
    function divorceA() public { alice.divorce(); marriedTotalSet = false; marriedTotal = 0; }
    function divorceB() public { bob.divorce(); marriedTotalSet = false; marriedTotal = 0; }

    function transferAtoB(uint change) public {
        uint c = change % 20000;
        alice.transferAllowance(c);
    }

    function transferBtoA(uint change) public {
        uint c = change % 20000;
        bob.transferAllowance(c);
    }

    function birthdayA() public {
        alice.haveBirthday();
        _updateMarriedTotal();
    }

    function birthdayB() public {
        bob.haveBirthday();
        _updateMarriedTotal();
    }
    
    function _updateMarriedTotal() internal {
        if (alice.isMarried() && bob.isMarried()) {
            uint baseA = _baseAllowance(alice);
            uint baseB = _baseAllowance(bob);
            marriedTotal = baseA + baseB;
            marriedTotalSet = true;
        }
    }

    function _baseAllowance(Taxpayer p) internal view returns (uint) {
        return p.age() >= 65 ? 7000 : 5000;
    }

    function _captureMarriedTotal() internal {
        _updateMarriedTotal();
    }

    // ========= Invariants =========

    /// @dev Age-dependent allowances with pooling conservation.
    function echidna_part3_age_and_pooling() public view returns (bool) {
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

    function echidna_no_self_marriage() public view returns (bool) {
        return alice.spouse() != address(alice) && bob.spouse() != address(bob);
    }

    function echidna_symmetric_marriage() public view returns (bool) {
        bool aToB = (alice.spouse() == address(bob));
        bool bToA = (bob.spouse()   == address(alice));
        return (aToB == bToA);
    }

    function echidna_no_half_married() public view returns (bool) {
        bool okA = (!alice.isMarried() && alice.spouse() == address(0)) ||
                   ( alice.isMarried() && alice.spouse() == address(bob));

        bool okB = (!bob.isMarried() && bob.spouse() == address(0)) ||
                   ( bob.isMarried() && bob.spouse() == address(alice));

        return okA && okB;
    }

    function echidna_divorce_cleans_up() public view returns (bool) {
        if (!alice.isMarried() && alice.spouse() != address(0)) return false;
        if (!bob.isMarried()   && bob.spouse()   != address(0)) return false;
        return true;
    }
}
