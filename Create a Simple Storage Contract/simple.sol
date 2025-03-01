// SPDX-License-Identifier: CC-BY-NC-4.0
// https://spdx.org/licenses/

pragma solidity ^0.8.25;

contract SimpleStorage {
    // State variable to store a number
    uint256 private storedData;

    // Event to log when the stored value is changed
    event ValueChanged(uint256 newValue);

    // Function to store a number
    function store(uint256 _value) public {
        storedData = _value;
        emit ValueChanged(_value);
    }

    // Function to retrieve the stored number
    function retrieve() public view returns(uint256)
    {
        return storedData;
    }
}