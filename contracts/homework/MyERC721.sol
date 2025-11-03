// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 支持 NFT 的铸造和转移。
contract TestERC721 is ERC721Enumerable, Ownable {

    // 存储每个 token 的 URI
    mapping (uint256 tokenId => string) private _tokenURIs;

    // 默认的 token URI
    string private _baseTokenURI;


    // 铸造事件
    event Mint(address indexed to, uint256 indexed tokenId);
    // 批量铸造事件
    event BatchMint(address indexed to, uint256[] tokenIds);


    // 构造函数
    // Ownable 指定合约拥有者
    constructor() ERC721("Troll", "Troll") Ownable(msg.sender) {}

    /**
     * 铸造 NFT
     * @param to 接收者
     * @param tokenId token 的 ID
     */
    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
        emit Mint(to, tokenId);
    }

    /**
     * 批量铸造 NFT
     */
    function batchMint(address to, uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i]);
        }
        emit BatchMint(to, tokenIds);
    }

    /**
     * 获取 token 的 URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // 判断 tokenId 是否存在
        require(exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // 获取 tokenURI
        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        return _baseTokenURI;
    }

    /**
     * 设置 token 的 URI
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * 设置基础 URI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * 删除指定的 URI
     */
    function removeTokenURI(uint256 tokenId) public onlyOwner {
        require(exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        delete _tokenURIs[tokenId];
    }

    /**
     * 判断 tokenId 是否存在
     * 
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return bytes(_tokenURIs[tokenId]).length > 0;
    }
}