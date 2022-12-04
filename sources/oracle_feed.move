//
// This module is used to parse the feed package, check the validity, and submit answers in batches
//
module AOracle::oracle_feed {
	use std::vector;
	use std::error;
	use std::string::String;
	use aptos_framework::account;
	use aptos_framework::timestamp;

	use AOracle::zkticket;
	use AOracle::buffer_utils;
	use AOracle::oracle;

	//
	// Errors
	//
	const ENO_NOT_ADMIN		: u64 = 1;
	const ENO_INVAILD_TICKET	: u64 = 500;
	const ENO_TIMEOUT		: u64 = 501;
	//
	
	// The maximum time offset allowed by the feed package
	const MAX_TIME_OFFSET		: u64 = 30;

	struct Feed has key, drop, store {
		// Reserved, Round number should be incremented in order to ensure no rollback
		round: u64,
		// Feed package generated timestamp
		time: u64,
		// Types list
		types: vector<String>,
		// Answers list
		answers: vector<u64>,
	}

	struct GlobalRes has key {
		// Global current round number
		round: u64,
		// Sub-account added to the ACL by oracle
		signer_cap: account::SignerCapability
	}
	
	fun init_module(_account: &signer) {

		let (_resource_signer, signer_cap) = account::create_resource_account(_account, b"oracle_seed_01");
	
		move_to(_account, GlobalRes{
			round:0,
			signer_cap
		});
	}
	
	// Parse Feed Packet to Object
	fun parse_feed(_data: &vector<u8>): Feed{

		// Create empty object
		let _feed_obj = Feed {
			round: 0,
			time: 0,
			types: vector<String>[],
			answers: vector<u64>[],
		};

		// Start to parse feed object
		let _buf = buffer_utils::init(*_data);
		
		///////////////////////////////////////////////////////
		// [Struct of feed]
		// version      u8	(should be 0)
		// round        u32
		// timestamp    u32
		// feed_len     u16
		// feed_data[]
		//    | type    String
		//    | answer  u64
		///////////////////////////////////////////////////////

		let _version = buffer_utils::read_u8(&mut _buf);

		_feed_obj.round = buffer_utils::read_u32(&mut _buf);
		_feed_obj.time = buffer_utils::read_u32(&mut _buf);
		
		let _feed_len = buffer_utils::read_u16(&mut _buf);
		
		while( _feed_len>0 ){
			
			vector::push_back(&mut _feed_obj.types, buffer_utils::read_string(&mut _buf) );
			vector::push_back(&mut _feed_obj.answers, buffer_utils::read_u64(&mut _buf) );

			_feed_len=_feed_len-1;
		};

		_feed_obj 
	}
	
	// Feed oracle datas from nodes
	public entry fun feed(_account: &signer, _data:vector<u8>, _ticket: vector<u8>) acquires GlobalRes {

		// Verify ticket 
		assert!( zkticket::check_ticket(&_ticket,&_data), error::permission_denied(ENO_INVAILD_TICKET));
	
		let res = borrow_global<GlobalRes>(@AOracle);

		// Get now timestamp
		let now = timestamp::now_seconds();

		// Parse data to object
		let feed = parse_feed(&_data);

		// The up and down time error cannot exceed MAX_TIME_OFFSET seconds
		assert!( feed.time > now - MAX_TIME_OFFSET &&
				 feed.time < now + MAX_TIME_OFFSET, error::permission_denied(ENO_TIMEOUT));

		let res_account = account::create_signer_with_capability(&res.signer_cap);

		// Submit answers
		oracle::updateManyAnswer_v2(&res_account, &feed.types, &feed.answers);
	}
}
