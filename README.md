# AOracle Contract

## About AOracle
Explore the decentralized AOracle networks(beta) powered by Apters.

## How to Integration AOracle

### Contract
Address: 0xffd89fe22fd620d2cba0b3aaccdde6f5ad63ce7a7b18d13c0dc61e21521affff
Source Code: https://github.com/AptosPassport/aoracle-contract

### Access off-chain
You can easily access AOracle real-time data through API.
Visit AOracle Board at [AOracle Board](http://aptpp.com/#/aoracle), choose pairand get API url. The maximum delay between this API and the data on the chain is 5 seconds

### Access on-chain
You should add a dependency in your project move.toml
```
[package]
name = "YourProject"
version = "0.0.1"
upgrade_policy = "compatible"

[dependencies]
AptosFramework = { local = "../../aptos-core-main/aptos-move/framework/aptos-framework" }
AptosStdlib = { local = "../../aptos-core-main/aptos-move/framework/aptos-stdlib" }
AptosToken = { local = "../../aptos-core-main/aptos-move/framework/aptos-token" }

// Add this line
AOracle = { git = "https://github.com/AptosPassport/aoracle-contract.git", rev = "main" }
```

Then add the module reference in the move code, and use AOracle like follow:

```
module YourProject::SomeModule {
  use std::error;
  use std::vector;
  use std::signer;
	
  // Use AOracle moudule
  use AOracle::oracle;
	
  /**
  * @notice Get latest recorded price from oracle
  */
  fun getPriceFromOracle(): (u64, u64) {	
    let (roundId, price, _, timestamp, _) = 
        oracle::latestRoundDataByName(string::utf8("APTUSDT"));
    (roundId, price)
  }
}
```

## More infomation
- [APass](https://aptpp.com)
- [AOracle Board](http://aptpp.com/#/aoracle)
- [Document](https://doc.aptpp.com/doc/aoracle)
