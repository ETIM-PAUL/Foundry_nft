// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "../src/MarketPlace.sol";

contract TestHelpers is Test {
    Vm cheat = Vm(0x9d4eF81F5225107049ba08F69F598D97B31ea644);

    function constructSig(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        address _nftOwner,
        uint256 deadline,
        uint256 privKey
    ) public returns (bytes memory sig) {
        bytes32 mHash = keccak256(
            abi.encodePacked(
                _tokenAddress,
                _tokenId,
                _price,
                _nftOwner,
                deadline
            )
        );

        mHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", mHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = cheat.sign(privKey, mHash);
        sig = getSig(v, r, s);
    }

    function getSig(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory sig) {
        sig = bytes.concat(r, s, bytes1(v));
    }

    function setUp() public {
        marketPlace = new MarketPlace();
    }

    function test_CreateListing() public {
        bytes sig = constructSig(
            0xe08E83520ab894BeFe423C9991272af8F84AbE80,
            1,
            0.001,
            0x9d4eF81F5225107049ba08F69F598D97B31ea644,
            (block.timestamp + 3600),
            ff33adc380a7764580c24d476df5af380723a7f188e919cb5314038c4e3aa013
        );
        marketPlace.putNFTForSale(
            sig,
            1,
            0xe08E83520ab894BeFe423C9991272af8F84AbE80,
            0.001,
            (block.timestamp + 3600)
        );
    }
}
