// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {IERC8167} from "../src/interfaces/IERC8167.sol";
import {Proxy, ProxyStorageView, Setup, FullAdmin} from "../src/Proxy.sol";

contract ProxyTest is Test {
    address internal proxy;
    address internal setupImpl;

    function deployProxy() internal returns (address) {
        return address(new Proxy());
    }

    function setUp() public {
        proxy = deployProxy();
        setupImpl = vm.computeCreateAddress(proxy, 1);
    }

    function testConstructorEvents() public {
        address expectedProxy = vm.computeCreateAddress(address(this), 2);
        address expectedSetupImpl = vm.computeCreateAddress(expectedProxy, 1);

        vm.expectEmit(expectedProxy);
        emit IERC8167.SelectorDelegated(Setup.install.selector, expectedSetupImpl);

        address actualProxy = deployProxy();

        assertEq(expectedProxy, actualProxy);
    }

    function testFunctionNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(IERC8167.FunctionNotFound.selector, IERC8167.implementation.selector));
        IERC8167(proxy).implementation(Setup.install.selector);
    }

    function testSetupInstallUnauthorized() public {
        address unauthorized = makeAddr("thief");
        vm.expectRevert(abi.encodeWithSelector(Setup.Unauthorized.selector, unauthorized));
        vm.prank(unauthorized);
        FullAdmin(proxy).install(Setup.install.selector, address(this));
    }

    function testSetupInstallIntrospect() public {
        address viewImpl = address(new ProxyStorageView());

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(IERC8167.implementation.selector, viewImpl);
        FullAdmin(proxy).install(IERC8167.implementation.selector, viewImpl);

        assertEq(IERC8167(proxy).implementation(IERC8167.implementation.selector), viewImpl);
        assertEq(IERC8167(proxy).implementation(Setup.install.selector), setupImpl);
        // testFullAdmin()
        address fullAdminImpl = address(new FullAdmin(address(this)));

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(FullAdmin.uninstall.selector, fullAdminImpl);
        FullAdmin(proxy).install(FullAdmin.uninstall.selector, fullAdminImpl);
        assertEq(IERC8167(proxy).implementation(FullAdmin.uninstall.selector), fullAdminImpl);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(FullAdmin.upgrade.selector, fullAdminImpl);
        FullAdmin(proxy).install(FullAdmin.upgrade.selector, fullAdminImpl);
        assertEq(IERC8167(proxy).implementation(FullAdmin.upgrade.selector), fullAdminImpl);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(Setup.install.selector, fullAdminImpl);
        FullAdmin(proxy).upgrade(Setup.install.selector, fullAdminImpl);
        assertEq(IERC8167(proxy).implementation(Setup.install.selector), fullAdminImpl);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(IERC8167.selectors.selector, viewImpl);
        FullAdmin(proxy).install(IERC8167.selectors.selector, viewImpl);

        bytes4[] memory selectors = IERC8167(proxy).selectors();
        assertEq(selectors.length, 5);
        assertEq(selectors[0], Setup.install.selector);
        assertEq(selectors[1], IERC8167.implementation.selector);
        assertEq(selectors[2], FullAdmin.uninstall.selector);
        assertEq(selectors[3], FullAdmin.upgrade.selector);
        assertEq(selectors[4], IERC8167.selectors.selector);

        vm.expectRevert();
        FullAdmin(proxy).install(IERC8167.implementation.selector, address(0));

        vm.expectRevert();
        FullAdmin(proxy).upgrade(IERC8167.implementation.selector, address(0));

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(FullAdmin.upgrade.selector, address(0));
        FullAdmin(proxy).uninstall(FullAdmin.upgrade.selector);
        assertEq(IERC8167(proxy).implementation(FullAdmin.upgrade.selector), address(0));
        selectors = IERC8167(proxy).selectors();
        assertEq(selectors.length, 4);
        assertEq(selectors[0], Setup.install.selector);
        assertEq(selectors[1], IERC8167.implementation.selector);
        assertEq(selectors[2], FullAdmin.uninstall.selector);
        assertEq(selectors[3], IERC8167.selectors.selector);

        vm.expectRevert();
        FullAdmin(proxy).uninstall(FullAdmin.upgrade.selector);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(FullAdmin.upgrade.selector, fullAdminImpl);
        FullAdmin(proxy).install(FullAdmin.upgrade.selector, fullAdminImpl);
        assertEq(IERC8167(proxy).implementation(FullAdmin.upgrade.selector), fullAdminImpl);
        selectors = IERC8167(proxy).selectors();
        assertEq(selectors.length, 5);
        assertEq(selectors[0], Setup.install.selector);
        assertEq(selectors[1], IERC8167.implementation.selector);
        assertEq(selectors[2], FullAdmin.uninstall.selector);
        assertEq(selectors[3], IERC8167.selectors.selector);
        assertEq(selectors[4], FullAdmin.upgrade.selector);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(Setup.install.selector, address(0));
        FullAdmin(proxy).uninstall(Setup.install.selector);
        assertEq(IERC8167(proxy).implementation(Setup.install.selector), address(0));
        selectors = IERC8167(proxy).selectors();
        assertEq(selectors.length, 4);
        assertEq(selectors[0], FullAdmin.upgrade.selector);
        assertEq(selectors[1], IERC8167.implementation.selector);
        assertEq(selectors[2], FullAdmin.uninstall.selector);
        assertEq(selectors[3], IERC8167.selectors.selector);

        vm.expectEmit(proxy);
        emit IERC8167.SelectorDelegated(IERC8167.selectors.selector, address(0));
        FullAdmin(proxy).uninstall(IERC8167.selectors.selector);
        assertEq(IERC8167(proxy).implementation(IERC8167.selectors.selector), address(0));

        vm.expectRevert(abi.encodeWithSelector(IERC8167.FunctionNotFound.selector, IERC8167.selectors.selector));
        IERC8167(proxy).selectors();
    }
}
