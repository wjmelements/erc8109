pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {ProxyStorageBase} from "../src/ProxyStorageBase.sol";
import {Bootstrap} from "../src/interfaces/Bootstrap.sol";
import {IERC8109Minimal} from "../src/interfaces/IERC8109Minimal.sol";

contract ProxyStorageView is ProxyStorageBase {
    function facetAddress(bytes4 selector) public view returns (address delegate) {
        return selectorToFacet[selector];
    }
}

contract ProxyStorageBaseTest is Test {
    address internal proxy;

    function setUp() public {
        proxy = deployCode("out/Proxy.constructor.evm/Proxy.constructor.json");
    }

    function testStorage() public {
        ProxyStorageView storageView = new ProxyStorageView();
        Bootstrap(proxy).configure(IERC8109Minimal.facetAddress.selector, address(storageView));
        assertEq(IERC8109Minimal(proxy).facetAddress(IERC8109Minimal.facetAddress.selector), address(storageView));
    }
}
