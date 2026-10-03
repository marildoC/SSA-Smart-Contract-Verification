// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./ILottery.sol";
import "./ITaxpayer.sol";

contract Taxpayer {
    uint public age;
    bool public isMarried;
    bool private iscontract;

    address public spouse;

    uint constant DEFAULT_ALLOWANCE = 5000;
    uint constant ALLOWANCE_OAP     = 7000;

    uint private tax_allowance;

    // Stored randomness for commit-reveal (Part 4)
    uint256 private rev;

    // Authorization for setTaxAllowance (only trusted contracts)
    mapping(address => bool) private authorizedCallers;

    function baseAllowance() public view returns (uint) {
        return age >= 65 ? ALLOWANCE_OAP : DEFAULT_ALLOWANCE;
    }

    constructor() {
        age = 0;
        isMarried = false;
        spouse = address(0);

        tax_allowance = baseAllowance();
        iscontract = true;
        
        authorizedCallers[address(this)] = true;
    }

    function _safeIsContract(address target) internal view returns (bool ok) {
        (bool success, bytes memory data) = target.staticcall(
            abi.encodeWithSignature("isContract()")
        );
        if (!success || data.length < 32) return false;
        return abi.decode(data, (bool));
    }

    /// @notice Helper used by the partner to synchronize marriage.
    function acknowledgeMarriage(address partner) external {
        require(msg.sender == partner, "only partner can acknowledge marriage");
        require(!isMarried && spouse == address(0), "already married");

        spouse = partner;
        isMarried = true;
        
        authorizedCallers[partner] = true;
    }

    /// @notice Helper used by the partner to synchronize divorce.
    function acknowledgeDivorce(address partner) external {
        require(msg.sender == partner, "only partner can acknowledge divorce");

        spouse = address(0);
        isMarried = false;
        authorizedCallers[partner] = false;
        tax_allowance = baseAllowance();
        rev = 0;
    }

    function marry(address new_spouse) public {
        require(new_spouse != address(0), "invalid spouse");
        require(new_spouse != address(this), "cannot marry self");
        require(!isMarried && spouse == address(0), "already married");
        require(_safeIsContract(new_spouse), "spouse must be Taxpayer contract");

        ITaxpayer other = ITaxpayer(new_spouse);
        require(!other.isMarried(), "spouse already married to someone else");
        require(other.spouse() == address(0), "spouse has existing partner");

        spouse = new_spouse;
        isMarried = true;
        authorizedCallers[new_spouse] = true;

        Taxpayer(new_spouse).acknowledgeMarriage(address(this));
    }

    function divorce() public {
        if (spouse == address(0)) {
            isMarried = false;
            spouse = address(0);
            tax_allowance = baseAllowance();
            rev = 0;
            return;
        }

        address ex = spouse;

        spouse = address(0);
        isMarried = false;
        tax_allowance = baseAllowance();
        rev = 0;
        authorizedCallers[ex] = false;

        Taxpayer(ex).acknowledgeDivorce(address(this));
    }

    function transferAllowance(uint change) public {
        require(isMarried && spouse != address(0), "must be married to transfer");
        require(change <= tax_allowance, "not enough allowance");

        tax_allowance = tax_allowance - change;

        Taxpayer sp = Taxpayer(spouse);
        sp.setTaxAllowance(sp.getTaxAllowance() + change);
    }

    /// @notice Increase age by one year.
    function haveBirthday() public {
        age++;

        if (age == 65) {
            uint delta = ALLOWANCE_OAP - DEFAULT_ALLOWANCE;
            tax_allowance += delta;
        }
    }

    /// @notice Authorize a lottery contract to modify tax allowance.
    function authorizeLottery(address lottery) public {
        require(lottery != address(0), "invalid lottery address");
        require(_safeIsContract(lottery), "lottery must be contract");
        authorizedCallers[lottery] = true;
    }

    /// @notice Low-level setter used by trusted contracts.
    function setTaxAllowance(uint ta) public {
        require(authorizedCallers[msg.sender], "unauthorized caller");
        tax_allowance = ta;
    }

    function getTaxAllowance() public view returns (uint) {
        return tax_allowance;
    }

    function isContract() public view returns (bool) {
        return iscontract;
    }

    /// @notice Join the lottery managed by lot with randomness r.
    function joinLottery(address lot, uint256 r) public {
        require(age < 65, "only under 65 can join lottery");
        require(lot != address(0), "invalid lottery");
        require(_safeIsContract(lot), "lottery must be contract");
        require(rev == 0, "pending reveal");

        ILottery l = ILottery(lot);
        l.commit(keccak256(abi.encode(r)));
        rev = r;
    }

    /// @notice Reveal the previously committed value to the lottery.
    function revealLottery(address lot, uint256 r) public {
        require(lot != address(0), "invalid lottery");
        require(r == rev, "reveal must match commit");
        require(rev != 0, "no pending reveal");

        ILottery l = ILottery(lot);
        l.reveal(r);

        rev = 0;
    }
}
