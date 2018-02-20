/*
  This file is part of The Colony Network.

  The Colony Network is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  The Colony Network is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with The Colony Network. If not, see <http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.17;
pragma experimental "v0.5.0";
pragma experimental "ABIEncoderV2";


import "./ERC20Extended.sol";


contract TokenAuction {
  ERC20Extended public token;
  uint256 public quantity;

  struct Bid {
    uint256 price;
    uint256 deposit;
    bytes32 blindedBid;
    bool claimed;
  }

  mapping (address => Bid) public bids;
  address public highestBidder;
  uint256 public secondHighestPrice;

  function TokenAuction(address _token, uint256 _quantity) public {
    token = ERC20Extended(_token);
    quantity = _quantity;
  }

  function submitBidSecret(uint256 _deposit, bytes32 _blindedBid) public {
    // TODO: Check the bidding period is open (3 days)
    // TODO: Lock _deposit tokens
    // MAYBE: Check they haven't bid before or overwrite their bid
    // MAYBE: Can we obfuscate the deposit amount too?
    bids[msg.sender] = Bid({
      price: 0,
      deposit: _deposit,
      blindedBid: _blindedBid,
      claimed: false
    });
  }

  /// Winner is the person who revealed the highest bid, but they only have to pay the amount of the second-highest bidder
  function revealBid(uint256 _price, bytes32 _salt) public {
    // TODO: Check the reveal period is open (2 days)
    Bid storage bid = bids[msg.sender];
    bytes32 secret = keccak256(_price, _salt);
    require(secret == bid.blindedBid);
    // Set the price offered
    bid.price = _price;

    // If this is the current highest bidder, set them
    if (_price > secondHighestPrice) {
      highestBidder = msg.sender;
      secondHighestPrice = _price;
    }
    // MAYBE: If bid is not the highest, refund deposit, less a 0.5% fee
  }

  function claimTokens() public {
    // TODO: check bid is not claimed already
    // Only the highest bidder can claim the tokens
    if (highestBidder == msg.sender) {
      Bid storage bid = bids[msg.sender];
      bid.claimed = true;
      token.transfer(msg.sender, quantity);
      // Their CLNY tokens deposit become ours 
    } else {
      // TODO: Unlock their deposit, use CLNY token instead
      token.transfer(msg.sender, quantity);
    }
  }

  // MAYBE: How to penalise bidders who didn't reveal? In ENS they lose their entire bid
}