
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
import com.salesforce.android.chat.core.model.PreChatField;
import com.salesforce.android.chat.core.model.PreChatEntityField;
import com.salesforce.android.chat.core.model.PreChatEntity;
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


    private LinkedList<PreChatField> preChatFields = new LinkedList<>();

    private LinkedList<PreChatEntity> preChatEntities = new LinkedList<>();

    private ChatConfiguration chatConfiguration;


    @ReactMethod
    public void configLaunch(ReadableMap chatSettings, ReadableMap userSettings) {

        preChatFields.clear();
        preChatEntities.clear();

        // Some required fields (Hidden)
        PreChatField id = new PreChatField.Builder().hidden(true)
                .value(userSettings.getString("salesforceId")).build("Id", "Id", PreChatField.STRING);

        preChatFields.add(id);

        // Create an entity field builder for Contact fields
        PreChatEntityField.Builder contactEntityBuilder = new PreChatEntityField.Builder()
                .doCreate(false).doFind(true).isExactMatch(true);

        // Create the Contact entity
        PreChatEntity contactEntity = new PreChatEntity.Builder()
                .saveToTranscript("Contact")
                .showOnCreate(true)
                .linkToEntityName("Contact")
                .linkToEntityField("ContactId")
                .addPreChatEntityField(contactEntityBuilder.build("Id", "Id"))
                .build("Contact");

        // Add the entities to the list
        preChatEntities.add(contactEntity);
    }

    @ReactMethod
    public void configChat(String ORG_ID, String DEPLOYMENT_ID, String BUTTON_ID, String LIVE_AGENT_POD, String VISITOR_NAME) {
        chatConfiguration = new ChatConfiguration.Builder(ORG_ID, BUTTON_ID, DEPLOYMENT_ID, LIVE_AGENT_POD)
                .preChatFields(preChatFields)
                .preChatEntities(preChatEntities)
                .visitorName(VISITOR_NAME)
                .build();
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
    public void launch(final Callback successCallback) {

        // Create an agent availability client
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
      ChatUIConfiguration chatUiConfiguration =
        new ChatUIConfiguration.Builder()
          .chatConfiguration(chatConfiguration)
          .disablePreChatView(true)
          .build();

        ChatUI.configure(chatUiConfiguration)
                .createClient(reactContext)
                .onResult(new Async.ResultHandler<ChatUIClient>() {

                        @Override public void handleResult (Async<?> operation,
                                                        @NonNull ChatUIClient chatUIClient) {
                        chatUIClient.startChatSession((FragmentActivity) getCurrentActivity());
                        }
                });
    };

}
