const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const leafKeys = [
  {
    "accountId": "0x247a9b0c9d9dfd787861c9d7d928dc321124996f",
    "expiredTime": 1670257878,
    "endPrice": 602,
    "proof": ["0x06bdf79aa284c76d792b8aab86924d922f910f30d222d92a6c2bec7f9e14bc5a", "0xeaedc863c9f9f430114a5b0589eb9b22b94dc5898d1e06a014124231edbb2f73", "0x98796ed086ca5dd488c62f44a0295d6b39857bf6de53a70171e5e6667eddd957"]
  },
  {
    "accountId": "0x245c7a6015522c389ab3027ccfd56ebd4e800546",
    "expiredTime": 1670257878,
    "endPrice": 604,
    "proof": ["0xcc29713d8144b0a2f7d92b344a79df46c7bad0916d66a6dbb5c5f9892f13a272", "0xeaedc863c9f9f430114a5b0589eb9b22b94dc5898d1e06a014124231edbb2f73", "0x98796ed086ca5dd488c62f44a0295d6b39857bf6de53a70171e5e6667eddd957"]
  },
  {
    "accountId": "0xed289aa951c63d5600ad31211a89a40215f297ff",
    "expiredTime": 1670257878,
    "endPrice": 603,
    "proof": ["0xe86544dc671659034f3411b663b3e89d50b4ad73d6cf19e11d405b1ec6958727", "0x1487a4f3b92851bcb6ff39fcdb30e73180b4b155209ec1cba7d577efa418bb62", "0x98796ed086ca5dd488c62f44a0295d6b39857bf6de53a70171e5e6667eddd957"]
  },
  {
    "accountId": "0xed0a36409177ecc572f855ca43082dc5dc2cb56e",
    "expiredTime": 1670257878,
    "endPrice": 606,
    "proof": ["0x6c8c15584fc901134be8b4bf7f430f54a6762be6bed719a3ca2cf3536ddeb3cc", "0x1487a4f3b92851bcb6ff39fcdb30e73180b4b155209ec1cba7d577efa418bb62", "0x98796ed086ca5dd488c62f44a0295d6b39857bf6de53a70171e5e6667eddd957"]
  },
  {
    "accountId": "0xc1f5d9f7249f379c887535001d6f641ee2dc6189",
    "expiredTime": 1670257878,
    "endPrice": 602,
    "proof": ["0x8d6bc8716d4f723904d5d6bf680ff30b5c86e4ce21d330c870f355e164f1365d", "0x0cb938ae748248ba412b4bd003ed18b7bb2dbfcf92ebbdc9cb0e4dd12ced7b6d", "0x0793e73b186416f073ddbf0e2bc4e5405d1e937c28168c241473e4c404d87e10"]
  },
  {
    "accountId": "0xc1e37e71c6dcffb454f6a317626d97b06958b237",
    "expiredTime": 1670257878,
    "endPrice": 602,
    "proof": ["0x0838d07022602c6582a9e4819ecd3184e093e0faffa66f801494007f4335d3e7", "0x0cb938ae748248ba412b4bd003ed18b7bb2dbfcf92ebbdc9cb0e4dd12ced7b6d", "0x0793e73b186416f073ddbf0e2bc4e5405d1e937c28168c241473e4c404d87e10"]
  },
];
const root = "0x6a5cf0d7c7a13cde6d12ba2a913c3a2f7c64a57cfc7d99deb2c9fc77c5052245";

