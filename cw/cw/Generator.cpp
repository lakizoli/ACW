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

	//Generate scandinavian crossword
	std::shared_ptr<Grid> grid = cw->GetGrid ();
	uint32_t row = 0; //The current free cell's row index
	uint32_t col = 0; //The current free cell's col index
	while (!grid->AllCellsAreFilled ()) {
		//1. step: find available question cell for the current pos in H and V directions also
		//... (we have to collect the already inserted alphabet pattern during the search)
		//-> if we found none, then we insert an empty question cell to the current pos (goto step 2!)
		//... (empty question cells will be spacers, if remains empty after all)
		//-> if we found a valid one for each direction, then we try to search words for each one (goto step 3!)
		Grid::FindQuestionResult hQ = grid->FindHorizontalQuestionForPos (row, col);
		Grid::FindQuestionResult hV = grid->FindVerticalQuestionForPos (row, col);
		if (!hQ.FoundAvailableQuestion () || !hV.FoundAvailableQuestion ()) { //We did'nt found valid question field for each direction
			//2. step: insert a free question mark to the position and jump the next available pos
			//TODO: ...
			
			//Advance to the next empty pos...
			//TODO: ...
			
			continue;
		}
		
		//3. step: search words for given patterns for each direction (all the two direction have to be passed in one step)
		//-> if we did'nt found valid words for all direction, then we have to rollback last insertion, and continue with the next available word
		//...(one direction rolled back at once!)
		//...(if we don't have available words at all, then we have to use the best filled state during generation history and exit!)
		//-> if we found valid words, then we have to insert them into the grid and questions, and have to jump to the next available position
		//TODO: ...
	}
	
	//TODO: provide progress callbacks...
	
	return cw;
}
