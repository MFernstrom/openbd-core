# Simple WebSocket Example

A minimal demonstration of OpenBD's WebSocket functionality using the `<cfwebsocket>` tag. This example shows the essential concepts needed to build real-time applications using WebSockets with the cfwebsocket tag for simplified integration.

## What This Example Does

This example demonstrates a basic publish/subscribe pattern using WebSockets:

1. **Connect** to the WebSocket server
2. **Subscribe** to a channel named "notifications"
3. **Publish** messages to the channel
4. **Receive** messages from other subscribers in real-time
5. **Unsubscribe** from the channel
6. **Disconnect** from the server

Open this page in multiple browser tabs to see real-time message broadcasting in action!

## Files

```
webapp/demo/websocket/simple/
├── README.md           # This file - documentation
├── Application.cfc     # Server-side: Registers the WebSocket channel (cfscript)
├── init.cfm            # Initialization and status page
├── index.cfm           # Client-side: Uses cfwebsocket tag for WebSocket integration
└── style.css           # CSS styles for the interface
```

## Quick Start

### 1. Ensure WebSocket is Enabled

Check your `bluedragon.xml` configuration file (in `webapp/WEB-INF/bluedragon/`):

```xml
<websocket>
  <enabled>true</enabled>
  <port>8580</port>
</websocket>
```

If you make changes, restart OpenBD.

### 2. Verify Channel Registration

First, check that the WebSocket channel is properly registered:
```
http://localhost:8080/demo/websocket/simple/init.cfm
```

This page will:
- Manually register the "notifications" channel if needed
- Show all registered channels
- Display application status
- Provide diagnostic information

**Important:** If you see "No channels registered" or errors, use the init.cfm page to manually register the channel before proceeding.

### 3. Open the Application

Navigate to:
```
http://localhost:8080/demo/websocket/simple/index.cfm
```

The application will automatically initialize on first access, but if you have issues, visit init.cfm first (step 2).

### 4. Try It Out

1. Click **"Connect"** to establish a WebSocket connection
2. Click **"Subscribe to 'notifications'"** to join the channel
3. Type a message and click **"Publish Message"**
4. Open the same URL in another browser tab and repeat steps 1-3
5. Watch messages appear in real-time on both tabs!

## Basic Setup Flow

Here's what happens behind the scenes:

### Server-Side Initialization (Application.cfc)

```
Application Starts
      ↓
onApplicationStart() is called
      ↓
wsRegisterChannel() registers "notifications" channel
      ↓
Channel is ready to accept subscribers
```

When the first user accesses the application, `Application.cfc` automatically runs and registers the "notifications" channel using the `wsRegisterChannel()` function.

### Client-Side Flow (index.cfm with cfwebsocket)

```
Page loads
      ↓
<cfwebsocket> tag generates JavaScript WebSocket client object (simpleWS)
      ↓
User clicks "Connect"
      ↓
simpleWS.openConnection() establishes connection to ws://hostname:8580/openbd/ws
      ↓
handleWsOpen() callback is triggered
      ↓
User clicks "Subscribe"
      ↓
simpleWS.subscribe(channelName, subscriberInfo, callback) subscribes to channel
      ↓
Server confirms subscription via callback
      ↓
User types message and clicks "Publish"
      ↓
simpleWS.publish(channelName, message) sends message to server
      ↓
Server broadcasts message to ALL subscribers
      ↓
All clients receive the message via handleWsMessage() callback
```

## The cfwebsocket Tag

This example uses the `<cfwebsocket>` tag, which simplifies WebSocket integration by automatically generating JavaScript code for WebSocket connections.

### What is cfwebsocket?

The `<cfwebsocket>` tag is an OpenBD-specific CFML tag that:
- Generates a JavaScript WebSocket client object
- Provides high-level methods for WebSocket operations
- Handles connection management automatically
- Simplifies event handling with named callbacks

### Basic Usage

