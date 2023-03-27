
* [API List](#API-List)
    * [GetAuctionPrice](#GetAuctionPrice)
    * [Bid](#Bid)
    
## API List

### GetAuctionPrice
**desc**
```
  Get the eth price (wei) of a onsale account.
```
**Request**
* functionname
```
"3bf6cebb": "getAuctionPrice(uint256,uint256)"
```
* contract address
```
  goerli: 0x64273552516A1EC3559F87707b0C50908cb839dE
  main: 
```
* output data
```
    expires: 1679560033
    basePrice: 602
```
* value
```
```
* return
```
    uint256
```

### Bid
**desc**
```
  eth contract api for bid a account
```
**Request**
* functionname
```
   "e96bb91d": "bid(string,uint256,uint256,bytes32[])"
```
* contract address
```
  goerli: 0x64273552516A1EC3559F87707b0C50908cb839dE
  main: 
```
* output data
```
    account_id: "0x9a37b7d825c217cb304123d58d73e1054e777043"
    expired_time: 1670257878
    basic_price: 602
    proof: [
            "0x08babd9938f918897b97fe3aa8a3bb1bc7dfdb890790628220483c4c65954c17",
            "0x8f5b4ee845254e25da04793dd0875edcb5ed5bf1f2805dbf2f7be554ef1006f6",
            "0x3c7fdd8231230491dca0cc582ff2862b540c03f138548fb1d89e2bf0366b1a33",
            "0x637be80294467800d75f35bf18b6bfce51857d12e0fec0cd4c6b080f154c6641"
        ]
```
* value
```
  value=溢价+basic_price
```