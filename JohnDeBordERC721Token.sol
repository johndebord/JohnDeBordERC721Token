pragma solidity ^0.4.23;


 /// Math operations with safety checks that throw on error
library SafeMath {
    /// @dev Multiplies two numbers, throws on overflow
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /// @dev Integer division of two numbers, truncating the quotient
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /// @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend)
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /// @dev Adds two numbers, throws on overflow
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
contract ERC721 {
    // Required methods
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract JohnDeBordERC721Token is ERC721 {
    using SafeMath for uint256;

    /*** CONSTANTS ***/

    string public constant name = "JohnDeBordERC721";
    string public constant symbol = "JD721";

    bytes4 constant InterfaceID_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 constant InterfaceID_ERC721 =
        bytes4(keccak256("name()")) ^
        bytes4(keccak256("symbol()")) ^
        bytes4(keccak256("totalSupply()")) ^
        bytes4(keccak256("balanceOf(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("transfer(address,uint256)")) ^
        bytes4(keccak256("transferFrom(address,address,uint256)")) ^
        bytes4(keccak256("tokensOfOwner(address)"));


    /*** DATA TYPES ***/

    struct Token {
        address mintedBy;
        uint64 mintedAt;
    }


    /*** STORAGE ***/

    Token[] tokens;

    mapping (uint256 => address) public tokenIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public tokenIndexToApproved;


    /*** EVENTS ***/

    event Mint(address owner, uint256 tokenId);


    /*** INTERNAL FUNCTIONS ***/

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return tokenIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return tokenIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(address _to, uint256 _tokenId) internal {
        tokenIndexToApproved[_tokenId] = _to;

        emit Approval(tokenIndexToOwner[_tokenId], tokenIndexToApproved[_tokenId], _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ++ownershipTokenCount[_to];
        tokenIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            --ownershipTokenCount[_from];
            delete tokenIndexToApproved[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function _mint(address _owner) internal returns (uint256 tokenId) {
        Token memory token = Token({
            mintedBy: _owner,
            mintedAt: uint64(now)
        });
        tokenId = tokens.push(token) - 1;

        emit Mint(_owner, tokenId);

        _transfer(0, _owner, tokenId);
    }


    /*** ERC721 IMPLEMENTATION ***/

    modifier isValidAddress(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return ownershipTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        require(tokenIndexToOwner[_tokenId] != address(0x0));

        owner = tokenIndexToOwner[_tokenId];
    }

    function transfer(address _to, uint256 _tokenId) external isValidAddress(_to) {
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external isValidAddress(_to) {
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) external isValidAddress(_to) {
        require(_owns(msg.sender, _tokenId));

        _approve(_to, _tokenId);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[]) {
        uint256 balance = balanceOf(_owner);

        if (balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](balance);
            uint256 maxTokenId = totalSupply;
            uint256 idx = 0;

            uint256 tokenId;
            for (tokenId = 1; tokenId <= maxTokenId; ++tokenId) {
                if (tokenIndexToOwner[tokenId] == _owner) {
                    result[idx] = tokenId;
                    ++idx;
                }
            }
        }

        return result;
    }

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceID_ERC165) || (_interfaceID == InterfaceID_ERC721));
    }


    /*** OTHER EXTERNAL FUNCTIONS ***/

    function mint() external returns (uint256) {
        return _mint(msg.sender);
    }

    function getToken(uint256 _tokenId) external view returns (address mintedBy, uint64 mintedAt) {
        Token memory token = tokens[_tokenId];

        mintedBy = token.mintedBy;
        mintedAt = token.mintedAt;
    }
}