// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./ITaxpayer.sol";

contract Lottery {
    address public owner;

    mapping(address => bytes32) private commits;
    mapping(address => uint)    private reveals;

    mapping(address => bool)    private participated;  // committed this round
    mapping(address => bool)    private hasRevealed;   // revealed this round

    address[] private committedList; // ALL committers (needed for cleanup)
    address[] private revealed;      // revealers (used for winner)

    uint256 public startTime;
    uint256 public revealTime;
    uint256 public endTime;
    uint256 public period;

    bool private iscontract;

    constructor(uint p) {
        owner = msg.sender;
        period = p;
        startTime = 0;
        revealTime = 0;
        endTime = 0;
        iscontract = true;
    }

    function getRevealedLength() external view returns (uint) {
        return revealed.length;
    }

    function getRevealedAddress(uint idx) external view returns (address) {
        return revealed[idx];
    }

    function getCommit(address who) external view returns (bytes32) {
        return commits[who];
    }

    function getReveal(address who) external view returns (uint) {
        return reveals[who];
    }

    function isContract() public view returns (bool) {
        return iscontract;
    }

    function _safeIsContract(address target) internal view returns (bool) {
        (bool success, bytes memory data) = target.staticcall(
            abi.encodeWithSignature("isContract()")
        );
        if (!success || data.length < 32) return false;
        return abi.decode(data, (bool));
    }

    function startLottery() public {
        require(startTime == 0, "lottery already running");

        startTime = block.timestamp;
        revealTime = startTime + period;
        endTime = revealTime + period;
    }

    function commit(bytes32 y) public {
        require(startTime != 0, "lottery not started");
        require(block.timestamp >= startTime, "too early to commit");
        require(block.timestamp < revealTime, "commit phase ended");
        require(_safeIsContract(msg.sender), "only Taxpayer contracts");

        ITaxpayer tp = ITaxpayer(msg.sender);
        require(tp.age() < 65, "only under 65 can participate");
        require(!participated[msg.sender], "already joined this round");

        commits[msg.sender] = y;
        participated[msg.sender] = true;
        committedList.push(msg.sender);
    }

    function reveal(uint256 rev) public {
        require(startTime != 0, "lottery not started");
        require(block.timestamp >= revealTime, "reveal phase not started");
        require(block.timestamp < endTime, "reveal phase ended");
        require(participated[msg.sender], "no commit for sender");
        require(!hasRevealed[msg.sender], "already revealed");
        
        ITaxpayer tp = ITaxpayer(msg.sender);
        require(tp.age() < 65, "only under 65 can reveal");

        require(
            keccak256(abi.encode(rev)) == commits[msg.sender],
            "invalid reveal"
        );

        hasRevealed[msg.sender] = true;
        revealed.push(msg.sender);
        reveals[msg.sender] = rev;
    }

    function endLottery() public {
        require(startTime != 0, "lottery not started");
        require(block.timestamp >= endTime, "too early to end");

        uint n = revealed.length;

        if (n == 0) {
            _resetRound();
            return;
        }

        uint winnerIndex = 0;
        unchecked {
            for (uint i = 0; i < n; i++) {
                winnerIndex = (winnerIndex + reveals[revealed[i]]) % n;
            }
        }
        address winner = revealed[winnerIndex];

        ITaxpayer(winner).setTaxAllowance(7000);

        _resetRound();
    }

    function _resetRound() internal {
        uint m = committedList.length;
        for (uint i = 0; i < m; i++) {
            address p = committedList[i];
            delete commits[p];
            delete reveals[p];
            participated[p] = false;
            hasRevealed[p] = false;
        }

        delete committedList;
        delete revealed;

        startTime = 0;
        revealTime = 0;
        endTime = 0;
    }
}
