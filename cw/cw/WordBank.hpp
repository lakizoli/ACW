//
//  WordBank.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef WordBank_hpp
#define WordBank_hpp

class QueryWords;

class WordBank {
//Definitions
	struct WordKey {
		uint8_t firstLetter = 0;
		uint8_t secondLetter = 0;
		
		bool operator < (const WordKey& chk) const {
			return firstLetter < chk.firstLetter || (firstLetter == chk.firstLetter && secondLetter < chk.secondLetter);
		}
	};
	
	struct WordList {
		std::map<WordKey, std::vector<uint32_t>> _indices; ///< The word indices assigned to their keys.
		
		void AddWord (uint32_t index, uint32_t length, const std::string& word);
	};
	
public:
	typedef std::function<bool (uint32_t idx, const std::string& word)> EnumWords;

//Data
private:
	std::map<uint32_t, std::shared_ptr<WordList>> _search; ///< The search tree (word lists assigned to their word lengths).
	std::shared_ptr<QueryWords> _words;
	
//Implementation
	WordBank () = default;
	bool EnumerateWordsOfIndices (const std::vector<uint32_t>& indices, EnumWords callback) const;
	
//Construction
public:
	static std::shared_ptr<WordBank> Create (std::shared_ptr<QueryWords> words);
	
//Interface
public:
	uint32_t GetMinLength () const;
	uint32_t GetMaxLength () const;
	bool ContainsLength (uint32_t len) const;
	
	void EnumerateWords (uint32_t len, EnumWords callback) const;
	void EnumerateWords (uint32_t len, uint8_t firstLetter, EnumWords callback) const;
	void EnumerateWords (uint32_t len, uint8_t firstLetter, uint8_t secondLetter, EnumWords callback) const;
};

#endif /* WordBank_hpp */