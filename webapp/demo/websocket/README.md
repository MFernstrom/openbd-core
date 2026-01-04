# WebSocket Chat Demo

A simple multi-room chat application demonstrating OpenBD WebSocket functionality.

## Overview

This demo showcases the core features of OpenBD's WebSocket implementation through a real-time chat application with multiple rooms. Users can join chat rooms, send messages, switch between rooms, and see full message history.

## Features

- **Two Chat Rooms**: Lobby (default) and General
- **Real-Time Messaging**: Instant message broadcasting to all users in the same room
- **Message History**: Full conversation history persists across room switches
- **Room Switching**: Seamlessly switch between rooms with automatic subscription management
- **Clean UI**: Modern, responsive interface with visual feedback
- **Username Support**: Customizable usernames for each session

## Files

```
webapp/demo/websocket/
├── README.md                    # This file
├── Application.cfc              # Application lifecycle management (auto-initialization)
├── init.cfm                     # Status page and manual reinitialization
├── index.html                   # Main chat application
├── getHistory.cfm               # API endpoint for message history
└── ChatHistoryListener.cfc      # Channel listener for message storage
```

## Architecture

### WebSocket Flow

1. **Connection**: Client connects to WebSocket server on port 8580 (ws://hostname:8580/openbd/ws)
2. **Subscription**: Client subscribes to a channel (Lobby or General)
   - Initial subscription delayed 500ms to allow channel registration
   - Auto-retry with exponential backoff if channel not ready (up to 3 attempts)
3. **Publishing**: User sends message → Server broadcasts to all subscribers in that room
4. **History**: Server stores messages in `server.chatHistory` via ChatHistoryListener
5. **Room Switch**: Unsubscribe from old room → Subscribe to new room → Load history

### Components

#### Application.cfc
- Manages application lifecycle and settings
- **Auto-initialization** on first request via `onApplicationStart()`
- Registers "Lobby" and "General" channels automatically
- Attaches ChatHistoryListener to both channels
- Initializes server.chatHistory storage (uses SERVER scope)
- Provides URL-based reinitialization (`?reinit=true`)
- Production-ready structure with error handling

#### ChatHistoryListener.cfc
- Extends `OPENBD.websocket.ChannelListener`
- Implements `beforePublish()` hook to add timestamps and store messages
- Stores up to 100 messages per room in `server.chatHistory`
- Uses SERVER scope (accessible from WebSocket context)
- Sanitizes usernames and message text

#### init.cfm
- Status and diagnostics page
- Displays current application state and message counts
- Provides manual reinitialization option
- Shows debug information when requested
- **Optional**: Not required for normal operation (auto-init via Application.cfc)

#### getHistory.cfm
- REST API endpoint for retrieving message history
- Accepts `?room=<roomName>` parameter
- Returns JSON array of messages with timestamps

#### index.html
- Single-page chat application
- WebSocket client implementation
- Room switching and subscription management
- Auto-retry logic for failed subscriptions
- Message history display
- Real-time message broadcasting

## Setup Instructions

### 1. Ensure WebSocket is Enabled

Check your `bluedragon.xml` configuration file:

```xml
<websocket>
  <enabled>true</enabled>
  <port>8580</port>
</websocket>
```

Restart OpenBD if you made changes.

### 2. Open the Chat Application

**That's it!** Just navigate to:

```
http://localhost:8080/demo/websocket/index.html
```

The application will automatically initialize on first request thanks to `Application.cfc`.

### 3. Join the Chat

1. Enter a username
2. Click "Join Chat"
3. You'll automatically join the Lobby room
4. Start chatting!

### 4. Test Multi-User Chat

Open the same URL in multiple browser tabs or different browsers to simulate multiple users.

### Optional: Check Application Status

Visit the status page to see channel registration status and message counts:

```
http://localhost:8080/demo/websocket/init.cfm
```

This page also allows manual reinitialization if needed (`?reinit=true`).

## Usage

### Sending Messages

1. Type your message in the input field at the bottom
2. Press Enter or click "Send"
3. Your message appears instantly for all users in the same room

### Switching Rooms

1. Click on the "Lobby" or "General" tabs
2. The chat window clears and loads the new room's history
3. You're automatically unsubscribed from the old room and subscribed to the new room

### Message History

- Message history is stored server-side in the SERVER scope
- When you switch rooms, the full history loads automatically
- History persists until the server restarts
- Maximum 100 messages per room

## WebSocket API Reference

### Subscribe to a Channel

```javascript
const subscribeMsg = {
  type: 'subscribe',
  channelName: 'Lobby',
  subscriberInfo: {
    username: 'Alice',
    room: 'Lobby'
  }
};
ws.send(JSON.stringify(subscribeMsg));
```

### Publish a Message

```javascript
const publishMsg = {
  type: 'publish',
  channelName: 'Lobby',
  message: {
    username: 'Alice',
    text: 'Hello everyone!',
    room: 'Lobby'
  }
};
ws.send(JSON.stringify(publishMsg));
```

### Unsubscribe from a Channel

```javascript
const unsubscribeMsg = {
  type: 'unsubscribe',
  channelName: 'Lobby'
};
ws.send(JSON.stringify(unsubscribeMsg));
```

### Receiving Messages

```javascript
ws.onmessage = function(event) {
  const msg = JSON.parse(event.data);

  if (msg.type === 'message') {
    // Display the message
    console.log(msg.message.username + ': ' + msg.message.text);
  } else if (msg.type === 'subscribed') {
    console.log('Subscribed to:', msg.channelName);
  } else if (msg.type === 'unsubscribed') {
    console.log('Unsubscribed from:', msg.channelName);
  } else if (msg.type === 'error') {
    console.error('Error:', msg.message);
  }
};
```

## Customization

### Adding More Rooms

1. **Edit init.cfm**: Add registration for new channel
   ```cfm
   <cfset result = wsRegisterChannel(
     channelName: "YourNewRoom",
     listener: "ChatHistoryListener"
   )>
   ```

2. **Edit index.html**: Add new tab in roomTabs section
   ```html
   <button class="roomTab" data-room="YourNewRoom" onclick="switchRoom('YourNewRoom')">
     Your New Room
   </button>
   ```

3. **Reinitialize**: Visit init.cfm to register the new channel

### Customizing Message Storage

Edit `ChatHistoryListener.cfc` to change:
- Maximum messages per room (currently 100)
- Message sanitization rules
- Additional metadata (IP address, session info, etc.)

### Styling

All styles are in `index.html` within the `<style>` tag. Customize colors, fonts, and layout as needed.

## Troubleshooting

### Cannot Connect to WebSocket

- **Check Port**: Ensure WebSocket is running on port 8580
- **Check Config**: Verify `bluedragon.xml` has WebSocket enabled with port 8580
- **Check Firewall**: Ensure port 8580 is not blocked
- **Check Endpoint**: Verify connection to `ws://hostname:8580/openbd/ws`
- **First-Time Connection**: On first app start, there's a 500ms delay before subscribing to allow channels to register. The app will auto-retry up to 3 times if needed.

### Messages Not Appearing

- **Check Console**: Open browser DevTools and check for JavaScript errors
- **Check Subscription**: Ensure you're subscribed to the channel (check logs)
- **Check Room**: Ensure you're in the same room as the sender

### History Not Loading

- **Check Application**: Visit init.cfm to see if application is initialized
- **Check Server Scope**: Visit init.cfm?debug=true to inspect server.chatHistory
- **Check CFC Path**: Ensure ChatHistoryListener.cfc is in webapp/demo/websocket/
- **Force Reinit**: Visit index.html?reinit=true to force reinitialization

### Channels Not Registered

- **CFC Path**: Make sure ChatHistoryListener.cfc is in the correct location
- **Restart Server**: Try restarting OpenBD after creating the files
- **Check Logs**: Check `bluedragon.log` for error messages

## Technical Notes

### Message Flow

1. **Client** → `publish` message → **WebSocket Server**
2. **Server** → `ChatHistoryListener.beforePublish()` → Add timestamp, store in history
3. **Server** → Broadcast to all subscribers in that channel
4. **Server** → Each subscriber receives message via `ws.onmessage`

### Storage

- Messages are stored in `server.chatHistory[channelName]`
- Uses SERVER scope (accessible from WebSocket context)
- Storage is in-memory and cleared on server restart
- For production, consider persisting to a database

### Security Considerations

This is a demo application. For production use:
- Add authentication/authorization
- Implement rate limiting
- Sanitize user input server-side
- Add CSRF protection
- Use SSL/TLS (wss://)
- Validate message size limits
- Add profanity filtering

## Production-Ready Pattern

This demo uses a **production-ready application structure**:

- **Application.cfc**: Manages lifecycle with automatic initialization
- **onApplicationStart()**: Auto-registers channels on first request
- **onRequestStart()**: Provides URL-based reinitialization
- **onError()**: Global error handling with logging
- **Session Management**: Tracks user sessions
- **Proper Locking**: Thread-safe storage access with named locks
- **SERVER Scope**: Uses SERVER scope for WebSocket context compatibility
- **Error Logging**: Comprehensive logging for debugging

To deploy to production:
1. Add authentication in `onRequestStart()`
2. Replace in-memory storage with database persistence
3. Add SSL/TLS configuration
4. Implement rate limiting
5. Add monitoring and alerting

## Learning Resources

### Key Concepts Demonstrated

1. **Application.cfc Pattern**: Production-ready lifecycle management
2. **Channel Registration**: `wsRegisterChannel(channelName, listener)`
3. **Channel Listeners**: Extend `OPENBD.websocket.ChannelListener`
4. **Lifecycle Hooks**: `beforePublish()`, `allowSubscribe()`, etc.
5. **Subscribe/Unsubscribe**: Managing channel subscriptions
6. **Publishing**: Broadcasting messages to subscribers
7. **Message History**: Storing and retrieving past messages

### Extending This Demo

Ideas for enhancements:
- Add private messaging between users
- Implement typing indicators
- Add file/image sharing
- Create user presence (online/offline status)
- Add message reactions (like, emoji)
- Implement admin moderation tools
- Add user roles and permissions
- Create persistent history with database storage

## License

This demo is part of the OpenBD project and follows the same license.

## Support

For issues or questions:
- Check the main OpenBD documentation
- Review WebSocket implementation in `/claude/websocket_todo.md`
- Examine test files in `/webapp/websocket_*.cfm`
