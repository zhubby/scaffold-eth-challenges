pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    uint256 public tokensPerEth = 100;
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

    YourToken public yourToken;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    // 购买代币
    function buyTokens() public payable returns (uint256 tokenAmount) {
      // 首先检查合约执行人的eth余额大于0
        require(msg.value > 0, "Send ETH to buy some tokens");
        // 获得代币和eth的比例
        uint256 amountToBuy = msg.value * tokensPerEth;
        // 获取合约所剩的所有余额
        uint256 vendorTokens = yourToken.balanceOf(msg.sender);
        // 检查合约所剩的余额大于执行人需要购买的数量
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );
        // 丛合约内转账到执行人
        bool sent = yourToken.transfer(msg.sender, amountToBuy);
        // 检查转账是否成功
        require(sent, "Failed to transfer token to user");
        // 发送购买事件
        emit BuyTokens(msg.sender, msg.value, amountToBuy);
        // 返回购买的代币数量
        return amountToBuy;
    }

    // 卖出代币 
    function sellTokens(uint256 tokenAmountToSell) public {
      // 检查买出的数量大于0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );
        // 获取用户的代币余额
        uint256 userBalance = yourToken.balanceOf(msg.sender);
        // 要求用户的卖出的代币数量小于用户持有的代币数量
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // 获取代币的和eth的兑换比例
        uint256 amountOfETHToTransfer = tokenAmountToSell / tokensPerEth;
        // 获取合约内可用的eth余额
        uint256 ownerETHBalance = address(this).balance;
        // 检查合约内的eth代币数量大于用户卖出的代币数量
        require(
            ownerETHBalance >= amountOfETHToTransfer,
            "Vendor has not enough funds to accept the sell request"
        );

        // 转账代币到合约
        bool sent = yourToken.transferFrom(
            msg.sender,
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // 转账eth到用户
        (sent, ) = msg.sender.call{value: amountOfETHToTransfer}("");
        require(sent, "Failed to send ETH to the user");
    }

    // 提现
    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has not balance to withdraw");

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");
    }
}
