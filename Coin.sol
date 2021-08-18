// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface tokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes calldata extraData) external;
}

/**
 * @title The Coin
 */
contract Coin {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) balance;
    mapping(address => mapping (address => uint256)) allowance;
    
    event Approval(address indexed owner, address indexed recipient, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Burn(address indexed from, uint256 value);

    constructor(uint256 _initialSupply) {
        name = "Coin";
        symbol = "C";
        decimals = 18;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balance[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
    
    modifier validRecipientAddress(address _to) {
        require(_to != address(0x0), "Transfer not allowed to the zero address");
        require(_to != address(this), "Transfer not allowed to the contract itself");
        _;
    }
    
    modifier checkAllowance(address _from, uint256 _value) {
        require(_value <= allowance[_from][msg.sender], "Not enough allowance assigned to sender");
        _;
    }
    
    /**
     * @param _owner Address of token owner
     */
    function balanceOf(address _owner) external view returns (uint256) {
        return balance[_owner];
    }
    
    /**
     * @param _owner Address of token owner
     * @param _spender Address of spender
     */
    function allowanceOf(address _owner, address _spender) external view returns (uint256) {
        return allowance[_owner][_spender];
    }
    
    /**
     * @param _from Address sending tokens
     * @param _to Address recieving tokens
     * @param _value Amount of tokens being sent
     */
    function _transfer(address _from, address _to, uint _value) 
        internal
        validRecipientAddress(_to)
    {
        require(balance[_from] >= _value, "Not enough tokens available for transfer");
        // Check for overflows
        require(balance[_to] + _value >= balance[_to], "Invalid transfer");
        
        uint previousBalances = balance[_from] + balance[_to];
        
        // Subtract tokens sent from sender
        balance[_from] -= _value;
        
        // Add tokens sent to recipient
        balance[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        
        // Assert balance sum equals value before transfer
        assert(balance[_from] + balance[_to] == previousBalances);
    }
    
    /**
     * @param _to Address recieving tokens
     * @param _value Amount of tokens being sent
     * @return success True if transfer is successful
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * @param _from Address sending tokens
     * @param _to Address recieving tokens
     * @param _value Amount of tokens being sent
     * @return success True if transfer is successful
     */
    function transferFrom(address _from, address _to, uint256 _value) 
        public 
        checkAllowance(_from, _value)
        returns (bool success) 
    {
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @param _spender Address of spender
     * @param _value Amount of tokens being approved
     * @return success True if approval is successful
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @param _spender Address of spender
     * @param _value Amount of tokens being approved for spender to spend
     * @param _extraData Additional information that can be sent to the approved contract
     * @return success True if successful
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if(approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
    
    /**
     * Permanently remove tokens from totalSupply
     * 
     * @param _value Amount of tokens to burn
     * @return success True if burn is successful
     */
    function burn(uint256 _value) public returns (bool success) {
        // Check if sender has enough tokens
        require(balance[msg.sender] >= _value, "Not enough tokens available for burn");
        balance[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    
    /**
     * @param _from Address where tokens will be burnt from
     * @param _value Amount of tokens that will be burnt
     * @return success True if burn is successful
     */
    function burnFrom(address _from, uint256 _value)
        public
        checkAllowance(_from, _value)
        returns (bool success)
    {
        require(balance[_from] >= _value, "Not enough tokens available for burn");
        balance[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}