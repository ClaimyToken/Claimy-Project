<h1>Claimy ERC20 & Staking Contract</h1>


<h2>Abstract - Claimy ERC20</h2>
<p>

- SafeMath Library:
    - Implements safe arithmetic operations to prevent overflow and underflow errors.

- ERC-20 Interface:
    - Implements the ERC-20 standard with functions such as totalSupply, decimals, symbol, name, getOwner, balanceOf, transfer, allowance, approve, transferFrom.
    - Defines events Transfer and Approval for tracking token transfers and approvals.

- Ownable Contract:
    - Provides basic ownership functionality.
    - Allows only the owner to execute certain functions (modifier onlyOwner).

- Uniswap Integration:
    - Interfaces with the Uniswap decentralized exchange protocol.
    - Creates a Uniswap trading pair during contract deployment.
    -  Utilizes Uniswap router for token swapping (swapExactTokensForETHSupportingFeeOnTransferTokens).

- Fee System:
    - Implements a fee mechanism on token transfers.
    - Fee percentage (SWAP_FEES) is set to 15%.
    - Excludes certain addresses from fees, managed through the feeExcludedAddresses mapping.
    - Allows the owner to set a fee collector address (FeeCollector).

- Staking Integration:
    - Interacts with a staking contract through the IClaimyStaking interface.
    - Calls the staking contract's addBuy function during token transfers to/from the Uniswap pair.

- Tokenomics:
    - Defines token name, symbol, and decimals.
    - Sets a total supply of 1 billion tokens with 9 decimal places.
    - Manages token balances through the _balances mapping.
    - Allows the owner to renounce ownership (renounceOwnership function).

- Swap and Fee Control:
    - Implements control flags (swapFlagEnabled and feesFlagEnabled) to enable/disable swapping and fees.
    - Sets a threshold amount (swapThresholdAmount) for triggering automatic token swaps.
    - Utilizes a modifier (lockedSwap) to prevent reentrant calls during token swaps.

- Internal Functions:
    - Includes internal functions such as _transferFrom, _internalTransfer, and takeFee for handling transfers and fee calculations.
    
- Claimy Staking:
    - Integrates with a staking contract, and staking-related functions are available.
    - Allows the owner to set the staking contract address (ClaimyStaking).
    - Provides a function (addUserReward) for the staking contract to add rewards to users.

- Fallback Function:
    - Includes a receive function to accept and handle incoming Ether.
</p>

<h2>Abstract - Claimy Staking</h2>
<h4>"ClaimyStaking," is a staking contract that enables users to deposit a specific token (Claimy) and earn rewards based on a set yield rate</h4>

<p>

- Ownable and Activity Contracts:
    - Implements an abstract Ownable contract, allowing for ownership control.
    - Extends the Ownable contract in the main contract and an IActivity abstract contract.
    - The IActivity contract provides a mechanism to control the activity state, allowing the owner to enable or disable staking.
- Token Interface:
    - Interfaces with an ERC-20 token contract through the IClaimy interface.
    - The token contract is specified during deployment and is stored in the erc20Token variable.
- Staking Parameters:
    - Defines staking parameters such as a rewards modifier (rewardsModifier), a time to claim modifier (timeToClaimModifier), and a variable to track total tokens rewarded (tokensRewarded).
- ClaimyBuy Struct:
    - Defines a struct (ClaimyBuy) to represent individual staking transactions, including information such as the user, staked amount, timestamp, claim status, and claimed timestamp.
- Staking Operations:
    - Users can deposit tokens by calling the addBuy function, which adds a new staking record to the claimyBuys array.
    - Users can claim rewards by calling the claim function, provided the staking is active (isAllowedClaiming modifier), the claim period has passed, and there are rewards to claim.
    - The claimed rewards are transferred to the user, and the staking record is marked as claimed.
- Query Functions:
    - Provides various functions to query information about staking records, including the total number of staking records (getClaimyBuysCount), all staking records (getClaimBuys), a specific staking record (getClaimyBuy), and staking records for a specific user (getClaimyBuysByUser).
- Modifiers:
    - Utilizes modifiers (onlyOwner and onlyContract) to restrict access to certain functions based on ownership or contract status.
- Token Balance and Rewards:
    - Provides functions to check the contract's token balance (getContractTokensBalance) and the total tokens rewarded (getTokensRewarded).
    - Allows the owner to set the rewards modifier (setRewardsModifier) and the reward lock time (setRewardLocktime).
- Reward Calculation:
    - Implements a function (getReward) to calculate the reward amount based on the staked amount and the rewards modifier.
</p>


<h2>Instructions</h2>

