// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        // counter.setNumbers(4, 6);
    }

    function test_slot_0() public {
        bytes32 data = vm.load(address(counter), bytes32(uint256(0)));
        assertEq(uint128(uint256(data)), 4);
    }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
