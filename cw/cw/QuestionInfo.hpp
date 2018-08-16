//
//  QuestionInfo.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef QuestionInfo_hpp
#define QuestionInfo_hpp

class QuestionInfo {
	
//Implementation
	QuestionInfo () = default;
	
//Construction
public:
	static std::shared_ptr<QuestionInfo> Create ();
	
//Interface
public:
	//TODO: implement QuestionInfo handling (max 2 question in a place!)
	bool HasAvailableQuestionPlace () const { return true; }
};

#endif /* QuestionInfo_hpp */
