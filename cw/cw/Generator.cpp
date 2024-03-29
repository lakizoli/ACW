//
//  Generator.cpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 07..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "Generator.hpp"
#include "Crossword.hpp"
#include "WordBank.hpp"
#include "QueryWords.hpp"
#include "Grid.hpp"
//#include <TargetConditionals.h>

Generator::InsertWordRes Generator::InsertWordIntoCells (bool isVertical, const std::vector<std::shared_ptr<Cell>>& cells,
														 std::set<std::wstring>& usedWordsOfWholePackage,
														 std::set<std::wstring>& usedWordsOfCrossword,
														 std::set<wchar_t>& usedCharsOfCrossword) const
{
	InsertWordRes res;
	
	uint32_t minLen = (uint32_t) cells.size ();
	while (minLen > 0 && cells[minLen-1]->IsEmpty ()) {
		--minLen;
	}
	
	for (uint32_t wordLen = (uint32_t) cells.size (); wordLen > minLen && !res.inserted; --wordLen) {
		_answers->EnumerateWords (wordLen, [&res, &cells, &usedWordsOfWholePackage, &usedWordsOfCrossword,
											&usedCharsOfCrossword, wordLen, isVertical]
								  (uint32_t idx, const std::wstring& word, const std::set<uint32_t>& spacePositions) -> bool
		{
			auto itUseCheck = usedWordsOfWholePackage.find (word);
			if (itUseCheck != usedWordsOfWholePackage.end ()) {
				return true; //continue enumeration
			}
			
			//Check word for cells pattern
			bool wordFits = true;
			for (uint32_t i = 0, iEnd = (uint32_t) word.length (); i < iEnd; ++i) {
				wchar_t ch = word[i];
				std::shared_ptr<Cell> cell = cells[i];
				if (cell->IsEmpty ()) {
					//This character fits the place well, so we have to do nothing...
				} else { //Cell has some value
					if (ch != cell->GetValue ()) {
						wordFits = false;
						break;
					}
				}
			}
			
			//If the word fits the pattern, we have found a valid word
			if (wordFits) {
				//Insert word into the cells
				for (uint32_t i = 0, iEnd = (uint32_t) word.length (); i < iEnd; ++i) {
					wchar_t ch = word[i];
					std::shared_ptr<Cell> cell = cells[i];
					cell->SetValue (ch);
					usedCharsOfCrossword.insert (ch);
					
					if (spacePositions.find (i) != spacePositions.end ()) { //We have to place a separator before the cell
						cell->SetSeparator (isVertical ? CellFlags::TopSeparator : CellFlags::LeftSeparator);
					}
				}
				
				bool addQuestion = word.length () < cells.size ();
				if (addQuestion) {
					std::shared_ptr<Cell> cell = cells[word.length ()];
					cell->ConfigureAsEmptyQuestion ();
				}
				
				//Place word to the used words
				usedWordsOfWholePackage.insert (word);
				usedWordsOfCrossword.insert (word);
				
				//Collect result
				res.inserted = true;
				res.questionAdded = addQuestion;
				res.insertedWordLen = wordLen;
				res.insertedWordIndex = idx;
				return false; //break enumeration
			}
			
			return true; //continue enumeration
		});
	}
	
	return res;
}

