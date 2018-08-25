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

Generator::InsertWordRes Generator::InsertWordIntoCells (const std::vector<std::shared_ptr<Cell>>& cells, std::set<std::string>& usedWords) const {
	InsertWordRes res;
	
	uint32_t minLen = (uint32_t) cells.size ();
	while (minLen > 0 && cells[minLen-1]->IsEmpty ()) {
		--minLen;
	}
	
	for (uint32_t wordLen = (uint32_t) cells.size (); wordLen > minLen && !res.inserted; --wordLen) {
		_answers->EnumerateWords (wordLen, [&res, &cells, &usedWords, wordLen] (uint32_t idx, const std::string& word) -> bool {
			auto itUseCheck = usedWords.find (word);
			if (itUseCheck != usedWords.end ()) {
				return true; //continue enumeration
			}
			
			//Check word for cells pattern
			bool wordFits = true;
			for (uint32_t i = 0, iEnd = (uint32_t) word.length (); i < iEnd; ++i) {
				uint8_t ch = word[i];
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
				for (uint32_t i = 0, iEnd = (uint32_t) word.length(); i < iEnd; ++i) {
					uint8_t ch = word[i];
					std::shared_ptr<Cell> cell = cells[i];
					cell->SetValue (ch);
				}
				
				bool addQuestion = word.length () < cells.size ();
				if (addQuestion) {
					std::shared_ptr<Cell> cell = cells[word.length ()];
					cell->ConfigureAsEmptyQuestion ();
				}
				
				//TODO: fill separator borders during generation...
				
				//Place index to the used word indices
				usedWords.insert (word);
				
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
										 uint32_t questionIndex) const
{
	std::shared_ptr<QuestionInfo> qInfo = questionCell->GetQuestionInfo ();
	const std::string& word = _questions->GetWord (questionIndex);
	
	const CellPos& questionPos = questionCell->GetPos ();
	const CellPos& firstLetterPos = firstLetterCell->GetPos ();
	if (firstLetterPos.row > questionPos.row) { //First letter is below the question
		QuestionInfo::Direction dir;
		if (secondLetterCell != nullptr && secondLetterCell->GetPos ().col == firstLetterPos.col) {
			dir = QuestionInfo::Direction::BottomDown;
		} else {
			dir = QuestionInfo::Direction::BottomRight;
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
		if (secondLetterCell != nullptr && secondLetterCell->GetPos ().col == firstLetterPos.col) {
			dir = QuestionInfo::Direction::RightDown;
		} else {
			dir = QuestionInfo::Direction::Right;
		}
		qInfo->AddQuestion (dir, questionIndex, word);
		firstLetterCell->AddQuestionToStartCell (questionCell);
	}
}

std::shared_ptr<Generator> Generator::Create (const std::string& path, const std::string& name, uint32_t width, uint32_t height,
											  std::shared_ptr<QueryWords> questions, std::shared_ptr<QueryWords> answers)
{
	std::shared_ptr<Generator> gen (new Generator ());
	gen->_path = path;
	gen->_name = name;
	gen->_width = width;
	gen->_height = height;
	gen->_questions = questions;
	gen->_answers = WordBank::Create (answers);
	if (gen->_answers == nullptr) {
		return nullptr;
	}
	
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
	std::set<std::string>& usedWords = cw->GetUsedWords (); //The used words in crossword
	
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
		Grid::FindQuestionResult vQ = grid->FindVerticalQuestionForPos (row, col);
		if (!hQ.FoundAvailableQuestion () || !vQ.FoundAvailableQuestion ()) { //We did'nt found valid question field for each direction
			//2. step: insert a free question mark to the position and jump the next available pos
			if (!grid->SetCellToFreeQuestionCell (row, col)) {
				return nullptr;
			}

			//Advance to the next empty pos...
			grid->AdvanceToTheNextAvailablePos (row, col);
			continue;
		}

		//3. step: search words for given patterns for each direction (all the two direction have to be passed in one step)
		//-> if we did'nt found valid words for all direction, then we have to rollback last insertion, and continue with the next available word
		//...(one direction rolled back at once!)
		//...(if we don't have available words at all, then we have to use the best filled state during generation history and exit!)
		//-> if we found valid words, then we have to insert them into the grid and questions, and have to jump to the next available position
		InsertWordRes hWord = InsertWordIntoCells (hQ.cellsAvailable, usedWords);
		if (hWord.inserted) {
			std::shared_ptr<Cell> secondLetterCell = hQ.cellsAvailable.size () > 1 ? hQ.cellsAvailable[1] : nullptr;
			ConfigureQuestionInCell (hQ.questionCell, hQ.cellsAvailable[0], secondLetterCell, hWord.insertedWordIndex);
		}
		
		InsertWordRes vWord = InsertWordIntoCells (vQ.cellsAvailable, usedWords);
		if (vWord.inserted) {
			std::shared_ptr<Cell> secondLetterCell = vQ.cellsAvailable.size () > 1 ? vQ.cellsAvailable[1] : nullptr;
			ConfigureQuestionInCell (vQ.questionCell, vQ.cellsAvailable[0], secondLetterCell, vWord.insertedWordIndex);
		}

		//Advance to the next available position
		grid->AdvanceToTheNextAvailablePos (row, col);
		
		//Handle stuck into cell
		if (row == lastRow && col == lastCol) {
			if (!grid->SetCellToFreeQuestionCell (row, col)) {
				return nullptr;
			}
			
			grid->AdvanceToTheNextAvailablePos (row, col);
		}
	}
	
//	grid->Dump ();
//	printf ("\n");

	return cw;
}
