// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/*
Marketplace contract 
*/

contract TestMarketplace is Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

  address public nftContract;
  address public acceptedTokenAddress;
  uint256 public listingPrice = 0.1 ether;

  struct MarketItem {
    uint itemId;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
  }

  mapping(uint256 => MarketItem) private idToMarketItem;

  event MarketItemCreated (
    uint indexed itemId,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price
  );

  constructor(address _nftContract, address _acceptedTokenAddress) {
    nftContract = _nftContract;
    acceptedTokenAddress = payable(_acceptedTokenAddress);
  }

  function changeNftContract(address _newContract) public onlyOwner {
    require(nftContract != _newContract, "Same Contract Address for New Contract");
    nftContract = _newContract;
  }

  function changeAcceptedToken(address _newAddress) public onlyOwner {
    require(acceptedTokenAddress != _newAddress, "Same Purchase Token supplied");
    acceptedTokenAddress = payable(_newAddress);
  }

  function addItemToMarket(
    uint256 tokenId,
    uint256 price,
    uint256 _listingPrice
  ) public payable nonReentrant onlyOwner {
    require(price > 0, "Price must be at least 1 wei");
    require(_listingPrice == listingPrice, "Price should be same as listing price");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();
  
    idToMarketItem[itemId] =  MarketItem(
      itemId,
      tokenId,
      payable(msg.sender),
      payable(address(this)),
      price
    );

    IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

    emit MarketItemCreated(
      itemId,
      tokenId,
      msg.sender,
      address(0),
      price
    );
  }

  function sellItem(
    uint256 itemId,
    uint256 itemPrice
    ) public payable nonReentrant {
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(itemPrice == price, "Asking Price not satisfied!");

    address prevSeller = payable(idToMarketItem[itemId].seller);
    address prevOwner = payable(idToMarketItem[itemId].owner);

    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].seller = payable(msg.sender);

    IERC721(nftContract).transferFrom(prevOwner, msg.sender, tokenId);
    
    IERC20(acceptedTokenAddress).transferFrom(msg.sender, prevSeller, itemPrice);
    
    _itemsSold.increment();

  }

  function getMarketItemById(uint256 marketItemId) public view returns (MarketItem memory) {
    MarketItem memory item = idToMarketItem[marketItemId];
    return item;
  }

  function getUnsoldItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem memory currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }

  function getItemsByOwner() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketItem memory currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }

  function getItemsBySeller(address _seller) public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == _seller) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == _seller) {
        uint currentId = i + 1;
        MarketItem memory currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }
}