```cfm
<!--- Define event handlers BEFORE the tag --->
<script>
function handleWsMessage(channelName, message) {
    console.log('Message from', channelName, message);
}

function handleWsOpen(event) {
    console.log('Connected!');
}

function handleWsClose(event) {
    console.log('Disconnected');
}

function handleWsError(error) {
    console.error('Error:', error);
}
</script>

<!--- Generate the WebSocket client --->
<cfwebsocket
    name="myWebSocket"
    onMessage="handleWsMessage"
    onOpen="handleWsOpen"
    onClose="handleWsClose"
    onError="handleWsError">

<!--- Use the generated object --->
<script>
// Connect to server
myWebSocket.openConnection();

// Subscribe to a channel
myWebSocket.subscribe('channelName', {userId: 123}, function(err, result) {
    if (!err) console.log('Subscribed!');
});

// Publish a message
myWebSocket.publish('channelName', {text: 'Hello!'});

// Unsubscribe
myWebSocket.unsubscribe('channelName');

// Disconnect
myWebSocket.closeConnection();
</script>
```

### Generated Methods

The `<cfwebsocket>` tag creates an object with these methods:

| Method | Description | Example |
|--------|-------------|---------|
| `openConnection()` | Connect to WebSocket server | `simpleWS.openConnection()` |
| `closeConnection()` | Disconnect from server | `simpleWS.closeConnection()` |
| `subscribe(channel, info, callback)` | Subscribe to a channel | `simpleWS.subscribe('chat', {user: 'Alice'}, fn)` |
| `unsubscribe(channel)` | Unsubscribe from a channel | `simpleWS.unsubscribe('chat')` |
| `publish(channel, message)` | Publish a message to channel | `simpleWS.publish('chat', {text: 'Hi!'})` |

### Event Handlers

| Handler | When Called | Parameters |
|---------|-------------|------------|
| `onMessage` | Message received from channel | `(channelName, message)` |
| `onOpen` | Connection established | `(event)` |
| `onClose` | Connection closed | `(event)` |
| `onError` | Error occurred | `(error)` |

## WebSocket Functionality Explained

### 1. Channel Registration (Server-Side)

**Function:** `wsRegisterChannel()`

**What it does:** Creates a named channel that clients can subscribe to.

**Where:** In `Application.cfc`'s `onApplicationStart()` method

**Code Example:**
```coldfusion
<cfset var result = wsRegisterChannel(channelName: "notifications")>
```

**Parameters:**
- `channelName` (required): The name of the channel (e.g., "notifications", "chat", "updates")
- `listener` (optional): A CFC that handles channel events (not used in this simple example)

**Think of it like:** Creating a radio station. Before people can tune in, the station must be set up and broadcasting.

---

### 2. WebSocket Connection with cfwebsocket (Client-Side)

**What it does:** Establishes a persistent, two-way connection between the browser and server using the cfwebsocket-generated object.

**Where:** In `index.cfm`'s `connect()` function

**Code Example (using cfwebsocket):**
```javascript
// Using the cfwebsocket-generated object
function connect() {
    simpleWS.openConnection();
}
```

**Event Handlers (defined before <cfwebsocket> tag):**
```javascript
function handleWsOpen(event) {
    console.log('Connected!');
    // Enable subscribe button, etc.
}

function handleWsClose(event) {
    console.log('Disconnected');
}

function handleWsError(error) {
    console.error('Error:', error);
}

function handleWsMessage(channelName, message) {
    console.log('Message from', channelName, message);
}
```

**The cfwebsocket tag:**
```cfm
<cfwebsocket
    name="simpleWS"
    onMessage="handleWsMessage"
    onOpen="handleWsOpen"
    onClose="handleWsClose"
    onError="handleWsError">
```

**URL Format:** `ws://hostname:port/openbd/ws` (automatically handled by cfwebsocket)
- `ws://` - WebSocket protocol (use `wss://` for secure connections)
- `hostname` - Your server's hostname or IP (automatically detected)
- `:8580` - WebSocket port (configured in bluedragon.xml)
- `/openbd/ws` - OpenBD's WebSocket endpoint (always the same)

**Think of it like:** Making a phone call. The cfwebsocket tag is like having speed dial - it simplifies the process!

---

