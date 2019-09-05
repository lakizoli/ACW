//
// Created by Laki Zoltán on 2019-09-05.
//

#ifndef ANKI_CROSSWORD_PACKAGE_HPP
#define ANKI_CROSSWORD_PACKAGE_HPP

#include <JavaObject.h>
#include <JavaContainers.h>

class Package;

class GameState : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (GameState);

public:
	GameState ();

public:
	void LoadFrom (const std::string& path) const;
};

class Deck : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (Deck);

public:
	Deck ();

public:
	void SetPack (const Package& pack);
	void SetDeckID  (int deckID);
	void SetName (const std::string& name);
};

class Package : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (Package);

public:
	Package ();

public:
	void SetPath (const std::string& path);
	void SetName (const std::string& name);
	void SetDecks (const JavaArrayList<Deck>& decks);
	void SetState (const GameState& state);
};


#endif //ANKI_CROSSWORD_PACKAGE_HPP
