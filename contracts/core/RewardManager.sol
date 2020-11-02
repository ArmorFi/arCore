pragma solidity ^0.6.6;

import '../general/SafeMath.sol';
import '../general/Ownable.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IStakeManager.sol';

import 'hardhat/console.sol';
/**
 * @dev RewardManager keeps track of reward balances that yNFT stakers receive. They will be deposited as ARMOR.
**/
contract RewardManager is Ownable {
    
    using SafeMath for uint;
    
    // IERC20 public armorToken;
    IStakeManager public stakeManager;
    
    // Deposits list keeps track of all deposits made.
    // To keep this somewhat clean, we will only be able to deposit a max of once a day.
    Deposit[] public deposits;
    
    // The cost of all currently active NFTs.
    uint256 public totalStakedPrice;
    
    // Full cover cost provided by this user.
    mapping (address => uint256) public userStakedPrice;
    
    // Because of streaming, balance needs to keep track of a few different variables.
    mapping (address => uint256) public balances;
    
    // The last `deposits` index that the user updated on.
    mapping (address => uint256) public nextIndex;
    
    // Deposit struct for every time a deposit of ARMOR tokens is made.
    // This will stream into an account over 24 hours.

    struct Deposit {
        uint256 curTotalPrice;
        uint256 amount;
        uint256 timestamp;
    }

    modifier updateRewards(address _user) {
        updateStake(_user);
        _;
    }
    
    /**
     * @dev Must have LendManager contract to get user balances.
    **/
    function initialize(address _stakeManager/*, address _armorToken*/)
      external
    {
        Ownable.initialize();
        require(stakeManager == IStakeManager( address(0) ), "Contract already initialized.");
        stakeManager = IStakeManager(_stakeManager);
    }

    modifier onlyStakeManager() {
      require(msg.sender == address(stakeManager), "Only StakeManager can call this function");
      _;
    }
    
    /**
     * @dev User can withdraw their rewards.
     * @param _amount The amount of rewards they would like to withdraw.
    **/
    function withdraw(uint256 _amount)
      external
      updateRewards(msg.sender)
    {
        address payable user = msg.sender;
        // Will throw if not enough.        
        balances[user] = balances[user].sub(_amount);
        //armorToken.transfer(user, _amount);
        user.transfer(_amount);
    }
    
    /**
     * @dev Update a user stake anytime stake is added or expired. Since we do this, we know user holdings at every deposit period.
     * @param _user The user whose stake we're updating.
    **/
    function updateStake(address _user)
      public
    {
        uint256 index = nextIndex[_user];
        
        // If user has been staking and is not updated, update reward, otherwise just update index.
        if (index != 0 && index != deposits.length) {
            uint256 coverCost = userStakedPrice[_user];
            uint256 reward = calculateReward(coverCost, index);
            balances[_user] = balances[_user].add(reward);
        }
        
        nextIndex[_user] = deposits.length;
    }
    
    /**
     * @dev Updates many users at once. Used in a case such as needing to update all users before a change to the staking method.
     * @param _users A list of all users to update.
    **/
    function bulkUpdate(address[] calldata _users)
      external
    {
       for (uint256 i = 0; i < _users.length; i++) {
           updateStake(_users[i]);
       } 
    }
    
    /**
     * @dev Deposit tokens to be staked. This is onlyOwner so malicious actors cannot spam the list.
    **/
    function deposit(/*uint256 _amount*/)
      external
      payable
      onlyOwner
    {
        require(msg.value > 0, "deposit amount should be larger than zero");
        Deposit memory newDeposit = Deposit(totalStakedPrice, /*_amount*/ msg.value, now);
        deposits.push(newDeposit);
    }
    
    /**
     * @dev Check the user's reward balance.
     * @param _user The address of the user to check.
    **/
    function balanceOf(address _user)
      external
      view
    returns (uint256 balance)
    {
        uint256 index = nextIndex[_user];
        balance = balances[_user];
         
        // If user has been staking and is not updated, update reward, otherwise just update index.
        if (index != 0 && index != deposits.length) {
            uint256 coverCost = userStakedPrice[_user];
            uint256 reward = calculateReward(coverCost, index);
            balance = balance.add(reward);
        }
    }
    
    /**
     * @dev Get the cover cost a user currently has staked.
     * @param _user Address of the user to check staked for.
    **/
    function getUserStaked(address _user)
      public
      view
    returns (uint256)
    {
        return userStakedPrice[_user];
    }
    
    /**
     * @dev Add stake cost to the individual user and to the total.
     * @param _user The user to add stake to.
     * @param _secondPrice The price of the cover per second.
    **/
    function addStakes(address _user, uint256 _secondPrice)
      external
      onlyStakeManager
      updateRewards(_user)
    {
        userStakedPrice[_user] = userStakedPrice[_user].add(_secondPrice);
        totalStakedPrice = totalStakedPrice.add(_secondPrice);
    }
    
    /**
     * @dev Subtract stake cost to the individual user and to the total.
     * @param _user The user to subtract stake from.
     * @param _secondPrice The price of the cover per second.
    **/
    function subStakes(address _user, uint256 _secondPrice)
      external
      onlyStakeManager
      updateRewards(_user)
    {
        userStakedPrice[_user] = userStakedPrice[_user].sub(_secondPrice);
        totalStakedPrice = totalStakedPrice.sub(_secondPrice);
    }
    
    /**
     * @dev Calculate the staking reward that an insurer should gain. This loops through deposits and calculates reward for each new one.
     * @param _userStakedCost The cost that the user had staked during these periods.
     * @param _lastIndex The last index of deposits that user was rewarded for.
    **/
    function calculateReward(uint256 _userStakedCost, uint256 _lastIndex)
      internal
      view
    returns (uint256 reward)
    {
        // Loop through each new deposit and figure out what the reward for each deposit was.
        for (uint256 i = _lastIndex; i < deposits.length; i++) {
            Deposit memory curDeposit = deposits[i];
            //CHECK: how to get _coverAmount?
            // Example with simple numbers, 10 is a buffer to ensure we don't divide by too big of a number.
            // reward = ( ( 1 * 10 ) / 2 ) * 2 ) / 10
            uint256 buffer = 1e18;
            reward = reward.add( ( _userStakedCost * buffer  * curDeposit.amount) / (curDeposit.curTotalPrice * buffer ));    
        }
    }
}
