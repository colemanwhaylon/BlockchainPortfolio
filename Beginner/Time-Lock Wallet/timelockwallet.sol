//SPDX-License-Identifier:  CC-BY-NC-4.0
// https://spdx.org/licenses/

pragma solidity 0.8.28;

/**  
* @title TimeLockWallet  
* @dev A wallet that locks funds for a specified time period.  
* Includes deposit, time-locked withdrawal, and emergency recovery functions.  
*/ 
contract TimeLockWallet
{
    address public owner;
    address public recoveryAddress;

    //Struck to track individual deposits and their lock times
    struct Deposit{
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    //Mapping from depositor address to their deposits
    mapping(address => Deposit[])public deposits;

    //Events for tracking wallet activities
    event FundsDeposited(address indexed depositor, uint256 amount, uint256 unlockTime);
    event FundsWithdrawn(address indexed withdrawer, uint256 amount);
    event EmergencyWithdrawal(address indexed recoveryAddress, uint256 amount);
    event RecoveryAddressChanged(address indexed oldRecoveryAddress, address indexed newRecoveryAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    //Modifers for access control
    modifier onlyOwner()
    {
        require(msg.sender == owner, "Only the wallet owner can perform this action");
        _;
    }

    modifier onlyRecovery()
    {
        require(msg.sender == recoveryAddress, "Only the recovery address can perform this action");
        _;
    }

     /**      
     * @dev Constructor sets the original owner and recovery address      
     * @param _recoveryAddress Address that can perform emergency recovery      
     */ 
     constructor(address _recoveryAddress)
     {
        require(_recoveryAddress != address(0), "Recovery address cannot be zero address");
        owner = msg.sender;
        recoveryAddress = _recoveryAddress;
     }

     /**      
     * @dev Deposit funds with a specified lock period      
     * @param _lockDuration Duration in seconds for which funds will be locked      
     */ 
     function deposit(uint256 _lockDuration)external payable {
        require(msg.value > 0, "Must deposit some ETH");
        require(_lockDuration > 0, "Lock duration must be greater than 0");

        uint256 unlockTime = block.timestamp  + _lockDuration;

        deposits[msg.sender].push(Deposit({
            amount: msg.value,
            unlockTime: unlockTime,
            withdrawn:false
        }));

        emit FundsDeposited(msg.sender, msg.value, unlockTime);
     }

    /**      
    * @dev Withdraw funds if the lock period has expired      
    * @param _depositIndex Index of the deposit to withdraw      
    */ 
    function withdraw(uint256 _depositIndex)external 
    {
        require(_depositIndex < deposits[msg.sender].length, "Invalid deposit index");

        Deposit storage userDeposit = deposits[msg.sender][_depositIndex];

        require(!userDeposit.withdrawn, "Funds already withdrawn");
        require(block.timestamp >= userDeposit.unlockTime, "Funds are still locked");
        require(userDeposit.amount > 0, "No funds to withdraw");
        uint256 amountToWithdraw = userDeposit.amount;
        userDeposit.withdrawn = true;

        //Mark as withdrawn before sending funds to prevent reentrancy attacks
        emit FundsWithdrawn(msg.sender, amountToWithdraw);

        //Use call method for sending ETH (safer than transfer or send)
        (bool success, ) = payable (msg.sender).call{value: amountToWithdraw}("");
        require(success, "Failed to send ETH");
    }


}