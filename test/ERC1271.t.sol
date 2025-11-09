// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "../src/CoinbaseSmartWalletFactory.sol";
import "../src/ERC1271.sol";
import {MockCoinbaseSmartWallet} from "./mocks/MockCoinbaseSmartWallet.sol";

contract ERC1271Test is Test {
    CoinbaseSmartWalletFactory factory;
    CoinbaseSmartWallet account;

    address constant TEST_WALLET_ADDR = 0x2Af621c1B01466256393EBA6BF183Ac2962fd98C;

    function setUp() public {
        factory = new CoinbaseSmartWalletFactory(address(new CoinbaseSmartWallet()));
        bytes[] memory initialOwners = new bytes[](2);
        initialOwners[0] = abi.encode(address(1));
        initialOwners[1] = abi.encode(address(2));
        account = factory.createAccount(initialOwners, 0);
    }

    function test_returnsExpectedDomainHashWhenProxy() public {
        (
            ,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = account.eip712Domain();

        assertEq(verifyingContract, address(account));
        assertEq(abi.encode(extensions), abi.encode(uint256(0)));
        assertEq(salt, bytes32(0));

        bytes32 expected = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
        assertEq(expected, account.domainSeparator());
    }

    function _testStatic(uint256 chainId, bytes32 expectedHash) internal {
        vm.chainId(chainId);

        bytes[] memory owners = new bytes[](3);
        owners[0] = abi.encode(address(1));
        owners[1] = abi.encode(address(2));
        owners[2] = hex"66efa90a7c6a9fe2f4472dc80307116577be940f06f4b81b3cce9207d0d35ebdd420af05337a40c253b6a37144c30ba22bbd54c71af9e4457774d790b34c8227";

        CoinbaseSmartWallet mockWallet = new MockCoinbaseSmartWallet();
        vm.etch(TEST_WALLET_ADDR, address(mockWallet).code);
        mockWallet.initialize(owners);

        bytes32 actual = CoinbaseSmartWallet(payable(TEST_WALLET_ADDR)).replaySafeHash(
            0x9ef3f7124243b092c883252302a74d4ed968efc9f612396f1a82bbeef8931328
        );
        assertEq(expectedHash, actual, "Replay-safe hash mismatch");
    }

    function test_static_84532() public {
        _testStatic(
            84532,
            0x1b03b7e3bddbb2f9b5080f154cf33fcbed9b9cd42c98409fb0730369426a0a69
        );
    }

    function test_static_747474() public {
        _testStatic(
            747474,
            0x1b03b7e3bddbb2f9b5080f154cf33fcbed9b9cd42c98409fb0730369426a0a69
        );
    }
}
