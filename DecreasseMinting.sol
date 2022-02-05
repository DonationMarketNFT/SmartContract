// Klaytn IDE uses solidity 0.4.24, 0.5.6 versions.
pragma solidity >=0.4.24 <=0.5.6;

contract IKIP17Receiver {
    function onKIP17Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}

contract NFTSimple {
    string public name = "Minjun";
    string public symbol = "MJ";

    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => string) public tokenURIs;

    // 소유한 토큰 리스트
    mapping(address => uint256[]) private _ownedTokens;
    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;

    function mintWithTokenURI(
        address to,
        uint256 baseTokenId,
        uint256 num2Mint,
        string memory tokenURI
    ) public returns (bool) {
        // to에게 N개의 tokenId(일련번호)를 발행하겠다.
        // 적힐 글자는 tokenURI
        for (uint i = 0; i < num2Mint; i++) {
            uint256 tokenId=baseTokenId+i;
            tokenOwner[tokenId] = to;
            tokenURIs[tokenId] = tokenURI;
            _ownedTokens[to].push(tokenId);   
        }
        return true;
    }

    function safeTransferFrom(
        address from,
        address to,
        bytes memory _data
    ) public {
        //1개씩 trasnfer하고, 0개가 남으면 transfer를 멈춘다
        require(from == msg.sender, "from != msg.sender");
        require(_ownedTokens[from].length == 0,"No NFT Left");
        
        uint256 tokenId = _ownedTokens[from][0];
        _removeTokenFromList(from, tokenId);
        _ownedTokens[to].push(tokenId);
        tokenOwner[tokenId] = to;
        require(
            _checkOnKIP17Received(from, to, tokenId, _data),
            "KIP17: transfer to non KIP17Receiver implementer"
        );
    }

    function _removeTokenFromList(address from, uint256 tokenId) private {
        uint256 lastTokenIdex = _ownedTokens[from].length - 1;
        for (uint256 i = 0; i < _ownedTokens[from].length; i++) {
            if (tokenId == _ownedTokens[from][i]) {
                // Swap last token with deleting token;
                _ownedTokens[from][i] = _ownedTokens[from][lastTokenIdex];
                _ownedTokens[from][lastTokenIdex] = tokenId;
                break;
            }
        }
        //
        _ownedTokens[from].length--;
    }

    function ownedTokens(address owner) public view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    function setTokenUri(uint256 id, string memory uri) public {
        tokenURIs[id] = uri;
    }

    function _checkOnKIP17Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bool success;
        bytes memory returndata;

        if (!isContract(to)) {
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(
                _KIP17_RECEIVED,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        if (
            returndata.length != 0 &&
            abi.decode(returndata, (bytes4)) == _KIP17_RECEIVED
        ) {
            return true;
        }

        return false;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// contract NFTMarket {
//     mapping(uint256 => address) public seller;

//     function buyNFT(uint256 tokenId, address NFT)
//         public
//         payable
//         returns (bool)
//     {
//         address payable receiver = address(uint160(seller[tokenId]));

//         // Send 0.01 klay to Seller
//         receiver.transfer(10**16);

//         // Send NFT if properly send klay
//         NFTSimple(NFT).safeTransferFrom(
//             address(this),
//             msg.sender,
//             tokenId,
//             "0x00"
//         );

//         return true;
//     }

//     // Called when SafeTransferFrom called from NFT Contract
//     function onKIP17Received(
//         address operator,
//         address from,
//         uint256 tokenId,
//         bytes memory data
//     ) public returns (bytes4) {
//         // Set token seller, who was a token owner
//         seller[tokenId] = from;

//         // return signature which means this contract implemented interface for ERC721
//         return
//             bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"));
//     }
// }
