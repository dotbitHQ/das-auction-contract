// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

contract auction is Initializable, UUPSUpgradeable,AccessControlUpgradeable {
    uint256 GRACE_PERIOD ;
    uint256 public  startPremium;
    uint256 public  endValue;
    uint256 constant public PRECISION = 1e18;
    uint256 constant bit1 = 999989423469314432;
    uint256 constant bit2 = 999978847050491904;
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
    bytes32 public rootHash;
    bytes32 public constant OWNER = keccak256("OWNER");
    bytes32 public constant MANAGER = keccak256("MANAGER");
    mapping(bytes20 => bool) public bidStatus;
    AggregatorInterface public usdOracle;
    event BidEvent(
        bytes20 account,
        uint256 value,
        address bid_user,
        uint256 bid_time
    );

    function initialize(AggregatorInterface _usdOracle,uint256 _startPremium,uint256 _totalDays) initializer public {
        usdOracle = _usdOracle;
        startPremium = _startPremium;
        GRACE_PERIOD = 90 days;
        endValue = _startPremium >> _totalDays;
        _setupRole(OWNER, msg.sender);
        _setupRole(MANAGER, msg.sender);
        _setRoleAdmin(OWNER,OWNER);
        _setRoleAdmin(MANAGER,OWNER);
      __UUPSUpgradeable_init();
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyRole(OWNER) {}
    
    function onSale(
        bytes32 root,
        //todo string address
        bytes20[] calldata clearAccountId
    ) public onlyRole(MANAGER) {
        require(root != rootHash, "There are no data need to be updated");
        //clear bidStatus 
        unchecked{
            for (uint256 i = 0; i < clearAccountId.length; i++) {
                delete bidStatus[clearAccountId[i]];
            }
        }
        rootHash = root;
    }

    function bid(
        bytes20 accountId,
        uint256 expiredTime,
        uint256 basicPrice,
        bytes32[] calldata proof
    ) public payable {
        require(!bidStatus[accountId], "Account has been sold");

        //verify merkletree root hash
        bytes memory pack = abi.encodePacked(
            accountId,
            expiredTime,
            basicPrice
        );
        bytes32 data = keccak256(pack);
        require(MerkleProof.verify(proof, rootHash, data), "Validation failed");

        //get price (basicPrice + premium) unit(wei)
        uint256 accountPrice = getAuctionPrice(expiredTime, basicPrice);
        require(msg.value >= accountPrice, "Value is too low");
        //refund extra ether 
        if (block.timestamp <= expiredTime+ 90 days + 14 days ) {
            payable(msg.sender).transfer(msg.value-accountPrice);
        }
        bidStatus[accountId] = true;
        emit BidEvent(accountId, msg.value, msg.sender, block.timestamp);
    }

    function withdraw(uint256 amount) public onlyRole(OWNER) {
        require(address(this).balance >= amount, "Insufficient funds");
        if (amount == 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
        payable(msg.sender).transfer(amount);
    }


    function getAuctionPrice(
        uint256 expires,
        uint256 basePrice
    ) public view returns (uint256) {
        uint256 preium = _premium(expires);
        uint256 accountPrice = basePrice + preium * 1e6; //unit($ * 10^6)
        //eth-usdt
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        // uint256 ethPrice = 196552000000;
        return (accountPrice * 1e20) / ethPrice;
    }

    
    function _premium(
        uint256 expires
    ) internal view returns (uint256) {
        expires = expires + GRACE_PERIOD;
        if (expires > block.timestamp) {
            return startPremium;
        }
        uint256 elapsed = block.timestamp - expires;
        uint256 premium = decayedPremium(startPremium, elapsed);
        if (premium >= endValue) {
            return (premium - endValue);
        }
        return 0;
    }

    function decayedPremium(
        uint256 _startPremium,
        uint256 elapsed
    ) internal pure returns (uint256) {
        uint256 daysPast = (elapsed * PRECISION) / 1 days;
        uint256 intDays = daysPast / PRECISION;
        uint256 premium = _startPremium >> intDays;
        uint256 partDay = (daysPast - intDays * PRECISION);
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