//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/openzeppelin-contracts-master/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    event AuctionStarted(
        address indexed _owner,
        uint256 _tokenId,
        string _name
    );

    struct itemsDetails {
        address payable currentOwner;
        address payable previousOwner;
        string name;
        uint256 tokenId;
        uint256 miniBid;
        uint32 mintTime;
        uint32 time;
        uint32 timePeriod;
        bool exists;
        bool auctionStart;
    }

    struct bider {
        uint256 bidAmnt;
        address payable biderAddress;
    }

    address public owner;

    uint256 tokenIds;

    mapping(uint256 => itemsDetails) items;
    mapping(uint256 => bider) public biders;
    mapping(uint256 => mapping(address => uint256)) fundByBiders;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
    }

    modifier onlyNFTowner(uint256 _tokenId) {
        itemsDetails memory _itemsDetails = items[_tokenId];
        require(
            msg.sender == _itemsDetails.currentOwner,
            "Access by only Owner of NFT."
        );
        _;
    }

    modifier notNFTowner(uint256 _tokenId) {
        itemsDetails memory _itemsDetails = items[_tokenId];
        require(
            msg.sender != _itemsDetails.currentOwner,
            "Current Owner can not bid."
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

    modifier auctionStarted(uint256 _tokenId) {
        itemsDetails memory _itemsDetails = items[_tokenId];
        require(_itemsDetails.auctionStart, "Auction not started yet.");
        _;
    }

    function mint(string memory _name) public {
        uint32 timenow = uint32(block.timestamp);
        tokenIds++;
        items[tokenIds] = itemsDetails(
            payable(msg.sender),
            payable(0x0),
            _name,
            tokenIds,
            0,
            timenow,
            0,
            0,
            true,
            false
        );
        _safeMint(msg.sender, tokenIds);
    }

    function getItemDetails(uint256 _tokenId)
        public
        view
        tokenExists(_tokenId)
        returns (
            address currentOwner,
            address previousOwner,
            string memory name,
            uint256 tokenId,
            uint256 miniBid,
            uint32 mintTime,
            uint32 time,
            uint32 timePeriod,
            bool exists,
            bool auctionStart
        )
    {
        itemsDetails memory _itemsDetails = items[_tokenId];
        return (
            _itemsDetails.currentOwner,
            _itemsDetails.previousOwner,
            _itemsDetails.name,
            _itemsDetails.tokenId,
            _itemsDetails.miniBid,
            _itemsDetails.mintTime,
            _itemsDetails.time,
            _itemsDetails.timePeriod,
            _itemsDetails.exists,
            _itemsDetails.auctionStart
        );
    }

    function startAuction(
        uint256 _tokenId,
        uint256 _minBid,
        uint32 _timePeriod
    ) public tokenExists(_tokenId) onlyNFTowner(_tokenId) {
        itemsDetails storage _itemsDetails = items[_tokenId];
        uint32 timenow = uint32(block.timestamp);

        _itemsDetails.miniBid = _minBid * 10**18;
        _itemsDetails.time = timenow;
        _itemsDetails.timePeriod = _itemsDetails.time + _timePeriod;
        _itemsDetails.auctionStart = true;
        emit AuctionStarted(
            _itemsDetails.currentOwner,
            _itemsDetails.tokenId,
            _itemsDetails.name
        );
    }

    function placeBid(uint256 _tokenId)
        public
        payable
        tokenExists(_tokenId)
        auctionStarted(_tokenId)
        notNFTowner(_tokenId)
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
        auctionStarted(_tokenId)
        returns (uint256, address)
    {
        bider memory _bider = biders[_tokenId];
        itemsDetails memory _itemDetails = items[_tokenId];

        if (block.timestamp < _itemDetails.timePeriod)
            revert("Auction still running check after auction ends.");
        return (_bider.bidAmnt, _bider.biderAddress);
    }

    function transferNFT(uint256 _tokenId)
        public
        tokenExists(_tokenId)
        onlyNFTowner(_tokenId)
        returns (bool)
    {
        bider storage _bider = biders[_tokenId];
        itemsDetails storage _itemDetails = items[_tokenId];
        if (block.timestamp < _itemDetails.timePeriod)
            revert("Auction still running check after auction ends.");
        safeTransferFrom(
            _itemDetails.currentOwner,
            _bider.biderAddress,
            _tokenId
        );
        (_itemDetails.currentOwner).transfer(_bider.bidAmnt);
        _itemDetails.previousOwner = _itemDetails.currentOwner;
        _itemDetails.currentOwner = _bider.biderAddress;
        _itemDetails.auctionStart = false;
        fundByBiders[_tokenId][_itemDetails.currentOwner] = 0;
        _bider.bidAmnt = 0;
        _bider.biderAddress = payable(0x0);
        return true;
    }

    function withdrawal(uint256 _tokenId) public tokenExists(_tokenId) {
        if (fundByBiders[_tokenId][msg.sender] < 1) revert();
        payable(msg.sender).transfer(fundByBiders[_tokenId][msg.sender]);
    }

    function getBalance()public view returns(uint){
        return address(this).balance;
    }
}
