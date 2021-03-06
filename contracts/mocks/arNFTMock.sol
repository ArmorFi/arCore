// SPDX-License-Identifier: MIT

// File: contracts/libraries/Context.sol

pragma solidity ^0.6.0;

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    external returns (bytes4);
}

contract ERC721 is Context {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    using SafeMath for uint256;
    using Address for address;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    uint256 internal _totalSupply;

    /**
     * @dev Enumerable takes care of this.
    **/
    //mapping (address => Counters.Counter) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
    }

    function totalSupply() public view returns (uint256) {
      return _totalSupply;
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _totalSupply = _totalSupply.add(1);

        emit Transfer(address(0), to, tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _tokenOwner[tokenId] = address(0);
        _totalSupply = _totalSupply.sub(1);

        emit Transfer(owner, address(0), tokenId);
    }
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract ERC721Enumerable is Context, ERC721 {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    /**
     * @dev We've removed allTokens functionality.
    **/
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () public {
    }
    
    /**
     * @dev Added for arNFT (removed from ERC721 basic).
    **/
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokens[owner].length;
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal virtual override {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }
    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal virtual override {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;
    }
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _ownedTokens[from].pop();
    }
}

contract ERC721Metadata is Context, ERC721 {
    string private _name;
    string private _symbol;
    string private _baseURI;
    mapping(uint256 => string) private _tokenURIs;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }
    function _burn(address owner, uint256 tokenId) internal virtual override {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract ERC721Full is ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
    function _burn(address owner, uint256 tokenId) internal override(ERC721Enumerable, ERC721Metadata) {
        super._burn(owner, tokenId);
    }
    function _mint(address owner, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._mint(owner, tokenId);
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._transferFrom(from, to, tokenId);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        _notEntered = true;
    }
    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        // disabled require for making usages simple
        //require((value == 0) || (token.allowance(address(this), spender) == 0),
        //    "SafeERC20: approve from non-zero to non-zero allowance"
        //);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IClaims {
    function getClaimbyIndex(uint _claimId) external view returns (
        uint claimId,
        uint status,
        int8 finalVerdict,
        address claimOwner,
        uint coverId
    );
    function submitClaim(uint coverId) external;
}

