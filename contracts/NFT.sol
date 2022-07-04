//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    event MintedSuccessfully(address indexed _to, uint256 tokenId);

    struct itemsDetails {
        address payable ownedBy;
        string name;
        uint256 miniBid;
        uint32 time;
        uint32 timePeriod;
        bool exists;
    }

    struct bider {
        uint256 bidAmnt;
        address payable biderAddress;
    }

    address public owner;

    uint256 public tokenId;

    mapping(uint256 => itemsDetails) public items;
    mapping(uint256 => bider) public biders;
    mapping(uint256 => mapping(address => uint256)) fundByBiders;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier NotOwner() {
        require(msg.sender != owner, "Not Buyer");
        _;
    }

    modifier winner(uint256 _tokenId) {
        bider memory _bider = biders[_tokenId];
        require(
            msg.sender == _bider.biderAddress,
            "Only Owner or only winner can access."
        );
        _;
    }

    modifier miniBidAmt(uint256 _tokenId) {
        itemsDetails memory _itemsDetails = items[_tokenId];
        require(
            msg.value > _itemsDetails.miniBid,
            "Bid amount is less than minimum amount."
        );
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        itemsDetails memory _itemsDetails = items[_tokenId];
        require(_itemsDetails.exists, "Token Id does not exist.");
        _;
    }

    function mint(
        string memory _name,
        uint256 _miniBid,
        uint32 _timePeriod
    ) public onlyOwner {
        uint32 timenow = uint32(block.timestamp);
        tokenId++;
        items[tokenId] = itemsDetails(
            payable(msg.sender),
            _name,
            _miniBid * 10**18,
            timenow,
            timenow + _timePeriod,
            true
        );
        _safeMint(msg.sender, tokenId);
    }

    function getItemDetails(uint256 _tokenId)
        public
        view
        tokenExists(_tokenId)
        returns (
            address ownedBy,
            string memory name,
            uint256 miniBid,
            uint32 time,
            uint32 timePeriod,
            bool exists
        )
    {
        itemsDetails memory _itemsDetails = items[_tokenId];
        return (
            _itemsDetails.ownedBy,
            _itemsDetails.name,
            _itemsDetails.miniBid,
            _itemsDetails.time,
            _itemsDetails.timePeriod,
            _itemsDetails.exists
        );
    }

    function placeBid(uint256 _tokenId)
        public
        payable
        tokenExists(_tokenId)
        NotOwner
        miniBidAmt(_tokenId)
        returns (bool success)
    {
        if (msg.value == 0) revert();

        bider storage _bider = biders[_tokenId];
        itemsDetails storage _itemDetails = items[_tokenId];

        if (block.timestamp > _itemDetails.timePeriod)
            revert("Biding time period ends.");

        uint256 newBid = fundByBiders[_tokenId][msg.sender] + msg.value;

        if (newBid <= _bider.bidAmnt) revert();

        if (msg.sender != _bider.biderAddress) {
            _bider.biderAddress = payable(msg.sender);
        }
        fundByBiders[_tokenId][msg.sender] = newBid;
        _bider.bidAmnt = newBid;
        return true;
    }

    function auctionResult(uint256 _tokenId)
        public
        view
        tokenExists(_tokenId)
        returns (uint256, address)
    {
        bider memory _bider = biders[_tokenId];
        itemsDetails memory _itemDetails = items[_tokenId];

        if (block.timestamp < _itemDetails.timePeriod)
            revert("Auction time still running check after auction ends.");
        return (_bider.bidAmnt, _bider.biderAddress);
    }

    function transferNFT(uint256 _tokenId)
        public
        tokenExists(_tokenId)
        onlyOwner
        returns (bool)
    {
        bider storage _bider = biders[_tokenId];
        itemsDetails storage _itemDetails = items[_tokenId];
        if (block.timestamp < _itemDetails.timePeriod)
            revert("Auction time still running check after auction ends.");
        if (msg.sender == owner) {
            safeTransferFrom(msg.sender, _bider.biderAddress, _tokenId);
            payable(owner).transfer(_bider.bidAmnt);
        }

        _itemDetails.ownedBy = _bider.biderAddress;

        _bider.bidAmnt = 0;
        _bider.biderAddress = payable(0x0);

        return true;
    }

    function OwnerOf(uint256 _tokenId) public view returns (address) {
        return ownerOf(_tokenId);
    }

    // function myTransfer(
    //     address _from,
    //     address _to,
    //     uint256 _tokenId
    // ) public {
    //     transferFrom(_from, _to, _tokenId);
    //     auctionItems storage _auctionItem = totalItems[_tokenId];
    //     _auctionItem.seller = payable(_to);
    // }
}