void Generator::ConfigureQuestionInCell (std::shared_ptr<Cell> questionCell,
										 std::shared_ptr<Cell> firstLetterCell,
										 std::shared_ptr<Cell> secondLetterCell,
										 uint32_t questionIndex,
										 bool isDirectionVertical) const
{
	std::shared_ptr<QuestionInfo> qInfo = questionCell->GetQuestionInfo ();
	const std::wstring& word = _questions->GetWord (questionIndex);
	
	const CellPos& questionPos = questionCell->GetPos ();
	const CellPos& firstLetterPos = firstLetterCell->GetPos ();
	if (firstLetterPos.row > questionPos.row) { //First letter is below the question
		QuestionInfo::Direction dir;
		if (secondLetterCell != nullptr) {
			if (secondLetterCell->GetPos ().col == firstLetterPos.col) {
				dir = QuestionInfo::Direction::BottomDown;
			} else {
				dir = QuestionInfo::Direction::BottomRight;
			}
		} else { //One word answer below the question cell
			if (isDirectionVertical) {
				dir = QuestionInfo::Direction::BottomDown;
			} else {
				dir = QuestionInfo::Direction::BottomRight;
			}
		}
		qInfo->AddQuestion (dir, questionIndex, word);
		firstLetterCell->AddQuestionToStartCell (questionCell);
	} else if (firstLetterPos.row < questionPos.row) { //First letter is above the question
		qInfo->AddQuestion (QuestionInfo::Direction::TopRight, questionIndex, word);
		firstLetterCell->AddQuestionToStartCell (questionCell);
	} else if (firstLetterPos.col < questionPos.col) { //First letter is on the left side of question
		qInfo->AddQuestion (QuestionInfo::Direction::LeftDown, questionIndex, word);
		firstLetterCell->AddQuestionToStartCell (questionCell);
	} else if (firstLetterPos.col > questionPos.col) { //First letter is on the right side of question
		QuestionInfo::Direction dir;
		if (secondLetterCell != nullptr) {
			if (secondLetterCell->GetPos ().col == firstLetterPos.col) {
				dir = QuestionInfo::Direction::RightDown;
			} else {
				dir = QuestionInfo::Direction::Right;
			}
		} else { //One word answer on the right side of the question cell
			if (isDirectionVertical) {
				dir = QuestionInfo::Direction::RightDown;
			} else {
				dir = QuestionInfo::Direction::Right;
			}
		}
		qInfo->AddQuestion (dir, questionIndex, word);
		firstLetterCell->AddQuestionToStartCell (questionCell);
	}
}

std::shared_ptr<Generator> Generator::Create (const std::string& path, const std::string& name, uint32_t width, uint32_t height,
											  std::shared_ptr<QueryWords> questions, std::shared_ptr<QueryWords> answers,
											  std::shared_ptr<QueryWords> usedWords, ProgressCallback progressCallback)
{
	std::shared_ptr<Generator> gen (new Generator ());
	gen->_name = name;
	gen->_width = width;
	gen->_height = height;
	gen->_questions = questions;
	
//#if TARGET_OS_OSX
	std::string wordBankPath = path + "/answers.wb";
	gen->_answers = WordBank::Load (wordBankPath, answers, progressCallback);
	if (gen->_answers == nullptr) {
//#endif
		gen->_answers = WordBank::Create (answers, progressCallback);
//#if TARGET_OS_OSX
		if (gen->_answers) {
			gen->_answers->Save (wordBankPath);
		}
	}
//#endif

	if (gen->_answers == nullptr) {
		return nullptr;
	}
	gen->_usedWords = usedWords;
	
	return gen;
}