/** 
    @title Armor NFT
    @dev Armor NFT allows users to purchase Nexus Mutual cover and convert it into 
         a transferable token. It also allows users to swap their Yearn yNFT for Armor arNFT.
    @author ArmorFi -- Robert M.C. Forster, Taek Lee
**/
contract arNFTMock is
    ERC721Full("ArmorNFT", "arNFT"),
    Ownable,
    ReentrancyGuard {
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    bytes4 internal constant ethCurrency = "ETH";
    
    // cover Id => claim Id
    mapping (uint256 => uint256) public claimIds;
    
    // cover Id => cover price
    mapping (uint256 => uint256) public coverPrices;
    
    // cover Id => yNFT token Id.
    // Used to route yNFT submits through their contract.
    // if zero, it is not swapped from yInsure
    mapping(uint256 => uint256) public swapIds;

    // indicates if swap for yInsure is available
    // cannot go back to false
    bool public swapActivated;

    // Mock data
    uint256 public coverIdMock;
    uint256 public claimIdMock;

    mapping(uint256 => uint8) status_;
    mapping(uint256 => uint256) sumAssured_;
    mapping(uint256 => uint16) coverPeriod_;
    mapping(uint256 => uint256) validUntil_;
    mapping(uint256 => address) scAddress_;
    mapping(uint256 => bytes4) currencyCode_;
    mapping(uint256 => uint256) premiumNXM_;
    mapping(uint256 => uint256) claimId_;
    mapping(uint256 => uint256) claimStatus_;
    
    enum CoverStatus {
        Active,
        ClaimAccepted,
        ClaimDenied,
        CoverExpired,
        ClaimSubmitted,
        Requested
    }
    
    enum ClaimStatus {
        PendingClaimAssessorVote, // 0
        PendingClaimAssessorVoteDenied, // 1
        PendingClaimAssessorVoteThresholdNotReachedAccept, // 2
        PendingClaimAssessorVoteThresholdNotReachedDeny, // 3
        PendingClaimAssessorConsensusNotReachedAccept, // 4
        PendingClaimAssessorConsensusNotReachedDeny, // 5
        FinalClaimAssessorVoteDenied, // 6
        FinalClaimAssessorVoteAccepted, // 7
        FinalClaimAssessorVoteDeniedMVAccepted, // 8
        FinalClaimAssessorVoteDeniedMVDenied, // 9
        FinalClaimAssessorVotAcceptedMVNoDecision, // 10
        FinalClaimAssessorVoteDeniedMVNoDecision, // 11
        ClaimAcceptedPayoutPending, // 12
        ClaimAcceptedNoPayout, // 13
        ClaimAcceptedPayoutDone // 14
    }

    event SwappedYInsure (
        uint256 indexed yInsureTokenId,
        uint256 indexed coverId
    );

    event ClaimSubmitted (
        uint256 indexed coverId,
        uint256 indexed claimId
    );
    
    event ClaimRedeemed (
        address indexed receiver,
        bytes4 indexed currency,
        uint256 value
    );

    event BuyCover (
        uint indexed coverId,
        address indexed buyer,
        address indexed coveredContract,
        bytes4 currency,
        uint256 coverAmount,
        uint256 coverPrice,
        uint256 startTime,
        uint16 coverPeriod
    );

    function mockSetCoverStatus(uint256 _coverId, uint8 _status) external {
        status_[_coverId] = _status;
    }

    function mockSetClaimStatus(uint256 _claimId, uint256 _claimStatus) external {
        claimStatus_[_claimId] = _claimStatus;
    }
    
    /**
     * @dev Make sure only the owner of a token or someone approved to transfer it can call.
     * @param _tokenId Id of the token being checked.
    **/
    modifier onlyTokenApprovedOrOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner");
        _;
    }

    receive() payable external {}
    
    // Arguments to be passed as coverDetails, from the quote api:
    //    coverDetails[0] = coverAmount;
    //    coverDetails[1] = coverPrice;
    //    coverDetails[2] = coverPriceNXM;
    //    coverDetails[3] = expireTime;
    //    coverDetails[4] = generationTime;
    /**
     * @dev Main function to buy a cover.
     * @param _coveredContractAddress Address of the protocol to buy cover for.
     * @param _coverCurrency bytes4 currency name to buy coverage for.
     * @param _coverPeriod Amount of time to buy cover for.
     * @param _v , _r, _s Signature of the Nexus Mutual API.
    **/
    function buyCover(
        address _coveredContractAddress,
        bytes4 _coverCurrency,
        uint[] calldata _coverDetails,
        uint16 _coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        uint256 coverPrice = _coverDetails[1];
        
        uint256 coverId = _buyCover(_coveredContractAddress, _coverCurrency, _coverDetails, _coverPeriod, _v, _r, _s);
        _mint(msg.sender, coverId);
        
        emit BuyCover(coverId, msg.sender, _coveredContractAddress, _coverCurrency, _coverDetails[0], _coverDetails[1], 
                      block.timestamp, _coverPeriod);
    }
    
    /**
     * @dev Submit a claim for the NFT after a hack has happened on its protocol.
     * @param _tokenId ID of the token a claim is being submitted for.
    **/
    function submitClaim(uint256 _tokenId) external onlyTokenApprovedOrOwner(_tokenId) {
        (uint256 coverId, uint8 coverStatus, /*sumAssured*/, /*coverPeriod*/, uint256 validUntil) = _getCover2(_tokenId);
        if (claimIds[_tokenId] > 0) {
            require(coverStatus == uint8(CoverStatus.ClaimDenied),
            "Can submit another claim only if the previous one was denied.");
        }
        
        // A submission until it has expired + a defined amount of time.
        require(validUntil + _getLockTokenTimeAfterCoverExpiry() >= block.timestamp, "Token is expired");
        uint256 claimId = _submitClaim(coverId);
        claimIds[_tokenId] = claimId;
        
        emit ClaimSubmitted(coverId, claimId);
    }
    
    /**
     * @dev Redeem a claim that has been accepted and paid out.
     * @param _tokenId Id of the token to redeem claim for.
    **/
    function redeemClaim(uint256 _tokenId) public onlyTokenApprovedOrOwner(_tokenId)  nonReentrant {
        require(claimIds[_tokenId] != 0, "No claim is in progress.");
        
        (/*cid*/, /*memberAddress*/, /*scAddress*/, bytes4 currencyCode, /*sumAssured*/, /*premiumNXM*/) = _getCover1(_tokenId);
        ( , uint8 coverStatus, uint256 sumAssured, , ) = _getCover2(_tokenId);
        
        require(coverStatus == uint8(CoverStatus.ClaimAccepted), "Claim is not accepted");
        require(_payoutIsCompleted(claimIds[_tokenId]), "Claim accepted but payout not completed");
       
        // this will prevent duplicate redeem 
        _burn(_tokenId);
        _sendAssuredSum(currencyCode, sumAssured);
        
        emit ClaimRedeemed(msg.sender, currencyCode, sumAssured);
    }
    
    function activateSwap()
      public
      onlyOwner
    {
        require(!swapActivated, "Already Activated");
        swapActivated = true;
    }

    /**
     * @dev External swap yNFT token for our own. Simple process because we do not need to create cover.
     * @param _ynftTokenId The ID of the token on yNFT's contract.
    **/
    function swapYnft(uint256 _ynftTokenId)
      public
    {
        emit SwappedYInsure(_ynftTokenId, 0);
    }
    
    /**
     * @dev Swaps a batch of yNFT tokens for our own.
     * @param _tokenIds An array of the IDs of the tokens on yNFT's contract.
    **/
    function batchSwapYnft(uint256[] calldata _tokenIds)
      external
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            swapYnft(_tokenIds[i]);
        }
    }
    
   /**
     * @dev Owner can approve the contract for any new ERC20 (so we don't need to in every buy).
     * @param _tokenAddress Address of the ERC20 that we want approved.
    **/
    function approveToken(address _tokenAddress)
      external
    {
        IERC20 erc20 = IERC20(_tokenAddress);
        erc20.safeApprove( address(0), uint256(-1) );
    }
    
    /**
     * @dev Getter for all token info from Nexus Mutual.
     * @param _tokenId of the token to get cover info for (also NXM cover ID).
    **/
    function getToken(uint256 _tokenId)
      external
      view
    returns (uint256 cid, 
             uint8 status, 
             uint256 sumAssured,
             uint16 coverPeriod, 
             uint256 validUntil, 
             address scAddress, 
             bytes4 currencyCode, 
             uint256 premiumNXM,
             uint256 coverPrice,
             uint256 claimId)
    {
        (/*cid*/, /*memberAddress*/, scAddress, currencyCode, /*sumAssured*/, premiumNXM) = _getCover1(_tokenId);
        (cid, status, sumAssured, coverPeriod, validUntil) = _getCover2(_tokenId);
        coverPrice = coverPrices[_tokenId];
        claimId = claimIds[_tokenId];
    }
    
    /**
     * @dev Get status of a cover claim.
     * @param _tokenId Id of the token we're checking.
    **/
    function getCoverStatus(uint256 _tokenId) external view returns (uint8 coverStatus, bool payoutCompleted) {
        (, coverStatus, , , ) = _getCover2(_tokenId);
        payoutCompleted = _payoutIsCompleted(claimIds[_tokenId]);
    }
    
    /**
     * @dev Get address of the NXM Member Roles contract.
    **/
    function getMemberRoles() public view returns (address) {
        return address(0);
    }
    
    /**
     * @dev Change membership to new address.
     * @param _newMembership Membership address to change to.
    **/
    function switchMembership(address _newMembership) external onlyOwner {
    }
    
    /**
     * @dev Internal function for buying cover--params are same as eponymous external function.
     * @return coverId ID of the new cover that has been bought.
    **/
    function _buyCover(
        address _coveredContractAddress,
        bytes4 _coverCurrency,
        uint[] memory _coverDetails,
        uint16 _coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal returns (uint256 coverId) {
    
        uint256 coverPrice = _coverDetails[1];

        status_[coverIdMock] = 0;
        sumAssured_[coverIdMock] = _coverDetails[0];
        coverPeriod_[coverIdMock] = _coverPeriod;
        validUntil_[coverIdMock] = now + _coverPeriod * 1 days;
        scAddress_[coverIdMock] = _coveredContractAddress;
        currencyCode_[coverIdMock] = _coverCurrency;
        premiumNXM_[coverIdMock] = _coverDetails[2];
   
        coverId = coverIdMock ++;
        
        // Keep track of how much was paid for this cover.
        coverPrices[coverId] = coverPrice;
    }
    
    function mockFillEther() external payable {}
    /**
     * @dev Internal submit claim function.
     * @param _coverId on the NXM contract (same as our token ID).
     * @return claimId of the new claim.
    **/
    function _submitClaim(uint256 _coverId) internal returns (uint256) {
        return ++claimIdMock;
    }
    
    /**
     * @dev Check whether the payout of a claim has occurred.
     * @param _claimId ID of the claim we are checking.
     * @return True if claim has been paid out, false if not.
    **/
    function _payoutIsCompleted(uint256 _claimId) internal view returns (bool) {
        uint256 status;
        status = claimStatus_[_claimId];
        return status == uint256(ClaimStatus.FinalClaimAssessorVoteAccepted)
            || status == uint256(ClaimStatus.ClaimAcceptedPayoutDone);
    }

    /**
     * @dev Send tokens after a successful redeem claim.
     * @param _coverCurrency bytes4 of the currency being used.
     * @param _sumAssured The amount of the currency to send.
    **/
    function _sendAssuredSum(bytes4 _coverCurrency, uint256 _sumAssured) internal {
        uint256 claimReward;

        if (_coverCurrency == ethCurrency) {
            claimReward = _sumAssured * (10 ** 18);
            msg.sender.transfer(claimReward);
        } else {
            IERC20 erc20 = IERC20(_getCurrencyAssetAddress(_coverCurrency));
            uint256 decimals = uint256(erc20.decimals());
        
            claimReward = _sumAssured * (10 ** decimals);
            erc20.safeTransfer(msg.sender, claimReward);
        }
    }
    
    /**
     * @dev Get (some) cover details from the NXM contracts.
     * @param _coverId ID of the cover to get--same as our token ID.
    **/
    function _getCover1 (
        uint256 _coverId
    ) internal view returns (
        uint256 cid,
        address memberAddress,
        address scAddress,
        bytes4 currencyCode,
        uint256 sumAssured,
        uint256 premiumNXM
    ) {
        return (_coverId, address(this), scAddress_[_coverId], currencyCode_[_coverId], sumAssured_[_coverId], premiumNXM_[_coverId]);
    }
    
    /**
     * @dev Get the rest of the cover details from NXM contracts.
     * @param _coverId ID of the cover to get--same as our token ID.
    **/
    function _getCover2 (
        uint256 _coverId
    ) internal view returns (
        uint256 cid,
        uint8 status,
        uint256 sumAssured,
        uint16 coverPeriod,
        uint256 validUntil
    ) {
        return (_coverId, status_[_coverId], sumAssured_[_coverId], coverPeriod_[_coverId], validUntil_[_coverId]);
    }
    
    /**
     * @dev Get current address of the desired currency.
     * @param _currency bytes4 currencyCode of the currency in question.
     * @return Address of the currency in question.
    **/
    function _getCurrencyAssetAddress(bytes4 _currency) internal view returns (address) {
        return address(0);
    }
    
    /**
     * @dev Get address of the NXM token.
     * @return Current NXM token address.
    **/
    function _getTokenAddress() internal view returns (address) {
        return address(0);
    }
    
    /**
     * @dev Get the amount of time that a token can still be redeemed after it expires.
    **/
    function _getLockTokenTimeAfterCoverExpiry() internal returns (uint256) {
        return 35 days;
    }
    
    /**
     * @dev Approve an address to spend NXM tokens from the contract.
     * @param _spender Address to be approved.
     * @param _value The amount of NXM to be approved.
    **/
    function nxmTokenApprove(address _spender, uint256 _value) public onlyOwner {
        IERC20 nxmToken = IERC20(_getTokenAddress());
        nxmToken.safeApprove(_spender, _value);
    }
}
