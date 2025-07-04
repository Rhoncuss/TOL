// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PowerNFT is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseURI;
    uint256 public mintPrice = 0.01 ether;
    bool public publicMintEnabled = true;

    event NFTMinted(address indexed minter, uint256 indexed tokenId, string tokenURI);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        baseURI = _baseURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function togglePublicMint(bool enabled) external onlyOwner {
        publicMintEnabled = enabled;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(string calldata customTokenURI) public payable whenNotPaused {
        require(publicMintEnabled || msg.sender == owner(), "Minting not allowed");
        require(msg.sender == owner() || msg.value >= mintPrice, "Not enough ETH");

        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, customTokenURI);

        emit NFTMinted(msg.sender, tokenId, customTokenURI);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory custom = super.tokenURI(tokenId);
        return bytes(custom).length > 0
            ? custom
            : string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }
}
