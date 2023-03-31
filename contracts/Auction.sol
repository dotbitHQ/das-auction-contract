// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//chainlink
interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}
//todo 新增manager角色，允许上架，不允许升级和提现
//
contract auction is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 GRACE_PERIOD ; //宽限期
    uint256 public  startPremium; //初始溢价 单位:美元
    uint256 public  endValue; //结束溢价 单位:美元
    uint256 constant public PRECISION = 1e18;
    uint256 constant bit1 = 999989423469314432; // 0.5 ^ 1/65536 * (10 ** 18)
    uint256 constant bit2 = 999978847050491904; // 0.5 ^ 2/65536 * (10 ** 18)
    uint256 constant bit3 = 999957694548431104;
    uint256 constant bit4 = 999915390886613504;
    uint256 constant bit5 = 999830788931929088;
    uint256 constant bit6 = 999661606496243712;
    uint256 constant bit7 = 999323327502650752;
    uint256 constant bit8 = 998647112890970240;
    uint256 constant bit9 = 997296056085470080;
    uint256 constant bit10 = 994599423483633152;
    uint256 constant bit11 = 989228013193975424;
    uint256 constant bit12 = 978572062087700096;
    uint256 constant bit13 = 957603280698573696;
    uint256 constant bit14 = 917004043204671232;
    uint256 constant bit15 = 840896415253714560;
    uint256 constant bit16 = 707106781186547584;


    bytes32 public root;
    bytes32 public manager;
    mapping(string => bool) public bidStatus;
    AggregatorInterface public usdOracle;
    event BidEvent(
        string account,
        uint256 value,
        address bid_user,
        uint256 bid_time
    );

    function initialize(AggregatorInterface _usdOracle,uint256 _startPremium,uint256 _totalDays) initializer public {
        usdOracle = _usdOracle;
        startPremium = _startPremium;
        GRACE_PERIOD = 90 days;
        endValue = _startPremium >> _totalDays;
      __Ownable_init();
      __UUPSUpgradeable_init();
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    //更新根hash（上架）
    function onSale(
        bytes32 rootHash,
        //todo string address
        string[] calldata clearAccountId
    ) public onlyOwner {
        //todo 确定不会越界的地方 uncheck

        require(root != rootHash, "There are no data need to be updated");
        //清理历史数据
        unchecked{
            for (uint256 i = 0; i < clearAccountId.length; i++) {
                delete bidStatus[clearAccountId[i]];
            }
        }
        
        root = rootHash;
    }

    //出价
    function bid(
        string calldata accountId,
        uint256 expiredTime,
        uint256 basicPrice,
        bytes32[] calldata proof
    ) public payable {
        //判断账号状态
        require(!bidStatus[accountId], "Account has been sold");

        //验证根hash
        bytes memory pack = abi.encodePacked(
            accountId,
            expiredTime,
            basicPrice
        );
        bytes32 data = keccak256(pack);
        require(MerkleProof.verify(proof, root, data), "Validation failed");

    
        //验证价格
        //获取当前账号的荷兰拍eth价格（单位wei）
        //基础价格 精度
        uint256 accountPrice = getAuctionPrice(expiredTime, basicPrice);
        //判断当前出价是否大于荷兰拍价格
        require(msg.value >= accountPrice, "Value is too low");
        //todo 多出的部分 退还
        //2/3时间内退款多出部分  多一个transfer 多多少gas

        //更新账号状态为“已被排拍走”
        bidStatus[accountId] = true;
        emit BidEvent(accountId, msg.value, msg.sender, block.timestamp);
    }

    //todo amount = 0 全部取
    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient funds");
        if (amount == 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
        payable(msg.sender).transfer(amount);
    }

    //获取荷兰拍价格 (单位wei)
    function getAuctionPrice(
        uint256 expires,
        uint256 basePrice
    ) public view returns (uint256) {
        uint256 preium = _premium(expires);
        uint256 accountPrice = basePrice + preium * 1e6; //单位美元的10^6
        //--获取当前eth的美元价格
        // uint256 ethPrice = uint256(usdOracle.latestAnswer());
        uint256 ethPrice = 166552000000;
        //100美分，
        return (accountPrice * 1e6 * 1e18) / ethPrice;
    }

    //计算溢价
    function _premium(
        uint256 expires //过期时间，过期之后有一个90天的宽限期
    ) internal view returns (uint256) {
        expires = expires + GRACE_PERIOD;
        //判断拍卖是否开始
        if (expires > block.timestamp) {
            return startPremium;
        }
        uint256 elapsed = block.timestamp - expires; //拍卖已经持续的时间
        uint256 premium = decayedPremium(startPremium, elapsed);
        if (premium >= endValue) {
            return (premium - endValue);
        }
        return 0;
    }

    //startPreium:初始溢价
    //elapsed：拍卖已经持续的时间
    function decayedPremium(
        uint256 _startPremium,
        uint256 elapsed
    ) internal pure returns (uint256) {
        uint256 daysPast = (elapsed * PRECISION) / 1 days; //拍卖已经持续的天数（高精度）
        uint256 intDays = daysPast / PRECISION; //拍卖持续的天数（整数）
        uint256 premium = _startPremium >> intDays; //最后一天的溢价（每天减半）
        uint256 partDay = (daysPast - intDays * PRECISION); //
        uint256 fraction = (partDay * (2 ** 16)) / PRECISION;
        uint256 totalPremium = addFractionalPremium(fraction, premium);
        return totalPremium;
    }

    function addFractionalPremium(
        uint256 fraction,
        uint256 premium
    ) internal pure returns (uint256) {
        if (fraction & (1 << 0) != 0) {
            premium = (premium * bit1) / PRECISION;
        }
        if (fraction & (1 << 1) != 0) {
            premium = (premium * bit2) / PRECISION;
        }
        if (fraction & (1 << 2) != 0) {
            premium = (premium * bit3) / PRECISION;
        }
        if (fraction & (1 << 3) != 0) {
            premium = (premium * bit4) / PRECISION;
        }
        if (fraction & (1 << 4) != 0) {
            premium = (premium * bit5) / PRECISION;
        }
        if (fraction & (1 << 5) != 0) {
            premium = (premium * bit6) / PRECISION;
        }
        if (fraction & (1 << 6) != 0) {
            premium = (premium * bit7) / PRECISION;
        }
        if (fraction & (1 << 7) != 0) {
            premium = (premium * bit8) / PRECISION;
        }
        if (fraction & (1 << 8) != 0) {
            premium = (premium * bit9) / PRECISION;
        }
        if (fraction & (1 << 9) != 0) {
            premium = (premium * bit10) / PRECISION;
        }
        if (fraction & (1 << 10) != 0) {
            premium = (premium * bit11) / PRECISION;
        }
        if (fraction & (1 << 11) != 0) {
            premium = (premium * bit12) / PRECISION;
        }
        if (fraction & (1 << 12) != 0) {
            premium = (premium * bit13) / PRECISION;
        }
        if (fraction & (1 << 13) != 0) {
            premium = (premium * bit14) / PRECISION;
        }
        if (fraction & (1 << 14) != 0) {
            premium = (premium * bit15) / PRECISION;
        }
        if (fraction & (1 << 15) != 0) {
            premium = (premium * bit16) / PRECISION;
        }
        return premium;
    }
}