std::shared_ptr<Crossword> Generator::Generate () const {
	std::shared_ptr<Crossword> cw = Crossword::Create (_name, _width, _height);
	if (cw == nullptr) {
		return nullptr;
	}

	//Generate swedish (arrow) crossword
	std::shared_ptr<Grid> grid = cw->GetGrid ();
	uint32_t lastRow, row = 1; //The current free cell's row index
	uint32_t lastCol, col = 1; //The current free cell's col index
	bool wasDiag = true; //The current cell is diagonal cell or not
	std::set<std::wstring> usedWords; //The used words of the whole package
	std::set<std::wstring> usedWordsOfCrossword; //The used words in crossword
	std::set<wchar_t> usedCharsOfCrossword; //The used characters in crossword
	
	if (_usedWords != nullptr) {
		for (uint32_t i = 0, iEnd = _usedWords->GetCount (); i < iEnd; ++i) {
			usedWords.insert (_usedWords->GetWord (i));
		}
	}
	
//	uint32_t r1 = 1, c1 = 1;
//	bool wasDiag1 = true;
//	while (c1 < _width && r1 < _height) {
//		grid->AdvanceToTheNextAvailablePos (r1, c1, wasDiag1);
//		printf ("row: %d, col: %d\n", r1, c1);
//	}

	for (uint32_t col = 0; col < _width; col += 2) {
		grid->SetCellToFreeQuestionCell (0, col);
	}
	
	for (uint32_t row = 0; row < _height; row += 2) {
		grid->SetCellToFreeQuestionCell (row, 0);
	}
	
	while (!grid->AllCellsAreFilled () && col < _width && row < _height) {
		lastCol = col;
		lastRow = row;
		
		//1. step: find available question cell for the current pos in H and V directions also
		//... (we have to collect the already inserted alphabet pattern during the search)
		//-> if we found none, then we insert an empty question cell to the current pos (goto step 2!)
		//... (empty question cells will be spacers, if remains empty after all)
		//-> if we found a valid one for each direction, then we try to search words for each one (goto step 3!)
		Grid::FindQuestionResult hQ = grid->FindHorizontalQuestionForPos (row, col);
		Grid::FindQuestionResult vQ = grid->FindVerticalQuestionForPos (row, col, hQ.questionCell);
		if (!hQ.FoundAvailableQuestion () || !vQ.FoundAvailableQuestion ()) { //We did'nt found valid question field for each direction
			//2. step: insert a free question mark to the position and jump the next available pos
			if (!grid->SetCellToFreeQuestionCell (row, col)) {
				return nullptr;
			}

			//Advance to the next empty pos...
			grid->AdvanceToTheNextAvailablePos (row, col, wasDiag);
			continue;
		}

		//3. step: search words for given patterns for each direction (all the two direction have to be passed in one step)
		//-> if we did'nt found valid words for all direction, then we have to rollback last insertion, and continue with the next available word
		//...(one direction rolled back at once!)
		//...(if we don't have available words at all, then we have to use the best filled state during generation history and exit!)
		//-> if we found valid words, then we have to insert them into the grid and questions, and have to jump to the next available position
		InsertWordRes hWord = InsertWordIntoCells (false, hQ.cellsAvailable, usedWords, usedWordsOfCrossword, usedCharsOfCrossword);
		if (hWord.inserted) {
			std::shared_ptr<Cell> secondLetterCell = hQ.cellsAvailable.size () > 1 ? hQ.cellsAvailable[1] : nullptr;
			ConfigureQuestionInCell (hQ.questionCell, hQ.cellsAvailable[0], secondLetterCell, hWord.insertedWordIndex, false);
		}
		
		InsertWordRes vWord = InsertWordIntoCells (true, vQ.cellsAvailable, usedWords, usedWordsOfCrossword, usedCharsOfCrossword);
		if (vWord.inserted) {
			std::shared_ptr<Cell> secondLetterCell = vQ.cellsAvailable.size () > 1 ? vQ.cellsAvailable[1] : nullptr;
			ConfigureQuestionInCell (vQ.questionCell, vQ.cellsAvailable[0], secondLetterCell, vWord.insertedWordIndex, true);
		}
		
//		grid->Dump ();
//		printf ("\n");
//		printf ("row: %d, col: %d\n", row, col);
//		printf ("\n");

		//Advance to the next available position
		grid->AdvanceToTheNextAvailablePos (row, col, wasDiag);
		
		//Handle stuck into cell
		if (row == lastRow && col == lastCol) {
			if (!grid->SetCellToFreeQuestionCell (row, col)) {
				return nullptr;
			}
			
			grid->AdvanceToTheNextAvailablePos (row, col, wasDiag);
		}
	}
	
	cw->SetWords (usedWordsOfCrossword);
	cw->SetUsedKeys (usedCharsOfCrossword);
	
	if (_usedWords != nullptr) {
		_usedWords->UpdateWithSet (usedWords);
	}
	
//	grid->Dump ();
//	printf ("\n");

	return cw;
}
