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

Generator::Generator () {
}

std::shared_ptr<Generator> Generator::Create (const std::string& name, uint32_t width, uint32_t height,
											  uint32_t questionIndex, uint32_t solutionIndex)
{
	std::shared_ptr<Generator> gen (new Generator ());
	gen->_name = name;
	gen->_width = width;
	gen->_height = height;
	gen->_questionIndex = questionIndex;
	gen->_solutionIndex = solutionIndex;
	
	//TODO: provide word database to generator...
	
	return gen;
}

std::shared_ptr<Crossword> Generator::Generate () const {
	//TODO: generate crossword...
	//TODO: provide progress callbacks...
	
	return nullptr;
}
