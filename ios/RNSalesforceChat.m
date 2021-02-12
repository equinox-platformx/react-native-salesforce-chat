#import <React/RCTConvert.h>
#import "RNSalesforceChat.h"

@implementation RNSalesforceChat

NSArray *prechatFields;
NSArray *prechatEntities;
SCSChatConfiguration *chatConfiguration;
SCAppearanceConfiguration *appearance;

RCT_EXPORT_MODULE();

//MARK: Private Methods
-(NSArray *)preChatObjects:(NSDictionary *) chatSettings userSettings: (NSDictionary *)userSettings {
    // Prechat objects

    SCSPrechatObject* inClubConciergeData = [[SCSPrechatObject alloc] 
                                    initWithLabel:@"InClubConcierge__c"
                                    value: userSettings[@"inClubConcierge"]];
    inClubConciergeData.transcriptFields = @[@"InClubConcierge__c"];

    SCSPrechatObject* facilityIdData = [[SCSPrechatObject alloc] 
                                    initWithLabel:@"Checkin_ClubID__c"
                                    value: userSettings[@"facilityId"]];
    facilityIdData.transcriptFields = @[@"Checkin_ClubID__c"];

    NSArray * prechatObjects = @[
        [[SCSPrechatObject alloc] initWithLabel:@"Id" value: userSettings[@"salesforceId"]],
        inClubConciergeData,
        facilityIdData,
    ];

    return prechatObjects;
}

-(SCSPrechatEntity *) contactEntity {
    SCSPrechatEntityField* idEntityField = [[SCSPrechatEntityField alloc] initWithFieldName:@"Id" label:@"Id"];
    idEntityField.doCreate = NO;
    idEntityField.doFind = YES;
    idEntityField.isExactMatch = YES;

    // Create an entity mapping for a Contact record type
    // (All this entity stuff is only required if you
    // want to map transcript fields to other Salesforce records.)
    SCSPrechatEntity* contactEntity = [[SCSPrechatEntity alloc] initWithEntityName:@"Contact"];
    contactEntity.saveToTranscript = @"Contact";
    contactEntity.showOnCreate = YES;
    contactEntity.linkToEntityName = @"Case";
    contactEntity.linkToEntityField = @"ContactId";
    [contactEntity.entityFieldsMaps addObject:idEntityField];

    return contactEntity;
}

//MARK: Public Methods
RCT_EXPORT_METHOD(isAgentAvailable:(RCTResponseSenderBlock)callback)
{
    [[SCServiceCloud sharedInstance].chatCore determineAvailabilityWithConfiguration:chatConfiguration completion:^(NSError *error, BOOL available, NSTimeInterval estimatedWaitTime) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != nil || !available) {
                callback(@[[NSNull null], @NO]);
                return;
            }

            callback(@[[NSNull null], @YES]);
            return;
        });
    }];
}

RCT_EXPORT_METHOD(configLaunch:(NSDictionary *)chatSettings userSettings:(NSDictionary *)userSettings)
{
    prechatFields = [self preChatObjects:chatSettings userSettings:userSettings];
    prechatEntities = [[NSArray new] arrayByAddingObjectsFromArray:@[[self contactEntity]]];
    appearance = [SCAppearanceConfiguration new];

    [appearance setColor:[UIColor colorWithRed: 0/255 green: 0/255 blue: 0/255 alpha: 1.0] forName:SCSAppearanceColorTokenBrandPrimary];
    [appearance setColor:[UIColor colorWithRed: 0/255 green: 0/255 blue: 0/255 alpha: 1.0] forName:SCSAppearanceColorTokenBrandSecondary];

    UIImage *agentImage = [RCTConvert UIImage:chatSettings[@"chatAgentAvatar"]];
    [appearance setImage:agentImage compatibleWithTraitCollection:nil forName:SCSAppearanceImageTokenChatAgentAvatar];

    UIImage *botImage = [RCTConvert UIImage:chatSettings[@"chatAgentAvatar"]];
    [appearance setImage:botImage compatibleWithTraitCollection:nil forName:SCSAppearanceImageTokenChatBotAvatar];
}

RCT_EXPORT_METHOD(configChat:(NSString *)orgId 
                  deploymentId:(NSString *)deploymentId 
                  buttonId:(NSString *)buttonId 
                  liveAgentPod:(NSString *)liveAgentPod 
                  suppliedName:(NSString *)suppliedName)
{
    chatConfiguration =
    [[SCSChatConfiguration alloc] initWithLiveAgentPod:liveAgentPod
                                                 orgId:orgId
                                          deploymentId:deploymentId
                                              buttonId:buttonId];

    chatConfiguration.visitorName = suppliedName;
    chatConfiguration.defaultToMinimized = NO;

    // Update config object with the pre-chat fields
    chatConfiguration.prechatFields = [[NSArray new] arrayByAddingObjectsFromArray:prechatFields];

    // Update config object with the entity mappings
    chatConfiguration.prechatEntities = [[NSArray new] arrayByAddingObjectsFromArray:prechatEntities];
}

RCT_EXPORT_METHOD(launch:(RCTResponseSenderBlock)callback)
{
    // NSString *imagePath = @"https://eqx--uat--c.cs11.visual.force.com/resource/1589563476000/embedded_chat_agent_logo";

    // Save configuration instance
    [SCServiceCloud sharedInstance].appearanceConfiguration = appearance;

    [[SCServiceCloud sharedInstance].chatCore determineAvailabilityWithConfiguration:chatConfiguration completion:^(NSError *error, BOOL available, NSTimeInterval estimatedWaitTime) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != nil) {
                // Handle it.
                return;
            }

            // Uncomment `available` if you wish to see Chat bubble.
            if (available) {
                [[SCServiceCloud sharedInstance].chatUI showChatWithConfiguration:chatConfiguration showPrechat:FALSE];
                return;
            }

            callback(@[[NSNull null]]);
            
        });
    }];
}

RCT_EXPORT_METHOD(finish:(RCTResponseSenderBlock)callback)
{
    [[SCServiceCloud sharedInstance].chatCore stopSessionWithCompletion:^(NSError *error, SCSChat *chat) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != nil) {
                callback(@[[NSNull null], @NO]);
                return;
            }

            [[SCServiceCloud sharedInstance].chatUI dismissChat];
            callback(@[[NSNull null], @YES]);
            return;
        });
    }];
}

@end
