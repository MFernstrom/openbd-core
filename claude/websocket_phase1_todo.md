# WebSocket Phase 1: Core Infrastructure - Task List

**Goal:** WebSocket server accepts connections, performs handshake, and exchanges raw messages (echo)

**Timeline:** 2 weeks

**Success Criteria:**
- ✅ Server starts/stops with OpenBD lifecycle
- ✅ Clients connect via WebSocket protocol
- ✅ Bidirectional message exchange works (echo)
- ✅ All unit and integration tests pass

---

## Week 1: Server Foundation

### Day 1-2: WebSocketServer.java - Basic Setup

- [ ] Create package `src/com/naryx/tagfusion/cfm/websocket/`
- [ ] Create `WebSocketServer.java` class file
- [ ] Implement singleton pattern with private constructor
- [ ] Add fields: `instance`, `bossGroup`, `workerGroup`, `bootstrap`, `serverChannel`, `port`
- [ ] Implement `getInstance()` method with synchronization
- [ ] Implement `start(int port)` method:
  - [ ] Initialize NioEventLoopGroup for boss (1 thread)
  - [ ] Initialize NioEventLoopGroup for worker (default threads)
  - [ ] Create ServerBootstrap
  - [ ] Configure channel type: NioServerSocketChannel
  - [ ] Set SO_BACKLOG option (128)
  - [ ] Set SO_KEEPALIVE child option (true)
  - [ ] Bind to port and sync
  - [ ] Store server channel reference
  - [ ] Add logging on successful start
- [ ] Implement `stop()` method:
  - [ ] Close server channel with sync
  - [ ] Shutdown worker group gracefully (0-5 seconds)
  - [ ] Shutdown boss group gracefully (0-5 seconds)
  - [ ] Add logging on successful stop
- [ ] Add `isRunning()` helper method
- [ ] Add error handling for BindException (port in use)
- [ ] Add error handling for other startup failures

**Unit Tests:**
- [ ] Create `src/test/java/com/naryx/tagfusion/cfm/websocket/WebSocketServerTest.java`
- [ ] Test: `testServerStartStop()` - server starts and stops cleanly
- [ ] Test: `testMultipleStartCalls()` - prevents starting twice
- [ ] Test: `testPortConflict()` - handles port already in use
- [ ] Test: `testIsRunning()` - correctly reports running state

**Manual Tests:**
- [ ] Start server on port 8580
- [ ] Verify server is listening: `netstat -an | grep 8580`
- [ ] Stop server
- [ ] Verify port is released

---

### Day 3: WebSocketChannelHandler.java - Pipeline Handler

- [ ] Create `WebSocketChannelHandler.java` class
- [ ] Extend `SimpleChannelInboundHandler<WebSocketFrame>`
- [ ] Add field: `WebSocketConnection connection`
- [ ] Override `channelActive(ChannelHandlerContext ctx)`:
  - [ ] Log "New WebSocket connection"
  - [ ] Call super.channelActive(ctx)
- [ ] Override `channelRead0(ChannelHandlerContext ctx, WebSocketFrame frame)`:
  - [ ] Handle TextWebSocketFrame: echo message back
  - [ ] Handle CloseWebSocketFrame: call handleClose()
  - [ ] Handle PingWebSocketFrame: respond with PongWebSocketFrame
  - [ ] Log unsupported frame types
- [ ] Override `channelInactive(ChannelHandlerContext ctx)`:
  - [ ] Log "WebSocket connection closed"
  - [ ] Call handleClose()
  - [ ] Call super.channelInactive(ctx)
- [ ] Override `exceptionCaught(ChannelHandlerContext ctx, Throwable cause)`:
  - [ ] Log error with stack trace
  - [ ] Close context
- [ ] Implement `handleTextMessage(String message)`:
  - [ ] Log received message
  - [ ] Send echo response: "Echo: " + message
  - [ ] Wrap in try/catch for error handling
- [ ] Implement `handleClose()`:
  - [ ] Add TODO comment for Phase 2 cleanup
  - [ ] Make idempotent (safe to call multiple times)

**Integration with Server:**
- [ ] Update `WebSocketServer.start()` to add handler to pipeline:
  - [ ] Add HttpServerCodec
  - [ ] Add HttpObjectAggregator(65536)
  - [ ] Add WebSocketServerProtocolHandler("/openbd/ws")
  - [ ] Add WebSocketChannelHandler (our custom handler)

