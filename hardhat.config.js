require("@nomicfoundation/hardhat-toolbox");
// npm install -D hardhat-deploy (hardhat 部署插件)
require("hardhat-deploy");
// 引入 openzeppelin hardhat upgrades 插件
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  // 给hardhat测试部署的账户命名别名
  namedAccounts: {
    deployer: 0,
    user1: 1,
    user2: 2,
  }
};
