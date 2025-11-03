// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

// 通过该模块实现合约可升级
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

using SafeERC20 for IERC20;

// 可升级合约
contract NftAuctionChainlink is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    // 拍卖结构体
    struct Auction {
        // 卖家
        address seller;
        // 拍卖开始时间
        uint256 startTime;
        // 拍卖最长持续时间
        uint256 duration;
        // 起始价格
        uint256 startPrice;
        // 最高出价者
        address highestBidder;
        // 最高出价
        uint256 highestBid;
        // 拍卖是否结束
        bool ended;
        // NFT 地址
        address nftContract;
        // NFT ID
        uint256 tokenId;
        // 参与竞价的资产类型 0x 地址表示eth，其他地址表示erc20
        // 0x0000000000000000000000000000000000000000 表示eth
        address tokenAddress;
    }

    // 拍卖ID => 拍卖结构体
    mapping(uint256 auctionId => Auction) public auctions;

    // 下一个拍卖ID
    uint256 public nextAuctionId;

    // 管理员地址
    address public admin;

    mapping(address => AggregatorV3Interface) public priceFeeds;

    // initializer 是初始化修饰符, 表示部署的时候，会调用该方法
    function initialize() public initializer {
        admin = msg.sender;
    }

    function setPriceFeed(address tokenAddress, address _priceFeed) public {
        priceFeeds[tokenAddress] = AggregatorV3Interface(_priceFeed);
    }

    // ETH -> USD => 1766 7512 1800 => 1766.75121800
    // USDC -> USD => 9999 4000 => 0.99994000
    function getChainlinkDataFeedLatestAnswer(
        address tokenAddress
    ) public view returns (int) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return answer;
    }

    // 创建拍卖
    function createAuction(
        uint256 _duration, // 拍卖时长
        uint256 _startPrice, // 起始价格
        address _nftContract,
        uint256 _tokenId
    ) public nonReentrant {
        // 添加防重入修饰符
        // 只有管理员才可以创建拍卖
        require(msg.sender == admin, "Only admin can create auctions");
        // 检查参数
        require(_duration >= 60, "Duration must be greater than 60s");
        require(_startPrice > 0, "Start price must be greater than 0");

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            startTime: block.timestamp,
            duration: _duration,
            startPrice: _startPrice,
            highestBidder: address(0),
            highestBid: 0,
            ended: false,
            nftContract: _nftContract,
            tokenId: _tokenId,
            tokenAddress: address(0)
        });

        nextAuctionId++;

        // 转移NFT到合约
        // 最后进行NFT转移，避免在不完整状态下被重入
        IERC721(_nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
    }

    // 参与拍卖出价
    function placeBid(
        uint256 _auctionId,
        uint256 _amount,
        address _tokenAddress
    ) external payable {
        // 取出对应的拍卖
        Auction storage auction = auctions[_auctionId];

        // 判断拍卖是否结束
        require(
            !auction.ended &&
                auction.startTime + auction.duration > block.timestamp,
            "Auction has ended!"
        );

        uint payValue;
        if (_tokenAddress != address(0)) {
            // ERC20 资产处理
            payValue =
                _amount *
                uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        } else {
            // ETH 处理
            _amount = msg.value;
            // TODO 为什么是 address(0)?
            payValue =
                _amount *
                uint(getChainlinkDataFeedLatestAnswer(address(0)));
        }

        uint startPriceValue = auction.startPrice *
            uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));
        uint highestBidValue = auction.highestBid *
            uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));

        require(
            payValue >= startPriceValue && payValue >= highestBidValue,
            "Bid must be higher than the current highest bid"
        );

        // 退还前最高价
        if (auction.highestBid > 0) {
            if (auction.tokenAddress == address(0)) {
                // ETH 情况
                payable(auction.highestBidder).transfer(auction.highestBid);
            } else {
                // ERC代币情况
                IERC20 token = IERC20(auction.tokenAddress);
                // using SafeERC20 for IERC20 （库使用语法）Solidity会将 token 作为第一个参数传递到方法中
                token.safeTransfer(auction.highestBidder, auction.highestBid);
            }
        }

        auction.tokenAddress = _tokenAddress;
        auction.highestBid = _amount;
        auction.highestBidder = msg.sender;
    }

    // 结束拍卖
    function endAuction(uint256 _auctionID) external {
        Auction storage auction = auctions[_auctionID];

        // 判断当前拍卖是否结束
        require(
            !auction.ended &&
                auction.startTime + auction.duration < block.timestamp,
            "auction has ended!"
        );

        // 先标记拍卖为已结束，防止重入
        auction.ended = true;

        // 转移 NFT 到最高出价者
        IERC721(auction.nftContract).safeTransferFrom(
            admin,
            auction.highestBidder,
            auction.tokenId
        );
    }

    // uups合约必须实现的函数
    function _authorizeUpgrade(address) internal view override {
        // 只有管理员才可以升级合约
        require(msg.sender == admin, "Only admin can upgrade");
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
