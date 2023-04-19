// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IERC4907.sol";
import "./ERC4907.sol";

contract ERC721Mock is ERC4907 {
    constructor(string memory name, string memory symbol) ERC4907(name, symbol) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
