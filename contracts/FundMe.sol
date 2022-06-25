//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Get funds from users
//Withdraw funds
//Set a minumum funding value in Dollars

import "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  //using constant in a state variable optimizes for gas costs(basically bc it compiles right at deploy time)
  uint256 public constant minimumUSD = 50 * 1e18;

  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;

  address public immutable owner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    //Want to be able to send a min fund amount in USD
    require(
      msg.value.getConversionRate(priceFeed) >= minimumUSD,
      "Didn't send enough"
    );
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    //reset funders balance to 0
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder];
    }
    // reset the array
    funders = new address[](0);
    //withdraw the funds

    //transfer
    //payable(msg.sender).transfer(address(this).balance);
    //send
    //bool sendSuccess= payable(msg.sender).send(address(this).balance);
    //require(sendSuccess, "Send Failed");
    //call
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call Failed");
  }

  modifier onlyOwner() {
    //require (msg.sender == owner);

    if (msg.sender != owner) {
      revert FundMe_NotOwner();
    }
    _;
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
}
