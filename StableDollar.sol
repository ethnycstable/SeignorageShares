pragma solidity ^0.5.1;

contract StableDollar {
    using SafeMath for uint256;

    uint8 public constant decimals = 18;
    uint256 public constant decimalFactor = 10 ** uint256(decimals);
    uint256 public totalSupply = 0;
    
    uint256 public eth_exposure;
    uint256 public usd_exposure;
    
    address medianizer = 0xa5aA4e07F5255E14F02B385b1f04b35cC50bdb66;
    
    uint256 public usdPrice = 200 * (10**uint256(18));
    mapping (address => uint256) public eth_balance;
    mapping (address => uint256) public usd_balance;
    mapping (address => uint256) public deposited_eth_balance;
    
    function deposit() public payable {
        eth_balance[msg.sender] += msg.value;
        //Keep track of this user's deposited/withdrawn eth so they can't make the contract insolvent when price goes down
        deposited_eth_balance[msg.sender] += msg.value;
        eth_exposure += msg.value;
    }
    
    function withdraw(uint256 value) public {
        require(eth_balance[msg.sender]>= value);
        require(value <= deposited_eth_balance[msg.sender]);

        eth_balance[msg.sender] -= value;
        //Keep track of this user's deposited/withdrawn eth so they can't make the contract insolvent when price goes down
        deposited_eth_balance[msg.sender] -= value;
        eth_exposure -= value;
        msg.sender.transfer(value);
    }
    
    function convert_to_usd(uint256 ethValue) public {
        require(eth_balance[msg.sender] >= ethValue);
        eth_balance[msg.sender] -= ethValue;
        eth_exposure -= ethValue;
        
        uint256 usdValue = (ethValue*getUsdPrice())/(10**uint256(18));
        
        mint(msg.sender, usdValue);
        usd_exposure += usdValue;
    }
    
    function transferUsd(uint256 usdValue, address _to) public {
        transfer(_to,usdValue);
    }
    
    function convert_to_eth(uint256 usdValue) public {
        require(usd_balance[msg.sender] >= usdValue);
        uint256 ethValue = ((usdValue*(10**uint256(18))/getUsdPrice()));
        eth_balance[msg.sender] += ethValue;
        eth_exposure += ethValue;
        
        burn(msg.sender, usdValue);
        usd_exposure -= usdValue;
    }
    
    function mint(address _to, uint256 _value) public {
        usd_balance[_to] += _value;
        totalSupply += _value;
    }
    
    function burn(address _from, uint256 _value) public {
        usd_balance[_from] -= _value;
        totalSupply -= _value;
    }
    
    function transfer(address _to, uint256 _value) internal returns(bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= usd_balance[msg.sender], "Insufficient tokens transferable");
    
        // SafeMath.sub will throw if the balance is not enough
        usd_balance[msg.sender] = usd_balance[msg.sender].sub(_value);
        usd_balance[_to] = usd_balance[_to].add(_value);
        //emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function getUsdPrice() public view returns (uint256) {
        return usdPrice;
    }
    
    function getUsdPriceO() public view returns (uint256) {
        (bytes32 price, bool valid) = IMedianizer(medianizer).peek();
        require(valid, "MakerDAO Oracle returning invalid value");
        return uint256(price);
    }
    
    function setUsdPrice(uint256 price) public {
        usdPrice = price;
    }
    
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IMedianizer {
    function peek() external view returns(bytes32, bool);

    function read() external view returns(bytes32);

    function set(address wat) external;

    function set(bytes12 pos, address wat) external;

    function setMin(uint96 min_) external;

    function setNext(bytes12 next_) external;

    function unset(bytes12 pos) external;

    function unset(address wat) external;

    function poke() external;

    function poke(bytes32) external;

    function compute() external view returns(bytes32, bool);

    function void() external;

}
