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

  uint256 private _amountCollected;

  address public nftContract;
  address public acceptedTokenAddress;
  uint256 public listingPrice = 0.1 ether;

  struct MarketItem {
    uint itemId;
    uint256 tokenId;
    address seller;
    address owner;
    uint256 price;
  }

  mapping(uint256 => MarketItem) public idToMarketItem;

  event MarketItemCreated (
    uint indexed itemId,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price
  );

  constructor(address _nftContract, address _acceptedTokenAddress) {
    nftContract = _nftContract;
    acceptedTokenAddress = _acceptedTokenAddress;
  }

  function addItemToMarket(
    uint256 tokenId,
    uint256 price
  ) public nonReentrant onlyOwner {
    require(price > 0, "Price must be at least 1 wei");
    require(price >= listingPrice, "Price should be at least same as listing price");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();
  
    idToMarketItem[itemId] =  MarketItem(
      itemId,
      tokenId,
      msg.sender,
      address(0),
      price
    );

    IERC20(acceptedTokenAddress).transferFrom(msg.sender, address(this), listingPrice);
    IERC721(nftContract).safeTransferFrom(msg.sender, address(0), tokenId);

    _amountCollected += listingPrice;

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
    ) public nonReentrant {
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(itemPrice >= price, "Asking Price not satisfied!");

    address prevSeller = idToMarketItem[itemId].seller;
    address prevOwner = idToMarketItem[itemId].owner;

    idToMarketItem[itemId].owner = msg.sender;
    idToMarketItem[itemId].seller = msg.sender;

    IERC721(nftContract).transferFrom(prevOwner, msg.sender, tokenId);
    
    IERC20(acceptedTokenAddress).transferFrom(msg.sender, address(this), itemPrice);
    
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
}