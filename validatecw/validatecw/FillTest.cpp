//
//  FillTest.cpp
//  validatecw
//
//  Created by Laki Zoltán on 2019. 09. 14..
//  Copyright © 2019. Laki Zoltán. All rights reserved.
//

#include "FillTest.hpp"

std::wstring FillTest::TestWordVertical (std::shared_ptr<Grid> grid, uint32_t row, uint32_t col, const std::wstring& word) {
	for (uint32_t i = 0, iEnd = (uint32_t) word.size (); i < iEnd; ++i) {
		if (row + i >= grid->GetHeight ()) { //Check too big word
			return L"";
		}
		
		std::shared_ptr<Cell> cell = grid->GetCell (row + i, col);
		if (cell == nullptr) { //Cell not found
			return L"";
		}
		
		uint32_t flags = (uint32_t) cell->GetFlags ();
		bool isValueCell = (flags & (uint32_t) CellFlags::Value) == (uint32_t) CellFlags::Value;
		bool isQuestionCell = (flags & (uint32_t) CellFlags::Question) == (uint32_t) CellFlags::Question;
		
		if (isQuestionCell || !isValueCell) { //Check question cell, or value cell failure
			return L"";
		}
		
		if (cell->GetValue () != word[i]) { //Check value failure
			return L"";
		}
	}
	
	//Test end of word
	bool isBottomEnd = row + (uint32_t) word.size () == grid->GetHeight ();
	if (isBottomEnd) { //The bottom is a valid word close
		return word;
	}
	
	std::shared_ptr<Cell> cell = grid->GetCell (row + (uint32_t) word.size (), col);
	if (cell == nullptr) { //Cell after word not found
		return L"";
	}
	
	uint32_t flags = (uint32_t) cell->GetFlags ();
	bool isValueCell = (flags & (uint32_t) CellFlags::Value) == (uint32_t) CellFlags::Value;
	bool isQuestionCell = (flags & (uint32_t) CellFlags::Question) == (uint32_t) CellFlags::Question;
	
	if (isValueCell || !isQuestionCell) { //Cell type is wrong at the end of the word
		return L"";
	}
	
	return word;
}

std::wstring FillTest::TestWordHorizontal (std::shared_ptr<Grid> grid, uint32_t row, uint32_t col, const std::wstring& word) {
	for (uint32_t i = 0, iEnd = (uint32_t) word.size (); i < iEnd; ++i) {
		if (col + i >= grid->GetWidth ()) { //Check too big word
			return L"";
		}
		
		std::shared_ptr<Cell> cell = grid->GetCell (row, col + i);
		if (cell == nullptr) { //Cell not found
			return L"";
		}
		
		uint32_t flags = (uint32_t) cell->GetFlags ();
		bool isValueCell = (flags & (uint32_t) CellFlags::Value) == (uint32_t) CellFlags::Value;
		bool isQuestionCell = (flags & (uint32_t) CellFlags::Question) == (uint32_t) CellFlags::Question;
		
		if (isQuestionCell || !isValueCell) { //Check question cell, or value cell failure
			return L"";
		}
		
		if (cell->GetValue () != word[i]) { //Check value failure
			return L"";
		}
	}
	
	//Test end of word
	bool isRightEnd = col + (uint32_t) word.size () == grid->GetWidth ();
	if (isRightEnd) { //The right end is a valid word close
		return word;
	}
	
	std::shared_ptr<Cell> cell = grid->GetCell (row, col + (uint32_t) word.size ());
	if (cell == nullptr) { //Cell after word not found
		return L"";
	}
	
	uint32_t flags = (uint32_t) cell->GetFlags ();
	bool isValueCell = (flags & (uint32_t) CellFlags::Value) == (uint32_t) CellFlags::Value;
	bool isQuestionCell = (flags & (uint32_t) CellFlags::Question) == (uint32_t) CellFlags::Question;
	
	if (isValueCell || !isQuestionCell) { //Cell type is wrong at the end of the word
		return L"";
	}
	
	return word;
}

