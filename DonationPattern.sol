// Klaytn IDE uses solidity 0.4.24, 0.5.6 versions.
pragma solidity >=0.4.24 <=0.5.6;

import "./KIP17Token.sol";

contract NFTSimple is KIP17Full {
    string public name = "KlayLion";
    string public symbol = "KL";
    
    constructor() public KIP17Full(name, symbol) {}


    mapping (uint256 => address) public tokenOwner;
    mapping (uint256 => string) public tokenURIs;

    // 소유한 토큰 리스트
    mapping(address => uint256[]) private _ownedTokens;
    // onKIP17Received bytes value
    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;
    // URI -> id[]
    mapping(string => uint256[]) public _tokenIds; 

    // 1. 목표금액 모이면, 총 수량만큼 민팅해주는 함수(크라우드 펀딩식) -> 이후 safeTransferFrom()로 기부자에게 전송
    function mintWithTokenURI1(uint256 tokenId, string memory tokenURI, uint256 num) public returns (bool) {
        // 함수 실행자에게 tokenId(일련번호)를 1씩 증가시키며 num개를 발행하겠다
        // 적힐 글자는 tokenURI
        for (uint i = tokenId; i < tokenId+num; i++) {
        tokenOwner[i] = msg.sender;
        tokenURIs[i] = tokenURI;
   
        // add token to the list
        _ownedTokens[msg.sender].push(i);
        }

        return true;
    }

    // 2. 사용자가 기부할때마다 금액에 맞는 수량을 발행해주는 함수 (목표금액이 정해지지 않은 기부방식)
    function mintWithTokenURI2(address to, string memory tokenURI, uint256 num) public returns (bool) {
        // 사용자(to)에게 tokenId(일련번호)를 1씩 증가시키며 num개 발행
        // 적힐 글자는 tokenURI 
        uint256 tokenId = _tokenIds[tokenURI].length;
        for (uint i = tokenId; i < tokenId+num; i++) {
        tokenOwner[i] = to;
        tokenURIs[i] = tokenURI;

        // add token to the list
        _ownedTokens[to].push(i);

        // tokenURI 에 있는 Id들을 배열로 추가 (다음 tokenId 지정)
        _tokenIds[tokenURI].push(i);
        }

        return true;

    }

    function tokenIds(string memory tokenURI) public view returns (uint256[] memory) {
        return _tokenIds[tokenURI];
    }


    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public returns (bool) {
        // to 에게 tokenId(일련번호)를 발행하겠다
        // 적힐 글자는 tokenURI
        tokenOwner[tokenId] = to;
        tokenURIs[tokenId] = tokenURI;

        // add token to the list
        _ownedTokens[to].push(tokenId);
        return true;

        // 
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(from == msg.sender, "from != msg.sender");
        require(from == tokenOwner[tokenId], "you are not the owner of the token");
        // 전송한 tokenId 토큰 리스트에서 제거
        _removeTokenFromList(from, tokenId);
        _ownedTokens[to].push(tokenId);
        // 소유자 변경
        tokenOwner[tokenId] = to;

        // 만약에 받는 쪽이 실행할 코드가 있는 스마트 컨트랙트이면 코드를 실행할 것
        require(
            _checkOnKIP17Received(from, to, tokenId, _data), "KIP17: transfer to non KIP17Receiver: implementer"
        );
    }

    function _checkOnKIP17Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
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
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _removeTokenFromList(address from, uint256 tokenId) private {
        // [10, 15, 19, 20] -> 19번을 삭제하고 싶어요
        // [10, 15, 20, 19] -> 자리옮김
        // [10, 15, 20] -> 끝에 자름
        uint256 lastTokenIndex = _ownedTokens[from].length -1;
        for(uint256 i=0;i<_ownedTokens[from].length;i++) {
            if (tokenId == _ownedTokens[from][i]) {
                // Swap las token with deleting token;
                _ownedTokens[from][i] = _ownedTokens[from][lastTokenIndex];
                _ownedTokens[from][lastTokenIndex] = tokenId;
                 break;
            }
        }
        _ownedTokens[from].length--;
    }
    
    function ownedTokens(address owner) public view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    function setTokenUri(uint256 id, string memory uri) public {
        tokenURIs[id] = uri;
    }

}

contract NFTMarket {
    mapping(uint256 => address) public seller;

    function buyNFT(uint256 tokenId, address NFTAddress) public payable returns (bool) {
        // 구매한 사람한테 0.01 KLAY 전송
        address payable receiver = address(uint160(seller[tokenId]));

        // Send 0.01 KLAY to receiver
        // 10 ** 18 PEB = 1 KLAY
        // 10 ** 16 PEB = 0.01 KLAY
        receiver.transfer(10 ** 16);

        NFTSimple(NFTAddress).safeTransferFrom(address(this), msg.sender, tokenId, '0x00');
        return true;
    }
    // Market이 Token을 받았을 때(판매대에 올라왔을 때), 판매자가 누구인지 기록해야함
    function onKIP17Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        seller[tokenId] = from;
        return bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"));
    }
}