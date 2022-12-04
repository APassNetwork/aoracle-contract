module AOracle::buffer_utils {
	use std::vector;
	use std::string::{Self,String};

	struct Buffer has drop {
		data: vector<u8>,
	}

	/// Init buffer from vector
	public fun init(data: vector<u8>): Buffer {
		vector::reverse(&mut data);
		Buffer {
			data,
		}
	}

	// Destory Buffer 
	public fun destroy(buf: Buffer) {
		let Buffer { data } = buf;
		vector::destroy_empty(data);
	}
	
	// Get one element from back
	public fun pop(buf: &mut Buffer): u8 {
		vector::pop_back(&mut buf.data)
	}

	public fun read_u8(buf: &mut Buffer): u8 {
		vector::pop_back(&mut buf.data)
	}

	public fun read_uint(buf: &mut Buffer, len: u8): u64 {
		let val: u64 = 0;
		while (len > 0) {
			let b = vector::pop_back(&mut buf.data);
			val = (val << 8) | (b as u64);
			len = len - 1;
		};

		val
	}

	public fun read_u64(buf: &mut Buffer): u64 {
		(read_uint(buf,8) as u64)
	}

	public fun read_u32(buf: &mut Buffer): u64 {
		(read_uint(buf,4) as u64)
	}

	public fun read_u16(buf: &mut Buffer): u64 {
		(read_uint(buf,2) as u64)
	}

	public fun read_vec_u8(buf: &mut Buffer): vector<u8> {
		let len=vector::pop_back(&mut buf.data);
		let vec=vector::empty();
		while (len > 0) {
			vector::push_back(&mut vec, vector::pop_back(&mut buf.data));
			len = len - 1;
		};
		vec
	}

	public fun read_vec_u64(buf: &mut Buffer): vector<u64> {
		let len=read_u16(buf);
		let vec=vector::empty();
		while (len > 0) {
			vector::push_back(&mut vec, read_u64(buf));
			len = len - 1;
		};
		vec
	}

	public fun read_string(buf: &mut Buffer): String {
		//string::utf8(read_vec_u8(buf))
		
		// Just want save gas ...

		let len=vector::pop_back(&mut buf.data);
		let vec=vector::empty();
		while (len > 0) {
			vector::push_back(&mut vec, vector::pop_back(&mut buf.data));
			len = len - 1;
		};

		string::utf8(vec)
	}

	//#[test_only]
	//use aptos_std::debug;

	#[test]
	fun test_buffer_utils() {
		let _data=x"010203445566778899aabb";
		let _buf=init(_data);

		assert!(read_u8(&mut _buf)==0x01,0);
		assert!(read_u16(&mut _buf)==0x0203,0);
		assert!(read_u64(&mut _buf)==0x445566778899aabb,0);

		destroy(_buf);
	}

	#[test]
	fun test_buffer_vec64() {
		let _data=x"0003000000000000000100000000000000020000000000000003";
		let _buf=init(_data);

		assert!(read_vec_u64(&mut _buf)==vector<u64>[1,2,3],0);
		//debug::print<vector<u64>>(&read_vec_u64(&mut _buf));

		destroy(_buf);
	}

	#[test]
	fun test_buffer_string() {
		let _data=x"03313233";
		let _buf=init(_data);

		assert!(read_string(&mut _buf)==string::utf8(b"123"),0);

		destroy(_buf);
	}
}