std::wstring FillTest::TestWordsForQuestion (std::shared_ptr<Grid> grid, uint32_t row, uint32_t col,
											 const QuestionInfo::Question& question, const std::set<std::wstring>& words)
{
	switch (question.dir) {
		case QuestionInfo::Direction::LeftDown:
			for (const std::wstring& word : words) {
				std::wstring res = TestWordVertical (grid, row, col - 1, word);
				if (!res.empty ()) {
					return res;
				}
			}
			break;
		case QuestionInfo::Direction::RightDown:
			for (const std::wstring& word : words) {
				std::wstring res = TestWordVertical (grid, row, col + 1, word);
				if (!res.empty ()) {
					return res;
				}
			}
			break;
		case QuestionInfo::Direction::Right:
			for (const std::wstring& word : words) {
				std::wstring res = TestWordHorizontal (grid, row, col + 1, word);
				if (!res.empty ()) {
					return res;
				}
			}
			break;
		case QuestionInfo::Direction::TopRight:
			for (const std::wstring& word : words) {
				std::wstring res = TestWordHorizontal (grid, row - 1, col, word);
				if (!res.empty ()) {
					return res;
				}
			}
			break;
		case QuestionInfo::Direction::BottomRight:
			for (const std::wstring& word : words) {
				std::wstring res = TestWordHorizontal (grid, row + 1, col, word);
				if (!res.empty ()) {
					return res;
				}
			}
			break;
		case QuestionInfo::Direction::BottomDown:
			for (const std::wstring& word : words) {
				std::wstring res = TestWordVertical (grid, row + 1, col, word);
				if (!res.empty ()) {
					return res;
				}
			}
			break;
		default:
		case QuestionInfo::Direction::None:
			break;
	}
	
	return L"";
}

bool FillTest::ValidateCrossword (const std::string& packagePath, const std::string& crosswordName) {
	bool pathEndsWithSeparator = packagePath.rfind ('/') == packagePath.length () - 1;
	std::shared_ptr<Crossword> cw = Crossword::Load (packagePath + (pathEndsWithSeparator ? "" : "/") + crosswordName);
	if (cw == nullptr) {
		return false;
	}
	
	std::shared_ptr<Grid> grid = cw->GetGrid ();
	if (grid == nullptr) {
		return false;
	}
	
	const std::set<std::wstring>& words = cw->GetWords ();
	std::vector<std::wstring> filledWords;
	for (uint32_t row = 0, rowEnd = grid->GetHeight (); row < rowEnd; ++row) {
		for (uint32_t col = 0, colEnd = grid->GetWidth (); col < colEnd; ++col) {
			std::shared_ptr<Cell> cell = grid->GetCell (row, col);
			if (cell == nullptr) {
				return false;
			}
			
			std::shared_ptr<QuestionInfo> qInfo = cell->GetQuestionInfo ();
			if (qInfo == nullptr) { //Not a question
				continue;
			}
			
			const std::vector<QuestionInfo::Question>& qs = qInfo->GetQuestions ();
			for (const QuestionInfo::Question& question : qs) {
				std::wstring tested = TestWordsForQuestion (grid, row, col, question, words);
				if (!tested.empty ()) {
					if (std::find (filledWords.begin (), filledWords.end (), tested) != filledWords.end ()) { //The word was filled already, and twice fill of same word is an error
						return false;
					}
					
					filledWords.push_back (tested);
				}
			}
		}
	}
	
	if (filledWords.size () != words.size ()) { //User can't fill all word in this crossword
		printf ("Not all words can be filled! The missing words are:\n");
		for (const std::wstring& word : words) {
			if (std::find (filledWords.begin (), filledWords.end (), word) == filledWords.end ()) {
				printf ("%ls\n", word.c_str ());
			}
		}
		return false;
	}
	
	return true;
}