describe("Auction test", function () {

  //deploy
  async function deployAuctionFixture() {
    const usdOracle = "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e";//Data Feed goerli contract address
    const startPremium = 100000000;//初始溢价
    const totalDays = 21;//荷兰拍持续天数
    const testAmount = 10_000_000_000;
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();
    const Auction = await ethers.getContractFactory("auction");
    const auction = await Auction.deploy(usdOracle, startPremium, totalDays, { value: testAmount });

    return { auction, usdOracle, startPremium, totalDays, owner, otherAccount, testAmount };
  }

  //test deploy
  describe("Deployment", function () {

    it("Should set the right params", async function () {
      const { auction, usdOracle, startPremium, owner } = await loadFixture(deployAuctionFixture);
      expect(await auction.usdOracle()).to.equal(usdOracle);
      expect(await auction.startPremium()).to.equal(startPremium);
      expect(await auction.owner()).to.equal(owner.address);
    });
  });

  //测试提现
  describe("Withdrawals", function () {
      //测试非合约的owner不可以提现
      it("Should revert with the right error if called from another account", async function () {
        const { auction, otherAccount, testAmount } = await loadFixture(
          deployAuctionFixture
        );
        await expect(auction.connect(otherAccount).withdraw(testAmount)).to.be.revertedWith(
          "You aren't the owner"
        );
      });  

      //测试owner可以提现
      it("Shouldn't fail if calle from owner account", async function () {
        const { auction, testAmount,owner ,otherAccount} = await loadFixture(
          deployAuctionFixture
        );
        await expect(auction.connect(owner).withdraw(testAmount)).not.to.be.reverted;
      });

      //测试owner不可以超额提现
      it("Should rever with the right error if called from owner account more than contract balance", async function(){
        const {auction, owner} = await loadFixture(
          deployAuctionFixture
        );
        const testAmount  = 11_000_000_000;
        await expect(auction.connect(owner).withdraw(testAmount)).to.be.revertedWith(
          "Insufficient funds"
        );
      });

    it("Should transfer the funds to the owner", async function () {
      const { auction, owner, testAmount } = await loadFixture(
        deployAuctionFixture
      );
      await expect(auction.withdraw(testAmount)).to.changeEtherBalances(
        [owner, auction],
        [testAmount, -testAmount]
      );
    });

  });

  //测试上架
  describe("Onsale", function () {
    //测试非owner不可以上架
    it("Should revert with the right error if called from another account", async function () {
      const { auction, otherAccount, owner } = await loadFixture(
        deployAuctionFixture
      );
      const root = "0xd5b65c1145eb1ad39c9ca70d88df01ec5af485d22f987de2e4a0c6bebfc82c79"
      const ids = ["a"];
      await expect(auction.connect(otherAccount).onSale(root, ids)).to.be.revertedWith(
        "You aren't the owner"
      );
      await auction.connect(owner).onSale(root, ids);
      expect(await auction.root()).to.equal(root);
    });

    it("Should clean the bidStatus", async function () {
      const { auction, owner, otherAccount } = await loadFixture(
        deployAuctionFixture
      );

      const ids1 = [];
      //上架
      await auction.connect(owner).onSale(root, ids1);
      //测试重复上架
      await expect(auction.connect(owner).onSale(root, ids1)).to.be.revertedWith(
        "There are no data need to be updated"
      );
      //测试上架清除竞拍状态
      const testAmount = ethers.utils.parseEther('100.0');
      //竞拍
      await auction.connect(otherAccount).bid(leafKeys[0].accountId,
        leafKeys[0].expiredTime, leafKeys[0].endPrice, leafKeys[0].proof, { value: testAmount });
      //测试竞拍成功标志未被标记为true
      expect(await auction.bidStatus("0x247a9b0c9d9dfd787861c9d7d928dc321124996f")).to.equal(true);
      //测试再次上架清空标志位
      const ids2 = ["0x247a9b0c9d9dfd787861c9d7d928dc321124996f"];
      const root2 = "0xa5b65c1145eb1ad39c9ca70d88df01ec5af485d22f987de2e4a0c6bebfc82c79";
      await auction.connect(owner).onSale(root2, ids2);
      expect(await auction.bidStatus("0x247a9b0c9d9dfd787861c9d7d928dc321124996f")).to.equal(false);
    });

  });
  
  //测试竞拍
  describe("Bid", function () {
    it("Should fail if bid params are incorrect", async function () {
      const { auction, owner, otherAccount } = await loadFixture(
        deployAuctionFixture
      );
      //上架
      await auction.connect(owner).onSale(root, []);
      //竞拍
      const testAmount = ethers.utils.parseEther('100.0');
      await expect(auction.connect(otherAccount).bid(leafKeys[1].accountId,
        leafKeys[0].expiredTime, leafKeys[0].endPrice, leafKeys[0].proof, { value: testAmount })).to.be.revertedWith("Validation failed");
    });

    it("Should fail if account has been sold", async function () {
      const { auction, owner, otherAccount } = await loadFixture(
        deployAuctionFixture
      );
      //上架
      await auction.connect(owner).onSale(root, []);
      //竞拍
      const testAmount = ethers.utils.parseEther('100.0');
      await auction.connect(otherAccount).bid(leafKeys[0].accountId,
        leafKeys[0].expiredTime, leafKeys[0].endPrice, leafKeys[0].proof, { value: testAmount });
      //再次竞拍
      await expect(auction.connect(otherAccount).bid(leafKeys[0].accountId,
        leafKeys[0].expiredTime, leafKeys[0].endPrice, leafKeys[0].proof, { value: testAmount })).to.be.revertedWith("Account has been sold");
    });

    it("Should fail if value is to low", async function () {
      const { auction, owner, otherAccount } = await loadFixture(
        deployAuctionFixture
      );
      //上架
      await auction.connect(owner).onSale(root, []);
      //竞拍
      const testAmount = ethers.utils.parseEther('1.0');//ether to wei
      const price = await auction.connect(otherAccount).getAuctionPrice(leafKeys[0].expiredTime, leafKeys[0].endPrice);
      console.log("account price: ", ethers.utils.formatEther(price), " eth");//wei to ether
      await expect(auction.connect(otherAccount).bid(
        leafKeys[0].accountId,
        leafKeys[0].expiredTime,
        leafKeys[0].endPrice,
        leafKeys[0].proof, 
        { value: testAmount }
      )).to.be.revertedWith("Value is too low");

      await auction.connect(otherAccount).bid(
        leafKeys[0].accountId, 
        leafKeys[0].expiredTime, 
        leafKeys[0].endPrice, 
        leafKeys[0].proof, 
        { value: price});
    });
  });

});
