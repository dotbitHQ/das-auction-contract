// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//chainlink
interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

contract auction {
    uint256 GRACE_PERIOD = 90 days; //宽限期
    uint256 public immutable startPremium; //初始溢价 单位:美元
    uint256 public immutable endValue; //结束溢价 单位:美元
    uint256 constant PRECISION = 1e18;
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

    address public owner;
    bytes32 public root;
    mapping(string => bool) public bidStatus;
    AggregatorInterface public immutable usdOracle;
    event BidEvent(
        string account,
        uint256 value,
        address bid_user,
        uint256 bid_time
    );

    //_usdOracle(goerli):0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e, _startPremium: 100000000，totalDays： 21。
    constructor(
        AggregatorInterface _usdOracle,
        uint256 _startPremium,
        uint256 _totalDays
    ) payable {
        usdOracle = _usdOracle;
        owner = msg.sender;
        startPremium = _startPremium;

        endValue = _startPremium >> _totalDays;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You aren't the owner");
        _;
    }

    //更新根hash（上架）
    function onSale(
        bytes32 rootHash,
        string[] calldata clearAccountId
    ) public onlyOwner {
        require(root != rootHash, "There are no data need to be updated");
        //清理历史数据
        for (uint256 i = 0; i < clearAccountId.length; i++) {
            delete bidStatus[clearAccountId[i]];
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
        //验证根hash
        bytes memory pack = abi.encodePacked(
            accountId,
            expiredTime,
            basicPrice
        );
        bytes32 data = keccak256(pack);
        require(MerkleProof.verify(proof, root, data), "Validation failed");

        //判断账号状态
        require(!bidStatus[accountId], "Account has been sold");

        //验证价格
        //获取当前账号的荷兰拍eth价格（单位wei）
        uint256 accountPrice = getAuctionPrice(expiredTime, basicPrice);
        //判断当前出价是否大于荷兰拍价格
        require(msg.value >= accountPrice, "Value is too low");
        //更新账号状态为“已被排拍走”
        bidStatus[accountId] = true;
        emit BidEvent(accountId, msg.value, msg.sender, block.timestamp);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient funds");
        payable(msg.sender).transfer(amount);
    }

    //获取荷兰拍价格 (单位wei)
    function getAuctionPrice(
        uint256 expires,
        uint256 basePrice
    ) public view returns (uint256) {
        uint256 preium = _premium(expires);
        uint256 accountPrice = basePrice + preium * 1e2; //单位 美分
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

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(
        bytes32[] memory proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(
        bytes32 a,
        bytes32 b
    ) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
