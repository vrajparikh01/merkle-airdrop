// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";
import { MemeToken } from "../src/MemeToken.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public merkleAirdrop;
    MemeToken public memeToken;

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 amountToCollect = (25 * 1e18); // 25.000000
    uint256 amountToSend = amountToCollect * 4;

    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [proofOne, proofTwo];

    address user;
    uint256 userPrivKey;

    function setup() public {
        memeToken = new MemeToken();
        merkleAirdrop = new MerkleAirdrop(ROOT, memeToken);

        memeToken.mint(memeToken.owner(), amountToSend);
        memeToken.transfer(address(merkleAirdrop), amountToSend);
        (user, userPrivKey) = makeAddrAndKey("user");
    }

    function signMessage(uint256 privKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = merkleAirdrop.getMessageHash(account, amountToCollect);
        (v, r, s) = vm.sign(privKey, hashedMessage);
    }

    function testUserCanClaim() public {
        console.log("User address: %s", user);

        uint256 startingBalance = memeToken.balanceOf(user);

        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivKey, user);
        vm.stopPrank();

        merkleAirdrop.claim(user, amountToCollect, proof, v, r, s);
        uint256 endingBalance = memeToken.balanceOf(user);
        console.log("Ending balance: %d", endingBalance);
        assertEq(endingBalance - startingBalance, amountToCollect);
    }
}