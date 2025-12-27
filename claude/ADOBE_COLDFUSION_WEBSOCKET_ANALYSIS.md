# Adobe ColdFusion WebSocket Implementation Analysis

**Document Created:** 2025-12-27
**Purpose:** Understanding Adobe ColdFusion's WebSocket implementation for potential OpenBD implementation

---

## Table of Contents

1. [Introduction & History](#introduction--history)
2. [Architecture Overview](#architecture-overview)
3. [Core Components](#core-components)
4. [Configuration & Setup](#configuration--setup)
5. [Channel Listener System](#channel-listener-system)
6. [Client-Side API](#client-side-api)
7. [Server-Side API](#server-side-api)
8. [Clustering & Scalability](#clustering--scalability)
9. [Limitations & Known Issues](#limitations--known-issues)
10. [Security Considerations](#security-considerations)
11. [Proxy Configuration](#proxy-configuration)
12. [Best Practices](#best-practices)
13. [Use Cases](#use-cases)
14. [References](#references)

---

## Introduction & History

Adobe ColdFusion introduced **native WebSocket support in ColdFusion 10** (released 2012), eliminating the need for third-party libraries for real-time bidirectional communication. This was a significant enhancement to the platform's HTML5 capabilities.

### Key Milestones

- **ColdFusion 10:** Initial WebSocket implementation
- **ColdFusion 11:** Added clustering support for WebSockets with multicast messaging
- **ColdFusion 2016+:** Enhanced security and proxy configuration
- **ColdFusion 2025:** Built-in SSL certificate generation and enhanced SSL support

---

## Architecture Overview

### High-Level Design

ColdFusion's WebSocket implementation provides a **messaging layer** on top of the standard WebSocket protocol (RFC 6455). This abstraction layer is controlled through:

1. **CFML code** (server-side)
2. **JavaScript API** (client-side)
3. **Channel-based messaging system** (pub/sub pattern)

### Core Principles

```
┌─────────────────────────────────────────────────────────────┐
│                     Browser Client                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │   JavaScript WebSocket API                           │  │
│  │   - subscribe()                                      │  │
│  │   - publish()                                        │  │
│  │   - openConnection()                                 │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │ WebSocket Protocol (ws:// or wss://)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  WebSocket Proxy (Optional)                 │
│         Apache mod_proxy_wstunnel or Nginx                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              ColdFusion WebSocket Server                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │   Internal WebSocket Server (Port 8575/8577)        │  │
│  │   ┌──────────────────────────────────────────────┐  │  │
│  │   │  Channel Management                          │  │  │
│  │   │  - Subscriber tracking                       │  │  │
│  │   │  - Message routing                           │  │  │
│  │   │  - Authentication/Authorization              │  │  │
│  │   └──────────────────────────────────────────────┘  │  │
│  │   ┌──────────────────────────────────────────────┐  │  │
│  │   │  Channel Listener CFCs                       │  │  │
│  │   │  - allowSubscribe()                          │  │  │
│  │   │  - allowPublish()                            │  │  │
│  │   │  - beforePublish()                           │  │  │
│  │   │  - canSendMessage()                          │  │  │
│  │   │  - beforeSendMessage()                       │  │  │
│  │   └──────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. WebSocket Server

- **Default Ports:**
  - HTTP: `8575`
  - HTTPS: `8577`
- **Purpose:** Dedicated WebSocket server running inside ColdFusion
- **Location:** Embedded within the ColdFusion runtime (not a separate process)

### 2. CFML Tags

#### `<cfwebsocket>`

Primary tag for creating WebSocket connections from CFML templates.

**Key Attributes:**

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | String | Yes | JavaScript object name for the WebSocket |
| `onMessage` | String | No | JavaScript callback for incoming messages |
| `onOpen` | String | No | JavaScript callback when connection opens |
| `onClose` | String | No | JavaScript callback when connection closes |
| `onError` | String | No | JavaScript callback for errors |
| `subscribeTo` | String | No | Comma-separated list of channels to auto-subscribe |
| `useCfAuth` | Boolean | No | Use CF session authentication (default: true) |

**Example:**

```cfml
<cfwebsocket
    name="chatWS"
    onMessage="handleMessage"
    onOpen="handleOpen"
    onClose="handleClose"
    subscribeTo="chatChannel"
    useCfAuth="true">
```

### 3. Channel Listener CFC

A ColdFusion Component (CFC) that extends `CFIDE.websocket.ChannelListener` to control message flow and access.

**Required Structure:**

```cfml
<cfcomponent extends="CFIDE.websocket.ChannelListener">

    <cffunction name="allowSubscribe" returntype="boolean">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <!--- Determine if user can join the channel --->
        <cfreturn true>
    </cffunction>

    <cffunction name="allowPublish" returntype="boolean">
        <cfargument name="publisherInfo" type="struct" required="true">
        <!--- Determine if user can publish to channel --->
        <cfreturn true>
    </cffunction>

    <cffunction name="beforePublish" returntype="any">
        <cfargument name="message" type="any" required="true">
        <!--- Format/modify message before broadcasting --->
        <cfreturn message>
    </cffunction>

    <cffunction name="canSendMessage" returntype="boolean">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <cfargument name="message" type="any" required="true">
        <!--- Determine if specific subscriber should receive message --->
        <cfreturn true>
    </cffunction>

    <cffunction name="beforeSendMessage" returntype="any">
        <cfargument name="message" type="any" required="true">
        <cfargument name="subscriberInfo" type="struct" required="true">
        <!--- Client-specific message formatting --->
        <cfreturn message>
    </cffunction>

</cfcomponent>
```

---

## Configuration & Setup

### Administrator Configuration

**Location:** ColdFusion Administrator → Server Settings → WebSocket

**Key Settings:**

1. **Enable WebSocket Service** (checkbox)
2. **WebSocket Port** (default: 8575 for HTTP, 8577 for HTTPS)
3. **Use Proxy** (checkbox - routes through web server instead of direct port)
4. **Enable WebSocket Cluster** (Enterprise only)
5. **Multicast Port** (for clustering, default: 45566)
6. **Frame Size** (default: 1024 KB)

### Enabling WebSocket (Basic Setup)

1. Open ColdFusion Administrator
2. Navigate to **Server Settings → WebSocket Settings**
3. Check **Enable WebSocket Service**
4. Save changes
5. **Restart ColdFusion server**

### SSL Configuration (ColdFusion 2025)

ColdFusion 2025 introduced built-in SSL certificate generation:

1. In Administrator, go to **Server Settings → SSL Certificate**
2. Generate self-signed certificate
3. Enable HTTPS
4. Navigate to **Server Settings → WebSocket**
5. Configure SSL settings for WebSocket
6. Use `wss://` protocol in client connections

---

## Channel Listener System

The **Channel Listener** is the heart of Adobe ColdFusion's WebSocket security and message routing architecture.

### Execution Flow

```
Client Action                  Server Method Called           Purpose
─────────────────────────────────────────────────────────────────────────
subscribe("channel")    →      allowSubscribe()              Authorization check

publish("channel", msg) →      allowPublish()                Can user publish?
                        →      beforePublish()               Format message
                        →      canSendMessage()              For each subscriber
                        →      beforeSendMessage()           Per-subscriber format
```

### Method Details

#### 1. `allowSubscribe(subscriberInfo)`

**Called:** When a client attempts to subscribe to a channel
**Purpose:** Authorization - determines if user can join
**Return:** Boolean (true = allow, false = deny)

**subscriberInfo Structure:**

```javascript
{
    connectionId: "unique-connection-id",
    channelName: "chatChannel",
    customData: { /* data passed during subscribe */ },
    cfid: "session-id",
    cftoken: "session-token"
}
```

**Security Note:** This method is critical for preventing unauthorized channel access.

#### 2. `allowPublish(publisherInfo)`

**Called:** When a client attempts to publish a message
**Purpose:** Authorization - determines if user can broadcast
**Return:** Boolean (true = allow, false = deny)

**Important:** A user can publish without subscribing! Always secure both `allowSubscribe` and `allowPublish`.

#### 3. `beforePublish(message)`

**Called:** After `allowPublish()` succeeds, before broadcasting
**Purpose:** Message transformation/formatting for all recipients
**Return:** Modified message (any type)

**Use Cases:**
- Add timestamps
- Sanitize content
- Add sender information
- Encrypt messages

#### 4. `canSendMessage(subscriberInfo, message)`

**Called:** For EACH subscriber before sending message
**Purpose:** Per-subscriber authorization (fine-grained control)
**Return:** Boolean (true = send to this subscriber, false = skip)

**Use Cases:**
- Implement "block user" functionality
- Role-based message filtering
- Private message routing
- Selective broadcasting

**Important Distinction:**
- `allowPublish`: Can user broadcast at all?
- `canSendMessage`: Should THIS specific subscriber receive THIS message?

#### 5. `beforeSendMessage(message, subscriberInfo)`

**Called:** After `canSendMessage()` returns true
**Purpose:** Per-subscriber message customization
**Return:** Modified message for specific subscriber

**Use Cases:**
- Add subscriber-specific data
- Translate messages per user locale
- Personalize content
- Apply subscriber-specific encryption

---

## Client-Side API

### JavaScript WebSocket Object

Created automatically by the `<cfwebsocket>` tag.

### Core Methods

#### Connection Management

```javascript
// Open connection
chatWS.openConnection();

// Close connection
chatWS.closeConnection();

// Check if connected
if (chatWS.isConnectionOpen()) {
    // Connection is active
}
```

#### Channel Operations

```javascript
// Subscribe to channel
chatWS.subscribe("channelName");

// Subscribe with custom data
chatWS.subscribe("channelName", {userId: 123, role: "admin"});

// Unsubscribe from channel
chatWS.unsubscribe("channelName");

// Get list of subscribed channels
var channels = chatWS.getSubscriptions();

// Get subscriber count for a channel
var count = chatWS.getSubscriberCount("channelName");
```

#### Publishing Messages

```javascript
// Publish message to channel
chatWS.publish("channelName", "Hello World");

// Publish complex data
chatWS.publish("channelName", {
    type: "chat",
    user: "John",
    message: "Hello",
    timestamp: new Date()
});
```

#### Advanced Publishing

```javascript
// Invoke server-side CFC method and publish result
chatWS.invokeAndPublish("channelName", "mycfc", "myMethod", {
    arg1: "value1",
    arg2: "value2"
});
```

#### Authentication

```javascript
// Authenticate with credentials (when useCfAuth="false")
chatWS.authenticate("username", "password");
```

### Event Handlers

Defined as JavaScript functions and referenced in `<cfwebsocket>` attributes:

```javascript
function handleOpen() {
    console.log("WebSocket connection opened");
}

function handleMessage(message) {
    console.log("Received:", message);
    // message can be string, object, array, etc.
}

function handleClose(event) {
    console.log("Connection closed:", event);
}

function handleError(error) {
    console.error("WebSocket error:", error);
}
```

---

## Server-Side API

### Publishing from Server

ColdFusion provides functions to publish messages from server-side code:

```cfml
<!--- Publish to all subscribers of a channel --->
<cfset wsPublish("channelName", "Message from server")>

<!--- Publish with complex data --->
<cfset messageData = {
    type = "notification",
    text = "Server update",
    timestamp = now()
}>
<cfset wsPublish("channelName", messageData)>
```

### Clustering Support (CF11+)

```cfml
<!--- Publish to all nodes in cluster --->
<cfset wsPublish("channelName", message, true)>
<!--- Third parameter 'true' broadcasts to all clustered nodes --->

<!--- Get subscriber info from all nodes --->
<cfset subscribers = wsGetSubscribers("channelName", true)>
```

### Getting Subscriber Information

```cfml
<!--- Get all subscribers for a channel --->
<cfset subscriberArray = wsGetSubscribers("chatChannel")>

<!--- Each subscriber struct contains: --->
<!--- - connectionId --->
<!--- - channelName --->
<!--- - subscribedAt (timestamp) --->
<!--- - customData (if provided during subscribe) --->
```

---

## Clustering & Scalability

### Enterprise Clustering (ColdFusion 11+)

Adobe ColdFusion Enterprise edition supports **WebSocket clustering** for horizontal scaling.

#### How It Works

- Multiple ColdFusion instances communicate via **multicast messaging**
- When a message is published on one node, it's broadcast to **all subscribers across all nodes**
- Uses UDP multicast for inter-node communication

#### Configuration

1. **On each node**, enable clustering in Administrator:
   - Navigate to **Server Settings → WebSocket**
   - Check **Enable WebSocket Cluster**
   - Set **Multicast Port** (must be identical across all nodes)
   - Default multicast port: `45566`

2. **Firewall Configuration:**
   - Allow UDP multicast traffic on the configured port
   - Ensure nodes can communicate via multicast address

#### Clustered API Functions

```cfml
<!--- Publish to ALL nodes in cluster --->
<cfset wsPublish("channel", message, true)>

<!--- Get subscribers from ALL nodes --->
<cfset allSubscribers = wsGetSubscribers("channel", true)>
```

### Load Balancing Considerations

- **Sticky sessions recommended** for WebSocket connections
- Each WebSocket connection is stateful and tied to a specific server
- Load balancer should route subsequent requests from same client to same server

### Scalability Limits

Based on community reports and documentation:

- **5,000 - 10,000 concurrent connections** may experience issues
- Performance degrades with:
  - Users subscribed to multiple channels
  - High message frequency
  - Large message payloads (near frame size limit)

**Recommendation:** For applications requiring 10,000+ concurrent connections, consider dedicated WebSocket servers (Socket.IO, SignalR, etc.) integrated with ColdFusion.

---

## Limitations & Known Issues

### 1. Frame Size Limitations

**Default Frame Size:** 1024 KB (1 MB)

**Issue:** Large messages exceeding frame size are fragmented, causing:
- Increased memory usage
- Connection instability
- Potential message loss

**Mitigation:**
- Keep messages small (< 100 KB recommended)
- If larger messages needed, increase frame size in Administrator
- Monitor memory usage when increasing frame size

### 2. Security Sandbox Incompatibility

**Issue:** ColdFusion Security Sandbox (when enabled) can break WebSocket functionality

**Affected Versions:** ColdFusion 2021 Update 18+

**Status:** Known issue, workaround is to disable Security Sandbox or use external WebSocket server

### 3. Proxy Configuration Complexity

**Issue:** WebSocket connections work perfectly in direct mode but require careful proxy configuration in production

**Challenges:**
- Reverse proxy configuration (Nginx, Apache)
- SSL termination
- Firewall rules for dedicated ports
- Load balancer sticky sessions

### 4. Broadcasting Inefficiency

**Issue:** No built-in selective broadcasting at protocol level

**Problem:** If you publish to a channel with 1,000 subscribers but only 10 should receive the message, all 1,000 go through `canSendMessage()` filtering

**Mitigation:** Use multiple channels or implement custom message routing

### 5. Connection Recovery

**Issue:** No automatic reconnection built into CFML implementation

**Impact:** Client must manually detect disconnection and reconnect

**Mitigation:** Implement custom reconnection logic in JavaScript:

```javascript
function reconnect() {
    setTimeout(function() {
        if (!chatWS.isConnectionOpen()) {
            chatWS.openConnection();
        }
    }, 5000); // Retry after 5 seconds
}
```

### 6. Clustering Multicast Requirements

**Issue:** Clustering requires UDP multicast, which can be blocked by:
- Cloud provider networks (AWS, Azure often block multicast)
- Corporate firewalls
- Network topology

**Workaround:** May require VPN or alternative clustering solutions

---

## Security Considerations

### 1. Authentication

#### Built-in CF Authentication (`useCfAuth="true"`)

- Automatically uses ColdFusion session (CFID/CFTOKEN)
- Inherits CF application security context
- No additional authentication needed

**Advantage:** Seamless integration with existing CF authentication
**Disadvantage:** Tied to CF sessions, may not work with alternative auth systems

#### Custom Authentication (`useCfAuth="false"`)

- Requires manual authentication via `authenticate()` method
- Full control over authentication logic
- Can integrate with OAuth, JWT, custom auth

**Example:**

```javascript
chatWS.authenticate("username", "password");
```

### 2. Authorization via Channel Listeners

**Critical Methods:**

```cfml
<!--- Always implement BOTH --->
<cffunction name="allowSubscribe" returntype="boolean">
    <!--- Check if user can join channel --->
    <cfargument name="subscriberInfo" type="struct">

    <!--- Example: Check role --->
    <cfif structKeyExists(subscriberInfo, "customData")>
        <cfif subscriberInfo.customData.role eq "admin">
            <cfreturn true>
        </cfif>
    </cfif>

    <cfreturn false>
</cffunction>

<cffunction name="allowPublish" returntype="boolean">
    <!--- Check if user can publish --->
    <cfargument name="publisherInfo" type="struct">

    <!--- Example: Prevent banned users --->
    <cfif isBannedUser(publisherInfo)>
        <cfreturn false>
    </cfif>

    <cfreturn true>
</cffunction>
```

**Important:** Users can publish without subscribing, so secure both methods!

### 3. Message Sanitization

Always sanitize messages before broadcasting:

```cfml
<cffunction name="beforePublish" returntype="any">
    <cfargument name="message" type="any">

    <!--- Sanitize HTML/JavaScript --->
    <cfif isSimpleValue(message)>
        <cfset message = htmlEditFormat(message)>
    </cfif>

    <!--- Filter profanity --->
    <cfset message = filterProfanity(message)>

    <cfreturn message>
</cffunction>
```

### 4. SSL/TLS Encryption

**Production Requirement:** Always use `wss://` (WebSocket Secure)

**Configuration:**
1. Enable SSL certificate in CF Administrator
2. Configure WebSocket to use HTTPS port (8577)
3. Update client to use `wss://` protocol

**ColdFusion 2025:** Built-in SSL certificate generation simplifies setup

### 5. Rate Limiting

Not built into ColdFusion WebSocket - must implement custom:

```cfml
<cffunction name="allowPublish" returntype="boolean">
    <cfargument name="publisherInfo" type="struct">

    <!--- Track message counts per user --->
    <cfif rateLimitExceeded(publisherInfo.connectionId)>
        <cfreturn false>
    </cfif>

    <cfreturn true>
</cffunction>
```

---

## Proxy Configuration

### Why Use a Proxy?

**Security:** Don't expose WebSocket ports (8575/8577) directly to internet
**Standards:** Use standard HTTP/HTTPS ports (80/443)
**Integration:** Unified domain/port with main application

### Apache Configuration

#### Prerequisites

- **Worker MPM** required (not prefork)
- mod_proxy
- mod_proxy_wstunnel (Apache 2.4+)

#### Configuration Tool

```bash
# Windows
<cf_install_root>/cfusion/bin/wsproxyconfig.exe

# Linux/Unix
<cf_install_root>/cfusion/bin/wsproxyconfig.sh
```

#### Manual Apache Config

```apache
<VirtualHost *:80>
    ServerName example.com

    # Regular HTTP proxy for CF
    ProxyPass / http://localhost:8500/
    ProxyPassReverse / http://localhost:8500/

    # WebSocket proxy
    ProxyPass /cfws/ ws://localhost:8575/cfws/
    ProxyPassReverse /cfws/ ws://localhost:8575/cfws/

    # For SSL
    SSLProxyEngine On
    ProxyPass /cfwss/ wss://localhost:8577/cfwss/
    ProxyPassReverse /cfwss/ wss://localhost:8577/cfwss/
</VirtualHost>
```

#### ColdFusion Administrator

After configuring Apache:

1. Navigate to **Server Settings → WebSocket**
2. Check **Use Proxy**
3. Submit changes

### Nginx Configuration

#### Configuration Tool

```bash
wsconfig -ws nginx -dir <Nginx_Installation_directory>/conf
```

#### Manual Nginx Config

```nginx
upstream cfbackend {
    server localhost:8500;
}

upstream cfws {
    server localhost:8575;
}

server {
    listen 80;
    server_name example.com;

    # Regular HTTP proxy
    location / {
        proxy_pass http://cfbackend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # WebSocket proxy
    location /cfws/ {
        proxy_pass http://cfws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400; # 24 hours
    }
}
```

**Critical Headers:**
- `Upgrade: websocket`
- `Connection: Upgrade`
- Long `proxy_read_timeout` to prevent connection drops

---

## Best Practices

### 1. Channel Design

**Use Granular Channels:**

```cfml
<!--- BAD: One global channel --->
<cfwebsocket name="ws" subscribeTo="global">

<!--- GOOD: Specific channels --->
<cfwebsocket name="ws" subscribeTo="chat-room-123,notifications-user-456">
```

**Benefits:**
- Reduced message filtering overhead
- Better security isolation
- Easier to scale

### 2. Message Size

**Keep Messages Small:**
- Recommended: < 100 KB
- Avoid sending large datasets
- Use message IDs and fetch details via REST if needed

**Example:**

```javascript
// BAD: Send entire user object
chatWS.publish("channel", {
    userId: 123,
    profile: { /* 500 KB of data */ }
});

// GOOD: Send reference, fetch details if needed
chatWS.publish("channel", {
    type: "user-update",
    userId: 123
});
// Client fetches full profile via AJAX if needed
```

### 3. Error Handling

**Client-Side:**

```javascript
function handleError(error) {
    console.error("WebSocket error:", error);

    // Attempt reconnection
    setTimeout(function() {
        if (!chatWS.isConnectionOpen()) {
            chatWS.openConnection();
        }
    }, 5000);
}
```

**Server-Side:**

```cfml
<cffunction name="allowPublish" returntype="boolean">
    <cftry>
        <!--- Authorization logic --->
        <cfcatch>
            <cflog file="websocket-errors" text="#cfcatch.message#">
            <cfreturn false>
        </cfcatch>
    </cftry>
</cffunction>
```

### 4. Logging and Monitoring

**Enable WebSocket Logging:**

```cfml
<!--- In Application.cfc --->
<cfset this.wschannels = [
    {name="chatChannel", cfcListener="components.ChatListener"}
]>

<!--- In ChatListener.cfc --->
<cffunction name="beforePublish" returntype="any">
    <cflog file="websocket-messages"
           text="Channel: #arguments.channelName#, Message: #serializeJSON(arguments.message)#">
    <cfreturn arguments.message>
</cffunction>
```

**Monitor Metrics:**
- Active connections count
- Message throughput
- Channel subscription counts
- Error rates

### 5. Application.cfc Integration

**Define Channels in Application.cfc:**

```cfml
<cfcomponent>
    <cfset this.name = "MyWebSocketApp">
    <cfset this.sessionManagement = true>

    <!--- Define WebSocket channels --->
    <cfset this.wschannels = [
        {
            name = "chatChannel",
            cfcListener = "components.listeners.ChatListener"
        },
        {
            name = "notificationChannel",
            cfcListener = "components.listeners.NotificationListener"
        }
    ]>
</cfcomponent>
```

**Benefits:**
- Centralized configuration
- Application-wide channel management
- Automatic listener registration

### 6. Security Checklist

- [ ] Use SSL (`wss://`) in production
- [ ] Implement both `allowSubscribe()` and `allowPublish()`
- [ ] Sanitize all messages in `beforePublish()`
- [ ] Use granular channels (not one global channel)
- [ ] Enable CF session authentication or custom auth
- [ ] Implement rate limiting
- [ ] Log all security events
- [ ] Regular security audits of channel listeners

---

## Use Cases

### 1. Real-Time Chat Applications

**Implementation:**

```cfml
<!--- chat.cfm --->
<cfwebsocket
    name="chatWS"
    onMessage="displayMessage"
    onOpen="handleConnect"
    subscribeTo="chat-room-#url.roomId#">

<script>
function sendMessage() {
    var msg = {
        user: '<cfoutput>#session.username#</cfoutput>',
        text: document.getElementById('msgInput').value,
        timestamp: new Date().toISOString()
    };
    chatWS.publish('chat-room-<cfoutput>#url.roomId#</cfoutput>', msg);
}

function displayMessage(message) {
    // Append message to chat window
    var msgDiv = document.createElement('div');
    msgDiv.innerHTML = '<strong>' + message.user + ':</strong> ' + message.text;
    document.getElementById('chatMessages').appendChild(msgDiv);
}
</script>
```

### 2. Live Dashboards & Monitoring

**Implementation:**

```cfml
<!--- Server-side scheduled task --->
<cfschedule
    action="create"
    task="updateDashboard"
    interval="10"
    url="http://localhost/updateDashboard.cfm">

<!--- updateDashboard.cfm --->
<cfset metrics = {
    cpuUsage = getCPUUsage(),
    memoryUsage = getMemoryUsage(),
    activeUsers = getActiveUserCount(),
    timestamp = now()
}>

<cfset wsPublish("dashboard-metrics", metrics)>

<!--- dashboard.cfm --->
<cfwebsocket
    name="dashboardWS"
    onMessage="updateCharts"
    subscribeTo="dashboard-metrics">

<script>
function updateCharts(metrics) {
    // Update chart libraries (Chart.js, D3, etc.)
    updateCPUChart(metrics.cpuUsage);
    updateMemoryChart(metrics.memoryUsage);
    updateUserCount(metrics.activeUsers);
}
</script>
```

### 3. Collaborative Editing

**Implementation:**

```cfml
<!--- editor.cfm --->
<cfwebsocket
    name="editorWS"
    onMessage="applyRemoteChanges"
    subscribeTo="document-#url.docId#">

<script>
var editor = ace.edit("editor");
var isLocalChange = true;

editor.on('change', function(delta) {
    if (isLocalChange) {
        editorWS.publish('document-<cfoutput>#url.docId#</cfoutput>', {
            userId: '<cfoutput>#session.userId#</cfoutput>',
            delta: delta,
            timestamp: Date.now()
        });
    }
});

function applyRemoteChanges(change) {
    if (change.userId != '<cfoutput>#session.userId#</cfoutput>') {
        isLocalChange = false;
        editor.getSession().getDocument().applyDelta(change.delta);
        isLocalChange = true;
    }
}
</script>
```

### 4. Notification Systems

**Implementation:**

```cfml
<!--- Send notification from anywhere in app --->
<cfset wsPublish("notifications-user-#userId#", {
    type = "info",
    title = "New Message",
    message = "You have a new message from John",
    timestamp = now()
})>

<!--- Client side --->
<cfwebsocket
    name="notificationWS"
    onMessage="showNotification"
    subscribeTo="notifications-user-#session.userId#">

<script>
function showNotification(notification) {
    // Use browser notification API or custom UI
    if (Notification.permission === "granted") {
        new Notification(notification.title, {
            body: notification.message,
            icon: '/images/notification-icon.png'
        });
    }
}
</script>
```

### 5. Live Auction/Bidding Systems

**Implementation:**

```cfml
<!--- Place bid --->
<cffunction name="placeBid">
    <cfargument name="auctionId" required="true">
    <cfargument name="userId" required="true">
    <cfargument name="bidAmount" required="true">

    <!--- Save bid to database --->
    <cfquery>
        INSERT INTO bids (auction_id, user_id, amount, created_at)
        VALUES (<cfqueryparam value="#auctionId#">,
                <cfqueryparam value="#userId#">,
                <cfqueryparam value="#bidAmount#">,
                <cfqueryparam value="#now()#">)
    </cfquery>

    <!--- Broadcast to all watchers --->
    <cfset wsPublish("auction-#auctionId#", {
        type = "new-bid",
        userId = userId,
        amount = bidAmount,
        timestamp = now()
    })>
</cffunction>

<!--- Client --->
<cfwebsocket
    name="auctionWS"
    onMessage="updateBidDisplay"
    subscribeTo="auction-#url.auctionId#">
```

### 6. Stock/Inventory Updates

**Implementation:**

```cfml
<!--- Update inventory --->
<cffunction name="updateInventory">
    <cfargument name="productId" required="true">
    <cfargument name="newStock" required="true">

    <!--- Update database --->
    <cfquery>
        UPDATE products
        SET stock_quantity = <cfqueryparam value="#newStock#">
        WHERE product_id = <cfqueryparam value="#productId#">
    </cfquery>

    <!--- Notify all users viewing this product --->
    <cfset wsPublish("product-#productId#", {
        productId = productId,
        stockQuantity = newStock,
        timestamp = now()
    })>
</cffunction>
```

---

## References

### Official Adobe Documentation

- [Use ColdFusion Web Sockets](https://helpx.adobe.com/coldfusion/developing-applications/coldfusion-and-html-5/using-coldfusion-websocket.html)
- [WebSocket Enhancements](https://helpx.adobe.com/coldfusion/developing-applications/coldfusion-and-html-5/using-coldfusion-websocket/websocket-enhancements.html)
- [Using WebSocket to broadcast messages](https://helpx.adobe.com/coldfusion/developing-applications/coldfusion-and-html-5/using-coldfusion-websocket/using-websocket-to-broadcast-messages.html)
- [ColdFusion and WebSocket](https://helpx.adobe.com/coldfusion/developing-applications/coldfusion-and-html-5/using-coldfusion-websocket/coldfusion-and-websocket.html)
- [cfwebsocket Tag Reference](https://helpx.adobe.com/coldfusion/cfml-reference/coldfusion-tags/tags-u-z/cfwebsocket.html)
- [Enable WebSocket Over SSL in ColdFusion](https://coldfusion.adobe.com/2025/06/enable-websocket-over-ssl-in-coldfusion/)

### Configuration Guides

- [Configuring ColdFusion Websocket proxy in distributed mode on Linux](https://coldfusion.adobe.com/2023/04/configuring-coldfusion-websocket-proxy-in-distributed-mode-on-linux/)
- [Why should we use WebSocket Proxy?](https://coldfusion.adobe.com/2015/07/why-should-we-use-websocket-proxy/)
- [Configuring Nginx with ColdFusion (PDF)](http://cfdownload.adobe.com/pub/adobe/coldfusion/nginx/prerelease/v7/Configuring_Nginx_with_ColdFusion.pdf)
- [Server Settings > WebSocket - ColdFusion Tuning Guide](https://www.cfguide.io/coldfusion-administrator/server-settings-websocket/)

### Community Resources

- [ColdFusion 10 - Control Flow And Scopes During A WebSocket Request](https://www.bennadel.com/blog/2348-coldfusion-10-control-flow-and-scopes-during-a-websocket-request.htm)
- [ColdFusion 10 WebSockets, Selectors, and canSendMessage](https://www.raymondcamden.com/2012/10/04/ColdFusion-10-WebSockets-Selectors-and-canSendMessage/)
- [Examples of authentication and ColdFusion 10 WebSockets](https://www.raymondcamden.com/2012/06/01/Examples-of-authentication-and-ColdFusion-10-WebSockets)
- [ColdFusion 10 Web Socket JavaScript APIs](https://www.raymondcamden.com/2012/02/23/ColdFusion-10-Web-Socket-JavaScript-APIs)
- [How to Use WebSockets in ColdFusion for Real-Time Data Streaming?](https://medium.com/@Deepak-Sir/how-to-use-websockets-in-coldfusion-for-real-time-data-streaming-6252b2a5ee31)
- [cfwebsocket Code Examples and CFML Documentation](https://cfdocs.org/cfwebsocket)

### Clustering & Scalability

- [Register remote server instances and enable cluster for load balancing and failover](https://coldfusion.adobe.com/2021/10/steps-register-remote-server-instances-enabling-cluster-load-balancing-failover/)
- [Clustering for load balancing & failover using ColdFusion 10 Enterprise](https://www.itlandmark.com/blog/clustering-for-load-balancing-and-failover-using-coldfusion-10/)

### Books

- [Adobe® ColdFusion® Web Application Construction Kit: ColdFusion® 10 Enhancements and Improvements - Chapter 2: Using WebSocket](https://www.oreilly.com/library/view/adobe-r-coldfusion-r-web/9780133352528/ch02.html)

---

**End of Document**
