
package org.andrewbestbier.salesforcechat;

import java.util.LinkedList;

import androidx.annotation.NonNull;
import androidx.fragment.app.FragmentActivity;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;

import com.salesforce.android.chat.core.ChatConfiguration;
import com.salesforce.android.chat.core.model.AvailabilityState;
import com.salesforce.android.chat.core.model.ChatUserData;
import com.salesforce.android.chat.core.model.ChatEntityField;
import com.salesforce.android.chat.core.model.ChatEntity;
import com.salesforce.android.chat.ui.ChatUI;
import com.salesforce.android.chat.ui.ChatUIClient;
import com.salesforce.android.chat.ui.ChatUIConfiguration;
import com.salesforce.android.service.common.utilities.control.Async;
import com.salesforce.android.chat.core.AgentAvailabilityClient;
import com.salesforce.android.chat.core.ChatCore;


public class RNSalesforceChatModule extends ReactContextBaseJavaModule {

    private static final String TAG = "RNSalesforceChat";

    private final ReactApplicationContext reactContext;

    public RNSalesforceChatModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return TAG;
    }


    private LinkedList<ChatUserData> userDataFields = new LinkedList<>();

    private LinkedList<ChatEntity> chatEntities = new LinkedList<>();

    private ChatConfiguration.Builder chatConfigurationBuilder;

    private ChatConfiguration chatConfiguration;

    private Async<ChatUIClient> AsyncChatUIClient;


    @ReactMethod
    public void configLaunch(
            ReadableMap chatSettings,
            ReadableMap userSettings
    ) {
        userDataFields.clear();
        chatEntities.clear();

        String salesForceId = userSettings.getString("salesforceId");
        boolean inClubConcierge = userSettings.getBoolean("inClubConcierge");

        ChatUserData idData = new ChatUserData("Id", salesForceId, true);
        ChatUserData attentionData = new ChatUserData("inClubConcierge", inClubConcierge, true, "InClubConcierge__c");

        userDataFields.add(idData);
        userDataFields.add(attentionData);

        ChatEntityField idField = new ChatEntityField.Builder()
                .doCreate(false)
                .doFind(true)
                .isExactMatch(true)
                .build("Id", idData);

        ChatEntity contactEntity = new ChatEntity.Builder()
                .showOnCreate(true)
                .linkToTranscriptField("Contact")
                .linkToAnotherSalesforceObject("Contact", "ContactId")
                .addChatEntityField(idField)
                .build("Contact");

        chatEntities.add(contactEntity);
    }

    @ReactMethod
    public void configChat(
            String ORG_ID,
            String DEPLOYMENT_ID,
            String BUTTON_ID,
            String LIVE_AGENT_POD,
            String VISITOR_NAME
    ) {
        chatConfigurationBuilder = new ChatConfiguration.Builder(
                ORG_ID,
                BUTTON_ID,
                DEPLOYMENT_ID,
                LIVE_AGENT_POD
        );

        chatConfigurationBuilder
                .chatUserData(userDataFields)
                .chatEntities(chatEntities)
                .visitorName(VISITOR_NAME);

        chatConfiguration = chatConfigurationBuilder.build();
    }

    @ReactMethod
    public void isAgentAvailable(final Callback successCallback) {

        // Create an agent availability client
        AgentAvailabilityClient client = ChatCore.configureAgentAvailability(chatConfiguration);

        client.check().onResult(new Async.ResultHandler<AvailabilityState>() {
            @Override
            public void handleResult(Async<?> async, @NonNull AvailabilityState state) {

                switch (state.getStatus()) {
                    case AgentsAvailable: {
                        successCallback.invoke(false, true);
                        break;
                    }
                    case NoAgentsAvailable: {
                        successCallback.invoke(false, false);
                        break;
                    }
                    case Unknown: {
                        successCallback.invoke(false, false);
                        break;
                    }
                }
                ;
            }
        });
    };

    @ReactMethod
    public void finish(final Callback successCallback) {
        if (this.AsyncChatUIClient != null) {
            this.AsyncChatUIClient.onResult(new Async.ResultHandler<ChatUIClient>() {
                @Override public void handleResult (Async<?> operation, @NonNull ChatUIClient chatUIClient) {
                    chatUIClient.endChatSession();
                    successCallback.invoke(false, true);
                }
            });
            return;
        }
        successCallback.invoke(false, false);
    };

    @ReactMethod
    public void launch(final Callback successCallback) {

        AgentAvailabilityClient client = ChatCore.configureAgentAvailability(chatConfiguration);

        client.check().onResult(new Async.ResultHandler<AvailabilityState>() {
            @Override
            public void handleResult(Async<?> async, @NonNull AvailabilityState state) {

                switch (state.getStatus()) {
                    case AgentsAvailable: {
                        startChat();
                        break;
                    }
                    case NoAgentsAvailable: {
                        successCallback.invoke();
                        break;
                    }
                    case Unknown: {
                        break;
                    }
                }
                ;
            }
        });
    };

    private void startChat() {
        ChatUIConfiguration chatUiConfiguration = new ChatUIConfiguration.Builder()
            .chatConfiguration(chatConfiguration)
            .disablePreChatView(true)
            .defaultToMinimized(false)
            .build();

        this.AsyncChatUIClient = ChatUI
                .configure(chatUiConfiguration)
                .createClient(getReactApplicationContext());

        this.AsyncChatUIClient.onResult(new Async.ResultHandler<ChatUIClient>() {
            @Override public void handleResult (Async<?> operation, @NonNull ChatUIClient chatUIClient) {
                chatUIClient.startChatSession(getCurrentActivity());
            }
        });
    };

}
