// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RentalContract is ERC721URIStorage {
    using Counters for Counters.Counter;

    address public owner;
    address payable public versepropAddress;
    uint256 public dailyRentFee;
    uint256 public mintLimit;
    uint256 public constant FEE_PERCENT = 10;
    string public tokenUri;

    Counters.Counter private tokenIdCounter;

    mapping(uint256 => uint256) public expirations;

    constructor(
        address payable _versepropAddress,
        uint256 _dailyRentFee,
        uint256 _mintLimit,
        string memory _tokenUri
    ) ERC721("VerseToken", "VT") {
        owner = msg.sender;
        versepropAddress = _versepropAddress;
        mintLimit = _mintLimit;
        dailyRentFee = _dailyRentFee;
        tokenUri = _tokenUri;
    }

    function withdraw() external {
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    function mint(uint256 numberOfDays) external payable {
        uint256 totalCost = dailyRentFee * numberOfDays;
        require(msg.value >= totalCost, "Incorrect payment amount");

        uint256 tokenId = tokenIdCounter.current() + 1;
        if (mintLimit > 0) {
            require(tokenId <= mintLimit, "Minting limit reached");
        }

        uint256 expiration = block.timestamp + (numberOfDays * 1 days);

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenUri);
        expirations[tokenId] = expiration;

        tokenIdCounter.increment();

        uint256 fee = totalCost / 10;
        payable(versepropAddress).transfer(fee);
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only token owner can burn");

        uint256 expiration = expirations[tokenId];
        require(expiration > 0, "Token does not exist");

        if (expiration <= block.timestamp) {
            _burn(tokenId);
        } else {
            revert("Token has not expired yet");
        }
    }
}
