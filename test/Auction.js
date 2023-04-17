//单测，要注释掉合约里的chainlink调用，因为测试走的是hardhat
const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers,upgrades } = require("hardhat");

const leafKeys = [
  {
    "accountId": "0x428b868fb0acd0a9fbde73bd55995f566a38fbd6",
    "expiredTime": 1672211096,
    "endPrice": 6052560,
    "proof": ["0xdaa769622ad71d024decf6e52531c0027ec35caa2a699049c4569f43e755c9b5","0x8d2b5fc85c3728f01df06d1053927a8dc6beebbd6849dde2e41134b133cbb25e"]
  },
  {
    "accountId": "0x02db18e7e889d2b60505c719895f949b5606f737",
    "expiredTime": 1672211096,
    "endPrice": 6052560,
    "proof": ["0xffbab1fb3d01bf5920f1ec973561ee32eb8e8a249b3fa5e3468ed0e34ed6e691","0x8d2b5fc85c3728f01df06d1053927a8dc6beebbd6849dde2e41134b133cbb25e"]
  },
  {
    "accountId": "0xc7298fe8e8c47c4bec4e7182898e36a3a06bb466",
    "expiredTime": 1672211096,
    "endPrice": 6052560,
    "proof": ["0xf4cc5cb5d4fac679b3e4d95c0648d29dc0339ad48deb5fba1084a3068ee01fb5","0x8e78a7d7eb1c9a38055a9067eb83145e3aa1dd71f4c411731dbd4e16354127fb"]
  }
];
const root = "0x011162d8a5de9068e8e8f89b04da365d6f9bc70ac29544fa07f31f0bd538dd1b";

const ownerRole = "0x6270edb7c868f86fda4adedba75108201087268ea345934db8bad688e1feb91b";//keccak256(OWNER)
const managerRole = "0xaf290d8680820aad922855f39b306097b20e28774d6c1ad35a20325630c3a02c";//keccak256(MANAGER)


