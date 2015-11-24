//
//  Constant.h
//  Cheddar for iOS
//
//  Created by Mac on 7/20/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#ifndef Cheddar_for_iOS_Constant_h
#define Cheddar_for_iOS_Constant_h
#define METEOR_DDP_URL_FORMAT @"ws://%@/websocket"
#define     UseStaticGoogleClient       NO


#define METEORCOLLECTION_USERS           @"users"                // Existing
#define METEORCOLLECTION_PEOPLE          @"contacts"             // Existing
#define METEORCOLLECTION_KEY             @"key_notes"            // Not Existing
#define METEORCOLLECTION_KNOTES          @"knotes"               // Existing
#define METEORCOLLECTION_MESSAGES        @"messages"             // Existing
#define METEORCOLLECTION_ACCOUNTS        @"user_accounts"        // Existing
#define METEORCOLLECTION_TOPICS          @"topics"               // Existing
#define METEORCOLLECTION_FILES           @"files"                // Existing
#define METEORCOLLECTION_NOTIFICATIONS   @"notifications"        // Existing
#define METEORCOLLECTION_ACTIVITES       @"activities"           // Existing
#define METEORCOLLECTION_HOTKNOTES       @"hotKnotes"
#define METEORCOLLECTION_USERPRIVATEDATA @"userPrivateData"
#define METEORCOLLECTION_MUTEKNOTES      @"muteKnotes"
#define METEORCOLLECTION_ARCHIVEDTOPICS  @"archivedTopics"       // Existing

#define METEORCOLLECTION_KNOTE_TOPIC            @"topic"
#define METEORCOLLECTION_KNOTE_DATES            @"date_events"
#define METEORCOLLECTION_KNOTE_PINNED           @"pinnedKnotesForTopic"
#define METEORCOLLECTION_KNOTE_ARCHIVED         @"archivedKnotesForTopic"
#define METEORCOLLECTION_KNOTE_REST             @"allRestKnotesByTopicId"

#define kTNUserIDKey @"CDKUserID"
#define kTNUserEmail @"TNUser_Email"
#define kTNUserName @"CDKUser_Name"
#define kTNUserSessionToken @"CDKUser_Session_Token"
#define kCDKKeychainServiceName = @"Tasknote"


#define kDefaultPadName @"Tasknotes"


//Update Types
#define kCDKUpdatedItemTypeUpdated  1 //updated
#define kCDKUpdatedItemTypeAdded  2 //added

#define kCDKUpdatedItemOfflineIDPrefix  @"OTN"

#define kCDKUpdateTask  1
#define kCDKUpdateList  2
#define kCDKUpdateTag   3




#define KnotebleShowPopUpMessage            @"KnotebleShowPopUpMessage"
#define kNeedChangeMongoDbServer            @"kNeedChangeMongoDbServer"
#define kNeedGoBackToLoginView              @"kNeedGoBackToLoginView"
#define kTaskChangedNotification            @"TaskChangedNotification"
#define kDoUpdateNotification               @"DoUpdateNotification"
#define kDidSignOutNotification             @"DidSignOutNotification"
#define kSafeToUpdateUINotification               @"SafeToUpdateUINotification"

#define kNeedChangeApplicationHost          @"kNeedChangeApplicationHost"


#define kDateFormat @"MMM dd yyyy,hh:mm aa"
#define kDateFormat1 @"MMM dd yyyy, hh:mm:ss aa"
#define kDateFormat2 @"EEE MMM dd hh:mm:ss aa yyy"

#endif
