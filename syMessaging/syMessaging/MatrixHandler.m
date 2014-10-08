/*
 Copyright 2014 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MatrixHandler.h"

static MatrixHandler *sharedHandler = nil;

@implementation MatrixHandler

@synthesize homeServerURL, userLogin, userId, accessToken;

+ (id)sharedHandler {
    @synchronized(self) {
        if(sharedHandler == nil)
        {
            sharedHandler = [[super allocWithZone:NULL] init];
        }
    }
    return sharedHandler;
}

-(MatrixHandler *)init
{
    if (self = [super init])
    {
        // Read potential homeserver in shared defaults object
        if (self.homeServerURL)
        {
            self.homeServer = [[MXHomeServer alloc] initWithHomeServer:self.homeServerURL];
        }
    }
    return self;
}

- (void)dealloc
{
    self.homeServer = nil;
}

- (BOOL)isLogged
{
    return (self.accessToken != nil);
}

- (NSString *)homeServerURL
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserver"];
}

- (void)setHomeServerURL:(NSString *)inHomeserver
{
    [[NSUserDefaults standardUserDefaults] setObject:inHomeserver forKey:@"homeserver"];
    self.homeServer = [[MXHomeServer alloc] initWithHomeServer:self.homeServerURL];
}

- (NSString *)userLogin
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userlogin"];
}

- (void)setUserLogin:(NSString *)inUserLogin
{
    [[NSUserDefaults standardUserDefaults] setObject:inUserLogin forKey:@"userlogin"];
}

- (NSString *)userId
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userid"];
}

- (void)setUserId:(NSString *)inUserId
{
    [[NSUserDefaults standardUserDefaults] setObject:inUserId forKey:@"userid"];
}

- (NSString *)accessToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"accesstoken"];
}

- (void)setAccessToken:(NSString *)inAccessToken
{
    [[NSUserDefaults standardUserDefaults] setObject:inAccessToken forKey:@"accesstoken"];
}

@end