describe("Auction test", function () {

  //deploy
  async function deployAuctionFixture() {
 
    // Contracts are deployed using the first signer/account by default
    // const [owner, otherAccount] = await ethers.getSigners();
    // const Auction = await ethers.getContractFactory("auction");
    // const auction = await Auction.deploy(usdOracle, startPremium, totalDays, { value: testAmount });


    UsdOracle = config.constructor_param.UsdOracle;
    StartPremium = config.constructor_param.StartPremium;
    TotalDays = config.constructor_param.TotalDays;
    
    if (UsdOracle == "" || UsdOracle == undefined) {
      console.log("constructor param UsdOracle error");
    }
    if (StartPremium == 0 || StartPremium == undefined) {
      console.log("constructor param StartPremium error");
    }
    if (TotalDays == 0 || TotalDays == undefined) {
      console.log("constructor param TotalDays error");
    }
    const [account1, account2, account3] = await ethers.getSigners();
    const Auction = await ethers.getContractFactory('auction');
    auction = (await upgrades.deployProxy(Auction, [UsdOracle,StartPremium,TotalDays], {kind: 'uups'}, { initializer: 'initialize' }));
    await auction.deployed();

    const testAmount = 1_000_000_000;

    console.log(await auction.address, " proxy");//代理合约的地址 
    return { auction, UsdOracle, StartPremium, TotalDays, account1, account2, account3, testAmount };
  }

  //test deploy
  describe("Deployment", function () {
    it("Should set the right params", async function () {
      const { auction, UsdOracle, StartPremium, account1 } = await loadFixture(deployAuctionFixture);
      expect(await auction.usdOracle()).to.equal(UsdOracle);
      expect(await auction.startPremium()).to.equal(StartPremium);
    });

    
    it("Should has the right role after grantRole or revokeRole",async function(){
      const { auction, UsdOracle, StartPremium, account1, account2, account3} = await loadFixture(deployAuctionFixture);
        //刚布署的合约的owner和manager都是account1
        expect(await auction.hasRole(ownerRole,account1.address)).to.equal(true);
        //测试将account2设置为owner
        await expect(auction.connect(account1).grantRole(ownerRole, account2.address)).not.to.be.reverted;
        expect(await auction.hasRole(ownerRole,account2.address)).to.equal(true);
        //测试将account1的owner权限删除
        await expect(auction.connect(account1).revokeRole(ownerRole, account1.address)).not.to.be.reverted;
        expect(await auction.hasRole(ownerRole, account1.address)).to.equal(false);
    });
  });

  //测试升级
  describe("Upgrade", function () {
    it("Should Upgrade with right role address", async function () {
      const { auction,account1,account2 } = await loadFixture(deployAuctionFixture);
      const Auction = await ethers.getContractFactory('auction');
      expect(await auction.hasRole(ownerRole, account1.address)).to.equal(true);
      console.log(await upgrades.erc1967.getImplementationAddress(auction.address)," getImplementationAddress")//旧逻辑合约地址

      //给account2授权owner角色
      await auction.grantRole(ownerRole,account2.address);
      expect(await auction.hasRole(ownerRole,account2.address)).to.be.equal(true);
      // proxy = (await upgrades.upgradeProxy(auction.address, Auction));
      //测试owner可以升级
      await expect(upgrades.upgradeProxy(auction.address, Auction)).not.to.be.reverted;

      //删除account1的owner角色
      await expect(auction.connect(account1).revokeRole(ownerRole, account1.address)).not.to.be.reverted;
      expect(await auction.hasRole(ownerRole, account1.address)).to.equal(false);
      //account1:  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
      //account2:  0x70997970C51812dc3A010C7d01b50e0d17dc79C8
      console.log("account1: ", account1.address);
      console.log("account2: ", account2.address);
      //没有owner角色的account1，升级失败
      await expect(upgrades.upgradeProxy(auction.address, Auction)).to.be.reverted;

      //
      // await expect(upgrades.upgradeProxy(auction.address, Auction)).to.be.reverted;
      // await expect(upgrades.upgradeProxy(auction.address, Auction, {from : account1.address})).to.be.reverted;
      // await proxy.deployed();
      // await expect(upgrades.upgradeProxy(auction.address, Auction, {from: account1})).not.to.be.reverted;
      // await proxy.deployed();
      console.log(await upgrades.erc1967.getImplementationAddress(auction.address)," getImplementationAddress")//新逻辑合约地址，地址可变，与proxy合约的状态变量需要EVM对齐
    });
  });

  //测试提现
  describe("Withdrawals", function () {
      //测试非合约的owner不可以提现
      it("Should revert with the right error if called from another account", async function () {
        const { auction, account2, testAmount } = await loadFixture(
          deployAuctionFixture
        );
        await expect(auction.connect(account2).withdraw(testAmount)).to.be.rejected;
      });  
  });

  //测试上架
  describe("Onsale", function () {
    //测试非manager不可以上架
    it("Should revert with the right error if called from another account", async function () {
      const { auction, account2, account1 } = await loadFixture(
        deployAuctionFixture
      );
      const root = "0xd5b65c1145eb1ad39c9ca70d88df01ec5af485d22f987de2e4a0c6bebfc82c79"
      const ids = ["0xc7298fe8e8c47c4bec4e7182898e36a3a06bb466"];
      await expect(auction.connect(account2).onSale(root, ids)).to.be.reverted;
      await auction.connect(account1).onSale(root, ids);
      expect(await auction.rootHash()).to.equal(root);
    });

    it("Should clean the bidStatus", async function () {
      const { auction, account1, account2 } = await loadFixture(
        deployAuctionFixture
      );

      const ids1 = [];
      //上架
      await auction.connect(account1).onSale(root, ids1);
      //测试重复上架

      await expect(auction.connect(account1).onSale(root, ids1)).to.be.revertedWith(
        "There are no data need to be updated"
      );
  
      //测试上架清除竞拍状态
      const testAmount = ethers.utils.parseEther('100.0');
      //竞拍
      await auction.connect(account2).bid(leafKeys[0].accountId,
        leafKeys[0].expiredTime, leafKeys[0].endPrice, leafKeys[0].proof, { value: testAmount });
      //测试竞拍成功标志未被标记为true
      expect(await auction.bidStatus("0x428b868fb0acd0a9fbde73bd55995f566a38fbd6")).to.equal(true);
      //测试再次上架清空标志位
      const ids2 = ["0x428b868fb0acd0a9fbde73bd55995f566a38fbd6"];
      const root2 = "0xa5b65c1145eb1ad39c9ca70d88df01ec5af485d22f987de2e4a0c6bebfc82c79";
      await auction.connect(account1).onSale(root2, ids2);
      expect(await auction.bidStatus("0x428b868fb0acd0a9fbde73bd55995f566a38fbd6")).to.equal(false);
    });

  });
  
  //测试竞拍
  describe("Bid", function () {
    it("Should fail if bid params are incorrect", async function () {
      const { auction, account1, account2 } = await loadFixture(
        deployAuctionFixture
      );
      //上架
      await auction.connect(account1).onSale(root, []);
      //竞拍
      const testAmount = ethers.utils.parseEther('100.0');
      await expect(auction.connect(account2).bid(leafKeys[1].accountId,
        leafKeys[0].expiredTime, leafKeys[0].endPrice, leafKeys[0].proof, { value: testAmount })).to.be.revertedWith("Validation failed");
    });

    it("Should fail if account has been sold", async function () {
      const { auction, account1, account2 } = await loadFixture(
        deployAuctionFixture
      );
      //上架
      await auction.connect(account1).onSale(root, []);
      //竞拍
      const testAmount = ethers.utils.parseEther('100.0');
      await auction.connect(account2).bid(leafKeys[0].accountId,
        leafKeys[0].expiredTime, leafKeys[0].endPrice, leafKeys[0].proof, { value: testAmount });
      //再次竞拍
      await expect(auction.connect(account2).bid(leafKeys[0].accountId,
        leafKeys[0].expiredTime, leafKeys[0].endPrice, leafKeys[0].proof, { value: testAmount })).to.be.revertedWith("Account has been sold");
    });

    it("Should fail if value is too low", async function () {
      const { auction, account1, account2 } = await loadFixture(
        deployAuctionFixture
      );
      //上架
      await auction.connect(account1).onSale(root, []);
      //竞拍
  
      const price = await auction.connect(account2).getAuctionPrice(leafKeys[0].expiredTime, leafKeys[0].endPrice);
      console.log("account price: ", ethers.utils.formatEther(price), " eth");//wei to ether
      

      // console.log("testAmount: ",ethers.BigNumber.from(price-10000));
      console.log(Number.MAX_SAFE_INTEGER);
      await expect(auction.connect(account2).bid(
        leafKeys[0].accountId,
        leafKeys[0].expiredTime,
        leafKeys[0].endPrice,
        leafKeys[0].proof, 
        { value: 100}
      )).to.be.revertedWith("Value is too low");

      // await expect(auction.connect(account2).bid(
      //   leafKeys[0].accountId, 
      //   leafKeys[0].expiredTime, 
      //   leafKeys[0].endPrice, 
      //   leafKeys[0].proof, 
      //   { value: price.add(10000000000)}
      // )).not.to.be.reverted;
   
    });
  });

});
