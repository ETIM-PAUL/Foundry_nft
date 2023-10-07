// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./interface/ERC721.sol";
import {Utils} from "./library/marketPlaceUtils.sol";

contract MarketPlace {
    event NFTSold(uint256 indexed orderId, Order);

    event NFTListed(uint256 indexed orderId, Order);

    event NFTOrderEdited(uint indexed orderId, Order);

    struct Order {
        address owner;
        address tokenAddress;
        uint tokenId;
        uint nftPrice;
        uint deadline;
        bytes signature;
        bool active;
    }

    //mapping to check if nft is not already listed
    mapping(bytes32 => bool) public hashedToken;

    mapping(uint => Order) public allOrders;

    uint orderId;

    constructor() {}

    function putNFTForSale(
        address _tokenAddress,
        uint _tokenId,
        uint _price,
        uint _deadline,
        bytes memory _signature
    ) public returns (uint _orderId) {
        //checks that the seller is the owner of the nft
        require(
            ERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender,
            "Not Owner"
        );

        //checks that the seller has approves the marketplace to sell the nft
        require(
            ERC721(_tokenAddress).getApproved(_tokenId) == address(this),
            "Please approve NFT to be sold"
        );

        //checks that token address is not an EOA
        // require(_tokenAddress.code.length > 0, "Token address is an EOA");

        //require that price is greater than zero
        require(_price != 0, "Price must be greater than zero");

        //require that deadline is one hour later than present time
        require(
            _deadline > (block.timestamp + 3600),
            "Deadline must be one hour later than present time"
        );

        bytes32 hashedVal = hashedListing(_tokenAddress, _tokenId);

        //checks if the nft has not been listed before
        require(!hashedToken[hashedVal], "token has been listed");

        bool isVerified = Utils.verify(
            msg.sender,
            _tokenAddress,
            _tokenId,
            _price,
            uint256(_deadline),
            _signature
        );
        require(isVerified, "Invalid Signature");

        orderId++;
        Order storage newOrder = allOrders[orderId];
        newOrder.owner = msg.sender;
        newOrder.signature = _signature;
        newOrder.tokenId = _tokenId;
        newOrder.nftPrice = _price;
        newOrder.deadline = _deadline;
        newOrder.tokenAddress = _tokenAddress;
        newOrder.active = true;
        hashedToken[hashedVal] = true;

        _orderId = orderId;

        emit NFTListed(orderId, newOrder);
    }

    function buyNFT(uint _orderId) public payable {
        Order storage order = allOrders[_orderId];
        address owner = order.owner;
        address tokenAddress = order.tokenAddress;
        uint tokenId = order.tokenId;
        uint nftPrice = order.nftPrice;
        uint deadline = order.deadline;
        bool active = order.active;

        require(active, "Listing not active");
        require(deadline < block.timestamp, "Deadline passed");
        require(msg.value == nftPrice, "Incorrect Eth Value");

        bytes32 hashedVal = hashedListing(tokenAddress, tokenId);

        //to avoid re-entrancy attack, we reset the active state to false
        active = false;
        hashedToken[hashedVal] = false;
        (bool callSuccess, ) = owner.call{value: msg.value}("");
        require(callSuccess, "NFT Purchased failed");
        ERC721(tokenAddress).safeTransferFrom(owner, msg.sender, tokenId);

        emit NFTSold(_orderId, order);
    }

    // add getter for listing
    function getOrder(uint256 _orderId) public view returns (Order memory) {
        // if (_listingId >= listingId)
        return allOrders[_orderId];
    }

    function editOrder(
        uint256 _orderId,
        uint256 _newPrice,
        bool _active
    ) public {
        require(_orderId <= orderId, "Order Doesn't Exist");
        Order storage _order = allOrders[_orderId];
        require(_order.owner == msg.sender, "Not Owner");
        _order.nftPrice = _newPrice;
        _order.active = _active;
        emit NFTOrderEdited(_orderId, _order);
    }

    //function to hash token listing to avoind duplicate
    function hashedListing(
        address _tokenAddress,
        uint _tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_tokenAddress, _tokenId));
    }
}
