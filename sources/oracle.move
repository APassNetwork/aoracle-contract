module AOracle::oracle {
	use std::signer;
	use std::acl;
	use std::error;
	use std::vector;
	use std::string::String;
	use aptos_std::table;
	use aptos_std::simple_map::SimpleMap;
	use aptos_framework::coin;
	use aptos_framework::timestamp;
	//use aptos_framework::aptos_coin::AptosCoin;

	//
	// Errors
	//
	const ENO_NOT_ADMIN			: u64 = 1;
	//

	struct Oracle has key, store {
		decimals: u8,

		// **** Lastest round data ***************************
		latestAnswer: u64,
		latestStartedAt: u64,
		latestTimestamp: u64,
		latestRound: u64,
		// ***************************************************
		
		// **** Reserved section for retroactive upgrades ****
		getAnswer: table::Table<u64, u64>,
		getTimestamp: table::Table<u64, u64>,
		getStartedAt: table::Table<u64, u64>,
		// ***************************************************
	}
	
	//************ Deprecated *************
	struct OracleMap has key, store {
		oracles: SimpleMap<String,Oracle>
	}
	//*************************************

	struct OracleTable has key, store {
		oracles: table::Table<String,Oracle>
	}
	
	// Acl Access contorl
	struct AclInfo has key, store {
		adminAddress			: address,	// address of the admin
		operatorAddress			: address,	// address of the operator
		voters					: acl::ACL,
	}

	fun admin_address(): address {
		@AOracle
	}

	fun init_module(sender: &signer) {

		if( !exists<AclInfo>(signer::address_of(sender)) ){	
			let aclinfo=AclInfo {
				adminAddress: admin_address(),
				operatorAddress: admin_address(),
				voters: acl::empty(),
			};
			
			acl::add(&mut aclinfo.voters, admin_address());

			move_to(sender, aclinfo);
		};
		
		if( !exists<OracleTable>(signer::address_of(sender)) ){	
			move_to(sender, OracleTable {
				oracles: table::new<String,Oracle>()
			});
		};
		
		//create_oracle_with_type<AptosCoin>(8);
		//create_oracle_with_type<ApCoin>(8);
	}
	
	fun create_oracle_struct(decimals:u8):Oracle {
		Oracle {
			decimals: decimals,
			latestAnswer: 0,
			latestTimestamp: 0,
			latestStartedAt: 0,
			latestRound: 0,

			getAnswer: table::new<u64, u64>(),
			getTimestamp: table::new<u64, u64>(),
			getStartedAt: table::new<u64, u64>(),
		}
	}

	// Create Oracle with an CoinType
	fun create_oracle_with_type<CoinType>(decimals:u8) acquires OracleTable {

		let name = coin::name<CoinType>();

		create_oracle_with_name(name, decimals);
	}
	
	// Create Oracle with an Name
	fun create_oracle_with_name(name: String, decimals:u8) acquires OracleTable {

		let oracles = borrow_global_mut<OracleTable>(admin_address());
		table::add( &mut oracles.oracles, name, create_oracle_struct(decimals) );
	}
	
	// ************************************************************************************

	// Create Oracle with an Name Pub
	public entry fun create_oracle(account: signer, name: String, decimals:u8) acquires OracleTable {
		assert!( admin_address()==signer::address_of(&account), error::permission_denied(ENO_NOT_ADMIN));
		
		create_oracle_with_name(name, decimals);
	}

	// Add a voter
	public entry fun add_voter(account: signer, voter: address) acquires AclInfo {
		assert!( admin_address()==signer::address_of(&account), error::permission_denied(ENO_NOT_ADMIN));

		let aclinfo = borrow_global_mut<AclInfo>(admin_address());
		acl::add(&mut aclinfo.voters, voter);
	}

	/// Remove a voter
	public entry fun remove_voter(account: signer, voter: address) acquires AclInfo {
		assert!( admin_address()==signer::address_of(&account), error::permission_denied(ENO_NOT_ADMIN));

		let aclinfo = borrow_global_mut<AclInfo>(admin_address());
		acl::remove(&mut aclinfo.voters, voter);
	}
		
	// Update many answer from oracle_feed::feed
	public entry fun updateManyAnswer(_account: signer, _types:vector<String>, _answers:vector<u64> ) acquires OracleTable, AclInfo {
		updateManyAnswer_v2(&_account,&_types,&_answers);
	}

	public entry fun updateManyAnswer_v2(account: &signer, _types:&vector<String>, _answers:&vector<u64> ) acquires OracleTable, AclInfo {
		
		let aclinfo = borrow_global<AclInfo>(@AOracle);
		acl::assert_contains( &aclinfo.voters, signer::address_of(account) );

		let oracles = borrow_global_mut<OracleTable>(@AOracle);
		
		let now = timestamp::now_seconds();
		let len = vector::length(_types);
		assert!( len == vector::length(_answers), 0);

		while( len>0 ) {

			let orcale = table::borrow_mut<String,Oracle>(
				&mut oracles.oracles,
				*vector::borrow(_types, len-1)
			);

			orcale.latestAnswer = *vector::borrow(_answers, len-1);
			orcale.latestTimestamp = now;
			orcale.latestStartedAt = now;
			orcale.latestRound = orcale.latestRound + 1;

			len = len - 1;
		}
	}

	// Update single answer
	public entry fun updateAnswer<CoinType>(account: signer, _answer:u64 ) acquires OracleTable, AclInfo {
		
		let aclinfo = borrow_global<AclInfo>(admin_address());
		acl::assert_contains( &aclinfo.voters, signer::address_of(&account) );

		let oracles = borrow_global_mut<OracleTable>(@AOracle);
		let name = coin::name<CoinType>();
		let orcale = table::borrow_mut<String,Oracle>(&mut oracles.oracles,name);

		orcale.latestAnswer = _answer;
		orcale.latestTimestamp = timestamp::now_seconds();
		orcale.latestStartedAt = timestamp::now_seconds();
		orcale.latestRound = orcale.latestRound + 1;
	}

	// Get lastet round data by CoinType
	public fun latestRoundData<CoinType>(): (u64,u64,u64,u64,u64) acquires OracleTable {

		let oracles = borrow_global<OracleTable>(admin_address());
		let name = coin::name<CoinType>();
		let orcale = table::borrow<String,Oracle>(&oracles.oracles,name);

		(
			orcale.latestRound,
			orcale.latestAnswer,
			orcale.latestStartedAt,
			orcale.latestTimestamp,
			orcale.latestRound
		)
	}

	// Get lastet round data by Name
	public fun latestRoundDataByName(name: String): (u64,u64,u64,u64,u64) acquires OracleTable {

		let oracles = borrow_global<OracleTable>(admin_address());
		let orcale = table::borrow<String,Oracle>(&oracles.oracles,name);

		(
			orcale.latestRound,
			orcale.latestAnswer,
			orcale.latestStartedAt,
			orcale.latestTimestamp,
			orcale.latestRound
		)
	}
}

