const { expect } = require("chai");
const { ethers, deployments } = require("hardhat");


describe("Test upgrade", async function () {
    it("Should be able to upgrade", async function () {

        // 1. 部署业务合约
        await deployments.fixture(["deployNftAuctionV1"]);
        const nftAuctionProxy = await deployments.get("NftAuctionProxy");
        // 2. 调用 createAuction 创建拍卖
        const nftAuctionV1 = await ethers.getContractAt("NftAuctionV1", nftAuctionProxy.address);
        await nftAuctionV1.createAuction(
            100*1000,
            ethers.parseEther("0.01"),
            ethers.ZeroAddress,
            1
        );
        const auctionV1 = await nftAuctionV1.auctions(0);
        console.log("创建拍卖成功: ", auctionV1);

        const implAddressV1 = await upgrades.erc1967.getImplementationAddress(
            nftAuctionProxy.address
        );

        // 3. 升级合约
        await deployments.fixture(["deployNftAuctionV2"]);
        
        const implAddressV2 = await upgrades.erc1967.getImplementationAddress(
            nftAuctionProxy.address
        )

        console.log("implAddressV1:", implAddressV1);
        console.log("implAddressV2:", implAddressV2);
        expect(implAddressV1).to.not.equal(implAddressV2);

        // 4. 读取合约的auction[0]，数据未丢失说明升级成功
        const auctionV2 = await nftAuctionV1.auctions(0);
        console.log("升级后读取拍卖: ", auctionV2);
        expect(auctionV2.startTime).to.equal(auctionV1.startTime);

        // 5. 测试升级后的业务逻辑
        const nftAuctionV2 = await ethers.getContractAt("NftAuctionV2", nftAuctionProxy.address);
        const hello = await nftAuctionV2.testHelloUpgrade();
        console.log("hello:", hello);

        // 两个部署脚本中保存的代理合约地址应该是一样的
        const nftAuctionProxyV2 = await deployments.get("NftAuctionProxyV2");
        expect(nftAuctionProxy.address).to.equal(nftAuctionProxyV2.address);
    });
});

describe.only("Test upgrade uups", async function () {
    it("Should be able to upgrade uups", async function () {

        // 1. 部署业务合约
        await deployments.fixture(["deployNftAuctionUUPSV1"]);
        const nftAuctionProxy = await deployments.get("NftAuctionProxyUUPS");
        // 2. 调用 createAuction 创建拍卖
        const nftAuctionV1 = await ethers.getContractAt("NftAuctionUUPSV1", nftAuctionProxy.address);
        await nftAuctionV1.createAuction(
            100*1000,
            ethers.parseEther("0.01"),
            ethers.ZeroAddress,
            1
        );
        const auctionV1 = await nftAuctionV1.auctions(0);
        console.log("创建拍卖成功: ", auctionV1);

        const implAddressV1 = await upgrades.erc1967.getImplementationAddress(
            nftAuctionProxy.address
        );

        // 3. 升级合约
        await deployments.fixture(["deployNftAuctionUUPSV2"]);
        
        const implAddressV2 = await upgrades.erc1967.getImplementationAddress(
            nftAuctionProxy.address
        )

        console.log("implAddressV1:", implAddressV1);
        console.log("implAddressV2:", implAddressV2);
        expect(implAddressV1).to.not.equal(implAddressV2);

        // 4. 读取合约的auction[0]，数据未丢失说明升级成功
        const auctionV2 = await nftAuctionV1.auctions(0);
        console.log("升级后读取拍卖: ", auctionV2);
        expect(auctionV2.startTime).to.equal(auctionV1.startTime);

        // 5. 测试升级后的业务逻辑
        const nftAuctionV2 = await ethers.getContractAt("NftAuctionUUPSV2", nftAuctionProxy.address);
        const hello = await nftAuctionV2.testHelloUpgrade();
        console.log("hello:", hello);

        // 两个部署脚本中保存的代理合约地址应该是一样的
        const nftAuctionProxyV2 = await deployments.get("NftAuctionProxyUUPSV2");
        expect(nftAuctionProxy.address).to.equal(nftAuctionProxyV2.address);
    });
});