**Manual Tests:**
- [ ] Install wscat: `npm install -g wscat`
- [ ] Start OpenBD WebSocket server
- [ ] Connect: `wscat -c ws://localhost:8580/openbd/ws`
- [ ] Send message: "hello"
- [ ] Verify echo received: "Echo: hello"
- [ ] Send JSON: `{"test": "message"}`
- [ ] Verify echo received: `Echo: {"test": "message"}`
- [ ] Disconnect (Ctrl+C)
- [ ] Verify server logs show connection/disconnection

---

### Day 4-5: WebSocketConnection.java - Connection Abstraction

- [ ] Create `WebSocketConnection.java` class
- [ ] Add imports for: UUID, AtomicBoolean, ConcurrentHashMap, ChannelHandlerContext, etc.
- [ ] Add fields:
  - [ ] `String connectionId` (final)
  - [ ] `ChannelHandlerContext ctx` (final)
  - [ ] `AtomicBoolean connected`
  - [ ] `cfSession session` (volatile)
  - [ ] `Set<String> subscribedChannels` (ConcurrentHashMap.newKeySet())
  - [ ] `cfStructData subscriberInfo` (volatile)
- [ ] Implement constructor:
  - [ ] Generate UUID for connectionId
  - [ ] Store ChannelHandlerContext
  - [ ] Initialize connected to true
  - [ ] Initialize subscribedChannels set
- [ ] Implement `getConnectionId()` getter
- [ ] Implement `sendMessage(String message)`:
  - [ ] Check if connected, return early if not
  - [ ] Create TextWebSocketFrame
  - [ ] Call ctx.writeAndFlush()
  - [ ] Add ChannelFutureListener for write completion
  - [ ] Log errors and close connection on failure
  - [ ] Wrap in try/catch
- [ ] Implement `close()`:
  - [ ] Set connected to false
  - [ ] Close channel via context
  - [ ] Make idempotent
- [ ] Implement `isConnected()` getter
- [ ] Implement `associateSession(cfSession session)`:
  - [ ] Store session reference
  - [ ] Log association with session ID
- [ ] Implement `getSession()` getter
- [ ] Implement `getSubscribedChannels()` - return unmodifiable set

**Unit Tests:**
- [ ] Create `WebSocketConnectionTest.java`
- [ ] Test: `testConnectionId()` - each connection has unique ID
- [ ] Test: `testSendMessage()` - message sent via context.writeAndFlush
- [ ] Test: `testSendMessageWhenClosed()` - no-op when connection closed
- [ ] Test: `testSessionAssociation()` - session stored and retrieved
- [ ] Test: `testClose()` - sets connected to false
- [ ] Test: `testCloseIdempotent()` - calling close() multiple times is safe

**Refactor Handler:**
- [ ] Update `WebSocketChannelHandler.channelActive()`:
  - [ ] Create WebSocketConnection instance
  - [ ] Store in handler field
  - [ ] Log with connection ID
- [ ] Update `handleTextMessage()`:
  - [ ] Use `connection.sendMessage()` instead of direct ctx.writeAndFlush()
- [ ] Update `handleClose()`:
  - [ ] Call `connection.close()`

**Manual Tests:**
- [ ] Connect with wscat
- [ ] Send multiple messages rapidly
- [ ] Verify all echoes received
- [ ] Check server logs for connection IDs

---

## Week 2: Integration & Hardening

### Day 1-2: cfEngine.java Integration

- [ ] Open `src/com/naryx/tagfusion/cfm/engine/cfEngine.java`
- [ ] Add field: `private WebSocketServer wsServer;`
- [ ] Locate `init()` method
- [ ] Add WebSocket initialization before end of init():
  - [ ] Read config: `server.websocket.enabled` (default: false)
  - [ ] If enabled, read: `server.websocket.port` (default: 8580)
  - [ ] Get WebSocketServer instance
  - [ ] Call start(port)
  - [ ] Log success: "WebSocket server started on port X"
  - [ ] Wrap in try/catch, log error but continue if fails
