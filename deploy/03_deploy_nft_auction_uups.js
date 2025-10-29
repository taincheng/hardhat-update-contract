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
    const nftAuction= await ethers.getContractFactory("NftAuctionUUPSV1")

    // 部署代理合约
    const nftAuctionProxy = await upgrades.deployProxy(nftAuction, [], {
        initializer: "initialize",
    })

    // 等待部署完成
    await nftAuctionProxy.waitForDeployment();

    const proxyAddress = await nftAuctionProxy.getAddress();
    console.log("代理合约地址:", proxyAddress);

    const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("实现合约地址:", implAddress);


    const storePath = path.resolve(__dirname, "./.cache/proxyNftAuctionUUPS.json");
    fs.writeFileSync(
        storePath,
        JSON.stringify({
            proxyAddress,
            implAddress,
            // 这是 Hardhat 和 Ethers.js 提供的功能，用于获取合约的 ABI 并格式化为 JSON 字符串
            abi: nftAuction.interface.format("json"),
        })
    );
    // 保存部署信息，方便后续使用
    await save("NftAuctionProxyUUPS", {
        address: proxyAddress,
        abi: nftAuction.interface.format("json"),
    });
};

// 添加标签
module.exports.tags = ["deployNftAuctionUUPSV1"];