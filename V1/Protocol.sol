// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {SharedDevice} from "./SharedDevice.sol";
import {ServiceMarket} from "./ServiceMarket.sol";

contract Protocol is ServiceMarket {
    constructor(address initialOwner) ServiceMarket(initialOwner) {}
}
