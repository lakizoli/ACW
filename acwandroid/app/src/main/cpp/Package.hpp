//
// Created by Laki Zoltán on 2019-09-05.
//

#ifndef ANKI_CROSSWORD_PACKAGE_HPP
#define ANKI_CROSSWORD_PACKAGE_HPP

#include <JavaObject.h>
#include <JavaContainers.h>
#include <set>

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
	Package GetPack () const;
	void SetPack (const Package& pack);

	int GetDeckID () const;
	void SetDeckID  (int deckID);

	std::string GetName () const;
	void SetName (const std::string& name);
};

class Package : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (Package);

public:
	Package ();

public:
	std::string GetPath () const;
	void SetPath (const std::string& path);

	void SetName (const std::string& name);
	void SetDecks (const JavaArrayList<Deck>& decks);
	void SetState (const GameState& state);
};

class SavedCrossword : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (SavedCrossword);

public:
	SavedCrossword ();

public:
	void SetPath (const std::string& path);
	void SetPackageName (const std::string& packageName);
	void SetName (const std::string& name);
	void SetWidth (int width);
	void SetHeight (int height);
	void SetWords (const JavaHashSet& words);
};

#endif //ANKI_CROSSWORD_PACKAGE_HPP
