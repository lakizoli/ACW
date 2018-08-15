//
//  QueryWords.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef QueryWords_hpp
#define QueryWords_hpp

struct QueryWords : public std::enable_shared_from_this<QueryWords> {
	virtual uint32_t GetCount () const = 0;
	virtual std::string GetWord (uint32_t idx) const = 0;
	virtual void Clear () = 0;
};

#endif /* QueryWords_hpp */
