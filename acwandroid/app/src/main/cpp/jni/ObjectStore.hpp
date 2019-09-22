//
// Created by Laki Zoltán on 2019-09-03.
//

#ifndef ANKI_CROSSWORD_OBJECTSTORE_HPP
#define ANKI_CROSSWORD_OBJECTSTORE_HPP

#include <unordered_map>
#include <memory>

template<class T>
class ObjectStore {
	int32_t _nextID = 1;
	std::unordered_map<int32_t, std::shared_ptr<T>> _store;

	ObjectStore () = default;

public:
	static ObjectStore& Get () {
		static ObjectStore<T> inst;
		return inst;
	}

	std::shared_ptr<T> Get (int32_t objID) const {
		auto it = _store.find (objID);
		if (it != _store.end ()) {
			return it->second;
		}
		return nullptr;
	}

	int32_t Add (std::shared_ptr<T> obj) {
		int32_t objID = _nextID++;
		_store.emplace (objID, obj);
		return objID;
	}

	void Remove (int32_t objID) {
		_store.erase (objID);
	}
};

#endif //ANKI_CROSSWORD_OBJECTSTORE_HPP
