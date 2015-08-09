//
//  NewsCoreDataStorageObject.h
//  
//
//  Created by D404 on 15/7/24.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NewsCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * messageDigest;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) id url;

@end
