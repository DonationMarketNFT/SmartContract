//Klaytn IDE uses solidity 0.4.24 0.5.6 versions.
pragma solidity >=0.4.24 <=0.5.6;

contract NFTSimple {
    string public name = "KlayLion";
    string public symbol = "KL"; // 단위 

    mapping(uint256 => address) public tokenOwner; // token owner mapping
    mapping(uint256 => string) public tokenURIs; // key - value type declare

    // 소유한 토큰 리스트
    mapping(address => uint256[]) private _ownedTokens;
    // onKIP17Received bytes value

    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;

    // mint(tokenId, uri, owner) : 발행
    // transferFrom(from, to, tokenId) : 전송 -> owner가 바뀌는 것 (from -> to)

    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public returns(bool){
        // to에게 tokenId(일련번호)를 발행하겠다. 
        // 적힐 글자는 tokenURI
        tokenOwner[tokenId] = to;
        tokenURIs[tokenId] = tokenURI;

        // add token to the list
        _ownedTokens[to].push(tokenId);

        return true;
    }

    function balanceOf(address owner) public view returns (uint256) {
    require(
        owner != address(0),
        "KIP17: balance query for the zero address"
    );
    return _ownedTokens[owner].length;
}

 function balance (address _addr) public view returns(uint){
          return balanceOf(_addr);
      }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public{
        require(from == msg.sender, "from !- msg.sender"); // 보내는 사람이 현재 이 함수를 실행한 주체 
        require(from == tokenOwner[tokenId], "you are not the owner of the token"); // 보내는 사람이 보내려고 하는 토큰의 주인
        //
        _removeTokenFromList(from, tokenId);
        _ownedTokens[to].push(tokenId);
        //
        tokenOwner[tokenId] = to;

        // 만약에 받는 쪽이 실행할 코드가 있는 스마트 컨트렉트이면 코드를 실행할 것
        require(
            _checkOnKIP17Received(from, to, tokenId, _data), "KIP17: transfer to non KIP17Receiver implement"
        );

        
    }

    //internal option : 외부 호춣 불가 
    function _checkOnKIP17Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns(bool){
        bool success;
        bytes memory returndata;

        if(!isContract(to)){ // smart contract address인지 판별
            return true;
        }

        (success, returndata) = to.call( // 성공여부와 return 값을 받아와라 
            abi.encodeWithSelector(
                _KIP17_RECEIVED, //smart contract면 이걸 실행해라
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        if(
            returndata.length != 0 && //만약 return 값이 존재하며 그 값이 _KIP17_RECEIVED이면, 
            abi.decode(returndata, (bytes4)) == _KIP17_RECEIVED
        ) {
            return true;
        }
        return false;
    }

    function isContract(address account) internal view returns(bool){
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function _removeTokenFromList(address from, uint256 tokenId) private{
        // [10, 15, 19, 20] -> 19번을 삭제하고 싶어요.
        // [10, 15, 20, 19]
        // [10, 15, 20]
        uint256 lastTokenIdx = _ownedTokens[from].length - 1;
        for(uint256 i = 0; i < _ownedTokens[from].length; i++){
            if(tokenId == _ownedTokens[from][i]){
                // swap last token with deleting token;
               _ownedTokens[from][i] = _ownedTokens[from][lastTokenIdx];
               _ownedTokens[from][lastTokenIdx] = tokenId;
                break;
            }
        }
        _ownedTokens[from].length--;
    }

    function ownedTokens(address owner) public view returns (uint256[] memory){
        return _ownedTokens[owner];
    }

    function setTokenUri(uint256 id, string memory uri) public { // memory는 좀 긴 타입의 데이터를 표시할 떄 쓴다. 
        tokenURIs[id] = uri; // mapping
    }
} 


contract NFTMarket {
    //token 보낸 사람을 기억 W
    mapping(uint256 => address) public seller;

    function buyNFT(uint256 tokenId, address NFTAddress) public payable returns (bool){ //payable이 있어야 KLAY를 보낼 수 있다. 
        //NFTAddress에는 NFTSimple이 배포된 주소를 넣어준다. 

        // 판매한 사람에게 0.01 KLAY 전송
        address payable receiver = address(uint160(seller[tokenId])); // 돈을 받을 사람은 seller이다. payable L 돈을 받을 수 있는~

        // Send 0.01 KAY to receiver
        // 10 ** 18 PEB = 1 KLAY
        // 10 ** 16 PEB = 0.01 KLAY
        receiver.transfer(10 ** 16); // buyNFT를 호출한 사람이 이것까지 낸다. 

        NFTSimple(NFTAddress).safeTransferFrom(address(this), msg.sender, tokenId, '0x00'); // to 대신 msg.sender 무조건 이 함수 호출한 사람에게 보낸다. 
        return true;
    }

    // Market이 토큰을 받았을 때 (판매대에 올라갔을 때), 판매자가 누구인지 기록해야 한다. 
    function onKIP17Received(address operator, address from , uint256 tokenId, bytes memory data) public returns (bytes4) {
        seller[tokenId] = from;

        return bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"));
        // return이 의미하는 것은 현재 구현된 함수가 이 smart contract에 존재한다는 것을 알리는 용도
    }
}