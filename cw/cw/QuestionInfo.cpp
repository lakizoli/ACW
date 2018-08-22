//
//  QuestionInfo.cpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "QuestionInfo.hpp"
#include "BinarySerializer.hpp"

std::shared_ptr<QuestionInfo> QuestionInfo::Create () {
	std::shared_ptr<QuestionInfo> questionInfo (new QuestionInfo ());

	return questionInfo;
}

std::shared_ptr<QuestionInfo> QuestionInfo::Deserialize (const BinaryReader& reader) {
	std::shared_ptr<QuestionInfo> info (new QuestionInfo ());
	
	reader.ReadArray ([info] (const BinaryReader& reader) -> void {
		info->_questions.push_back (Question {
			(Direction) reader.ReadUInt32 (),
			reader.ReadUInt32 (),
			reader.ReadString ()
		});
	});

	return info;
}

void QuestionInfo::Serialize (BinaryWriter& writer) {
	writer.WriteArray (_questions, [] (BinaryWriter& writer, const Question& question) -> void {
		writer.WriteUInt32 ((uint32_t) question.dir);
		writer.WriteUInt32 (question.questionIndex);
		writer.WriteString (question.question);
	});
}

void QuestionInfo::AddQuestion (Direction dir, uint32_t questionIndex, const std::string& question) {
	if (!HasAvailableQuestionPlace ()) {
		return;
	}
	
	_questions.push_back (Question {
		dir,
		questionIndex,
		question
	});
	
	if (_questions.size () > 1) {
		std::sort (_questions.begin (), _questions.end (), [] (const Question& q1, const Question& q2) -> bool {
			return (uint32_t) q1.dir < (uint32_t) q2.dir;
		});
	}
}
