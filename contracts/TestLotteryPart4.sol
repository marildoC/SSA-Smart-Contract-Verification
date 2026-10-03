// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./Taxpayer.sol";
import "./Lottery.sol";

/// @title Echidna harness for Part 4 (lottery for under-65 taxpayers)
contract TestLotteryPart4 {
    Lottery  public lot;
    Taxpayer public alice;
    Taxpayer public bob;
    Taxpayer public carol;

    constructor() {
        lot   = new Lottery(1);
        alice = new Taxpayer();
        bob   = new Taxpayer();
        carol = new Taxpayer();

        alice.authorizeLottery(address(lot));
        bob.authorizeLottery(address(lot));
        carol.authorizeLottery(address(lot));
    }

    function startL() public { lot.startLottery(); }
    function endL() public { lot.endLottery(); }

    function joinA(uint r) public { alice.joinLottery(address(lot), r); }
    function joinB(uint r) public { bob.joinLottery(address(lot), r); }
    function joinC(uint r) public { carol.joinLottery(address(lot), r); }

    function revealA(uint r) public { alice.revealLottery(address(lot), r); }
    function revealB(uint r) public { bob.revealLottery(address(lot), r); }
    function revealC(uint r) public { carol.revealLottery(address(lot), r); }

    function birthdayA() public { alice.haveBirthday(); }
    function birthdayB() public { bob.haveBirthday(); }
    function birthdayC() public { carol.haveBirthday(); }

    // ========= Invariants for Part 4 =========

    /// @dev All revealed participants must be valid Taxpayer contracts and under 65.
    function echidna_valid_under65_participants() public view returns (bool) {
        uint n = lot.getRevealedLength();
        for (uint i = 0; i < n; i++) {
            address addr = lot.getRevealedAddress(i);
            Taxpayer p = Taxpayer(addr);

            if (!p.isContract()) return false;
            if (p.age() >= 65)   return false;
        }
        return true;
    }

    /// @dev No address should appear more than once in the revealed list.
    function echidna_no_double_participation() public view returns (bool) {
        uint n = lot.getRevealedLength();
        for (uint i = 0; i < n; i++) {
            address a = lot.getRevealedAddress(i);
            for (uint j = i + 1; j < n; j++) {
                if (a == lot.getRevealedAddress(j)) return false;
            }
        }
        return true;
    }

    /// @dev Under-65 allowance should never exceed 7000.
    function echidna_allowance_cap_under65() public view returns (bool) {
        Taxpayer[3] memory ps = [alice, bob, carol];
        for (uint i = 0; i < 3; i++) {
            if (ps[i].age() < 65 && ps[i].getTaxAllowance() > 7000) {
                return false;
            }
        }
        return true;
    }
}
