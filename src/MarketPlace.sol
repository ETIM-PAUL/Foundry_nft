// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
    using Strings for uint256;
    string public baseURI;
    uint256 public currentTokenId;
    uint256 public constant TOTAL_SUPPLY = 10_000;
    uint256 public constant MINT_PRICE = 0.01 ether;

    error MintPriceNotPaid();
    error MaxSupply();
    error NonExistentTokenURI();

    struct Order {
        address owner;
        uint tokenId;
        uint nftPrice;
        uint deadline;
        bytes32 signature;
    }

    mapping(uint => Order) allOrders;

    uint orderId;
    uint tokenId;

    uint public constant TOTAL_SUPPLY = 10;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    function mintTo() public payable returns (uint256) {
        if (msg.value != MINT_PRICE) {
            revert MintPriceNotPaid();
        }
        uint256 newTokenId = ++tokenId;
        if (newTokenId > TOTAL_SUPPLY) {
            revert MaxSupply();
        }
        _safeMint(msg.sender, newTokenId);
        return newTokenId;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        if (ownerOf(_tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tokenId.toString()))
                : "";
    }

    function getOrderHash(
        address _tokenAddress,
        uint _tokenId,
        uint _price,
        address _nftOwner
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_tokenAddress, _tokenId, _price, _nftOwner)
            );
    }

    function getEthSignedOrderHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function putNFTForSale(
        bytes32 _signature,
        uint _tokenId,
        uint _price,
        uint _deadline
    ) public {
        orderId++;
        Order newOrder = allOrders[orderId];
        newOrder.signature = _signature;
        newOrder.tokenId = _tokenId;
        newOrder.price = _price;
        newOrder.deadline = _deadline;
    }

    function verify(
        address _signer,
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
}
