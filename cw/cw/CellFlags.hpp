//
//  CellFlags.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef CellFlags_hpp
#define CellFlags_hpp

enum class CellFlags : uint32_t {
	Empty =				0x0000,
	
	Value =				0x0001,
	Question =			0x0002,
	HasSomeValue =		0x000F, ///< Test for value flags only!
	
	LeftSeparator =		0x0010,
	RightSeparator =	0x0020,
	TopSeparator =		0x0040,
	BottomSeparator =	0x0080,
	
	StartCell =			0x0100, //Flag to sign start cells
};

inline CellFlags operator | (CellFlags lhs, CellFlags rhs) {
	using T = std::underlying_type_t<CellFlags>;
	return (CellFlags) (static_cast<T> (lhs) | static_cast<T> (rhs));
}

inline CellFlags& operator |= (CellFlags& lhs, CellFlags rhs) {
	using T = std::underlying_type_t<CellFlags>;
	lhs = (CellFlags) (static_cast<T> (lhs) | static_cast<T> (rhs));
	return lhs;
}

inline CellFlags operator & (CellFlags lhs, CellFlags rhs) {
	using T = std::underlying_type_t<CellFlags>;
	return (CellFlags) (static_cast<T> (lhs) & static_cast<T> (rhs));
}

#endif /* CellFlags_hpp */
