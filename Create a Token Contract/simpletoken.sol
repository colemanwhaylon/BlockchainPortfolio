//SPDX-License-Identifier: CC-BY-NC-4.0
// https://spdx.org/licenses/

pragma solidity 0.8.28;

contract SimpleToken {
    // Token details
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Mapping of addresses to balances
    mapping(address => uint256) public balanceOf;

    // Mapping of addresses to their allowances for other addresses
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Constructor to initialize the token contract
     * @param _name Name of the token
     * @param _symbol Symbol of the token
     * @param _decimals Number of decimal places
     * @param _initialSupply Initial supply of tokens
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        // Calculate total supply with decimals
        totalSupply = _initialSupply * 10**uint256(decimals);

        // Assign all tokens to the contract creator
        balanceOf[msg.sender] = totalSupply;

        // Emit transfer event from address(0) to creator
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /**
     * @dev Transfer tokens from sender to specified address
     * @param _to Address to transfer tokens to
     * @param _value Amount of tokens to transfer
     * @return success Whether the transfer was successful or not     
     */
     function transfer(address _to, uint256 _value)public returns(bool success)
     {
        require(_to != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
     }

         /**      
         * @dev Approve spender to withdraw from your account up to the amount specified     
         * @param _spender Address authorized to spend      
         * @param _value Amount they can spend      
         * @return success Whether the approval was successful or not      
         */ 
         function approve(address _spender, uint256 _value)public returns(bool success)
         {
            allowance[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
         }

        /**      
        * @dev Transfer tokens from one address to another      
        * @param _from Address to transfer tokens from      
        * @param _to Address to transfer tokens to      
        * @param _value Amount of tokens to transfer      
        * @return success Whether the transfer was successful or not      
        */
        function transferFrom(address _from, address _to, uint256 _value)public returns(bool success)
        {
            require(_to != address(0), "Transfer to zero address");
            require(balanceOf[_from] >= _value, "Insufficient balance");
            require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");

            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            allowance[_from][msg.sender] -= _value;

            emit Transfer(_from, _to, _value);
            return true;
        }

}
