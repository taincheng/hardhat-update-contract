// harhat用来部署的
const { deployments, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");

// npm install -d @openzeppelin/hardhat-upgrades

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { save } = deployments;
    // 获取hardhat配置的部署节点别名
    const { deployer } = await getNamedAccounts();

    console.log("部署用户地址:", deployer);

    // 获取代理合约地址
    const storePath = path.resolve(__dirname, "./.cache/proxyNftAuction.json");
    const storeData = fs.readFileSync(storePath, "utf-8");
    const { proxyAddress, implAddress, abi } = JSON.parse(storeData);

    // 升级版的业务合约
    const nftAuctionV2 = await ethers.getContractFactory("NftAuctionV2");

    // 升级代理合约
    const nftAuctionV2Proxy = await upgrades.upgradeProxy(proxyAddress, nftAuctionV2)
    await nftAuctionV2Proxy.waitForDeployment();
    const proxyAddressV2 = await nftAuctionV2Proxy.getAddress();
    console.log("代理合约地址:", proxyAddressV2);

    const implAddressV2 = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("实现合约地址:", implAddressV2);

    // fs.writeFileSync(
    //     storePath,
    //     JSON.stringify({
    //         proxyAddressV2,
    //         implAddressV2,
    //         // 这是 Hardhat 和 Ethers.js 提供的功能，用于获取合约的 ABI 并格式化为 JSON 字符串
    //         abi: nftAuctionV2.interface.format("json"),
    //     })
    // );
    // 保存部署信息，方便后续使用
    await save("NftAuctionProxyV2", {
        address: proxyAddressV2,
        abi: nftAuctionV2.interface.format("json"),
    });
};

// 添加标签
module.exports.tags = ["deployNftAuctionV2"];