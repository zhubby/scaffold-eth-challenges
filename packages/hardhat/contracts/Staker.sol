pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    // Add the `receive()` special function that receives eth and calls stake()
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;

    uint256 public deadline = block.timestamp + 30 seconds;

    event Stake(address indexed sender, uint256 amount);

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // 修饰符 检查到期时间
    modifier deadlineReached(bool requireReached) {
        uint256 timeRemaining = timeLeft();
        if (requireReached) {
            require(timeRemaining == 0, "Deadline is not reached yet");
        } else {
            require(timeRemaining > 0, "Deadline is already reached");
        }
        _;
    }

    // 修饰符 检查质押是否完成
    modifier stakeNotCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");
        _;
    }

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    function execute() public stakeNotCompleted deadlineReached(false) {
        uint256 contractBalance = address(this).balance;
        // check the contract has enough ETH to reach the treshold
        require(contractBalance >= threshold, "Threshold not reached");
        // Execute the external contract, transfer all the balance to the contract
        // (bool sent, bytes memory data) = exampleExternalContract.complete{value: contractBalance}();
        (bool sent, ) = address(exampleExternalContract).call{
            value: contractBalance
        }(abi.encodeWithSignature("complete()"));
        require(sent, "exampleExternalContract.complete failed");
    }

    /**
     * @notice Allow users to withdraw their balance from the contract only if deadline is reached but the stake is not completed
     * Add a `withdraw(address payable)` function lets users withdraw their balance
     */
    function withdraw() public deadlineReached(true) stakeNotCompleted {
        uint256 userBalance = balances[msg.sender];

        // check if the user has balance to withdraw
        require(userBalance > 0, "You don't have balance to withdraw");

        // reset the balance of the user
        balances[msg.sender] = 0;

        // Transfer balance back to the user
        (bool sent, ) = msg.sender.call{value: userBalance}("");
        require(sent, "Failed to send user balance back to the user");
    }

    function stake() public payable {
        // update the user's balance
        balances[msg.sender] += msg.value;

        // emit the event to notify the blockchain that we have correctly Staked some fund for the user
        emit Stake(msg.sender, msg.value);
    }
}