- [ ] Locate `shutdown()` method
- [ ] Add WebSocket shutdown at START of shutdown():
  - [ ] Check if wsServer is not null
  - [ ] Call wsServer.stop()
  - [ ] Log "WebSocket server stopped"
  - [ ] Wrap in try/catch

**Configuration:**
- [ ] Open example `bluedragon.xml` or create test config
- [ ] Add `<websocket>` section under `<system>`:
  ```xml
  <websocket>
      <enabled>true</enabled>
      <port>8580</port>
  </websocket>
  ```
- [ ] Document configuration in comments

**Build & Deploy Tests:**
- [ ] Run `ant -buildfile build/build.xml war`
- [ ] Verify build succeeds
- [ ] Deploy OpenBlueDragon.jar to test server
- [ ] Start OpenBD
- [ ] Check logs for "WebSocket server started on port 8580"
- [ ] Connect with wscat
- [ ] Send test messages
- [ ] Shutdown OpenBD
- [ ] Check logs for "WebSocket server stopped"
- [ ] Verify no error stack traces

---

### Day 3-4: Error Handling & Edge Cases

**Connection Limits:**
- [ ] Add to `WebSocketServer.java`:
  - [ ] Field: `AtomicInteger connectionCount`
  - [ ] Field: `static final int MAX_CONNECTIONS = 10000`
  - [ ] Method: `incrementConnectionCount()` - returns false if at limit
  - [ ] Method: `decrementConnectionCount()`
- [ ] Update `WebSocketChannelHandler.channelActive()`:
  - [ ] Call incrementConnectionCount()
  - [ ] If false, send CloseWebSocketFrame(1008, "Server at capacity")
  - [ ] Close context and return
- [ ] Update `WebSocketChannelHandler.channelInactive()`:
  - [ ] Call decrementConnectionCount()

**Resource Cleanup:**
- [ ] Review all `channelRead0()` handlers
- [ ] Ensure PongWebSocketFrame retains content: `frame.content().retain()`
- [ ] Add connection timeout handling
- [ ] Configure buffer allocator in ServerBootstrap:
  ```java
  .childOption(ChannelOption.RCVBUF_ALLOCATOR,
      new AdaptiveRecvByteBufAllocator(64, 1024, 65536))
  ```

**Improved Error Messages:**
- [ ] Add custom exception: `WebSocketException.java`
- [ ] Use throughout codebase for WebSocket-specific errors
- [ ] Add error codes for common failures:
  - [ ] PORT_IN_USE
  - [ ] MAX_CONNECTIONS_REACHED
  - [ ] INVALID_MESSAGE
  - [ ] SEND_FAILED

**Logging Improvements:**
- [ ] Replace all `System.out.println` with `cfEngine.log()`
- [ ] Add log levels where appropriate
- [ ] Add connection ID to all log messages
- [ ] Add request context where available

**Tests:**
- [ ] Test: Connection limit enforcement
- [ ] Test: Port conflict handling
- [ ] Test: Graceful shutdown with active connections
- [ ] Test: Message send failure handling
- [ ] Test: Resource cleanup on error

---

### Day 5: Testing & Documentation

**Integration Tests:**
- [ ] Create `WebSocketIntegrationTest.java`
- [ ] Test: Single client connection end-to-end
- [ ] Test: Multiple concurrent connections (10 clients)
- [ ] Test: Rapid connect/disconnect cycles
- [ ] Test: Large message handling (64KB)
- [ ] Test: Server restart with no connections
- [ ] Test: Client timeout handling

**Browser Test Page:**
- [ ] Create `webapp/test/websocket/phase1_test.html`
- [ ] Add connection controls (Connect/Disconnect buttons)
- [ ] Add message input field
- [ ] Add send button
- [ ] Add message log display
- [ ] Add WebSocket status indicator
- [ ] Test in Chrome
- [ ] Test in Firefox
- [ ] Test in Safari

**Performance Baseline:**
- [ ] Create `WebSocketBenchmark.java`
- [ ] Measure: Time to connect 100 clients
- [ ] Measure: Message round-trip latency (avg, p95, p99)
- [ ] Measure: Memory usage per connection
- [ ] Document baseline metrics for future comparison

