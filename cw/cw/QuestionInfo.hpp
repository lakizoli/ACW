//
//  QuestionInfo.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef QuestionInfo_hpp
#define QuestionInfo_hpp

class BinaryReader;
class BinaryWriter;

class QuestionInfo {
//Declaration
public:
	enum class Direction : uint32_t {
		None,
		LeftDown,
		RightDown,
		TopRight,
		Right,
		BottomDown,
		BottomRight
	};
	
	struct Question {
		Direction dir = Direction::None;
		uint32_t questionIndex = 0;
		std::wstring question;
	};
	
//Data
private:
	std::vector<Question> _questions;
	
//Implementation
	QuestionInfo () = default;
	
//Construction
public:
	static std::shared_ptr<QuestionInfo> Create ();
	
	static std::shared_ptr<QuestionInfo> Deserialize (const BinaryReader& reader);
	void Serialize (BinaryWriter& writer);

//Interface
public:
	const std::vector<Question> GetQuestions () const { return _questions; }
	
	//Max 2 question in a place!
	bool HasAvailableQuestionPlace () const { return _questions.size () < 2; }
	
	void AddQuestion (Direction dir, uint32_t questionIndex, const std::wstring& question);
};

#endif /* QuestionInfo_hpp */