### 3. Subscribe to a Channel (using cfwebsocket)

**What it does:** Registers your connection to receive messages from a specific channel.

**Where:** In `index.cfm`'s `subscribeToChannel()` function

**Code Example (using cfwebsocket):**
```javascript
function subscribeToChannel() {
    simpleWS.subscribe(
        'notifications',                    // Channel name
        {                                   // Subscriber info (optional)
            userAgent: navigator.userAgent,
            timestamp: new Date().toISOString()
        },
        function(err, result) {             // Callback function
            if (err) {
                console.error('Subscribe error:', err);
            } else {
                console.log('Subscribed successfully!');
            }
        }
    );
}
```

**Method Signature:**
```javascript
simpleWS.subscribe(channelName, subscriberInfo, callback)
```

**Parameters:**
- `channelName` (required): The channel name (must match a registered channel)
- `subscriberInfo` (optional): Any JSON object with information about the subscriber
- `callback` (required): Function called with `(err, result)` when subscription completes

**Callback Response:**
- Success: `err` is null/undefined, `result` contains confirmation
- Failure: `err` contains error message (e.g., "Channel not found")

**Think of it like:** Subscribing to a YouTube channel. The cfwebsocket method makes it as easy as clicking a button!

---

### 4. Publish a Message (using cfwebsocket)

**What it does:** Sends a message to all subscribers of a channel.

**Where:** In `index.cfm`'s `publishMessage()` function

**Code Example (using cfwebsocket):**
```javascript
function publishMessage() {
    const messageText = document.getElementById('messageInput').value;

    simpleWS.publish('notifications', {
        text: messageText,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent
    });
}
```

**Method Signature:**
```javascript
simpleWS.publish(channelName, message)
```

**Parameters:**
- `channelName` (required): The channel to publish to (you must be subscribed)
- `message` (required): Your message content (can be any JSON-serializable value)

**What the message can contain:**
- A simple string: `simpleWS.publish('notifications', 'Hello')`
- A number: `simpleWS.publish('notifications', 42)`
- An object: `simpleWS.publish('notifications', { text: "Hi", user: "Alice" })`
- An array: `simpleWS.publish('notifications', [1, 2, 3])`

**Broadcasting:** When you publish, the server sends your message to **ALL subscribers** of that channel (including you).

**Think of it like:** Posting to a group chat. The cfwebsocket method makes publishing as simple as one function call!

---

### 5. Receiving Messages (using cfwebsocket)

**What it does:** Handles incoming messages from subscribed channels.

**Where:** In the `handleWsMessage()` callback function (defined before cfwebsocket tag)

**Code Example (using cfwebsocket):**
```javascript
function handleWsMessage(channelName, message) {
    console.log('Received message from channel:', channelName);
    console.log('Message content:', message);

    // Display the message in your UI
    displayMessage(channelName, message);
}
```

**Callback Signature:**
```javascript
function handleWsMessage(channelName, message) { }
```

**Parameters:**
- `channelName`: The channel the message came from (e.g., "notifications")
- `message`: The message content (already parsed as a JavaScript object)

**Note:** With cfwebsocket, you DON'T need to:
- Parse JSON manually (`JSON.parse()` is done automatically)
- Handle different message types (subscribed/unsubscribed/error) manually
- Check message structure - cfwebsocket only calls `onMessage` for actual channel messages

**Subscription/Unsubscription confirmations:** These are handled by the subscribe() callback, not onMessage.

**Errors:** These are handled by the `handleWsError()` callback.

**Think of it like:** Having a personal assistant who filters your mail and only shows you the important letters!

---

### 6. Unsubscribe from a Channel (using cfwebsocket)

**What it does:** Stops receiving messages from a channel.

**Where:** In `index.cfm`'s `unsubscribeFromChannel()` function

**Code Example (using cfwebsocket):**
```javascript
function unsubscribeFromChannel() {
    simpleWS.unsubscribe('notifications');
    console.log('Unsubscribed from notifications');
}
```

**Method Signature:**
```javascript
simpleWS.unsubscribe(channelName)
```

