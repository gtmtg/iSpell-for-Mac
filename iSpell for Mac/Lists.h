//
//  Lists.h
//  iSpell for Mac
//
//  Created by Mihir Garimella on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Lists : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * words;

@end
