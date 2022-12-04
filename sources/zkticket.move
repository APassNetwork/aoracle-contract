module AOracle::zkticket {
	use std::error;
	use std::signer;
	use aptos_std::ed25519::{Self,UnvalidatedPublicKey};
	
	struct StoreCheckKey has key{
		pub: UnvalidatedPublicKey
	}
	
	//
	// Errors
	//
	const ENO_NOT_ADMIN			: u64 = 1;
	//	

	public fun admin_address(): address {
		@AOracle
	}
	
	public entry fun init_pub(account: signer, pub: vector<u8> ) {
		
		let account_addr = signer::address_of(&account);
	
		assert!( admin_address()==account_addr, error::permission_denied(ENO_NOT_ADMIN));
		
		if( !exists<StoreCheckKey>( account_addr ) ){	
			move_to(&account, StoreCheckKey {
				pub: ed25519::new_unvalidated_public_key_from_bytes(pub)
			});
		};

	}

	public fun check_ticket(ticket:& vector<u8>, message:& vector<u8>): bool acquires StoreCheckKey {
		let sign=& ed25519::new_signature_from_bytes(*ticket);
		let pub=& borrow_global<StoreCheckKey>(admin_address()).pub;
		let ret=ed25519::signature_verify_strict(sign, pub, *message);

		ret
	}
}
