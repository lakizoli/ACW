//
//  Generator.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 07..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef Generator_hpp
#define Generator_hpp

class Crossword;

class Generator {
	std::string _name;
	uint32_t _width = 0;
	uint32_t _height = 0;
	uint32_t _questionIndex = 0;
	uint32_t _solutionIndex = 0;
	
	Generator ();
	
public:
	static std::shared_ptr<Generator> Create (const std::string& name, uint32_t width, uint32_t height, uint32_t questionIndex, uint32_t solutionIndex);
	
	std::shared_ptr<Crossword> Generate () const;
};

#endif /* Generator_hpp */