```
1 - Deploy Claimy contract
2 - Approve max uint allowing the router to spend on behalf of owner
3 - Check for allowance using allowance(ownerAddress, routerAddress)
4 - Deploy Claimy Staking contract setting the ERC20 contract address to the deployed Claimy contract
5 - Set the Claimy Staking contract's address on Claimy contract using setClaimyStaking function
6 - Transfer 45% of total supply to the Claimy Staking contract
7 - Using uniswap router v2, add liquidity to the contract using 50% of total supply
8 - Users are going to be able to swap eth for tokens
9 - To enable claiming tokens - the Claimy owner has to enable claiming using allowClaim(true)
10 - Users would be able to claim tokens after X seconds set by the owner 
```

<h2>List of available functions on ERC20 contract</h2>

```
function setFeeCollector(address _feeCollector) external onlyOwner;
function setExcludedAddresses(address _excludedAddress, bool flag) external onlyOwner;
function setClaimyStaking(address _claimyStakingAddress) external onlyOwner;
function approve(address spender, uint256 amount) public override returns (bool);
function name() external pure override returns (string memory);
function symbol() external pure override returns (string memory);
function decimals() public pure override returns (uint8);
function totalSupply() public view override returns (uint256);
function balanceOf(address account) public view override returns (uint256);
function allowance(address holder, address spender) public view override returns (uint256);
function getOwner() external view override returns (address);
function allowedSwap() internal view returns (bool);
function shouldTakeFee(address sender) internal view returns (bool);
function transfer(address recipient, uint256 amount) public override returns (bool);
function addUserReward(address _user, uint256 _amount);
```


<h2>List of available functions on Claimy Staking contract</h2>

```
function claim(uint idx) external isAllowedClaiming;
function addBuy(address _sender, uint256 _amount, uint256 _timestamp) external onlyContract;
function getClaimyBuysCount() public view returns (uint256);
function getClaimBuys() public view returns (ClaimyBuy[] memory);
function getClaimyBuy(uint256 index) public view returns (ClaimyBuy memory claimy_stake);
function getClaimyBuysByUser(address user) public view returns (ClaimyBuy[] memory claimy_stakes, uint256[] memory claimy_stakes_idx);
function getContractTokensBalance() public view returns (uint256);
function getTokensRewarded() public view returns (uint256);
function setRewardsModifier(uint256 _modifier) external onlyOwner;
function setRewardLocktime(uint256 _seconds) external onlyOwner;
function getReward(uint256 amount) public view returns (uint256);
```

<h2>Simulations</h2>

Simulation 1 - Expected result:
```
Deplyed Claimy ERC20 contract: 0x7f4F351eDdB573D0A55403CAa8c65F0f79ba06e1
Name: Claimy
Symbol: CLAIMY
Total Supply: 1000000000000000000
Decimals: 9
Successfully approved tokens by 0x603E2F582C5a2E52280eBaeA7Ae5aaBF0CF6e982
Checking allowance: 83076749736557242056487941267521535
Successfully deployed Claimy Staking contract: 0x7603D7CFa4765A6700Ed899Fd1350B6E97B32499
Successfully set Claimy Staking contract address
Successfully set staking active flag to true
------------------------
Transferring 45% of total supply to Claimy Staking contract
Successfully transferred 45% of tokens to Claimy Staking contract
Successfully added liquidity
#1 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
#2 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
#3 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
#4 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
#5 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
------------------------
#1 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
#2 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
#3 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
#4 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
#5 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
Checking amount deposited 1244942183545288
Estimated reward amount 12449421835452 for 1244942183545288 deposited
0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 balance: 6262113051555059
0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully claimed tokens
Balance init: 6262113051555059
Balance final: 6274562473390511
Total balance change: 1%
```

Simulation 2 - Expected result:
```
Deplyed Claimy ERC20 contract: 0x7f4F351eDdB573D0A55403CAa8c65F0f79ba06e1
Name: Claimy
Symbol: CLAIMY
Total Supply: 1000000000000000000
Decimals: 9
Successfully approved tokens by 0x603E2F582C5a2E52280eBaeA7Ae5aaBF0CF6e982
Checking allowance: 83076749736557242056487941267521535
Successfully deployed Claimy Staking contract: 0x7603D7CFa4765A6700Ed899Fd1350B6E97B32499
Successfully set Claimy Staking contract address
Successfully set staking active flag to true
------------------------
Transferring 45% of total supply to Claimy Staking contract
Successfully transferred 45% of tokens to Claimy Staking contract
Successfully added liquidity
#1 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
#2 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
#3 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
#4 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
#5 0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully swapped exact eth for tokens
------------------------
#1 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
#2 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
#3 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
#4 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
#5 0x16D97c4B974fF8e1886442aEcF2f02B5Fe2DA7e1 successfully swapped exact eth for tokens
Checking amount deposited 1244942183545288
Estimated reward amount 41083092056994 for 1244942183545288 deposited
0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 balance: 6262113051555059
0x5FBb3997750ea5D6B92da0Ce83cF6619a605aA05 successfully claimed tokens
Balance init: 6262113051555059
Balance final: 6303196143612053
Total balance change: 3.30%
```
