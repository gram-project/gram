# GRAM

GRAM is a trustless ERC20 token representing gold denomination in grams, backed 1:1 by XAUT (Tether Gold). The contract enables projects from Dwarf Systems to integrate gold-backed tokens with gram precision without counterparty risk.

## Architecture

The GRAM contract is immutable with no administrative control:

- No ownership (Ownable, AccessControl)
- No upgradeable proxy patterns
- No pause or blacklist functions
- No modifiable fee mechanism (fee is a constant)
- No admin minting capability

All critical parameters are defined as constants at deployment.

## Core Mechanics

### Minting (XAUT to GRAM)

Users deposit XAUT and receive GRAM at a fixed conversion rate. A 0.05% fee is deducted and sent to the treasury. The fee encourages gold usage over fiat currency for payments and savings.

```
1 XAUT = 31,103.4768 GRAM (1 troy oz = 31.1034768 grams per International Yard and Pound Agreement, 1959)
```

### Burning (GRAM to XAUT)

Users burn GRAM to redeem XAUT. Floor division ensures protocol solvency.

### Decimals Synchronization

The `updateDecimals()` function is permissionless and fetches XAUT decimals dynamically from the token. This allows the contract to adapt if XAUT's decimal representation changes.

## Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| CONVERSION_RATE | 31103476800000000000 | XAUT to GRAM multiplication factor |
| FEE_BASIS_POINTS | 5 | 0.05% minting fee |
| XAUT_DECIMALS | 8 | XAUT token decimals (synchronizable) |

## Integration

```solidity
// Mint GRAM from XAUT
gram.mint(xautAmount);

// Burn GRAM for XAUT
gram.burn(gramAmount);

// Update XAUT decimals if needed
gram.updateDecimals();
```

## Security

The contract prioritizes trustlessness over flexibility. There are no admin keys, no upgrade mechanisms, and no emergency pauses. Users can verify the immutable nature of the contract by examining the source code.

## Testing

```bash
forge test
```

Test coverage includes:
- Mint/burn conversion accuracy
- Fee distribution
- Solvency invariants (fuzz tested)
- Rounding behavior
- Event emission
- Access control reverts

## Deployment

Mainnet addresses are configured in `src/script/DeployGRAM.s.sol`:

- XAUT: 0x68749665FF8D2d112Fa859AA293F07A622782F38
- TREASURY: 0x300Df392cE8910E0E4D42C6ecb9bA1a8b19bAdF0
