# OpenBD WebSocket Reference

OpenBD provides full WebSocket support for real-time bidirectional communication between clients and server. The implementation includes a publish/subscribe channel system, server-side functions for programmatic message delivery, and optional Channel Listener CFCs for advanced message filtering and transformation.

---

## Table of Contents

- [Client-Side](#client-side)
  - [JavaScript WebSocket Protocol](#javascript-websocket-protocol)
  - [cfwebsocket Tag](#cfwebsocket-tag)
  - [Message Types](#message-types)
- [Server-Side](#server-side)
  - [Configuration](#configuration)
  - [CFML Functions](#cfml-functions)
  - [Channel Listener CFCs](#channel-listener-cfcs)

---

## Client-Side

### JavaScript WebSocket Protocol

#### Connection

Connect to the OpenBD WebSocket server using the standard WebSocket API:

```javascript
const ws = new WebSocket('ws://hostname:8580/openbd/ws');

ws.onopen = function(event) {
    console.log('Connected to OpenBD WebSocket server');
};

ws.onclose = function(event) {
    console.log('Disconnected from WebSocket server');
};

ws.onerror = function(error) {
    console.error('WebSocket error:', error);
};

ws.onmessage = function(event) {
    const message = JSON.parse(event.data);
    handleMessage(message);
};
```

**Connection URL Format:**
- Protocol: `ws://` (or `wss://` for secure connections)
- Host: Your server hostname or IP
- Port: WebSocket port (default 8580, configured in `bluedragon.xml`)
- Path: `/openbd/ws` (fixed endpoint)

#### Subscribing to a Channel

Send a subscribe message to receive messages from a channel:

```javascript
const subscribeMsg = {
    type: 'subscribe',
    channelName: 'chatChannel',
    subscriberInfo: {
        userId: 'user123',
        username: 'Alice',
        room: 'lobby'
    }
};

ws.send(JSON.stringify(subscribeMsg));
```

**Subscribe Message Structure:**
- `type` (string, required): Must be `"subscribe"`
- `channelName` (string, required): Name of the channel to subscribe to
- `subscriberInfo` (object, optional): Custom metadata about the subscriber

**Server Response:**
```javascript
// Success
{
    type: 'subscribed',
    channelName: 'chatChannel'
}

// Failure
{
    type: 'error',
    message: 'Channel not found: chatChannel'
}
```

#### Publishing a Message

Send a message to all subscribers of a channel:

```javascript
const publishMsg = {
    type: 'publish',
    channelName: 'chatChannel',
    message: {
        text: 'Hello, World!',
        timestamp: new Date().toISOString(),
        userId: 'user123'
    }
};

ws.send(JSON.stringify(publishMsg));
```

**Publish Message Structure:**
- `type` (string, required): Must be `"publish"`
- `channelName` (string, required): Name of the channel to publish to
- `message` (any, required): The message content (can be any JSON-serializable value)

**Note:** You must be subscribed to a channel before you can publish to it.

#### Unsubscribing from a Channel

Stop receiving messages from a channel:

```javascript
const unsubscribeMsg = {
    type: 'unsubscribe',
    channelName: 'chatChannel'
};

ws.send(JSON.stringify(unsubscribeMsg));
```

**Unsubscribe Message Structure:**
- `type` (string, required): Must be `"unsubscribe"`
- `channelName` (string, required): Name of the channel to unsubscribe from

**Server Response:**
```javascript
{
    type: 'unsubscribed',
    channelName: 'chatChannel'
}
```

#### Receiving Messages

Handle incoming messages from subscribed channels:

```javascript
ws.onmessage = function(event) {
    const msg = JSON.parse(event.data);

    switch (msg.type) {
        case 'subscribed':
            console.log('Successfully subscribed to:', msg.channelName);
            break;

        case 'unsubscribed':
            console.log('Successfully unsubscribed from:', msg.channelName);
            break;

        case 'message':
            console.log('Message from', msg.channelName, ':', msg.message);
            // Process the broadcast message
            displayMessage(msg.channelName, msg.message);
            break;

        case 'error':
            console.error('Error:', msg.message);
            break;
    }
};
```

---

### cfwebsocket Tag

The `<cfwebsocket>` tag automatically generates JavaScript code for WebSocket client integration, simplifying connection management and providing a high-level API.

#### Basic Usage

```cfm
<!--- Define event handlers BEFORE the cfwebsocket tag --->
<script>
function handleMessage(channelName, message) {
    console.log('Message from', channelName, ':', message);
}

function handleOpen(event) {
    console.log('Connected!');
}

function handleClose(event) {
    console.log('Disconnected');
}

function handleError(error) {
    console.error('Error:', error);
}
</script>

<!--- Generate the WebSocket client --->
<cfwebsocket
    name="myWebSocket"
    onMessage="handleMessage"
    onOpen="handleOpen"
    onClose="handleClose"
    onError="handleError">
```

#### Tag Attributes

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | JavaScript variable name for the generated WebSocket client object |
| `onMessage` | No | JavaScript function name to call when a message is received (receives `channelName, message`) |
| `onOpen` | No | JavaScript function name to call when connection opens (receives `event`) |
| `onClose` | No | JavaScript function name to call when connection closes (receives `event`) |
| `onError` | No | JavaScript function name to call when an error occurs (receives `error`) |
| `subscribeTo` | No | Channel name to automatically subscribe to after connection |
| `port` | No | Override the WebSocket server port (default from config) |
| `useCFAuth` | No | Include CF session authentication (not yet implemented) |
| `attributeCollection` | No | Struct containing tag attributes |

#### Generated Methods

The `<cfwebsocket>` tag creates a JavaScript object with these methods:

**`openConnection()`**
- Opens a WebSocket connection to the server
- Example: `myWebSocket.openConnection()`

**`closeConnection()`**
- Closes the WebSocket connection
- Example: `myWebSocket.closeConnection()`

**`subscribe(channelName, subscriberInfo, callback)`**
- Subscribe to a channel
- Parameters:
  - `channelName` (string, required): Channel to subscribe to
  - `subscriberInfo` (object, optional): Custom subscriber metadata
  - `callback` (function, required): Called with `(err, result)` on completion
- Example:
  ```javascript
  myWebSocket.subscribe('chatChannel', {userId: 123}, function(err, result) {
      if (err) {
          console.error('Subscribe failed:', err);
      } else {
          console.log('Subscribed successfully');
      }
  });
  ```

**`unsubscribe(channelName)`**
- Unsubscribe from a channel
- Parameters:
  - `channelName` (string, required): Channel to unsubscribe from
- Example: `myWebSocket.unsubscribe('chatChannel')`

**`publish(channelName, message)`**
- Publish a message to a channel
- Parameters:
  - `channelName` (string, required): Channel to publish to
  - `message` (any, required): Message content (any JSON-serializable value)
- Example:
  ```javascript
  myWebSocket.publish('chatChannel', {
      text: 'Hello!',
      timestamp: new Date().toISOString()
  });
  ```

#### Complete Example

```cfm
<!DOCTYPE html>
<html>
<head>
    <title>WebSocket Example</title>
</head>
<body>
    <h1>Chat Application</h1>
    <div id="messages"></div>
    <input type="text" id="messageInput">
    <button onclick="sendMessage()">Send</button>

    <script>
    function handleMessage(channelName, message) {
        const div = document.createElement('div');
        div.textContent = message.username + ': ' + message.text;
        document.getElementById('messages').appendChild(div);
    }

    function handleOpen(event) {
        console.log('Connected!');
        // Subscribe to chat channel
        chatClient.subscribe('chatChannel', {username: 'Alice'}, function(err) {
            if (!err) console.log('Subscribed to chat');
        });
    }

    function sendMessage() {
        const text = document.getElementById('messageInput').value;
        chatClient.publish('chatChannel', {
            text: text,
            username: 'Alice',
            timestamp: new Date().toISOString()
        });
        document.getElementById('messageInput').value = '';
    }
    </script>

    <cfwebsocket
        name="chatClient"
        onMessage="handleMessage"
        onOpen="handleOpen">

    <script>
    // Auto-connect when page loads
    chatClient.openConnection();
    </script>
</body>
</html>
```

---

### Message Types

#### Client → Server Messages

**Subscribe**
```json
{
    "type": "subscribe",
    "channelName": "chatChannel",
    "subscriberInfo": {
        "userId": "123",
        "room": "lobby"
    }
}
```

**Publish**
```json
{
    "type": "publish",
    "channelName": "chatChannel",
    "message": {
        "text": "Hello",
        "timestamp": "2025-01-04T12:00:00Z"
    }
}
```

**Unsubscribe**
```json
{
    "type": "unsubscribe",
    "channelName": "chatChannel"
}
```

#### Server → Client Messages

**Subscribed Confirmation**
```json
{
    "type": "subscribed",
    "channelName": "chatChannel"
}
```

**Unsubscribed Confirmation**
```json
{
    "type": "unsubscribed",
    "channelName": "chatChannel"
}
```

**Broadcast Message**
```json
{
    "type": "message",
    "channelName": "chatChannel",
    "message": {
        "text": "Hello",
        "timestamp": "2025-01-04T12:00:00Z"
    }
}
```

**Error**
```json
{
    "type": "error",
    "message": "Channel not found: chatChannel"
}
```

---

## Server-Side

### Configuration

WebSocket support is configured in `bluedragon.xml`:

```xml
<system>
    <websocket>
        <!-- Enable/disable WebSocket server -->
        <enabled>true</enabled>

        <!-- Port for WebSocket connections -->
        <port>8580</port>
    </websocket>
</system>
```

**Configuration Options:**

| Setting | Default | Description |
|---------|---------|-------------|
| `enabled` | `false` | Enable or disable the WebSocket server |
| `port` | `8580` | Port for WebSocket connections |

**After changing configuration:**
1. Edit `webapp/WEB-INF/bluedragon/bluedragon.xml`
2. Add or modify the `<websocket>` section
3. Restart OpenBD for changes to take effect

---

### CFML Functions

#### wsRegisterChannel

Register a WebSocket channel for client subscriptions.

**Syntax:**
```cfml
wsRegisterChannel(channelName [, listener])
```

**Parameters:**
- `channelName` (string, required): Name of the channel to register
- `listener` (string, optional): Path to a Channel Listener CFC

**Returns:** `boolean`
- `true` if channel was registered
- `false` if channel already exists

**Examples:**

```cfml
<!--- Basic channel registration --->
<cfset result = wsRegisterChannel("chatChannel")>

<!--- Register with a Channel Listener CFC --->
<cfset result = wsRegisterChannel(
    channelName: "moderatedChat",
    listener: "OPENBD.websocket.ModeratedChannelListener"
)>
```

```javascript
// CFScript
result = wsRegisterChannel("notificationChannel");

result = wsRegisterChannel(
    channelName="privateMessages",
    listener="myapp.websocket.PrivateMessageListener"
);
```

**Notes:**
- Channels must be registered before clients can subscribe
- Channel names are case-sensitive
- Typically called in `Application.cfc`'s `onApplicationStart()`
- Channel Listener path is relative to webroot (e.g., `OPENBD.websocket.AuthChannelListener`)

---

#### wsPublish

Publish a message to a WebSocket channel from server-side CFML code.

**Syntax:**
```cfml
wsPublish(channelName, message)
```

**Parameters:**
- `channelName` (string, required): Name of the channel to publish to
- `message` (any, required): Message to publish (can be any CFML data type)

**Returns:** `boolean`
- `true` if message was published successfully
- `false` otherwise

**Examples:**

```cfml
<!--- Publish a simple string --->
<cfset wsPublish("alerts", "Server maintenance in 5 minutes")>

<!--- Publish a struct --->
<cfset message = {
    type: "notification",
    text: "New order received",
    orderId: 12345,
    timestamp: now()
}>
<cfset wsPublish("notifications", message)>

<!--- Publish an array --->
<cfset wsPublish("dataFeed", [100, 200, 300])>
```

```javascript
// CFScript
wsPublish("chatChannel", "Welcome to the chat!");

message = {
    type: "alert",
    severity: "high",
    message: "Critical system error"
};
wsPublish("adminAlerts", message);
```

**Notes:**
- Channel must be registered with `wsRegisterChannel()` first
- Message can be any JSON-serializable CFML data type (string, number, struct, array, etc.)
- All subscribers of the channel will receive the message
- Useful for server-initiated notifications, scheduled tasks, background jobs, etc.

---

#### wsGetSubscribers

Get a list of all subscribers currently subscribed to a channel.

**Syntax:**
```cfml
wsGetSubscribers(channelName)
```

**Parameters:**
- `channelName` (string, required): Name of the channel

**Returns:** `array`
- Array of structs, each representing a subscriber
- Empty array if channel doesn't exist or has no subscribers

**Subscriber Struct Fields:**
- `connectionId` (string): Unique connection ID
- `subscriberInfo` (struct, optional): Custom data provided during subscription
- `subscribedChannelCount` (numeric): Number of channels this connection is subscribed to
- `connected` (boolean): Whether the connection is still active

**Examples:**

```cfml
<!--- Get all subscribers --->
<cfset subscribers = wsGetSubscribers("chatChannel")>
<cfoutput>Channel has #arrayLen(subscribers)# subscribers</cfoutput>

<!--- Display subscriber details --->
<cfloop array="#subscribers#" index="sub">
    <cfoutput>
        Connection: #sub.connectionId#<br>
        Subscribed to #sub.subscribedChannelCount# channel(s)<br>
        <cfif structKeyExists(sub, "subscriberInfo")>
            User: #sub.subscriberInfo.username#<br>
        </cfif>
    </cfoutput>
</cfloop>
```

```javascript
// CFScript
subscribers = wsGetSubscribers("chatChannel");

for (sub in subscribers) {
    writeOutput("Connection: " & sub.connectionId & "<br>");

    if (structKeyExists(sub, "subscriberInfo")) {
        writeDump(sub.subscriberInfo);
    }
}
```

**Notes:**
- Returns real-time snapshot of current subscribers
- Useful for analytics, admin dashboards, and debugging
- `subscriberInfo` only exists if client provided it during subscription

---

#### wsGetAllChannels

Get a list of all registered WebSocket channels.

**Syntax:**
```cfml
wsGetAllChannels()
```

**Parameters:** None

**Returns:** `array`
- Array of channel names (strings)
- Empty array if no channels are registered

**Examples:**

```cfml
<!--- List all channels --->
<cfset channels = wsGetAllChannels()>
<cfoutput>
    <h3>Registered Channels (#arrayLen(channels)#)</h3>
    <ul>
        <cfloop array="#channels#" index="channelName">
            <cfset subCount = arrayLen(wsGetSubscribers(channelName))>
            <li>#channelName# - #subCount# subscriber(s)</li>
        </cfloop>
    </ul>
</cfoutput>
```

```javascript
// CFScript
channels = wsGetAllChannels();

for (channelName in channels) {
    subscribers = wsGetSubscribers(channelName);
    writeOutput(channelName & ": " & arrayLen(subscribers) & " subscribers<br>");
}
```

**Notes:**
- Useful for admin interfaces and diagnostics
- Returns all channels registered with `wsRegisterChannel()`
- Channel names are returned in no particular order

---

### Channel Listener CFCs

Channel Listener CFCs provide advanced control over WebSocket channels through lifecycle hooks that intercept and modify subscription, publishing, and message delivery.

#### Overview

**Purpose:**
- Authorization and authentication
- Message validation and transformation
- Room-based filtering
- Content moderation
- Message history storage
- Custom business logic

**Base Class:** `OPENBD.websocket.ChannelListener`

All custom Channel Listeners must extend this base component.

#### Lifecycle Hooks

Channel Listener CFCs can override five lifecycle hooks:

**1. allowSubscribe(subscriberInfo)**
- **When Called:** Before a client is allowed to subscribe
- **Purpose:** Authorization check
- **Return:** `boolean` - `true` to allow, `false` to reject
- **Use Cases:** User authentication, permission checks, subscription limits

**2. allowPublish(publisherInfo)**
- **When Called:** Before a client is allowed to publish a message
- **Purpose:** Authorization check
- **Return:** `boolean` - `true` to allow, `false` to reject
- **Use Cases:** User authentication, rate limiting, permission checks

**3. beforePublish(publisherInfo, message)**
- **When Called:** After `allowPublish()` succeeds, before broadcasting
- **Purpose:** Message transformation and validation
- **Return:** `any` - The transformed message
- **Use Cases:** Add timestamps, sanitize content, validate structure, store history

**4. canSendMessage(subscriberInfo, message)**
- **When Called:** For each subscriber, to filter messages
- **Purpose:** Per-subscriber filtering
- **Return:** `boolean` - `true` to send, `false` to skip
- **Use Cases:** Room-based filtering, private messages, permissions

**5. beforeSendMessage(subscriberInfo, message)**
- **When Called:** For each subscriber, before sending
- **Purpose:** Per-subscriber message transformation
- **Return:** `any` - The transformed message for this subscriber
- **Use Cases:** Hide private fields, customize content per user

#### Hook Parameters

**subscriberInfo (struct):**
- Custom data provided by client during subscription
- May include: `userId`, `username`, `room`, `sessionId`, etc.
- Structure defined by client application

**publisherInfo (struct):**
- `connectionId` (string): Unique ID of the publishing connection
- `subscriberInfo` (struct): The publisher's subscription data

**message (any):**
- The message being published or sent
- Can be any type: string, struct, array, number, etc.

#### Creating a Channel Listener

**Basic Template:**

```cfml
<cfcomponent extends="OPENBD.websocket.ChannelListener">

    <cffunction name="allowSubscribe" returntype="boolean">
        <cfargument name="subscriberInfo" type="struct" required="true">

        <!--- Your authorization logic --->
        <cfreturn true>
    </cffunction>

    <cffunction name="beforePublish" returntype="any">
        <cfargument name="publisherInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">

        <!--- Your transformation logic --->
        <cfreturn arguments.message>
    </cffunction>

</cfcomponent>
```

#### Example: Authentication Channel Listener

```cfml
<!---
  AuthChannelListener.cfc
  Only allow authenticated users to subscribe and publish
--->
<cfcomponent extends="OPENBD.websocket.ChannelListener">

    <cffunction name="allowSubscribe" returntype="boolean">
        <cfargument name="subscriberInfo" type="struct" required="true">

        <!--- Require userId in subscriber info --->
        <cfif NOT structKeyExists(arguments.subscriberInfo, "userId")>
            <cfreturn false>
        </cfif>

        <!--- Verify user is logged in --->
        <cfif NOT structKeyExists(session, "userLoggedIn") OR NOT session.userLoggedIn>
            <cfreturn false>
        </cfif>

        <cfreturn true>
    </cffunction>

    <cffunction name="allowPublish" returntype="boolean">
        <cfargument name="publisherInfo" type="struct" required="true">

        <!--- Verify publisher is authenticated --->
        <cfif NOT structKeyExists(arguments.publisherInfo.subscriberInfo, "userId")>
            <cfreturn false>
        </cfif>

        <cfreturn true>
    </cffunction>

</cfcomponent>
```

**Usage:**
```cfml
<cfset wsRegisterChannel(
    channelName: "privateChannel",
    listener: "OPENBD.websocket.AuthChannelListener"
)>
```

#### Example: Message History Listener

```cfml
<!---
  ChatHistoryListener.cfc
  Store message history and add timestamps
--->
<cfcomponent extends="OPENBD.websocket.ChannelListener">

    <cffunction name="beforePublish" returntype="any">
        <cfargument name="publisherInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">

        <!--- Add timestamp to message --->
        <cfif isStruct(arguments.message)>
            <cfset arguments.message.timestamp = now()>
            <cfset arguments.message.timestampFormatted = dateFormat(now(), "yyyy-mm-dd") & " " & timeFormat(now(), "HH:mm:ss")>
        </cfif>

        <!--- Store in server-side history --->
        <cflock name="chatHistory" type="exclusive" timeout="5">
            <cfif NOT structKeyExists(server, "chatHistory")>
                <cfset server.chatHistory = []>
            </cfif>

            <!--- Keep last 100 messages --->
            <cfif arrayLen(server.chatHistory) GTE 100>
                <cfset arrayDeleteAt(server.chatHistory, 1)>
            </cfif>

            <cfset arrayAppend(server.chatHistory, arguments.message)>
        </cflock>

        <cfreturn arguments.message>
    </cffunction>

</cfcomponent>
```

#### Example: Room-Based Channel Listener

```cfml
<!---
  RoomChannelListener.cfc
  Filter messages so users only receive messages from their room
--->
<cfcomponent extends="OPENBD.websocket.ChannelListener">

    <cffunction name="canSendMessage" returntype="boolean">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">

        <!--- Only send message if subscriber is in the same room --->
        <cfif isStruct(arguments.message) AND structKeyExists(arguments.message, "room")>
            <cfif structKeyExists(arguments.subscriberInfo, "room")>
                <cfreturn arguments.subscriberInfo.room EQ arguments.message.room>
            </cfif>
        </cfif>

        <!--- Default: send to all --->
        <cfreturn true>
    </cffunction>

</cfcomponent>
```

**Usage:**
```cfml
<cfset wsRegisterChannel(
    channelName: "multiRoomChat",
    listener: "myapp.websocket.RoomChannelListener"
)>
```

**Client-side subscription:**
```javascript
// Alice subscribes to lobby
ws.send(JSON.stringify({
    type: 'subscribe',
    channelName: 'multiRoomChat',
    subscriberInfo: { username: 'Alice', room: 'lobby' }
}));

// Bob subscribes to general
ws.send(JSON.stringify({
    type: 'subscribe',
    channelName: 'multiRoomChat',
    subscriberInfo: { username: 'Bob', room: 'general' }
}));

// Alice publishes to lobby - only lobby subscribers receive it
ws.send(JSON.stringify({
    type: 'publish',
    channelName: 'multiRoomChat',
    message: { text: 'Hello lobby!', room: 'lobby', username: 'Alice' }
}));
```

#### Example: Content Moderation Listener

```cfml
<!---
  ModeratedChannelListener.cfc
  Filter profanity and validate message structure
--->
<cfcomponent extends="OPENBD.websocket.ChannelListener">

    <cffunction name="beforePublish" returntype="any">
        <cfargument name="publisherInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">

        <!--- Only process struct messages with text --->
        <cfif NOT isStruct(arguments.message) OR NOT structKeyExists(arguments.message, "text")>
            <cfreturn arguments.message>
        </cfif>

        <!--- Filter profanity --->
        <cfset var text = arguments.message.text>
        <cfset var profanityList = ["badword1", "badword2", "badword3"]>

        <cfloop array="#profanityList#" index="word">
            <cfset text = replaceNoCase(text, word, "***", "ALL")>
        </cfloop>

        <!--- Update message --->
        <cfset arguments.message.text = text>
        <cfset arguments.message.moderated = true>

        <cfreturn arguments.message>
    </cffunction>

</cfcomponent>
```

#### Execution Flow

When a client publishes a message, the hooks are called in this order:

```
Client publishes message
        ↓
1. allowPublish(publisherInfo)
        ↓ (if false, reject)
2. beforePublish(publisherInfo, message)
        ↓ (transform message)
For each subscriber:
    3. canSendMessage(subscriberInfo, message)
        ↓ (if false, skip this subscriber)
    4. beforeSendMessage(subscriberInfo, message)
        ↓ (transform for this subscriber)
    Send to subscriber
```

#### Best Practices

1. **Performance:**
   - Keep hooks lightweight - they're called for every message
   - Use caching for expensive operations
   - Avoid database calls in `canSendMessage()` (called per subscriber)

2. **Security:**
   - Always validate `subscriberInfo` structure
   - Use `allowSubscribe()` and `allowPublish()` for authorization
   - Sanitize user input in `beforePublish()`
   - Never trust client-provided data

3. **Error Handling:**
   - Add try/catch blocks in hooks
   - Return safe defaults on errors
   - Log errors for debugging

4. **Thread Safety:**
   - Use `<cflock>` for shared resources (server scope, application scope)
   - Keep locks short and specific

5. **Storage:**
   - Use SERVER scope for WebSocket-accessible data
   - APPLICATION scope works but be aware of scope access
   - Consider external storage (database, Redis) for persistence

#### Channel Listener Registration

**In Application.cfc:**
```cfml
<cfcomponent>
    <cfset this.name = "MyApp">

    <cffunction name="onApplicationStart" returntype="boolean">
        <!--- Register channels with listeners --->
        <cfset wsRegisterChannel("chatChannel", "myapp.websocket.ChatHistoryListener")>
        <cfset wsRegisterChannel("privateChannel", "OPENBD.websocket.AuthChannelListener")>
        <cfset wsRegisterChannel("moderatedChannel", "OPENBD.websocket.ModeratedChannelListener")>

        <cfreturn true>
    </cffunction>
</cfcomponent>
```

**CFScript version:**
```javascript
component {
    this.name = "MyApp";

    function onApplicationStart() {
        wsRegisterChannel("chatChannel", "myapp.websocket.ChatHistoryListener");
        wsRegisterChannel("privateChannel", "OPENBD.websocket.AuthChannelListener");
        wsRegisterChannel("moderatedChannel", "OPENBD.websocket.ModeratedChannelListener");

        return true;
    }
}
```

---

## Additional Resources

- **Demo Applications:** `webapp/demo/websocket/`
- **Simple Example:** `webapp/demo/websocket/simple/`
- **Base Listener CFC:** `webapp/OPENBD/websocket/ChannelListener.cfc`
- **Example Listeners:** `webapp/OPENBD/websocket/` (Auth, Moderated, Room-based)
- **Configuration Example:** `claude/websocket_config_example.xml`
