// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NotPudgyPenguins is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "https://nftstorage.link/ipfs/";
    string public uriSuffix = ".json";
    string public metadataUri;

    uint256 public cost = 2500000000000000;
    uint256 public maxSupply = 8888;
    uint256 public reserve = 222;
    uint256 public freeClaim = 2000;
    uint256 public maxMintPerWallet = 5;
    uint256 public freeCount = 0;

    bool public paused = true;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _metadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setMetadataUri(_metadataUri);
        _safeMint(msg.sender, reserve);
    }

    function mintPublic(uint256 _mintAmount) public payable {
        require(
            msg.sender == tx.origin,
            "No transaction from smart contracts!"
        );
        require(!paused, "The contract is paused!");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );

        if (freeCount != freeClaim && freeCount < freeClaim) {
            require(
                balanceOf(_msgSender()) + _mintAmount <= maxMintPerWallet,
                "Limit Per Wallet Reached"
            );
            freeCount += _mintAmount;
        } else {
            require(msg.value >= cost * (_mintAmount), "Insufficient Funds");
            require(
                balanceOf(_msgSender()) + _mintAmount <= maxMintPerWallet,
                "Limit Per Wallet Reached"
            );
        }

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintDev(uint256 _mintAmount, address _to) external {
        require(msg.sender == owner(), "Invalid Sender!");
        require(totalSupply() + _mintAmount < maxSupply, "Max Allocation Reached!");

        _safeMint(_to, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = metadataUri;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        uriPrefix,
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setMetadataUri(string memory _metadataUri) public onlyOwner {
        metadataUri = _metadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() external {
        require(msg.sender == owner(), "Invalid Sender");
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataUri;
    }
}
