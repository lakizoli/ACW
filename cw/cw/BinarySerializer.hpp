//
//  BinarySerializer.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef BinarySerializer_hpp
#define BinarySerializer_hpp

class BinaryReader {
	mutable uint64_t mReadPos;
	const std::vector<uint8_t>& mData;
	
	template<class T>
	T ReadArray () const {
		uint32_t len = ReadUInt32 ();
		if (len == 0) {
			return T ();
		}
		
		const uint8_t* ptr = &mData[mReadPos];
		mReadPos += len;
		return T (ptr, ptr + len);
	}
	
	template<typename T>
	T ReadValue () const {
		uint32_t len = sizeof (T);
		
		const uint8_t* ptr = &mData[mReadPos];
		mReadPos += len;
		
		T val;
		std::memcpy (&val, ptr, len);
		return val;
	}
	
public:
	BinaryReader (const std::vector<uint8_t>& data) :
		mReadPos (0),
		mData (data)
	{
	}
	
	const std::vector<uint8_t>& GetData () const { return mData; }
	
//Interface
public:
	std::vector<uint8_t> ReadData () const { return ReadArray<std::vector<uint8_t>> (); }
	std::string ReadString () const { return ReadArray<std::string> (); }
	
	bool ReadBoolean () const { return ReadValue<uint8_t> () != 0; }
	uint8_t ReadUInt8 () const { return ReadValue<uint8_t> (); }
	
	int32_t ReadInt32 () const { return ReadValue<int32_t> (); }
	uint32_t ReadUInt32 () const { return ReadValue<uint32_t> (); }
	
	int64_t ReadInt64 () const { return ReadValue<int64_t> (); }
	uint64_t ReadUInt64 () const { return ReadValue<uint64_t> (); }
	
	float ReadFloat () const { return ReadValue<float> (); }
	double ReadDouble () const { return ReadValue<double> (); }
	
	wchar_t ReadWideChar () const { return ReadValue<wchar_t> (); }
	std::wstring ReadWideString () const {
		std::wstring res;
		ReadArray([&res] (const BinaryReader& reader) -> void {
			res.push_back (reader.ReadWideChar ());
		});
		return res;
	}
	
	void ReadArray (std::function<void (const BinaryReader&)> readItem) const {
		uint32_t count = ReadUInt32 ();

		for (uint32_t i = 0;i < count;++i) {
			readItem (*this);
		}
	}
};

class BinaryWriter {
	std::vector<uint8_t>& mData;
	
	template<class T>
	void WriteArray (const T& arr) {
		uint32_t len = (uint32_t) arr.size ();
		WriteUInt32 (len);
		
		if (len > 0) {
			std::copy (arr.begin (), arr.end (), std::back_inserter (mData));
		}
	}
	
	template<typename T>
	void WriteValue (T val) {
		uint32_t len = sizeof (T);
		const uint8_t* ptr = (const uint8_t*) &val;
		std::copy (ptr, ptr + len, std::back_inserter (mData));
	}
	
public:
	BinaryWriter (std::vector<uint8_t>& data) :
		mData (data)
	{
		//In writer, we truncate the content if any
		mData.clear ();
	}
	
	const std::vector<uint8_t>& GetData () const { return mData; }
	
//Interface
public:
	void WriteData (const std::vector<uint8_t>& data) { WriteArray<std::vector<uint8_t>> (data); }
	void WriteString (const std::string& val) { WriteArray<std::string> (val); }
	
	void WriteBoolean (bool val) { WriteValue<uint8_t> (val ? 1 : 0); }
	void WriteUInt8 (uint8_t val) { WriteValue<uint8_t> (val); }
	
	void WriteInt32 (int32_t val) { WriteValue<int32_t> (val); }
	void WriteUInt32 (uint32_t val) { WriteValue<uint32_t> (val); }
	
	void WriteInt64 (int64_t val) { WriteValue<int64_t> (val); }
	void WriteUInt64 (uint64_t val) { WriteValue<uint64_t> (val); }

	void WriteFloat (float val) { WriteValue<float> (val); }
	void WriteDouble (double val) { WriteValue<double> (val); }
	
	void WriteWideChar (wchar_t val) { WriteValue<wchar_t> (val); }
	void WriteWideString (const std::wstring& val) {
		WriteArray (val, [] (BinaryWriter& writer, const wchar_t& item) -> void {
			writer.WriteWideChar (item);
		});
	}

	template<class T>
	void WriteArray (const T& arr, std::function<void (BinaryWriter&, const typename T::value_type&)> writeItem) {
		uint32_t count = (uint32_t) arr.size ();
		WriteUInt32 (count);
		
		for (const typename T::value_type& item : arr) {
			writeItem (*this, item);
		}
	}
};

#endif /* BinarySerializer_hpp */
