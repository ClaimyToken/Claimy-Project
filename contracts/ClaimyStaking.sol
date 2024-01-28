// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

abstract contract Ownable {
    address internal owner;
    address internal ercContract;

    constructor(address _owner, address _ercContract) {
        owner = _owner;
        ercContract = _ercContract;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not allowed");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    modifier onlyContract() {
        require(isContract(msg.sender), "Not allowed");
        _;
    }

    function isContract(address account) public view returns (bool) {
        return account == ercContract;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
}
abstract contract IActivity is Ownable {
    bool _isActive = false;

    modifier isAllowedClaiming() {
        require(_isActive, "Staking is not active");
        _;
    }

    function allowClaiming(bool _active) external onlyOwner {
        _isActive = _active;
    }

    constructor() {}
}

interface IClaimy {
    function transferFrom(address from, address to, uint256 value) external pure returns (bool);
    function transfer(address to, uint256 value) external pure returns (bool);
    function balanceOf(address account) external pure returns (uint256); 
    function addUserReward(address _user, uint256 _amount) external;
}

contract ClaimyStaking is Ownable, IActivity {
    IClaimy erc20Token;
    
    uint256 rewardsModifier = 10;
    uint256 timeToClaimModifier = 3600;
    uint256 tokensRewarded = 0;

    struct ClaimyBuy {
        uint256 index;
        address user;
        uint256 amount;
        uint256 timestamp;
        bool claimed;
        uint256 claimed_timestamp;
    }

    ClaimyBuy[] claimyBuys;

    constructor(address _address) Ownable(msg.sender, _address) {
        erc20Token = IClaimy(_address);
    }

    function claim(uint idx) external isAllowedClaiming {
        require(idx < claimyBuys.length, "Buy record does not exist");
        require(claimyBuys[idx].user == msg.sender, "Caller is not the depositor");
        require(block.timestamp >= claimyBuys[idx].timestamp + timeToClaimModifier, "User cannot claim at this time");
        uint256 claimable_amount = getReward(claimyBuys[idx].amount);
        require(claimable_amount > 0, "No tokens to claim");
        require(getContractTokensBalance() >= claimable_amount, "Insufficient contract balance");
        uint256 final_amount = claimable_amount;
        require(final_amount > 0, "Contract does not contain enough tokens to cover claim");
        require(erc20Token.balanceOf(msg.sender) >= claimyBuys[idx].amount, "User does not have required funds - not allowed");
        erc20Token.addUserReward(msg.sender, final_amount);
        claimyBuys[idx].claimed_timestamp = block.timestamp; 
        claimyBuys[idx].claimed = true; 
        tokensRewarded += claimable_amount;
    }

    function addBuy(address _sender, uint256 _amount, uint256 _timestamp) external onlyContract {
        ClaimyBuy memory claimy_buy = ClaimyBuy(claimyBuys.length, _sender, _amount, _timestamp, false, 0);
        claimyBuys.push(claimy_buy);
    }

    function getClaimyBuysCount() public view returns (uint256) {
        return claimyBuys.length;
    }

    function getClaimBuys() public view returns (ClaimyBuy[] memory) {
        return claimyBuys;
    }

    function getClaimyBuy(uint256 index) public view returns (ClaimyBuy memory claimy_stake) {
        return claimyBuys[index];
    }

    function getClaimyBuysByUser(address user) public view returns (ClaimyBuy[] memory claimy_stakes, uint256[] memory claimy_stakes_idx) {
        uint256 count = 0;
        for (uint256 i = 0 ; i < claimyBuys.length; i++){
            if(claimyBuys[i].user == user){
                count++;
            }
        }
        ClaimyBuy[] memory temp_claimy_stakes = new ClaimyBuy[](count);
        uint256[] memory temp_claimy_stakes_idx = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0 ; i < claimyBuys.length; i++){
            if(claimyBuys[i].user == user){
                temp_claimy_stakes[j] = claimyBuys[i];
                temp_claimy_stakes_idx[j] = i;
                j++;
            }
        }
        return (temp_claimy_stakes, temp_claimy_stakes_idx);
    }

    function getContractTokensBalance() public view returns (uint256) {
        return erc20Token.balanceOf(address(this));
    }

    function getTokensRewarded() public view returns (uint256) {
        return tokensRewarded;
    }

    function setRewardsModifier(uint256 _modifier) external onlyOwner {
        require(rewardsModifier <= 1000, "Yield rate cannot exceed cannot exceed 1000");
        rewardsModifier = _modifier;
    }

    function setRewardLocktime(uint256 _seconds) external onlyOwner {
        timeToClaimModifier = _seconds;
    }

    function getReward(uint256 amount) public view returns (uint256) {
        return (amount * rewardsModifier) / 1000;
    }
}
