# SmartContract Code

<br/>

## DonationPattern.sol

mintWithTokenURI1 : 목표금액이 모이면, 총 수량만큼 Minting 해주는 함수(크라우드 펀딩식) -> 이후 safeTransferFrom()로 기부자에게 전송 
<br/>
<br/>
mintWithTokenURI2 : 사용자가 기부할 때마다 금액에 맞는 수량을 발행해주는 함수 (목표금액이 정해지지 않은 기부방식)
<br/>
<br/>

## DecreaseMinting.sol

mintWithTokenURI : 기부자에게 N개의 token을 발행

safeTransferFrom: 1개 씩 Transfer하고, 0개가 남으면 Transfer를 멈춘다. 