// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "../src/MarketPlace.sol";
import {NFT} from "../src/NFT.sol";

contract TestHelpers is Test {
    NFT private nft;
    MarketPlace private marketPlace;
    address nftOwner = 0x9d4eF81F5225107049ba08F69F598D97B31ea644;
    uint256 privKey = vm.envUint("PK");
    event NFTLISTED(uint orderId);
    event NFTSOLD(uint orderId);
    uint token_id;
    uint orderId;
    uint deadline = block.timestamp + 3601;

    function constructSig(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        address _nftOwner
    ) public view returns (bytes memory sig) {
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

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, mHash);
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
        // Deploy NFT contract
        nft = new NFT("IDAN_NFT", "IDAN", "baseUri");
        token_id = nft.mintTo(
            address(0x9d4eF81F5225107049ba08F69F598D97B31ea644)
        );
        vm.prank(0x9d4eF81F5225107049ba08F69F598D97B31ea644);
        nft.approve(address(marketPlace), token_id);
    }

    function test_CreateListing() public {
        //List NFT
        vm.startPrank(0x9d4eF81F5225107049ba08F69F598D97B31ea644);
        bytes memory sig = constructSig(address(nft), token_id, 1e15, nftOwner);
        vm.expectEmit(true, false, false, false);
        // The event we expect
        emit NFTLISTED(1);
        marketPlace.putNFTForSale(sig, token_id, address(nft), 1e15, deadline);
        orderId = 1;
        vm.stopPrank();

        vm.warp(block.timestamp + 3800);
        //Buy NFT
        vm.startPrank(0x1b6e16403b06a51C42Ba339E356a64fE67348e92);
        vm.deal(0x1b6e16403b06a51C42Ba339E356a64fE67348e92, 1e18);
        vm.expectEmit(true, false, false, false);
        // The event we expect
        emit NFTSOLD(1);
        marketPlace.buyNFT{value: 0.001 ether}(orderId);
        vm.stopPrank();
    }
}
