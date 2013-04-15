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
    
    [self dumpFullAddressBook];
    
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
        
        // Re-export all records
        [self dumpFullAddressBook];
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
        
        // Grab all the deleted records and remove them
        for (NSString *identifier in deletedRecords)
        {
            NSString *fileName = [self fileNameFromUniqueID:identifier];
            [self deleteFileWithName:fileName];
        }
    }
}

- (void)dumpFullAddressBook
{
    // Keep track of which records are still around
    NSMutableSet *recordsToDelete = [NSMutableSet set];
    
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self repositoryPath] error:NULL])
    {
        if ([file hasSuffix:@".vcard"])
        {
            [recordsToDelete addObject:file];
        }
    }
    
    // Export all the person records
    for (ABPerson *person in [_addressBook people])
    {
        [self exportPerson:person];
        [recordsToDelete removeObject:[self fileNameFromUniqueID:person.uniqueId]];
    }
    
    // Delete any removed records
    for (NSString *fileName in recordsToDelete)
    {
        [self deleteFileWithName:fileName];
    }
}

- (NSString *)fileNameFromUniqueID:(NSString *)uniqueID
{
    return [[uniqueID stringByReplacingOccurrencesOfString:@":ABPerson" withString:@""]
            stringByAppendingPathExtension:@"vcard"];
}

- (void)exportPerson:(ABPerson *)person
{
    NSData *vCardData = [person vCardRepresentation];
    
    // TODO: Figure out a way to use more human-friendly file names
    NSString *fileName = [self fileNameFromUniqueID:person.uniqueId];
    NSString *filePath = [[self repositoryPath] stringByAppendingPathComponent:fileName];
    [vCardData writeToFile:filePath atomically:YES];
}

- (void)deleteFileWithName:(NSString *)fileName
{
    NSLog(@"Deleting %@", fileName);
    NSString *filePath = [[self repositoryPath] stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
}

- (NSString *)repositoryPath
{
    NSString *publicFolderPath = [NSSearchPathForDirectoriesInDomains(NSSharedPublicDirectory, NSUserDomainMask, YES) lastObject];
    return [publicFolderPath stringByAppendingPathComponent:@"test"];
}

@end