**Load Testing:**
- [ ] Test with 100 concurrent connections
- [ ] Test with 500 concurrent connections
- [ ] Test with 1000 concurrent connections
- [ ] Document results and any issues
- [ ] Identify performance bottlenecks

**Documentation:**
- [ ] Update `claude/websocket_phase1_todo.md` with completion notes
- [ ] Document any deviations from original plan
- [ ] Document known issues or limitations
- [ ] Document performance baselines
- [ ] Create Phase 1 summary report

---

## Final Checklist - Phase 1 Complete

### Functionality
- [ ] WebSocket server starts on configured port
- [ ] Server binds correctly and listens for connections
- [ ] WebSocket handshake completes successfully
- [ ] Client can connect from browser
- [ ] Client can connect from wscat
- [ ] Server echoes text messages back to client
- [ ] Server handles ping/pong frames
- [ ] Server handles close frames gracefully
- [ ] Multiple clients can connect simultaneously
- [ ] Server stops gracefully on OpenBD shutdown

### Integration
- [ ] Server starts when OpenBD starts (if enabled in config)
- [ ] Server stops when OpenBD stops
- [ ] Configuration loaded from bluedragon.xml
- [ ] Default disabled (backward compatibility)
- [ ] Logs indicate server status

### Error Handling
- [ ] Port conflicts detected and logged
- [ ] Invalid handshakes rejected
- [ ] Connection limit enforced
- [ ] Send failures handled gracefully
- [ ] Exceptions don't crash OpenBD
- [ ] Resources cleaned up on error

### Testing
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Manual wscat test works
- [ ] Browser JavaScript test works
- [ ] Load test (100 connections) passes
- [ ] No memory leaks detected
- [ ] Performance baseline documented

### Code Quality
- [ ] All code follows OpenBD style conventions
- [ ] All public methods have Javadoc comments
- [ ] No compiler warnings
- [ ] No IDE warnings (unused imports, etc.)
- [ ] Error messages are clear and actionable
- [ ] Logging is appropriate (not too verbose, not too quiet)

### Documentation
- [ ] Configuration options documented
- [ ] Test procedures documented
- [ ] Known limitations documented
- [ ] Phase 1 summary written
- [ ] Phase 2 prerequisites identified

---

## Files Created/Modified

### New Files
- [ ] `src/com/naryx/tagfusion/cfm/websocket/WebSocketServer.java`
- [ ] `src/com/naryx/tagfusion/cfm/websocket/WebSocketConnection.java`
- [ ] `src/com/naryx/tagfusion/cfm/websocket/WebSocketChannelHandler.java`
- [ ] `src/com/naryx/tagfusion/cfm/websocket/WebSocketException.java`
- [ ] `src/test/java/com/naryx/tagfusion/cfm/websocket/WebSocketServerTest.java`
- [ ] `src/test/java/com/naryx/tagfusion/cfm/websocket/WebSocketConnectionTest.java`
- [ ] `src/test/java/com/naryx/tagfusion/cfm/websocket/WebSocketIntegrationTest.java`
- [ ] `src/test/java/com/naryx/tagfusion/cfm/websocket/WebSocketBenchmark.java`
- [ ] `webapp/test/websocket/phase1_test.html`

### Modified Files
- [ ] `src/com/naryx/tagfusion/cfm/engine/cfEngine.java` - Add init/shutdown hooks
- [ ] Example configuration file with `<websocket>` section

---

## Success Metrics

**By end of Phase 1, we should achieve:**

- ✅ **0 crashes** - Server never crashes OpenBD, even on error
- ✅ **100+ concurrent connections** - Can handle at least 100 simultaneous WebSocket clients
- ✅ **<50ms latency** - Echo round-trip in under 50ms (p95)
- ✅ **<10MB overhead** - Server uses less than 10MB RAM with no connections
- ✅ **100% test coverage** - All critical paths have unit/integration tests
- ✅ **Clean shutdown** - No threads left running, all resources released

---

## Ready for Phase 2?

Before starting Phase 2 (Channel Management), verify:

- [ ] All Phase 1 checklist items complete
- [ ] Performance meets targets
- [ ] No known critical bugs
- [ ] Code reviewed and approved
- [ ] Documentation complete
- [ ] Build artifact tested in clean environment

**Next:** Phase 2 will add channel registration, subscription management, and message routing to subscribers.