**Parameters:**
- `channelName` (required): The channel to unsubscribe from

**Note:** Unsubscribing does NOT disconnect you from the WebSocket. You can subscribe to other channels or re-subscribe to the same channel later.

**Think of it like:** Unsubscribing from a mailing list. The cfwebsocket method makes it a single, simple function call!

---

### 7. Disconnect (using cfwebsocket)

**What it does:** Closes the WebSocket connection.

**Where:** In `index.cfm`'s `disconnect()` function

**Code Example (using cfwebsocket):**
```javascript
function disconnect() {
    simpleWS.closeConnection();
}
```

**What happens:**
1. The connection is terminated
2. `handleWsClose()` callback is triggered
3. You're automatically unsubscribed from all channels
4. To communicate again, you must reconnect with `simpleWS.openConnection()`

**Think of it like:** Hanging up the phone. The cfwebsocket method ensures a clean disconnect!

---

## Complete Workflow Example (with cfwebsocket)

Here's a complete example of using all the functionality together:

### Server-Side (Application.cfc in cfscript)
```javascript
component {
    this.name = "SimpleWebSocketDemo";

    // This runs automatically when the app starts
    function onApplicationStart() {
        // Register a channel called "notifications"
        var result = wsRegisterChannel(channelName="notifications");
        return true;
    }
}
```

### Client-Side (index.cfm using cfwebsocket)

**Step 1: Define event handlers BEFORE the cfwebsocket tag**
```javascript
<script>
function handleWsMessage(channelName, message) {
    console.log('Received message:', message);
}

function handleWsOpen(event) {
    console.log('Connected!');
}

function handleWsClose(event) {
    console.log('Disconnected!');
}

function handleWsError(error) {
    console.error('Error:', error);
}
</script>
```

**Step 2: Add the cfwebsocket tag**
```cfm
<cfwebsocket
    name="myWS"
    onMessage="handleWsMessage"
    onOpen="handleWsOpen"
    onClose="handleWsClose"
    onError="handleWsError">
```

**Step 3: Use the generated WebSocket object**
```javascript
<script>
// 1. CONNECT to WebSocket server
myWS.openConnection();

// Wait for connection, then subscribe
setTimeout(() => {
    // 2. SUBSCRIBE to the "notifications" channel
    myWS.subscribe('notifications', {}, function(err, result) {
        if (!err) {
            console.log('Subscribed successfully!');

            // 3. PUBLISH a message
            myWS.publish('notifications', {
                text: 'Hello, World!',
                timestamp: new Date().toISOString()
            });
        }
    });
}, 500);

// Messages are received via handleWsMessage() callback
// After 5 seconds, clean up
setTimeout(() => {
    // 4. UNSUBSCRIBE from the channel
    myWS.unsubscribe('notifications');

    // 5. DISCONNECT from WebSocket
    myWS.closeConnection();
}, 5000);
</script>
```

**Benefits of cfwebsocket:**
- No manual JSON parsing/stringifying
- Cleaner, more intuitive API
- Automatic message routing to callbacks
- Error handling built-in
- Less boilerplate code

## Testing Multi-User Real-Time Messaging

To see real-time broadcasting in action:

1. Open `http://localhost:8080/demo/websocket/simple/index.cfm` in **Browser Tab 1**
2. Click "Connect", then "Subscribe to 'notifications'"
3. Open the same URL in **Browser Tab 2**
4. Click "Connect", then "Subscribe to 'notifications'"
5. In **Tab 1**, type a message and click "Publish Message"
6. Watch the message appear in **both Tab 1 and Tab 2** instantly!

This demonstrates that messages are broadcast to **all** subscribers in real-time.

## Common Use Cases

WebSockets are perfect for real-time applications:

- **Chat applications** - Instant messaging between users
- **Live notifications** - Alert users about new events
- **Real-time dashboards** - Update metrics and charts live
- **Collaborative editing** - Multiple users editing the same document
- **Live sports scores** - Push score updates to all viewers
- **Stock tickers** - Stream live price updates
- **Gaming** - Multiplayer game state synchronization
- **IoT monitoring** - Display sensor data in real-time

