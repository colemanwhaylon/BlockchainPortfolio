// SPDX-License-Identifier: CC-BY-NC-4.0
// https://spdx.org/licenses/

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable2Step.sol";  // Import Ownable from OpenZeppelin


contract SimpleStorage is Ownable2Step {
    // State variable to store a number
    uint256 private _storedData;

    // Event to log when the stored value is changed
    event ValueChanged(uint256 newValue);

    constructor() payable Ownable(msg.sender){}

    // Function to store a number
    function store(uint256 _value) public onlyOwner {
        uint256 currentValue = _storedData;
        if (_value != currentValue) {
            _storedData = _value;
            emit ValueChanged(_value);
        }
    }

    // Function to retrieve the stored number
    function retrieve() public view returns (uint256 storedValue) {
         storedValue = _storedData;
    }
}
