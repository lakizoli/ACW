//
//  FillTest.hpp
//  validatecw
//
//  Created by Laki Zoltán on 2019. 09. 14..
//  Copyright © 2019. Laki Zoltán. All rights reserved.
//

#ifndef FillTest_hpp
#define FillTest_hpp

#include <cw.hpp>
#include <adb.hpp>

class FillTest {
	static std::wstring TestWordVertical (std::shared_ptr<Grid> grid, uint32_t row, uint32_t col, const std::wstring& word);
	static std::wstring TestWordHorizontal (std::shared_ptr<Grid> grid, uint32_t row, uint32_t col, const std::wstring& word);
	static std::wstring TestWordsForQuestion (std::shared_ptr<Grid> grid, uint32_t row, uint32_t col, const QuestionInfo::Question& question, const std::set<std::wstring>& words);
	
public:
	static bool ValidateCrossword (const std::string& packagePath, const std::string& crosswordName);
};

#endif /* FillTest_hpp */