## Advanced: Adding a Channel Listener

This simple example doesn't use a channel listener, but you can add one to:
- Validate messages before broadcasting
- Add timestamps to messages
- Store message history
- Filter messages based on content
- Implement permissions and access control

See the full chat demo (`webapp/demo/websocket/`) for an example with a `ChatHistoryListener.cfc`.

## Troubleshooting

### "Failed to connect" Error

**Problem:** Can't connect to `ws://localhost:8580/openbd/ws`

**Solutions:**
1. Check that WebSocket is enabled in `bluedragon.xml`:
   ```xml
   <websocket>
     <enabled>true</enabled>
     <port>8580</port>
   </websocket>
   ```
2. Restart OpenBD after changing the configuration
3. Verify the port is not blocked by a firewall
4. Try using your computer's IP address instead of "localhost"

### "Channel not found" Error

**Problem:** Server returns error when subscribing: `{"type":"error","message":"Failed to subscribe to channel: notifications"}`

**Solutions:**
1. **First, visit init.cfm:** Go to `http://localhost:8080/demo/websocket/simple/init.cfm` to check if the channel is registered and manually register it if needed
2. Visit `http://localhost:8080/demo/websocket/simple/index.cfm?reinit=true` to reinitialize the application
3. Check that `Application.cfc` registered the channel correctly
4. Look for errors in OpenBD's log file (`bluedragon.log`) in `webapp/WEB-INF/bluedragon/logs/`

### Messages Not Appearing

**Problem:** Published messages don't show up

**Solutions:**
1. Make sure you're subscribed to the channel (status shows "Subscribed")
2. Check the browser console (F12) for JavaScript errors
3. Verify both tabs are connected and subscribed to the same channel
4. Try refreshing the page

### Application Not Initializing

**Problem:** Channels aren't registered on startup

**Solutions:**
1. **Use init.cfm:** Visit `http://localhost:8080/demo/websocket/simple/init.cfm` to manually register the channel and see diagnostic information
2. Make sure `Application.cfc` is in the correct directory (`webapp/demo/websocket/simple/`)
3. Check the file permissions (must be readable)
4. Look for errors in `bluedragon.log` in `webapp/WEB-INF/bluedragon/logs/`
5. Try visiting the page with `?reinit=true` to force reinitialization

## Key Concepts Summary

| Concept | What It Is | Where It Happens |
|---------|------------|------------------|
| **Channel** | A named communication pathway that clients can subscribe to | Server-side registration |
| **Register** | Creating a channel on the server using `wsRegisterChannel()` | Application.cfc |
| **Connect** | Establishing a WebSocket connection to the server | Client-side JavaScript |
| **Subscribe** | Joining a channel to receive its messages | Client sends message to server |
| **Publish** | Sending a message to all subscribers of a channel | Client sends message to server |
| **Broadcast** | The server distributing a published message to all subscribers | Automatic (server-side) |
| **Unsubscribe** | Leaving a channel (stop receiving messages) | Client sends message to server |
| **Disconnect** | Closing the WebSocket connection | Client-side JavaScript |

## Next Steps

Once you understand this simple example, you can:

1. **Add more channels** - Register multiple channels for different topics
2. **Add a listener** - Create a CFC to process messages before broadcasting
3. **Store message history** - Save messages to a database or server scope
4. **Add authentication** - Verify users before allowing subscription
5. **Build a chat app** - See the full demo at `webapp/demo/websocket/`

## Security Notes

This is a demonstration example. For production use:
- Use secure WebSocket connections (`wss://` instead of `ws://`)
- Implement user authentication
- Validate and sanitize all message content
- Add rate limiting to prevent abuse
- Implement authorization (who can subscribe/publish to which channels)
- Use SSL/TLS certificates

## Further Reading

- Main WebSocket Demo: `webapp/demo/websocket/`
- OpenBD Documentation: [OpenBD Website](http://www.openbluedragon.org/)
- WebSocket API: [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)

---

**Happy coding!** If you have questions or find issues, check the OpenBD documentation or examine the more advanced chat demo.
