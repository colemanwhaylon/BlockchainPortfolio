//SPDX-License-Identifier:  CC-BY-NC-4.0
// https://spdx.org/licenses/

pragma solidity 0.8.28;

/**
 * @title TimeLockWallet
 * @dev A wallet that locks funds for a specified time period.
 * Includes deposit, time-locked withdrawal, and emergency recovery functions.
 */
contract TimeLockWallet {
    address public owner;
    address public recoveryAddress;

    //Struck to track individual deposits and their lock times
    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    //Mapping from depositor address to their deposits
    mapping(address => Deposit[]) public deposits;

    //Events for tracking wallet activities
    event FundsDeposited(
        address indexed depositor,
        uint256 amount,
        uint256 unlockTime
    );
    event FundsWithdrawn(address indexed withdrawer, uint256 amount);
    event EmergencyWithdrawal(address indexed recoveryAddress, uint256 amount);
    event RecoveryAddressChanged(
        address indexed oldRecoveryAddress,
        address indexed newRecoveryAddress
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    //Modifers for access control
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the wallet owner can perform this action"
        );
        _;
    }

    modifier onlyRecovery() {
        require(
            msg.sender == recoveryAddress,
            "Only the recovery address can perform this action"
        );
        _;
    }

    /**
     * @dev Constructor sets the original owner and recovery address
     * @param _recoveryAddress Address that can perform emergency recovery
     */
    constructor(address _recoveryAddress) {
        require(
            _recoveryAddress != address(0),
            "Recovery address cannot be zero address"
        );
        owner = msg.sender;
        recoveryAddress = _recoveryAddress;
    }

    /**
     * @dev Deposit funds with a specified lock period
     * @param _lockDuration Duration in seconds for which funds will be locked
     */
    function deposit(uint256 _lockDuration) external payable {
        require(msg.value > 0, "Must deposit some ETH");
        require(_lockDuration > 0, "Lock duration must be greater than 0");

        uint256 unlockTime = block.timestamp + _lockDuration;

        deposits[msg.sender].push(
            Deposit({
                amount: msg.value,
                unlockTime: unlockTime,
                withdrawn: false
            })
        );

        emit FundsDeposited(msg.sender, msg.value, unlockTime);
    }

    /**
     * @dev Withdraw funds if the lock period has expired
     * @param _depositIndex Index of the deposit to withdraw
     */
    function withdraw(uint256 _depositIndex) external {
        require(
            _depositIndex < deposits[msg.sender].length,
            "Invalid deposit index"
        );

        Deposit storage userDeposit = deposits[msg.sender][_depositIndex];

        require(!userDeposit.withdrawn, "Funds already withdrawn");
        require(
            block.timestamp >= userDeposit.unlockTime,
            "Funds are still locked"
        );
        require(userDeposit.amount > 0, "No funds to withdraw");
        uint256 amountToWithdraw = userDeposit.amount;
        userDeposit.withdrawn = true;

        //Mark as withdrawn before sending funds to prevent reentrancy attacks
        emit FundsWithdrawn(msg.sender, amountToWithdraw);

        //Use call method for sending ETH (safer than transfer or send)
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}(
            ""
        );
        require(success, "Failed to send ETH");
    }

    /**
     * @dev Emergency withdrawal by recovery address
     * @notice This should only be used in emergencies like owner key loss
     */
    function emergencyWithdraw() external onlyRecovery {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");

        emit EmergencyWithdrawal(recoveryAddress, contractBalance);

        //Use call method for sending ETH
        (bool success, ) = payable(recoveryAddress).call{
            value: contractBalance
        }("");
        require(success, "Failed to send ETH");
    }

    /**
     * @dev Change the recovery address
     * @param _newRecoveryAddress New address for emergency recovery
     */
    function changeRecoveryAddress(address _newRecoveryAddress)
        external
        onlyOwner
    {
        require(
            _newRecoveryAddress != address(0),
            "New recovery address cannot be zero address"
        );
        emit RecoveryAddressChanged(recoveryAddress, _newRecoveryAddress);
        recoveryAddress = _newRecoveryAddress;
    }

    /**
     * @dev Transfer ownership of the contract
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Get total number of deposits for a given address
     * @param _depositor Address to check
     * @return Number of deposits
     */
    function getDepositCount(address _depositor)
        external
        view
        returns (uint256)
    {
        return deposits[_depositor].length;
    }

    /**
     * @dev Get detailed information about a specific deposit
     * @param _depositor Address of the depositor
     * @param _depositIndex Index of the deposit
     * @return amount Amount of ETH deposited
     * @return unlockTime Timestamp when funds unlock
     * @return withdrawn Whether funds have been withdrawn
     * @return isUnlocked Whether the time lock has expired
     */
    function getDepositInfo(address _depositor, uint256 _depositIndex)
        external
        view
        returns (
            uint256 amount,
            uint256 unlockTime,
            bool withdrawn,
            bool isUnlocked
        )
    {
        require(
            _depositIndex < deposits[_depositor].length,
            "Invalid deposit index"
        );

        Deposit storage userDeposit = deposits[_depositor][_depositIndex];

        return (
            userDeposit.amount,
            userDeposit.unlockTime,
            userDeposit.withdrawn,
            block.timestamp >= userDeposit.unlockTime
        );
    }

    /**
     * @dev Get contract balance
     * @return Contract balance in wei
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Fallback function to accept ETH
     */
    receive() external payable {
        //Automatically create a deposit with 24-hour lock time
        uint256 unlockTime = block.timestamp + 1 days;

        deposits[msg.sender].push(
            Deposit({
                amount: msg.value,
                unlockTime: unlockTime,
                withdrawn: false
            })
        );

        emit FundsDeposited(msg.sender, msg.value, unlockTime);
    }
}
