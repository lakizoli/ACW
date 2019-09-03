//
// Created by Laki Zoltán on 2019-09-03.
//

#ifndef ANKI_CROSSWORD_OBJECTSTORE_HPP
#define ANKI_CROSSWORD_OBJECTSTORE_HPP

#include <unordered_map>
#include <memory>

template<class T>
class ObjectStore {
	int32_t nextID = 1;
	std::unordered_map<int32_t, std::shared_ptr<T>> _store;

	ObjectStore () = default;

public:
	static ObjectStore& Get () {
		static ObjectStore<T> inst;
		return inst;
	}

	int32_t Add (std::shared_ptr<T> obj) {
		int32_t objID = nextID++;
		_store.emplace (nextID, obj);
		return objID;
	}

	void Remove (int32_t objID) {
		_store.erase (objID);
	}
};

#endif //ANKI_CROSSWORD_OBJECTSTORE_HPP
