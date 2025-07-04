// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TOLCOIN is ERC20, ERC20Burnable, Pausable, Ownable {
    using Address for address;

    uint256 public constant MAX_SUPPLY = 1_000_000_000_000 * 10 ** 18;
    uint256 public transferDelay = 30; // Anti-bot delay (seconds)
    mapping(address => uint256) private _lastTransferTimestamp;
    mapping(address => bool) public isExcludedFromAntiBot;

    constructor() ERC20("TOLCOIN", "TOLCOIN") Ownable(msg.sender) {
        _mint(msg.sender, MAX_SUPPLY);
        isExcludedFromAntiBot[msg.sender] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function excludeFromAntiBot(address account, bool excluded) external onlyOwner {
        isExcludedFromAntiBot[account] = excluded;
    }

    function setTransferDelay(uint256 delayInSeconds) external onlyOwner {
        require(delayInSeconds <= 300, "Delay too long");
        transferDelay = delayInSeconds;
    }

    // Overriding hook manually since we don't inherit another token extension that defines this hook
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual
    {
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!isExcludedFromAntiBot[from] && !isExcludedFromAntiBot[to]) {
            require(
                block.timestamp - _lastTransferTimestamp[from] >= transferDelay,
                "Anti-bot: Transfer too soon"
            );
            _lastTransferTimestamp[from] = block.timestamp;
        }
    }
}
