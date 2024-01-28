// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
 
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not allowed");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

interface IClaimyStaking {
    function addBuy(address _sender, uint256 _amount, uint256 _timestamp) external;
}

contract Claimy is ERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "Claimy";
    string constant _symbol = "CLAIMY";
    uint8 constant _decimals = 9;
    uint256 SWAP_FEES = 15;
    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);

    address public uniswapV2Pair;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) feeExcludedAddresses;

    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public FeeCollector;
    address public ClaimyStaking;
    bool public swapFlagEnabled = true;
    bool public feesFlagEnabled = true;
    uint256 public swapThresholdAmount = (_totalSupply / 1000) * 1;
    bool processingSwap; 

    modifier lockedSwap() {
        processingSwap = true;
        _;
        processingSwap = false;
    }

    constructor() Ownable(msg.sender) {
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        feeExcludedAddresses[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    } 

    function setFeeCollector(address _feeCollector) external onlyOwner {
        FeeCollector = _feeCollector;
    }

    function setExcludedAddresses(address _excludedAddress, bool flag) external onlyOwner {
        feeExcludedAddresses[_excludedAddress] = flag;
    }

    function setClaimyStaking(address _claimyStakingAddress) external onlyOwner {
       ClaimyStaking = _claimyStakingAddress;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }   
    
    function name() external pure override returns (string memory) {
        return _name;
    }    
    
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
		return _decimals;
	}

    function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}   
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) public view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function allowedSwap() internal view returns (bool) {
        return msg.sender != uniswapV2Pair && !processingSwap && swapFlagEnabled && _balances[address(this)] >= swapThresholdAmount;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !feeExcludedAddresses[sender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(SWAP_FEES).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function swapExactTokensForETH() internal lockedSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(swapThresholdAmount, 0, path, address(this), block.timestamp);

        uint256 balanceETH = address(this).balance;

        (bool success, ) = payable(FeeCollector).call{value: balanceETH}("");
        require(success, "Failed to send ETH");
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (processingSwap) {
            return _internalTransfer(sender, recipient, amount);
        }

        if (allowedSwap()) {
            swapExactTokensForETH();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived;
        if (sender == ClaimyStaking || recipient == ClaimyStaking){
            amountReceived = amount;
        } else {
            amountReceived = feesFlagEnabled && shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        }
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if (sender == address(uniswapV2Pair)) {
            IClaimyStaking(ClaimyStaking).addBuy(recipient, amountReceived, block.timestamp);
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _internalTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function addUserReward(address _user, uint256 _amount) external {
        require(msg.sender == ClaimyStaking, "Only staking contract can add user rewards");
        _balances[ClaimyStaking] -= _amount;
        _balances[_user] += _amount;
        emit Transfer(ClaimyStaking, _user, _amount);
    }

    receive() external payable {}
}
