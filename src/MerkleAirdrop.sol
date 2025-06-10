// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    IERC20 private immutable i_airdropToken;
    bytes32 private immutable i_merkleRoot;
    mapping(address => bool) private s_hasClaimed;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claimed(address account, uint256 amount);
    event MerkleRootUpdated(bytes32 newMerkleRoot);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    )
        external
    {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // Verify the merkle proof
        // calculate the leaf node hash
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        // verify the merkle proof
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        s_hasClaimed[account] = true; // prevent users claiming more than once and draining the contract
        emit Claimed(account, amount);

        i_airdropToken.safeTransfer(account, amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
