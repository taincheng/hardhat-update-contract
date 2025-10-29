// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

// 透明代理

// 通过该模块实现合约可升级
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// 可升级合约
contract NftAuctionV1 is Initializable {

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
        address nftAddress;
        // NFT ID
        uint256 tokenId;
    }

    // 拍卖ID => 拍卖结构体
    mapping(uint256 auctionId => Auction) public auctions;

    // 下一个拍卖ID
    uint256 public nextAuctionId;

    // 管理员地址
    address public admin;

    // initializer 是初始化修饰符, 表示部署的时候，会调用该方法
    function initialize() initializer public {
        admin = msg.sender;
    }

    // 创建拍卖
    function createAuction (
        uint256 _duration, // 拍卖时长
        uint256 _startPrice, // 起始价格
        address _nftAddress,
        uint256 _tokenId
    ) public {
        // 只有管理员才可以创建拍卖
        require(msg.sender == admin, "Only admin can create auctions");
        // 检查参数
        require(_duration >= 1000 * 60, "Duration must be greater than 1m");
        require(_startPrice > 0, "Start price must be greater than 0");

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            startTime: block.timestamp,
            duration: _duration,
            startPrice: _startPrice,
            highestBidder: address(0),
            highestBid: 0,
            ended: false,
            nftAddress: _nftAddress,
            tokenId: _tokenId
        });

        nextAuctionId++;
    }

    
    // 参与拍卖出价
    function placeBid(uint256 _auctionId) external payable {
        // 取出对应的拍卖
        Auction storage auction = auctions[_auctionId];

        // 判断拍卖是否结束
        require(!auction.ended && auction.startTime + auction.duration > block.timestamp, "Auction has ended!");
        // 检查价格
        require(msg.value > auction.highestBid && msg.value >= auction.startPrice, "Bid must be greater than then current highestBid!");

        // 如果满足条件，需要将上一个出价最高的钱退回
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }
}