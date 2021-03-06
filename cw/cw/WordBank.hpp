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
	struct WordList {
		std::map<uint32_t, std::vector<uint32_t>> _indices; ///< The word indices assigned to their importance.
		
		static uint32_t IntersectionCount (const std::wstring& w1, const std::wstring& w2);
		void AddWord (uint32_t index, uint32_t length, const std::wstring& word, std::shared_ptr<QueryWords> allWords);
	};
	
public:
	typedef std::function<bool (uint32_t idx, const std::wstring& word, const std::set<uint32_t>& spacePositions)> EnumWords;

//Data
private:
	std::map<uint32_t, std::shared_ptr<WordList>> _search; ///< The search tree (word lists assigned to their word lengths).
	std::shared_ptr<QueryWords> _words;
	
//Implementation
	WordBank () = default;
	bool EnumerateWordsOfIndices (const std::vector<uint32_t>& indices, EnumWords callback) const;
	static bool IsSeparatorOrSpace (wchar_t ch);
	static uint32_t LengthOfWordWithoutSpaces (const std::wstring& word);
	std::wstring RemoveSpacesAndCollectPlaces (const std::wstring& word, std::set<uint32_t>& spacePositions) const;

//Construction
public:
	static std::shared_ptr<WordBank> Create (std::shared_ptr<QueryWords> words, std::function<bool (float)> progressCallback);
	
	static std::shared_ptr<WordBank> Load (const std::string& path, std::shared_ptr<QueryWords> words, std::function<bool (float)> progressCallback);
	bool Save (const std::string& path) const;
	
//Interface
public:
	uint32_t GetMinLength () const;
	uint32_t GetMaxLength () const;
	bool ContainsLength (uint32_t len) const;
	
	void EnumerateWords (uint32_t len, EnumWords callback) const;
};

#endif /* WordBank_hpp */
