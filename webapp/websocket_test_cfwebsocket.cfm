<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>CFWEBSOCKET Tag Test</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 900px; margin: 20px auto; padding: 20px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; font-weight: bold; }
        .connected { background-color: #d4edda; color: #155724; }
        .disconnected { background-color: #f8d7da; color: #721c24; }
        .messages {
            border: 1px solid #ccc;
            height: 300px;
            overflow-y: scroll;
            padding: 10px;
            margin: 10px 0;
            background-color: #f8f9fa;
            font-family: monospace;
            font-size: 13px;
        }
        .message {
            padding: 5px;
            margin: 3px 0;
            border-left: 3px solid #007bff;
            background-color: white;
        }
        .message.success { border-left-color: #28a745; background-color: #d4edda; }
        .message.error { border-left-color: #dc3545; background-color: #f8d7da; }
        button {
            padding: 8px 15px;
            margin: 3px;
            font-size: 13px;
            cursor: pointer;
            border: none;
            border-radius: 4px;
            color: white;
            background-color: #007bff;
        }
        button:hover { background-color: #0056b3; }
        button.success { background-color: #28a745; }
        button.danger { background-color: #dc3545; }
        input, textarea { padding: 8px; margin: 5px; }
        textarea { width: 95%; }
    </style>
</head>
<body>
    <h1>CFWEBSOCKET Tag Test</h1>

    <div class="message" style="background-color: #fff3cd; border-left-color: #ffc107; color: #856404;">
        <strong>⚠️ IMPORTANT: Register Channels First!</strong><br>
        Before testing, you must register channels by visiting:
        <a href="websocket_init_test_channels.cfm" style="color: #856404; text-decoration: underline;">
            websocket_init_test_channels.cfm
        </a>
        <br>Channels must be registered before clients can subscribe to them.
    </div>

    <div class="message success">
        <strong>✅ The &lt;cfwebsocket&gt; tag has been processed!</strong><br>
        A JavaScript WebSocket client object named <code>myWebSocket</code> is now available.<br>
        Check your browser console to see the generated JavaScript code.
    </div>

    <div id="status" class="status disconnected">Disconnected</div>

    <h3>Controls</h3>
    <button onclick="myWebSocket.openConnection()">Connect</button>
    <button class="danger" onclick="myWebSocket.closeConnection()">Disconnect</button>

    <h3>Subscribe to Channel</h3>
    <input type="text" id="channelName" value="testChannel" placeholder="Channel name">
    <input type="text" id="userId" value="user123" placeholder="User ID">
    <button class="success" onclick="subscribeToChannel()">Subscribe</button>

    <h3>Publish Message</h3>
    <input type="text" id="pubChannel" value="testChannel" placeholder="Channel name"><br>
    <textarea id="messageText" rows="3" placeholder="Message text">Hello from CFWEBSOCKET tag!</textarea><br>
    <button onclick="publishMessage()">Publish Message</button>

    <h3>📨 Messages</h3>
    <button onclick="clearMessages()">Clear Messages</button>
    <div class="messages" id="messages"></div>

    <h3>🔍 Test Info</h3>
    <ul>
        <li>WebSocket client object: <code>window.myWebSocket</code></li>
        <li>Methods available: openConnection(), closeConnection(), subscribe(), publish(), unsubscribe()</li>
        <li>Event handlers: onOpen, onClose, onError, onMessage</li>
    </ul>

    <script>
        // Define event handler functions BEFORE the cfwebsocket tag
        // so they exist when the tag references them
        function handleMessage(channelName, message) {
            console.log('Received message on channel:', channelName, message);
            var text = '<strong>[' + channelName + ']</strong> ' + JSON.stringify(message);
            addMessage(text, 'success');
        }

        function handleOpen(evt) {
            console.log('WebSocket connected', evt);
            document.getElementById('status').textContent = 'Connected';
            document.getElementById('status').className = 'status connected';
            addMessage('✅ Connected to WebSocket server', 'success');
        }

        function handleClose(evt) {
            console.log('WebSocket disconnected', evt);
            document.getElementById('status').textContent = 'Disconnected';
            document.getElementById('status').className = 'status disconnected';
            addMessage('🔌 Disconnected from WebSocket server');
        }

        function handleError(error) {
            console.error('WebSocket error:', error);
            addMessage('❌ WebSocket error: ' + error, 'error');
        }
    </script>

    <!--- Generate the WebSocket client using the cfwebsocket tag --->
    <cfwebsocket
        name="myWebSocket"
        onMessage="handleMessage"
        onOpen="handleOpen"
        onClose="handleClose"
        onError="handleError">

    <script>
        // Helper functions
        function addMessage(text, type) {
            var messagesDiv = document.getElementById('messages');
            var div = document.createElement('div');
            div.className = 'message ' + (type || '');
            div.innerHTML = new Date().toLocaleTimeString() + ' - ' + text;
            messagesDiv.appendChild(div);
            div.scrollIntoView();
        }

        function subscribeToChannel() {
            var channelName = document.getElementById('channelName').value;
            var userId = document.getElementById('userId').value;

            if (!channelName) {
                alert('Enter a channel name!');
                return;
            }

            try {
                myWebSocket.subscribe(channelName, { userId: userId }, function(err, result) {
                    if (err) {
                        addMessage('❌ Subscribe error: ' + err, 'error');
                    } else {
                        addMessage('✅ Subscribed to ' + channelName, 'success');
                    }
                });
                addMessage('📤 Subscribing to ' + channelName + '...');
            } catch (e) {
                addMessage('❌ Error: ' + e.message, 'error');
            }
        }

        function publishMessage() {
            var channelName = document.getElementById('pubChannel').value;
            var messageText = document.getElementById('messageText').value;

            if (!channelName || !messageText) {
                alert('Enter channel name and message!');
                return;
            }

            try {
                myWebSocket.publish(channelName, {
                    text: messageText,
                    timestamp: new Date().toISOString()
                });
                addMessage('📤 Published to ' + channelName);
            } catch (e) {
                addMessage('❌ Error: ' + e.message, 'error');
            }
        }

        function clearMessages() {
            document.getElementById('messages').innerHTML = '';
        }

        // Display available methods
        console.log('=== CFWEBSOCKET Tag Generated Object ===');
        console.log('Available on window.myWebSocket:', myWebSocket);
        console.log('Methods:', Object.keys(myWebSocket).filter(k => typeof myWebSocket[k] === 'function'));
    </script>
</body>
</html>
