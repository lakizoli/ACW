//
// Created by Laki Zoltán on 2019-09-10.
//

#ifndef ANKI_CROSSWORD_GENERATORINFO_HPP
#define ANKI_CROSSWORD_GENERATORINFO_HPP

#include <Package.hpp>

class Card : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (Card);

public:
	Card ();

public:
	void SetCardID (uint64_t cardID);
	void SetNoteID (uint64_t noteID);
	void SetModelID (uint64_t modelID);
	void AddFieldValue (const std::string& fieldValue);
	void SetSolutionFieldValue (const std::string& solutionFieldValue);
};

class Field : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (Field);

public:
	Field ();

public:
	void SetIdx (uint32_t idx);
	void SetName (const std::string& name);
};

class GeneratorInfo : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (GeneratorInfo);

public:
	GeneratorInfo ();

public:
	void AddDeck (const Deck& deck);
	void AddCard (const Card& card);
	void AddField (const Field& field);

	void AddUsedWord (const JavaString& usedWord);
	void ClearUsedWords ();

	void SetCrosswordName (const std::string& crosswordName);
	void SetWidth (int width);
	void SetHeight (int height);
	void SetQuestionFieldIndex (int questionFieldIndex);
	void SetSolutionFieldIndex (int solutionFieldIndex);
};


#endif //ANKI_CROSSWORD_GENERATORINFO_HPP
