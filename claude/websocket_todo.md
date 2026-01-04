# OpenBD WebSocket Implementation Plan

## Executive Summary

This plan outlines the implementation of WebSocket support in OpenBD to match Adobe ColdFusion's WebSocket capabilities. The implementation will provide channel-based pub/sub messaging with security controls through a channel listener CFC pattern.

**Target Feature Parity with Adobe CF:**
- `<cfwebsocket>` tag for client-side integration
- Channel-based messaging with subscriptions
- Channel Listener CFCs with 5 lifecycle hooks
- Server-side CFML functions (wsPublish, wsGetSubscribers, etc.)
- JavaScript client API (subscribe, publish, openConnection, etc.)
- Security controls (allowSubscribe, allowPublish, message filtering)

**Key Architectural Differences:**
- Adobe CF: Built-in WebSocket server on dedicated ports (8575/8577)
- OpenBD: Will use embedded WebSocket server (Netty-based, leveraging existing Netty 4.x JARs)
- Adobe CF: Automatic channel registration via XML config
- OpenBD: Will use CFML-based channel registration with server.websocket API

---

## Part 1: Architecture Overview

### Adobe ColdFusion WebSocket Architecture (Reference)

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Browser                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  <cfwebsocket name="ws" onMessage="handleMsg"         │  │
│  │               subscribeTo="chatChannel">              │  │
│  │                                                       │  │
│  │  JavaScript API:                                      │  │
│  │  - ws.subscribe({channelName:"...", subscriberInfo})  │  │
│  │  - ws.publish(channelName, message)                   │  │
│  │  - ws.openConnection()                                │  │
│  │  - ws.closeConnection()                               │  │
│  └───────────────────────────────────────────────────────┘  │
└───────────────────────┬─────────────────────────────────────┘
                        │ WebSocket (ws://host:8575/cfws)
                        │
┌───────────────────────▼─────────────────────────────────────┐
│               Adobe CF WebSocket Server                     │
│                    (Ports 8575/8577)                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          Channel Router & Manager                     │  │
│  │  - Message routing to subscribers                     │  │
│  │  - Subscription management                            │  │
│  │  - Channel lifecycle                                  │  │
│  └────────┬─────────────────────────┬────────────────────┘  │
│           │                         │                       │
│  ┌────────▼────────┐       ┌────────▼────────┐              │
│  │ chatChannel     │       │ notifyChannel   │              │
│  │ Listener CFC    │       │ Listener CFC    │              │
│  └─────────────────┘       └─────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

**Channel Listener Lifecycle Hooks:**
1. `allowSubscribe(subscriberInfo)` - Authorization check before subscription
2. `allowPublish(publisherInfo)` - Authorization check before publishing
3. `beforePublish(publisherInfo, message)` - Message transformation/validation
4. `canSendMessage(subscriberInfo, message)` - Per-subscriber filtering
5. `beforeSendMessage(subscriberInfo, message)` - Per-subscriber transformation

### Proposed OpenBD WebSocket Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Browser                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  <cfwebsocket name="ws" onMessage="handleMsg"         │  │
│  │               subscribeTo="chatChannel">              │  │
│  │                                                       │  │
│  │  JavaScript API (identical to Adobe CF):              │  │
│  │  - ws.subscribe({channelName:"...", subscriberInfo})  │  │
│  │  - ws.publish(channelName, message)                   │  │
│  │  - ws.openConnection(), closeConnection()             │  │
│  └───────────────────────────────────────────────────────┘  │
└───────────────────────┬─────────────────────────────────────┘
                        │ WebSocket (ws://host:8580/openbd/ws)
                        │
┌───────────────────────▼─────────────────────────────────────┐
│              OpenBD WebSocket Server (New)                  │
│                (Netty-based, port 8580)                     │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  WebSocketChannelManager (New)                        │  │
│  │  - Channel registration & lifecycle                   │  │
│  │  - Subscription management                            │  │
│  │  - Message routing to subscribers                     │  │
│  │  - Channel Listener CFC invocation                    │  │
│  └────────┬─────────────────────────┬────────────────────┘  │
│           │                         │                       │
│  ┌────────▼────────┐       ┌────────▼────────┐              │
│  │ chatListener    │       │ notifyListener  │              │
│  │ CFC (extends    │       │ CFC (extends    │              │
│  │ WebSocket       │       │ WebSocket       │              │
│  │ ChannelListener)│       │ ChannelListener)│              │
│  └─────────────────┘       └─────────────────┘              │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Integration with cfEngine                            │  │
│  │  - Uses existing cfSession for auth context           │  │
│  │  - Leverages cfCOMPONENT for Channel Listener CFCs    │  │
│  │  - Uses existing request context infrastructure       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 2: Component Breakdown

### 2.1 WebSocket Server Infrastructure

**Technology Choice: Netty WebSocket (Already Available)**

OpenBD already has Netty 4.1.15 JARs in `webapp/WEB-INF/lib/`:
- `netty-codec-4.1.15.Final.jar`
- `netty-handler-4.1.15.Final.jar`
- `netty-transport-4.1.15.Final.jar`
- `netty-buffer-4.1.15.Final.jar`
- `netty-common-4.1.15.Final.jar`

**New Files to Create:**

#### `src/com/naryx/tagfusion/cfm/websocket/WebSocketServer.java`
- Netty-based WebSocket server
- Listens on configurable port (default 8580)
- Handles WebSocket handshake and frame decoding
- Routes messages to WebSocketChannelManager
- Manages connection lifecycle
- Singleton pattern (started by cfEngine on initialization)

**Key Responsibilities:**
```java
public class WebSocketServer {
    private static WebSocketServer instance;
    private ServerBootstrap bootstrap;
    private Channel serverChannel;
    private int port;

    public static WebSocketServer getInstance() { ... }
    public void start(int port) throws Exception { ... }
    public void stop() { ... }
    public void broadcastToChannel(String channelName, String message) { ... }
}
```

#### `src/com/naryx/tagfusion/cfm/websocket/WebSocketChannelManager.java`
- Central registry of channels and subscriptions
- Manages channel lifecycle (create, destroy)
- Routes messages to appropriate subscribers
- Invokes Channel Listener CFC lifecycle methods
- Thread-safe subscription management

**Key Responsibilities:**
```java
public class WebSocketChannelManager {
    private static WebSocketChannelManager instance;
    private Map<String, WebSocketChannel> channels; // channelName -> channel
    private Map<String, cfCOMPONENT> channelListeners; // channelName -> CFC instance

    public void registerChannel(String channelName, String listenerCFCPath) { ... }
    public void unregisterChannel(String channelName) { ... }
    public boolean subscribe(String channelName, WebSocketConnection conn, cfStructData subscriberInfo) { ... }
    public void unsubscribe(String channelName, WebSocketConnection conn) { ... }
    public void publish(String channelName, cfData message, cfStructData publisherInfo) { ... }
    public cfArrayData getSubscribers(String channelName) { ... }
}
```

#### `src/com/naryx/tagfusion/cfm/websocket/WebSocketChannel.java`
- Represents a single channel
- Maintains list of subscribed connections
- Delegates to Channel Listener CFC for permission checks
- Filters and transforms messages per subscriber

**Key Responsibilities:**
```java
public class WebSocketChannel {
    private String channelName;
    private cfCOMPONENT listenerCFC;
    private Set<WebSocketConnection> subscribers;

    public boolean allowSubscribe(cfStructData subscriberInfo) { ... }
    public boolean allowPublish(cfStructData publisherInfo) { ... }
    public cfData beforePublish(cfStructData publisherInfo, cfData message) { ... }
    public void publish(cfData message, cfStructData publisherInfo) { ... }
    public List<WebSocketConnection> getSubscribers() { ... }
}
```

#### `src/com/naryx/tagfusion/cfm/websocket/WebSocketConnection.java`
- Represents a single WebSocket connection from client
- Tracks subscribed channels
- Maintains subscriber info (session ID, custom metadata)
- Sends messages to client

**Key Responsibilities:**
```java
public class WebSocketConnection {
    private ChannelHandlerContext nettyContext;
    private String connectionId; // UUID
    private cfSession session; // Associated cfSession
    private Set<String> subscribedChannels;
    private cfStructData subscriberInfo; // Custom metadata from client

    public void sendMessage(cfData message) { ... }
    public void subscribe(String channelName, cfStructData info) { ... }
    public void unsubscribe(String channelName) { ... }
    public void close() { ... }
}
```

#### `src/com/naryx/tagfusion/cfm/websocket/WebSocketChannelHandler.java`
- Netty ChannelInboundHandlerAdapter
- Handles WebSocket frame events
- Decodes JSON messages from client
- Routes to WebSocketChannelManager

**Message Protocol (JSON-based, compatible with Adobe CF):**
```javascript
// Client -> Server
{
    "type": "subscribe",
    "channelName": "chatChannel",
    "subscriberInfo": { "userId": 123, "room": "general" }
}

{
    "type": "publish",
    "channelName": "chatChannel",
    "message": { "text": "Hello", "from": "user123" }
}

{
    "type": "unsubscribe",
    "channelName": "chatChannel"
}

// Server -> Client
{
    "type": "message",
    "channelName": "chatChannel",
    "message": { "text": "Hello", "from": "user123" }
}

{
    "type": "error",
    "message": "Subscription not allowed"
}

{
    "type": "subscribed",
    "channelName": "chatChannel"
}
```

### 2.2 Channel Listener CFC Base Class

#### `src/com/naryx/tagfusion/cfm/websocket/ChannelListenerBase.java`
- Java class that Channel Listener CFCs will extend (via mapping)
- Provides default implementations of 5 lifecycle methods
- Returns permissive defaults (true for allow methods, unchanged for transform methods)

**Alternative: Pure CFML Base Component**
Create `webapp/OPENBD/websocket/ChannelListener.cfc`:
```cfml
<cfcomponent displayname="ChannelListener" hint="Base class for WebSocket channel listeners">

    <cffunction name="allowSubscribe" returntype="boolean" access="public">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <cfreturn true>
    </cffunction>

    <cffunction name="allowPublish" returntype="boolean" access="public">
        <cfargument name="publisherInfo" type="struct" required="true">
        <cfreturn true>
    </cffunction>

    <cffunction name="beforePublish" returntype="any" access="public">
        <cfargument name="publisherInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">
        <cfreturn arguments.message>
    </cffunction>

    <cffunction name="canSendMessage" returntype="boolean" access="public">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">
        <cfreturn true>
    </cffunction>

    <cffunction name="beforeSendMessage" returntype="any" access="public">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">
        <cfreturn arguments.message>
    </cffunction>

</cfcomponent>
```

**Recommendation:** Use pure CFML base component for easier developer adoption and debugging.

### 2.3 CFML Tag: `<cfwebsocket>`

#### `src/com/naryx/tagfusion/cfm/tag/ext/cfWEBSOCKET.java`
- Extends `cfTag`
- Generates JavaScript code and injects into page
- Supports attributes: name, subscribeTo, onMessage, onOpen, onClose, onError

**Attributes:**
- `name` (required) - JavaScript variable name for WebSocket object
- `subscribeTo` (optional) - Comma-separated list of channels to auto-subscribe
- `onMessage` (required) - JavaScript callback function name for messages
- `onOpen` (optional) - JavaScript callback for connection open
- `onClose` (optional) - JavaScript callback for connection close
- `onError` (optional) - JavaScript callback for errors
- `secure` (optional, default=false) - Use WSS instead of WS

**Generated JavaScript:**
```javascript
var chatWS = {
    ws: null,
    connectionId: null,

    openConnection: function() {
        this.ws = new WebSocket('ws://localhost:8580/openbd/ws');
        this.ws.onopen = function(evt) {
            // Auto-subscribe to channels if specified
            chatWS.subscribe({channelName: 'chatChannel'});
            if (typeof onOpenCallback === 'function') onOpenCallback(evt);
        };
        this.ws.onmessage = function(evt) {
            var msg = JSON.parse(evt.data);
            if (msg.type === 'message') {
                handleMessage(msg.channelName, msg.message);
            }
        };
        this.ws.onerror = function(evt) {
            if (typeof onErrorCallback === 'function') onErrorCallback(evt);
        };
        this.ws.onclose = function(evt) {
            if (typeof onCloseCallback === 'function') onCloseCallback(evt);
        };
    },

    subscribe: function(config) {
        // config: {channelName, subscriberInfo, onSuccess, onError}
        var msg = {
            type: 'subscribe',
            channelName: config.channelName,
            subscriberInfo: config.subscriberInfo || {}
        };
        this.ws.send(JSON.stringify(msg));
    },

    publish: function(channelName, message) {
        var msg = {
            type: 'publish',
            channelName: channelName,
            message: message
        };
        this.ws.send(JSON.stringify(msg));
    },

    unsubscribe: function(channelName) {
        var msg = {
            type: 'unsubscribe',
            channelName: channelName
        };
        this.ws.send(JSON.stringify(msg));
    },

    closeConnection: function() {
        if (this.ws) this.ws.close();
    },

    getConnectionId: function() {
        return this.connectionId;
    }
};

// Auto-connect on page load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
        chatWS.openConnection();
    });
} else {
    chatWS.openConnection();
}
```

**Tag Registration:**
Add to `src/com/naryx/tagfusion/cfm/tag/tagChecker.java`:
```java
tagElements.put("CFWEBSOCKET", new TagElement("CFWEBSOCKET", false, "com.naryx.tagfusion.cfm.tag.ext.cfWEBSOCKET"));
```

### 2.4 CFML Functions

#### `src/com/naryx/tagfusion/expression/function/websocket/wsPublish.java`
- Extends `functionBase`
- Publishes message to channel from server-side CFML
- Signature: `wsPublish(channelName, message [, publisherInfo])`

```java
public class wsPublish extends functionBase {
    public cfData execute(cfSession _session, cfArgStructData argStruct) throws cfmRunTimeException {
        String channelName = getNamedStringParam(argStruct, "channelname", null);
        cfData message = getNamedParam(argStruct, "message");
        cfStructData publisherInfo = getNamedStructParam(argStruct, "publisherinfo", new cfStructData());

        WebSocketChannelManager.getInstance().publish(channelName, message, publisherInfo);
        return cfBooleanData.TRUE;
    }
}
```

#### `src/com/naryx/tagfusion/expression/function/websocket/wsGetSubscribers.java`
- Returns array of subscriber info structures for a channel
- Signature: `wsGetSubscribers(channelName)`

```java
public class wsGetSubscribers extends functionBase {
    public cfData execute(cfSession _session, cfArgStructData argStruct) throws cfmRunTimeException {
        String channelName = getNamedStringParam(argStruct, "channelname", null);
        return WebSocketChannelManager.getInstance().getSubscribers(channelName);
    }
}
```

#### `src/com/naryx/tagfusion/expression/function/websocket/wsGetChannels.java`
- Returns array of registered channel names
- Signature: `wsGetChannels()`

#### Function Registration:**
Add to `src/com/naryx/tagfusion/expression/compile/registerTagsExpressions.java`:
```java
public static void registerFunctions(Map<String, String> functions) {
    // ... existing functions ...
    functions.put("wspublish", "com.naryx.tagfusion.expression.function.websocket.wsPublish");
    functions.put("wsgetsubscribers", "com.naryx.tagfusion.expression.function.websocket.wsGetSubscribers");
    functions.put("wsgetchannels", "com.naryx.tagfusion.expression.function.websocket.wsGetChannels");
}
```

### 2.5 Configuration and Initialization

#### Modify `src/com/naryx/tagfusion/cfm/engine/cfEngine.java`

Add WebSocket server initialization:
```java
public class cfEngine {
    private WebSocketServer wsServer;

    private void init() {
        // ... existing initialization ...

        // Initialize WebSocket server
        boolean wsEnabled = systemParameters.getBoolean("server.websocket.enabled", false);
        if (wsEnabled) {
            int wsPort = systemParameters.getInt("server.websocket.port", 8580);
            try {
                wsServer = WebSocketServer.getInstance();
                wsServer.start(wsPort);
                systemOut.println("WebSocket server started on port " + wsPort);
            } catch (Exception e) {
                systemOut.println("Failed to start WebSocket server: " + e.getMessage());
            }
        }
    }

    public void shutdown() {
        // ... existing shutdown ...
        if (wsServer != null) {
            wsServer.stop();
        }
    }
}
```

#### Configuration via `bluedragon.xml`

Add new configuration section:
```xml
<system>
    <websocket>
        <enabled>true</enabled>
        <port>8580</port>
        <secure>false</secure>
        <keystorePath></keystorePath>
        <keystorePassword></keystorePassword>
    </websocket>
</system>
```

#### Channel Registration API

Create server-side API for registering channels:

**Function: `wsRegisterChannel()`**
```java
// src/com/naryx/tagfusion/expression/function/websocket/wsRegisterChannel.java
public class wsRegisterChannel extends functionBase {
    public cfData execute(cfSession _session, cfArgStructData argStruct) throws cfmRunTimeException {
        String channelName = getNamedStringParam(argStruct, "channelname", null);
        String listenerPath = getNamedStringParam(argStruct, "listener", null);

        WebSocketChannelManager.getInstance().registerChannel(channelName, listenerPath);
        return cfBooleanData.TRUE;
    }
}
```

**Usage in Application.cfc:**
```cfml
<cffunction name="onApplicationStart">
    <cfset wsRegisterChannel("chatChannel", "myapp.websocket.ChatListener")>
    <cfset wsRegisterChannel("notifyChannel", "myapp.websocket.NotifyListener")>
</cffunction>
```

---

## Part 3: Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)
**Goal:** WebSocket server running and accepting connections

**Tasks:**
1. Create `WebSocketServer.java` using Netty
   - Basic server bootstrap on port 8580
   - WebSocket handshake handling
   - Frame encoding/decoding
   - Connection lifecycle management
   - Unit tests for server start/stop

2. Create `WebSocketConnection.java`
   - Connection state management
   - Send/receive message handling
   - Session association
   - JSON message parsing
   - Unit tests for message serialization

3. Create `WebSocketChannelHandler.java`
   - Netty pipeline handler
   - Route messages to manager
   - Error handling
   - Integration tests with server

4. Integrate with `cfEngine.java`
   - Configuration loading from bluedragon.xml
   - Server lifecycle (start on init, stop on shutdown)
   - Integration test: server starts with OpenBD

**Deliverables:**
- WebSocket server accepts connections
- Can send/receive raw messages
- Starts/stops with OpenBD lifecycle
- Configuration via bluedragon.xml works

**Test Plan:**
```bash
# Manual test with wscat
npm install -g wscat
wscat -c ws://localhost:8580/openbd/ws
# Should connect successfully
```

### Phase 2: Channel Management (Week 2-3)
**Goal:** Channel registration, subscription, and message routing

**Tasks:**
1. Create `WebSocketChannelManager.java`
   - Channel registry (thread-safe Map)
   - Channel creation/destruction
   - Subscription management
   - Message routing to subscribers
   - Unit tests for all operations

2. Create `WebSocketChannel.java`
   - Subscriber list management
   - Publish to all subscribers
   - Thread-safe operations
   - Unit tests

3. Implement message protocol
   - JSON schema for subscribe/publish/unsubscribe
   - Message validation
   - Error response handling
   - Protocol tests

4. Create `wsRegisterChannel()` function
   - Function implementation
   - Registration in expressionEngine
   - Integration tests

**Deliverables:**
- Channels can be registered via CFML
- Clients can subscribe to channels
- Messages route to correct subscribers
- Multiple clients per channel work

**Test Plan:**
```cfml
<!--- test_channel_basic.cfm --->
<cfset wsRegisterChannel("testChannel", "")>
<cfset result = wsGetChannels()>
<cfoutput>#arrayLen(result)# channels registered</cfoutput>
```

### Phase 3: Channel Listener CFC Support (Week 3-4)
**Goal:** Channel Listener CFCs with lifecycle hooks working

**Tasks:**
1. Create `webapp/OPENBD/websocket/ChannelListener.cfc`
   - Base CFC with 5 lifecycle methods
   - Default implementations
   - Documentation comments

2. Modify `WebSocketChannel.java` to invoke CFC methods
   - Load CFC instance via cfCOMPONENT
   - Invoke allowSubscribe() before subscription
   - Invoke allowPublish() before publishing
   - Invoke beforePublish() for message transformation
   - Invoke canSendMessage() for each subscriber
   - Invoke beforeSendMessage() for each subscriber
   - Error handling for CFC invocation failures

3. Create sample Channel Listener CFC
   - Example with all hooks implemented
   - Documentation and comments

4. Unit tests for CFC invocation
   - Mock CFC components
   - Test each lifecycle method
   - Test error scenarios

**Deliverables:**
- Channel Listener CFCs can be created and registered
- All 5 lifecycle hooks are invoked correctly
- Subscription/publish authorization works
- Message transformation works
- Per-subscriber filtering works

**Test Plan:**
```cfml
<!--- webapp/test/ChatListener.cfc --->
<cfcomponent extends="OPENBD.websocket.ChannelListener">
    <cffunction name="allowSubscribe" returntype="boolean">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <!--- Only allow if userId is provided --->
        <cfreturn structKeyExists(arguments.subscriberInfo, "userId")>
    </cffunction>

    <cffunction name="beforePublish" returntype="any">
        <cfargument name="publisherInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">
        <!--- Add timestamp --->
        <cfset arguments.message.timestamp = now()>
        <cfreturn arguments.message>
    </cffunction>
</cfcomponent>

<!--- test_listener.cfm --->
<cfset wsRegisterChannel("chatChannel", "test.ChatListener")>
<!--- Test from JavaScript client --->
```

### Phase 4: `<cfwebsocket>` Tag (Week 4-5)
**Goal:** CFML tag generates JavaScript client API

**Tasks:**
1. Create `cfWEBSOCKET.java`
   - Extend cfTag
   - Parse attributes (name, subscribeTo, onMessage, etc.)
   - Generate JavaScript code
   - Inject into page output
   - Handle attribute validation

2. JavaScript API generation
   - openConnection() method
   - subscribe() method with callbacks
   - publish() method
   - unsubscribe() method
   - closeConnection() method
   - getConnectionId() method
   - Auto-connect logic
   - Error handling

3. Register tag in `tagChecker.java`

4. Integration tests
   - Tag renders on page
   - JavaScript is valid
   - Connection works
   - Subscribe/publish work

**Deliverables:**
- `<cfwebsocket>` tag works in CFML pages
- Generated JavaScript connects to server
- Client can subscribe and publish
- Callbacks work (onMessage, onOpen, onClose, onError)

**Test Plan:**
```cfml
<!--- webapp/test/websocket_test.cfm --->
<html>
<head>
    <script>
    function handleMessage(channelName, message) {
        console.log('Message from ' + channelName + ':', message);
        document.getElementById('messages').innerHTML +=
            '<div>' + JSON.stringify(message) + '</div>';
    }
    </script>
</head>
<body>
    <cfwebsocket name="testWS"
                 subscribeTo="testChannel"
                 onMessage="handleMessage">

    <button onclick="testWS.publish('testChannel', {text: 'Hello'})">
        Send Message
    </button>

    <div id="messages"></div>
</body>
</html>
```

### Phase 5: Server-Side Functions (Week 5)
**Goal:** Complete server-side CFML API

**Tasks:**
1. Implement `wsPublish()` function
   - Publish from server-side code
   - Support all data types
   - Error handling

2. Implement `wsGetSubscribers()` function
   - Return array of subscriber info
   - Include connection IDs and custom metadata

3. Implement `wsGetChannels()` function
   - Return array of registered channels

4. Register all functions in `registerTagsExpressions.java`

5. Integration tests for all functions

**Deliverables:**
- Server-side CFML can publish to channels
- Can query subscribers and channels
- Functions work with Channel Listener CFCs

**Test Plan:**
```cfml
<!--- test_server_functions.cfm --->
<cfset wsRegisterChannel("alertChannel", "")>

<!--- Publish from server --->
<cfset wsPublish("alertChannel", {
    type: "warning",
    message: "Server maintenance in 5 minutes"
})>

<!--- Query subscribers --->
<cfset subscribers = wsGetSubscribers("alertChannel")>
<cfoutput>
    <p>#arrayLen(subscribers)# subscribers connected</p>
    <cfdump var="#subscribers#">
</cfoutput>

<!--- List all channels --->
<cfset channels = wsGetChannels()>
<cfdump var="#channels#" label="Registered Channels">
```

### Phase 6: Security and Hardening (Week 6)
**Goal:** Production-ready security and error handling

**Tasks:**
1. Authentication integration
   - Associate WebSocket connections with cfSession
   - Pass session credentials to Channel Listener
   - Prevent session hijacking

2. SSL/TLS support
   - Configure WSS protocol
   - Keystore configuration
   - Certificate management

3. Rate limiting
   - Limit messages per second per connection
   - Prevent DoS attacks
   - Configurable limits

4. Error handling
   - Graceful CFC invocation failures
   - Client disconnection handling
   - Channel cleanup on errors
   - Comprehensive logging

5. Input validation
   - JSON schema validation
   - Channel name validation
   - Message size limits
   - XSS prevention

**Deliverables:**
- WebSocket connections authenticated via session
- SSL/TLS works
- Rate limiting prevents abuse
- All error scenarios handled gracefully
- Security audit passed

### Phase 7: Documentation and Examples (Week 6-7)
**Goal:** Complete documentation for developers

**Tasks:**
1. Developer documentation
   - Setup guide
   - Configuration reference
   - Channel Listener API reference
   - JavaScript API reference
   - CFML function reference

2. Example applications
   - Chat application (multi-room)
   - Real-time notifications
   - Live dashboard with updates
   - Collaborative editing demo

3. Migration guide
   - Differences from Adobe CF
   - Code compatibility notes
   - Performance tuning guide

4. Troubleshooting guide
   - Common errors
   - Debug logging
   - Network configuration

**Deliverables:**
- Complete documentation published
- 4 working example applications
- Migration guide for Adobe CF users

---

## Part 4: Technical Decisions

### Decision 1: Plugin vs Core Implementation
**Choice:** Core implementation (not plugin)

**Rationale:**
- WebSocket is a fundamental feature like HTTP
- Requires tight integration with cfEngine lifecycle
- Needs access to cfSession, cfCOMPONENT, and core infrastructure
- Tag registration requires core integration
- Adobe CF implements it as core feature

**Alternative Considered:** Plugin approach
- Pros: Cleaner separation, optional installation
- Cons: Can't register tags, limited cfEngine integration, breaks feature parity

### Decision 2: WebSocket Library
**Choice:** Netty 4.1.15 (already in classpath)

**Rationale:**
- Already available in OpenBD (no new dependencies)
- Production-proven WebSocket implementation
- High performance with async I/O
- Used by many enterprise applications
- Good documentation and community

**Alternatives Considered:**
- Java-WebSocket: Simpler but less performant
- Jetty WebSocket: Not in classpath, would add dependency
- Tyrus (JSR 356): Not in classpath, would add dependency

### Decision 3: Message Protocol
**Choice:** JSON-based text frames (compatible with Adobe CF)

**Rationale:**
- Adobe CF uses JSON protocol
- Easy to debug (human-readable)
- JavaScript native support
- CFML native support (serializeJSON/deserializeJSON)
- Extensible schema

**Alternative Considered:** Binary frames with MessagePack
- Pros: More efficient, smaller messages
- Cons: Incompatible with Adobe CF, harder to debug

### Decision 4: Channel Registration Approach
**Choice:** Runtime registration via `wsRegisterChannel()` CFML function

**Rationale:**
- More flexible than XML configuration
- Aligns with OpenBD's dynamic nature
- Can register channels conditionally
- Easier to test and develop
- Can register in Application.cfc::onApplicationStart()

**Alternative Considered:** XML configuration in bluedragon.xml
- Pros: Centralized configuration, like Adobe CF
- Cons: Requires server restart, less flexible

### Decision 5: Channel Listener Implementation
**Choice:** Pure CFML CFC extending base component

**Rationale:**
- CFML developers more comfortable with CFML than Java
- Easier to debug and modify
- Hot-reloading support (if enabled)
- Matches Adobe CF approach exactly
- Lowers barrier to adoption

**Alternative Considered:** Java interface implementation
- Pros: Better performance, compile-time type checking
- Cons: Requires Java knowledge, harder to develop

### Decision 6: Threading Model
**Choice:** Netty's event loop for I/O, separate thread pool for CFC invocation

**Rationale:**
- Don't block Netty event loop with slow CFC operations
- CFC invocation can take arbitrary time
- Prevents one slow channel from blocking all WebSocket I/O
- Configurable thread pool size

**Implementation:**
```java
public class WebSocketChannelManager {
    private ExecutorService cfcInvocationPool =
        Executors.newFixedThreadPool(10); // Configurable

    public void publish(String channelName, cfData message, cfStructData publisherInfo) {
        cfcInvocationPool.submit(() -> {
            // Invoke Channel Listener CFC methods
            // Route to subscribers
        });
    }
}
```

### Decision 7: Session Management
**Choice:** Create or reuse cfSession for WebSocket connections

**Rationale:**
- Channel Listener needs session context for authorization
- Leverage existing session-based authentication
- Session variables available in Channel Listener CFCs

**Implementation:**
- WebSocket handshake includes session cookie
- Look up existing cfSession by session ID
- If no session, create new one
- Associate with WebSocketConnection

### Decision 8: Clustering Support
**Choice:** Phase 2 feature (not in initial release)

**Rationale:**
- Adobe CF clustering has significant limitations
- Requires complex infrastructure (message broker or multicast)
- Initial implementation focuses on single-server
- Can add later with Redis pub/sub or similar

**Future Considerations:**
- Use Redis pub/sub for cross-server message routing
- Share subscriber info across cluster
- Handle failover and connection migration

---

## Part 5: File Structure

### New Files to Create

```
src/com/naryx/tagfusion/cfm/websocket/
├── WebSocketServer.java              [Core server using Netty]
├── WebSocketChannelManager.java      [Channel registry and routing]
├── WebSocketChannel.java             [Single channel representation]
├── WebSocketConnection.java          [Single client connection]
├── WebSocketChannelHandler.java      [Netty pipeline handler]
├── WebSocketMessage.java             [Message protocol POJOs]
└── WebSocketException.java           [Custom exceptions]

src/com/naryx/tagfusion/cfm/tag/ext/
└── cfWEBSOCKET.java                  [<cfwebsocket> tag implementation]

src/com/naryx/tagfusion/expression/function/websocket/
├── wsPublish.java                    [Server-side publish function]
├── wsGetSubscribers.java             [Get subscribers function]
├── wsGetChannels.java                [List channels function]
└── wsRegisterChannel.java            [Register channel function]

webapp/OPENBD/websocket/
└── ChannelListener.cfc               [Base CFC for channel listeners]

webapp/test/websocket/
├── ChatListener.cfc                  [Example: chat listener]
├── NotifyListener.cfc                [Example: notification listener]
├── test_basic.cfm                    [Basic connectivity test]
├── test_channel_listener.cfm         [Channel listener tests]
└── chat_demo.cfm                     [Complete chat demo]

claude/
└── websocket_todo.md                 [This file - implementation plan]
```

### Files to Modify

```
src/com/naryx/tagfusion/cfm/engine/cfEngine.java
  - Add WebSocket server initialization in init()
  - Add WebSocket server shutdown in shutdown()
  - Add configuration loading for websocket settings

src/com/naryx/tagfusion/cfm/tag/tagChecker.java
  - Add CFWEBSOCKET tag registration in registerTags()

src/com/naryx/tagfusion/expression/compile/registerTagsExpressions.java
  - Add wsPublish, wsGetSubscribers, wsGetChannels, wsRegisterChannel
    to registerFunctions()

webapp/WEB-INF/bluedragon.xml
  - Add <websocket> configuration section

build/build.xml
  - No changes needed (Netty JARs already in classpath)

.classpath
  - No changes needed (Netty JARs already in classpath)
```

---

## Part 6: Testing Strategy

### Unit Tests

**Framework:** JUnit 4 (match existing OpenBD tests)

**Test Classes:**
```
src/test/java/com/naryx/tagfusion/cfm/websocket/
├── WebSocketServerTest.java
│   - testServerStartStop()
│   - testMultipleConnections()
│   - testPortConflict()
│
├── WebSocketChannelManagerTest.java
│   - testChannelRegistration()
│   - testSubscriptionManagement()
│   - testMessageRouting()
│   - testConcurrentAccess()
│
├── WebSocketChannelTest.java
│   - testSubscriberManagement()
│   - testPublishToSubscribers()
│   - testCFCInvocation()
│
└── WebSocketConnectionTest.java
    - testSendMessage()
    - testJSONParsing()
    - testConnectionClose()
```

### Integration Tests

**MXUnit Test CFCs:**
```
webapp/openbdtest/functions/websocket/
├── WebSocketBasicTest.cfc
│   - testServerRunning()
│   - testChannelRegistration()
│   - testFunctionExistence()
│
├── WebSocketChannelTest.cfc
│   - testPublishFromServer()
│   - testGetSubscribers()
│   - testGetChannels()
│
└── WebSocketTagTest.cfc
    - testTagRendering()
    - testJavaScriptGeneration()
```

### Manual Testing

**Test Suite (browser-based):**
```
webapp/test/websocket/
├── index.html                        [Test runner page]
├── test_connect.html                 [Basic connection test]
├── test_subscribe.html               [Subscribe/unsubscribe test]
├── test_publish.html                 [Publish messages test]
├── test_multi_client.html            [Multiple clients test]
└── test_listener_hooks.html          [Channel listener hooks test]
```

**Load Testing:**
- Tool: Apache JMeter with WebSocket plugin
- Scenarios:
  - 100 concurrent connections
  - 1000 messages/second
  - 10 channels with 100 subscribers each
- Performance targets:
  - < 50ms message latency
  - > 10,000 messages/second throughput
  - Support 1,000 concurrent connections

### Compatibility Testing

**Adobe ColdFusion Compatibility:**
- Test JavaScript API is compatible with Adobe CF client code
- Test Channel Listener CFC signatures match
- Test message format is compatible
- Document any differences

---

## Part 7: Configuration Reference

### bluedragon.xml Configuration

```xml
<bluedragon>
    <system>
        <!-- Existing configuration -->

        <websocket>
            <!-- Enable/disable WebSocket server -->
            <enabled>true</enabled>

            <!-- WebSocket server port (default: 8580) -->
            <port>8580</port>

            <!-- Use secure WebSocket (WSS) -->
            <secure>false</secure>

            <!-- SSL/TLS configuration (required if secure=true) -->
            <keystorePath>/path/to/keystore.jks</keystorePath>
            <keystorePassword>changeit</keystorePassword>
            <keystoreType>JKS</keystoreType>

            <!-- Thread pool size for CFC invocations (default: 10) -->
            <cfcThreadPoolSize>10</cfcThreadPoolSize>

            <!-- Maximum connections (default: 1000) -->
            <maxConnections>1000</maxConnections>

            <!-- Message size limit in bytes (default: 64KB) -->
            <maxMessageSize>65536</maxMessageSize>

            <!-- Rate limiting: messages per second per connection (default: 100) -->
            <maxMessagesPerSecond>100</maxMessagesPerSecond>

            <!-- Idle timeout in seconds (default: 300) -->
            <idleTimeout>300</idleTimeout>

            <!-- Enable debug logging -->
            <debugLogging>false</debugLogging>
        </websocket>
    </system>
</bluedragon>
```

### Application.cfc Channel Registration

```cfml
<cfcomponent>
    <cfset this.name = "MyWebSocketApp">
    <cfset this.sessionManagement = true>
    <cfset this.sessionTimeout = createTimeSpan(0, 0, 30, 0)>

    <cffunction name="onApplicationStart" returnType="boolean" output="false">
        <!--- Register WebSocket channels --->
        <cfset wsRegisterChannel(
            channelName = "chatChannel",
            listener = "myapp.websocket.ChatChannelListener"
        )>

        <cfset wsRegisterChannel(
            channelName = "notifyChannel",
            listener = "myapp.websocket.NotifyChannelListener"
        )>

        <cfreturn true>
    </cffunction>

    <cffunction name="onSessionStart" returnType="void" output="false">
        <!--- Initialize user-specific state --->
        <cfset session.userId = createUUID()>
    </cffunction>
</cfcomponent>
```

---

## Part 8: Example Implementations

### Example 1: Basic Chat Application

**Channel Listener: `ChatChannelListener.cfc`**
```cfml
<cfcomponent extends="OPENBD.websocket.ChannelListener">

    <cffunction name="allowSubscribe" returntype="boolean" access="public">
        <cfargument name="subscriberInfo" type="struct" required="true">

        <!--- Require authentication --->
        <cfif not structKeyExists(session, "userId")>
            <cfreturn false>
        </cfif>

        <!--- Require username --->
        <cfif not structKeyExists(arguments.subscriberInfo, "username")>
            <cfreturn false>
        </cfif>

        <cfreturn true>
    </cffunction>

    <cffunction name="allowPublish" returntype="boolean" access="public">
        <cfargument name="publisherInfo" type="struct" required="true">

        <!--- Only authenticated users can publish --->
        <cfreturn structKeyExists(session, "userId")>
    </cffunction>

    <cffunction name="beforePublish" returntype="any" access="public">
        <cfargument name="publisherInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">

        <!--- Add timestamp and sanitize HTML --->
        <cfset arguments.message.timestamp = now()>
        <cfset arguments.message.text = htmlEditFormat(arguments.message.text)>

        <!--- Add user info from session --->
        <cfset arguments.message.userId = session.userId>

        <cfreturn arguments.message>
    </cffunction>

    <cffunction name="canSendMessage" returntype="boolean" access="public">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">

        <!--- Filter: only send messages to users in the same room --->
        <cfif structKeyExists(arguments.subscriberInfo, "room") and
              structKeyExists(arguments.message, "room")>
            <cfreturn arguments.subscriberInfo.room eq arguments.message.room>
        </cfif>

        <cfreturn true>
    </cffunction>

</cfcomponent>
```

**Client Page: `chat.cfm`**
```cfml
<!DOCTYPE html>
<html>
<head>
    <title>OpenBD Chat</title>
    <script>
    var currentRoom = 'general';
    var username = prompt('Enter your username:');

    function handleMessage(channelName, message) {
        var msgDiv = document.createElement('div');
        msgDiv.innerHTML = '<strong>' + message.username + ':</strong> ' +
                          message.text +
                          ' <em>(' + message.timestamp + ')</em>';
        document.getElementById('messages').appendChild(msgDiv);
    }

    function sendMessage() {
        var text = document.getElementById('messageInput').value;
        if (!text) return;

        chatWS.publish('chatChannel', {
            text: text,
            username: username,
            room: currentRoom
        });

        document.getElementById('messageInput').value = '';
    }

    function joinRoom(room) {
        currentRoom = room;
        document.getElementById('messages').innerHTML = '';
        document.getElementById('currentRoom').innerText = room;
    }
    </script>
</head>
<body>
    <h1>OpenBD WebSocket Chat</h1>

    <cfwebsocket name="chatWS"
                 subscribeTo="chatChannel"
                 onMessage="handleMessage">

    <script>
    // Subscribe with room info
    chatWS.subscribe({
        channelName: 'chatChannel',
        subscriberInfo: {
            username: username,
            room: currentRoom
        }
    });
    </script>

    <div>
        <strong>Room:</strong> <span id="currentRoom">general</span>
        <button onclick="joinRoom('general')">General</button>
        <button onclick="joinRoom('tech')">Tech</button>
        <button onclick="joinRoom('random')">Random</button>
    </div>

    <div id="messages" style="border:1px solid #ccc; height:400px; overflow-y:scroll; margin:10px 0;">
    </div>

    <input type="text" id="messageInput" size="50"
           onkeypress="if(event.keyCode==13) sendMessage()">
    <button onclick="sendMessage()">Send</button>
</body>
</html>
```

**Server-side Admin: `chat_admin.cfm`**
```cfml
<h1>Chat Administration</h1>

<!--- Get all subscribers --->
<cfset subscribers = wsGetSubscribers("chatChannel")>

<h2>Active Users (#arrayLen(subscribers)#)</h2>
<table border="1">
    <tr>
        <th>Username</th>
        <th>Room</th>
        <th>Connection ID</th>
    </tr>
    <cfloop array="#subscribers#" index="sub">
        <tr>
            <td>#sub.username#</td>
            <td>#sub.room#</td>
            <td>#sub.connectionId#</td>
        </tr>
    </cfloop>
</table>

<!--- Send server announcement --->
<cfif structKeyExists(form, "announcement")>
    <cfset wsPublish("chatChannel", {
        text: form.announcement,
        username: "SERVER",
        room: "all",
        type: "announcement"
    })>
    <p>Announcement sent!</p>
</cfif>

<form method="post">
    <h2>Send Announcement</h2>
    <textarea name="announcement" rows="3" cols="50"></textarea>
    <button type="submit">Send to All</button>
</form>
```

### Example 2: Real-time Notifications

**Channel Listener: `NotifyChannelListener.cfc`**
```cfml
<cfcomponent extends="OPENBD.websocket.ChannelListener">

    <cffunction name="allowSubscribe" returntype="boolean" access="public">
        <cfargument name="subscriberInfo" type="struct" required="true">

        <!--- Only authenticated users --->
        <cfreturn structKeyExists(session, "userId")>
    </cffunction>

    <cffunction name="canSendMessage" returntype="boolean" access="public">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">

        <!--- Only send notification to intended recipient --->
        <cfif structKeyExists(arguments.message, "targetUserId")>
            <cfreturn arguments.subscriberInfo.userId eq arguments.message.targetUserId>
        </cfif>

        <!--- Broadcast notifications (no targetUserId) go to everyone --->
        <cfreturn true>
    </cffunction>

</cfcomponent>
```

**Client Page: `notifications.cfm`**
```cfml
<!DOCTYPE html>
<html>
<head>
    <title>Notifications</title>
    <script>
    function handleNotification(channelName, message) {
        // Show browser notification
        if (Notification.permission === 'granted') {
            new Notification(message.title, {
                body: message.text,
                icon: '/images/notification-icon.png'
            });
        }

        // Add to notification list
        var notifDiv = document.createElement('div');
        notifDiv.className = 'notification notification-' + message.type;
        notifDiv.innerHTML = '<strong>' + message.title + '</strong><br>' + message.text;
        document.getElementById('notifications').prepend(notifDiv);
    }
    </script>
</head>
<body>
    <h1>Notifications</h1>

    <cfwebsocket name="notifyWS"
                 subscribeTo="notifyChannel"
                 onMessage="handleNotification">

    <script>
    // Request notification permission
    if (Notification.permission !== 'granted') {
        Notification.requestPermission();
    }

    // Subscribe with user ID
    notifyWS.subscribe({
        channelName: 'notifyChannel',
        subscriberInfo: {
            userId: '<cfoutput>#session.userId#</cfoutput>'
        }
    });
    </script>

    <div id="notifications"></div>
</body>
</html>
```

**Server-side Trigger: `send_notification.cfm`**
```cfml
<!--- Called by application logic when event occurs --->
<cffunction name="notifyUser" access="public">
    <cfargument name="userId" type="string" required="true">
    <cfargument name="title" type="string" required="true">
    <cfargument name="text" type="string" required="true">
    <cfargument name="type" type="string" default="info">

    <cfset wsPublish("notifyChannel", {
        targetUserId: arguments.userId,
        title: arguments.title,
        text: arguments.text,
        type: arguments.type,
        timestamp: now()
    })>
</cffunction>

<!--- Example usage --->
<cfset notifyUser(
    userId = "user123",
    title = "New Message",
    text = "You have a new message from John Doe",
    type = "info"
)>
```

---

## Part 9: Known Limitations and Future Enhancements

### Known Limitations (Initial Release)

1. **No Clustering Support**
   - WebSocket connections are local to single server
   - Messages don't route across cluster
   - **Workaround:** Use load balancer with sticky sessions
   - **Future:** Add Redis pub/sub for cross-server messaging

2. **No Binary Message Support**
   - Only text frames (JSON) supported
   - Large binary data should use HTTP instead
   - **Future:** Add binary frame support for file transfers

3. **No Message Persistence**
   - Messages are not stored
   - Disconnected clients miss messages
   - **Workaround:** Application-level message queue
   - **Future:** Add optional message persistence

4. **No Automatic Reconnection**
   - Client must manually reconnect on disconnect
   - **Workaround:** Add JavaScript reconnection logic
   - **Future:** Add auto-reconnect to generated JavaScript

5. **No Custom Subprotocols**
   - Only default WebSocket protocol supported
   - **Future:** Allow subprotocol negotiation

### Future Enhancements

**Priority 1 (Next Release):**
- [ ] Auto-reconnection in JavaScript API
- [ ] Heartbeat/ping-pong for connection health
- [ ] Connection metrics and monitoring
- [ ] Admin console for managing channels

**Priority 2 (Future):**
- [ ] Clustering support via Redis
- [ ] Message persistence option
- [ ] Binary message support
- [ ] Compression (permessage-deflate)

**Priority 3 (Nice to Have):**
- [ ] Custom subprotocols
- [ ] GraphQL over WebSocket
- [ ] Server-to-server WebSocket (not just browser clients)

---

## Part 10: Migration from Adobe ColdFusion

### Compatibility

**What Works Identically:**
- `<cfwebsocket>` tag attributes
- JavaScript API methods (subscribe, publish, etc.)
- Channel Listener CFC signatures
- CFML functions (wsPublish, wsGetSubscribers)
- Message format and protocol

**Differences:**

| Feature | Adobe ColdFusion | OpenBD |
|---------|------------------|---------|
| **Default Port** | 8575/8577 | 8580 |
| **Configuration** | cf_root/cfusion/lib/wsconfig.xml | bluedragon.xml |
| **Channel Registration** | XML config | CFML function wsRegisterChannel() |
| **Base CFC Path** | CFIDE.websocket.ChannelListener | OPENBD.websocket.ChannelListener |
| **Clustering** | UDP multicast (limited) | Not supported initially |
| **SSL** | Separate keystore | Uses same keystore as HTTPS |

### Migration Steps

1. **Update Configuration:**
   ```xml
   <!-- Adobe CF: wsconfig.xml -->
   <channels>
       <channel name="chatChannel" customClass="myapp.ChatListener"/>
   </channels>

   <!-- OpenBD: Application.cfc -->
   <cffunction name="onApplicationStart">
       <cfset wsRegisterChannel("chatChannel", "myapp.ChatListener")>
   </cffunction>
   ```

2. **Update Channel Listener CFCs:**
   ```cfml
   <!--- Adobe CF --->
   <cfcomponent extends="CFIDE.websocket.ChannelListener">

   <!--- OpenBD --->
   <cfcomponent extends="OPENBD.websocket.ChannelListener">
   ```

3. **Update Client Code:**
   ```html
   <!-- Adobe CF -->
   <cfwebsocket name="ws" subscribeTo="chat"
                onMessage="handleMsg">

   <!-- OpenBD: IDENTICAL, no changes needed -->
   <cfwebsocket name="ws" subscribeTo="chat"
                onMessage="handleMsg">
   ```

4. **Update Server-side Functions:**
   ```cfml
   <!--- Both Adobe CF and OpenBD: IDENTICAL --->
   <cfset wsPublish("chatChannel", {text: "Hello"})>
   <cfset subscribers = wsGetSubscribers("chatChannel")>
   ```

### Testing Checklist

- [ ] All channels registered in onApplicationStart()
- [ ] Channel Listener CFCs extend OPENBD.websocket.ChannelListener
- [ ] WebSocket port updated in client URLs (or use server variable)
- [ ] SSL certificates configured if using WSS
- [ ] All `<cfwebsocket>` tags render correctly
- [ ] JavaScript API methods work (subscribe, publish)
- [ ] Server-side functions work (wsPublish, wsGetSubscribers)
- [ ] Authorization logic in allowSubscribe/allowPublish works
- [ ] Message filtering in canSendMessage works

---

## Part 11: Performance Considerations

### Scalability Targets

**Single Server:**
- 1,000 concurrent WebSocket connections
- 10,000 messages/second throughput
- < 50ms message latency (p95)
- < 100MB memory overhead per 1,000 connections

**Optimization Strategies:**

1. **Connection Pooling:**
   - Reuse Netty worker threads
   - Configure thread pool based on CPU cores
   - Recommended: 2x CPU cores for I/O threads

2. **Message Batching:**
   - Batch multiple messages to same subscriber
   - Reduce syscall overhead
   - Configurable batch size and timeout

3. **JSON Serialization:**
   - Cache serialized messages when sending to multiple subscribers
   - Use Jackson for fast JSON processing
   - Pre-serialize common message patterns

4. **Channel Listener Caching:**
   - Cache CFC instances per channel
   - Avoid repeated CFC loading
   - Implement CFC pooling if needed

5. **Memory Management:**
   - Use direct byte buffers for Netty
   - Limit message size to prevent OOM
   - Implement connection limits

### Monitoring and Metrics

**Key Metrics to Track:**
```cfml
<!--- Get WebSocket metrics --->
<cfset metrics = wsGetMetrics()>
<cfdump var="#metrics#">

<!--- Sample output:
{
    totalConnections: 523,
    activeChannels: 12,
    messagesPerSecond: 1250,
    avgMessageLatency: 23,
    memoryUsageMB: 45,
    errorCount: 0
}
--->
```

**Logging:**
- Connection open/close events
- Channel subscription events
- Message publish events
- CFC invocation failures
- Rate limit violations

---

## Part 12: Security Considerations

### Attack Vectors and Mitigations

1. **Cross-Site WebSocket Hijacking (CSWSH)**
   - **Risk:** Attacker tricks victim's browser into opening malicious WebSocket
   - **Mitigation:**
     - Validate Origin header during handshake
     - Require CSRF token in subscriberInfo
     - Use WSS (secure WebSocket) only

2. **Denial of Service**
   - **Risk:** Attacker floods server with connections or messages
   - **Mitigation:**
     - Connection limit per IP
     - Rate limiting (messages per second)
     - Message size limits
     - Idle timeout

3. **Session Hijacking**
   - **Risk:** Attacker steals session cookie and impersonates user
   - **Mitigation:**
     - Use secure, httpOnly cookies
     - Validate session on every message
     - Implement session binding to IP

4. **XSS via Messages**
   - **Risk:** Attacker injects malicious JavaScript in messages
   - **Mitigation:**
     - Sanitize all message content in beforePublish()
     - Use htmlEditFormat() on display
     - Content Security Policy headers

5. **Authorization Bypass**
   - **Risk:** Attacker subscribes to channels they shouldn't access
   - **Mitigation:**
     - Implement strict allowSubscribe() checks
     - Validate session and permissions
     - Log all authorization failures

### Security Best Practices

```cfml
<!--- Secure Channel Listener Example --->
<cfcomponent extends="OPENBD.websocket.ChannelListener">

    <cffunction name="allowSubscribe" returntype="boolean">
        <cfargument name="subscriberInfo" type="struct" required="true">

        <!--- 1. Verify session exists and is valid --->
        <cfif not structKeyExists(session, "userId") or not session.authenticated>
            <cflog file="websocket" type="warning"
                   text="Unauthorized subscribe attempt: no session">
            <cfreturn false>
        </cfif>

        <!--- 2. Validate CSRF token --->
        <cfif not structKeyExists(arguments.subscriberInfo, "csrfToken") or
              arguments.subscriberInfo.csrfToken neq session.csrfToken>
            <cflog file="websocket" type="warning"
                   text="Unauthorized subscribe attempt: invalid CSRF token">
            <cfreturn false>
        </cfif>

        <!--- 3. Check channel-specific permissions --->
        <cfif not hasChannelPermission(session.userId, "chatChannel", "read")>
            <cflog file="websocket" type="warning"
                   text="Unauthorized subscribe attempt: no channel permission">
            <cfreturn false>
        </cfif>

        <cfreturn true>
    </cffunction>

    <cffunction name="beforePublish" returntype="any">
        <cfargument name="publisherInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">

        <!--- Sanitize all string fields --->
        <cfif isStruct(arguments.message)>
            <cfloop collection="#arguments.message#" item="key">
                <cfif isSimpleValue(arguments.message[key])>
                    <cfset arguments.message[key] = htmlEditFormat(arguments.message[key])>
                </cfif>
            </cfloop>
        </cfif>

        <!--- Add server timestamp to prevent replay attacks --->
        <cfset arguments.message._serverTimestamp = now()>

        <cfreturn arguments.message>
    </cffunction>

</cfcomponent>
```

---

## Part 13: Development Timeline

### Estimated Effort: 6-7 weeks

**Week 1-2: Core Infrastructure**
- WebSocket server with Netty
- Connection management
- Basic message routing
- Integration with cfEngine
- Estimated: 60 hours

**Week 2-3: Channel Management**
- Channel registry
- Subscription management
- Message routing to subscribers
- wsRegisterChannel() function
- Estimated: 40 hours

**Week 3-4: Channel Listener CFCs**
- Base ChannelListener.cfc
- CFC invocation from Java
- All 5 lifecycle hooks
- Error handling
- Estimated: 40 hours

**Week 4-5: `<cfwebsocket>` Tag**
- Tag implementation
- JavaScript generation
- Client API
- Auto-connect logic
- Estimated: 30 hours

**Week 5: Server-side Functions**
- wsPublish()
- wsGetSubscribers()
- wsGetChannels()
- Function registration
- Estimated: 20 hours

**Week 6: Security and Hardening**
- Authentication integration
- SSL/TLS support
- Rate limiting
- Error handling
- Input validation
- Estimated: 40 hours

**Week 6-7: Documentation and Examples**
- Developer documentation
- Example applications
- Migration guide
- Troubleshooting guide
- Estimated: 30 hours

**Total Estimated Effort: 260 hours (~6.5 weeks for 1 developer)**

### Milestones

1. **Milestone 1 (End of Week 2):** WebSocket server accepts connections and routes messages
2. **Milestone 2 (End of Week 3):** Channels can be registered and messages route to subscribers
3. **Milestone 3 (End of Week 4):** Channel Listener CFCs work with all hooks
4. **Milestone 4 (End of Week 5):** Complete CFML API (tag + functions) working
5. **Milestone 5 (End of Week 6):** Security hardening complete
6. **Milestone 6 (End of Week 7):** Documentation and examples complete, ready for release

---

## Part 14: Success Criteria

### Functional Requirements

- [ ] WebSocket server starts on configurable port
- [ ] Channels can be registered via wsRegisterChannel()
- [ ] Clients can subscribe to channels
- [ ] Clients can publish messages to channels
- [ ] Messages route to all subscribers of channel
- [ ] Channel Listener CFCs control subscriptions and messages
- [ ] All 5 lifecycle hooks work correctly
- [ ] `<cfwebsocket>` tag generates working JavaScript
- [ ] Server-side functions (wsPublish, etc.) work
- [ ] SSL/TLS support works
- [ ] Configuration via bluedragon.xml works

### Non-Functional Requirements

- [ ] Support 1,000 concurrent connections
- [ ] Throughput > 10,000 messages/second
- [ ] Message latency < 50ms (p95)
- [ ] No memory leaks under load
- [ ] Graceful degradation under overload
- [ ] All errors logged appropriately
- [ ] Code follows OpenBD style and patterns
- [ ] Unit test coverage > 80%
- [ ] Integration tests cover all features
- [ ] Documentation is complete and accurate

### Compatibility Requirements

- [ ] JavaScript API matches Adobe CF API
- [ ] Channel Listener CFC signatures match Adobe CF
- [ ] CFML functions match Adobe CF
- [ ] Message protocol compatible with Adobe CF clients
- [ ] Migration path from Adobe CF documented

---

## Conclusion

This implementation plan provides a comprehensive roadmap for adding WebSocket support to OpenBD that achieves feature parity with Adobe ColdFusion. The design leverages OpenBD's existing architecture patterns while using the already-available Netty library for WebSocket infrastructure.

Key strengths of this approach:
- **No new dependencies** - uses existing Netty JARs
- **Core integration** - not a plugin, deeply integrated with cfEngine
- **Developer-friendly** - pure CFML Channel Listener CFCs
- **Compatible** - matches Adobe CF API for easy migration
- **Scalable** - targets 1,000+ concurrent connections
- **Secure** - comprehensive security considerations

The phased implementation allows for incremental development and testing, with each phase building on the previous. The estimated 6-7 week timeline assumes a single developer working full-time.

Once complete, OpenBD will have a production-ready WebSocket implementation suitable for real-time applications like chat, notifications, dashboards, and collaborative editing.
