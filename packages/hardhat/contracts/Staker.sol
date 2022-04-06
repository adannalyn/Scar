pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1000000000000000 wei;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw;
    bool contractNotLive;

    event Stake(address staker, uint256 amount);

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        require(deadline >= block.timestamp, "cannot stake after deadline");
        balances[tx.origin] += msg.value;
        emit Stake(tx.origin, balances[tx.origin]);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() public {
        require(block.timestamp > deadline, "wait for the deadline :)");
        require(contractNotLive == false, "function already executed");
        contractNotLive = true;
        if (address(this).balance > threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function withdraw() public {
        require(openForWithdraw == true, "contract is not open for withdrawal");
        uint256 amountOwed = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).call{value: amountOwed}("");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() external view returns (uint256) {
        if (deadline <= block.timestamp) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()

    receive() external payable {
        stake();
    }
}