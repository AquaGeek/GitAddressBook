//
//  L42AppDelegate.m
//  GitAddressBook
//
//  Copyright (c) 2013 Lab 42 Development. All rights reserved.
//

#import "L42AppDelegate.h"

#import <AddressBook/AddressBook.h>

@implementation L42AppDelegate
{
@private
    ABAddressBook *_addressBook;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Listen for changes to the address book
    _addressBook = [ABAddressBook sharedAddressBook];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addressBookChanged:)
                                                 name:kABDatabaseChangedExternallyNotification
                                               object:nil];
}

- (void)addressBookChanged:(NSNotification *)notification
{
    NSLog(@"Address book changed:");
    
    if (notification.userInfo[kABInsertedRecords] == nil &&
        notification.userInfo[kABUpdatedRecords] == nil &&
        notification.userInfo[kABDeletedRecords] == nil)
    {
        NSLog(@"Everything changed.");
    }
    else
    {
        NSArray *insertedRecords = notification.userInfo[kABInsertedRecords];
        NSArray *updatedRecords = notification.userInfo[kABUpdatedRecords];
        NSArray *deletedRecords = notification.userInfo[kABDeletedRecords];
        
        NSLog(@"  Inserted: %@", insertedRecords ?: @"0");
        NSLog(@"  Updated: %@", updatedRecords ?: @"0");
        NSLog(@"  Deleted: %@", deletedRecords ?: @"0");
        
        // Grab all the new and updated records and re-export them as vCards
        for (NSString *identifier in [insertedRecords ?: @[] arrayByAddingObjectsFromArray:updatedRecords])
        {
            // We only care about person records
            if (![[_addressBook recordClassFromUniqueId:identifier] isEqualToString:NSStringFromClass([ABPerson class])])
            {
                continue;
            }
            
            ABPerson *person = (ABPerson *)[_addressBook recordForUniqueId:identifier];
            [self exportPerson:person];
        }
        
        // TODO: Grab all the deleted records and remove them
    }
}

- (void)exportPerson:(ABPerson *)person
{
    NSData *vCardData = [person vCardRepresentation];
    
    // TODO: Figure out a way to use more human-friendly file names
    NSString *fileName = [person.uniqueId stringByReplacingOccurrencesOfString:@":ABPerson" withString:@""];
    NSString *filePath = [[self repositoryPath] stringByAppendingFormat:@"%@.vcard", fileName];
    [vCardData writeToFile:filePath atomically:YES];
}

- (NSString *)repositoryPath
{
    NSString *publicFolderPath = [NSSearchPathForDirectoriesInDomains(NSSharedPublicDirectory, NSUserDomainMask, YES) lastObject];
    return [publicFolderPath stringByAppendingPathComponent:@"test"];
}

@end
