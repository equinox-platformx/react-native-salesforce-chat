#import "RNSalesforceChat.h"

@implementation RNSalesforceChat

NSArray *prechatFields;
NSArray *prechatEntities;
SCSChatConfiguration *chatConfiguration;

RCT_EXPORT_MODULE();

//MARK: Private Methods
-(NSArray *)preChatObjects:(NSDictionary *) chatSettings userSettings: (NSDictionary *)userSettings {

    // Prechat objects
    NSArray * prechatObjects = @[
        [[SCSPrechatObject alloc] initWithLabel:@"Id" value: userSettings[@"salesforceId"]],
    ];

    return prechatObjects;
}

+(NSArray *)preChatEntityFields {

    // Prechat entities
    NSArray *entityFields = @[
         [[SCSPrechatEntityField alloc] initWithFieldName:@"Subject" label:@"Subject"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"Origin" label:@"Origin"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"CurrencyISOCode" label:@"CurrencyIsoCode"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"Status" label:@"Status"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"ContactType__c" label:@"ContactType__c"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"Locale__c" label:@"Locale__c"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"SuppliedName" label:@"SuppliedName"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"SuppliedEmail" label:@"SuppliedEmail"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"Email" label:@"Email"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"CanTroubleshootingbedone__c" label:@"CanTroubleshootingbedone__c"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"ProductV2__c" label:@"ProductV2__c"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"EquipmentV2__c" label:@"EquipmentV2__c"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"AdditionalInformation__c" label:@"AdditionalInformation__c"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"GenericBotMessage__c" label:@"GenericBotMessage__c"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"Version__c" label:@"Version__c"],
         [[SCSPrechatEntityField alloc] initWithFieldName:@"PointOfCustomerJourney__c" label:@"PointOfCustomerJourney__c"]
    ];

    for (SCSPrechatEntityField* entityField in entityFields) {
        entityField.doCreate = YES;
    }

    return entityFields;
}

-(SCSPrechatEntity *) contactEntity {
    SCSPrechatEntityField* emailEntityField = [[SCSPrechatEntityField alloc] initWithFieldName:@"Id" label:@"Id"];
    emailEntityField.doCreate = NO;
    emailEntityField.doFind = YES;
    emailEntityField.isExactMatch = YES;

    // Create an entity mapping for a Contact record type
    // (All this entity stuff is only required if you
    // want to map transcript fields to other Salesforce records.)
    SCSPrechatEntity* contactEntity = [[SCSPrechatEntity alloc] initWithEntityName:@"Contact"];
    contactEntity.saveToTranscript = @"Contact";
    contactEntity.showOnCreate = YES;
    contactEntity.linkToEntityName = @"Case";
    contactEntity.linkToEntityField = @"ContactId";
    [contactEntity.entityFieldsMaps addObject:emailEntityField];

    return contactEntity;
}

-(SCSPrechatEntity *) caseEntity {

    // Create an entity mapping for a Case record type
    SCSPrechatEntity* caseEntity = [[SCSPrechatEntity alloc] initWithEntityName:@"Case"];
    caseEntity.saveToTranscript = @"Case";
    caseEntity.showOnCreate = YES;
    [caseEntity.entityFieldsMaps addObjectsFromArray:[RNSalesforceChat preChatEntityFields]];

    return caseEntity;
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
    // Create appearance configuration instance
    SCAppearanceConfiguration *appearance = [SCAppearanceConfiguration new];

    // NSString *imagePath = @"https://eqx--uat--c.cs11.visual.force.com/resource/1589563476000/embedded_chat_agent_logo";
    // NSURL *url = [NSURL URLWithString:[imagePath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    // UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:url]];

    // NSString *forNameValue = @"chatAgentAvatar";
    // // Sets agent image
    // [appearance setImage:image compatibleWithTraitCollection:nil forName:forNameValue];
    // Customize color tokens
    [appearance setColor:[UIColor colorWithRed: 0/255 green: 0/255 blue: 0/255 alpha: 1.0] forName:SCSAppearanceColorTokenBrandPrimary];
    [appearance setColor:[UIColor colorWithRed: 0/255 green: 0/255 blue: 0/255 alpha: 1.0] forName:SCSAppearanceColorTokenBrandSecondary];

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

@end
