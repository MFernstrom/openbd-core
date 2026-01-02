<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>CFWEBSOCKET Tag - Premium Chat Example</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 20px auto;
            padding: 20px;
        }
        .container {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 20px;
        }
        .client-panel {
            border: 2px solid #007bff;
            border-radius: 8px;
            padding: 15px;
            background-color: #f8f9fa;
        }
        .client-panel.alice { border-color: #28a745; }
        .client-panel.bob { border-color: #17a2b8; }
        .status {
            padding: 8px;
            margin: 10px 0;
            border-radius: 4px;
            font-weight: bold;
            text-align: center;
        }
        .connected { background-color: #d4edda; color: #155724; }
        .disconnected { background-color: #f8d7da; color: #721c24; }
        .messages {
            border: 1px solid #ccc;
            height: 250px;
            overflow-y: auto;
            padding: 10px;
            margin: 10px 0;
            background-color: white;
            font-family: monospace;
            font-size: 12px;
        }
        .message {
            padding: 5px;
            margin: 3px 0;
            border-left: 3px solid #007bff;
            background-color: #f8f9fa;
        }
        .message.success { border-left-color: #28a745; background-color: #d4edda; }
        .message.error { border-left-color: #dc3545; background-color: #f8d7da; }
        .message.warning { border-left-color: #ffc107; background-color: #fff3cd; }
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
        button:disabled { background-color: #6c757d; cursor: not-allowed; }
        button.success { background-color: #28a745; }
        button.danger { background-color: #dc3545; }
        input, textarea {
            padding: 8px;
            margin: 5px 0;
            width: calc(100% - 20px);
        }
        textarea { height: 60px; }
        .tier-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: bold;
            margin-left: 10px;
        }
        .tier-free { background-color: #6c757d; color: white; }
        .tier-premium { background-color: #ffc107; color: #000; }
        .tier-vip { background-color: #dc3545; color: white; }
        h3 { margin: 15px 0 10px 0; font-size: 16px; }
        .info-box {
            background-color: #d1ecf1;
            border: 1px solid #bee5eb;
            border-radius: 4px;
            padding: 10px;
            margin: 10px 0;
            font-size: 13px;
        }
    </style>
</head>
<body>
    <h1>🚀 CFWEBSOCKET Tag - Premium Chat Integration</h1>

    <div style="background-color: #fff3cd; border: 1px solid #ffc107; border-radius: 4px; padding: 10px; margin: 10px 0; font-size: 13px; color: #856404;">
        <strong>⚠️ IMPORTANT: Register Channels First!</strong><br>
        Before testing, you must register channels by visiting:
        <a href="websocket_init_test_channels.cfm" style="color: #856404; text-decoration: underline;">
            websocket_init_test_channels.cfm
        </a>
    </div>

    <div class="info-box">
        <strong>📋 This demo shows:</strong>
        <ul style="margin: 5px 0;">
            <li>Two CFWEBSOCKET clients (Alice: Free tier, Bob: Premium tier)</li>
            <li>Integration with PremiumChatListener CFC</li>
            <li>Premium features like attachments and formatting</li>
            <li>Real-time message filtering based on user tier</li>
        </ul>
    </div>

    <div class="container">
        <!-- Alice (Free User) Panel -->
        <div class="client-panel alice">
            <h2>
                👤 Alice
                <span class="tier-badge tier-free">FREE</span>
            </h2>

            <div id="aliceStatus" class="status disconnected">Disconnected</div>

            <h3>🔌 Connection</h3>
            <button onclick="aliceConnect()">Connect</button>
            <button class="danger" onclick="aliceDisconnect()">Disconnect</button>

            <h3>📡 Subscribe to Channel</h3>
            <select id="aliceChannel">
                <option value="lobby">lobby (public)</option>
                <option value="premium">premium (premium only)</option>
                <option value="vip">vip (VIP only)</option>
            </select>
            <button class="success" onclick="aliceSubscribe()">Subscribe</button>

            <h3>✉️ Send Message</h3>
            <textarea id="aliceMessage" placeholder="Type your message...">Hello from Alice!</textarea><br>
            <label>
                <input type="checkbox" id="aliceAttachment">
                Include attachment (Premium feature)
            </label><br>
            <label>
                <input type="checkbox" id="aliceFormatting">
                Use rich formatting (Premium feature)
            </label><br>
            <button onclick="aliceSendMessage()">Send to Current Channel</button>

            <h3>📨 Messages</h3>
            <button onclick="clearAliceMessages()">Clear</button>
            <div class="messages" id="aliceMessages"></div>
        </div>

        <!-- Bob (Premium User) Panel -->
        <div class="client-panel bob">
            <h2>
                👤 Bob
                <span class="tier-badge tier-premium">PREMIUM</span>
            </h2>

            <div id="bobStatus" class="status disconnected">Disconnected</div>

            <h3>🔌 Connection</h3>
            <button onclick="bobConnect()">Connect</button>
            <button class="danger" onclick="bobDisconnect()">Disconnect</button>

            <h3>📡 Subscribe to Channel</h3>
            <select id="bobChannel">
                <option value="lobby">lobby (public)</option>
                <option value="premium">premium (premium only)</option>
                <option value="vip">vip (VIP only)</option>
            </select>
            <button class="success" onclick="bobSubscribe()">Subscribe</button>

            <h3>✉️ Send Message</h3>
            <textarea id="bobMessage" placeholder="Type your message...">Hello from Bob!</textarea><br>
            <label>
                <input type="checkbox" id="bobAttachment">
                Include attachment (Premium feature)
            </label><br>
            <label>
                <input type="checkbox" id="bobFormatting">
                Use rich formatting (Premium feature)
            </label><br>
            <button onclick="bobSendMessage()">Send to Current Channel</button>

            <h3>📨 Messages</h3>
            <button onclick="clearBobMessages()">Clear</button>
            <div class="messages" id="bobMessages"></div>
        </div>
    </div>

    <script>
        // Define event handler functions BEFORE the cfwebsocket tags
        // so they exist when the tags reference them

        // Track subscribed channels (can subscribe to multiple)
        var aliceChannels = [];
        var bobChannels = [];

        // Alice event handlers
        function aliceHandleMessage(channelName, message) {
            console.log('[Alice] Message on', channelName, message);
            addAliceMessage('📩 [' + channelName + '] ' + formatMessage(message), 'success');
        }

        function aliceHandleOpen(evt) {
            console.log('[Alice] Connected');
            document.getElementById('aliceStatus').textContent = 'Connected';
            document.getElementById('aliceStatus').className = 'status connected';
            addAliceMessage('✅ Connected to WebSocket server', 'success');
        }

        function aliceHandleClose(evt) {
            console.log('[Alice] Disconnected');
            document.getElementById('aliceStatus').textContent = 'Disconnected';
            document.getElementById('aliceStatus').className = 'status disconnected';
            addAliceMessage('🔌 Disconnected from server');
            aliceChannels = [];
        }

        function aliceHandleError(error) {
            console.error('[Alice] Error:', error);
            addAliceMessage('❌ Error: ' + error, 'error');
        }

        // Bob event handlers
        function bobHandleMessage(channelName, message) {
            console.log('[Bob] Message on', channelName, message);
            addBobMessage('📩 [' + channelName + '] ' + formatMessage(message), 'success');
        }

        function bobHandleOpen(evt) {
            console.log('[Bob] Connected');
            document.getElementById('bobStatus').textContent = 'Connected';
            document.getElementById('bobStatus').className = 'status connected';
            addBobMessage('✅ Connected to WebSocket server', 'success');
        }

        function bobHandleClose(evt) {
            console.log('[Bob] Disconnected');
            document.getElementById('bobStatus').textContent = 'Disconnected';
            document.getElementById('bobStatus').className = 'status disconnected';
            addBobMessage('🔌 Disconnected from server');
            bobChannels = [];
        }

        function bobHandleError(error) {
            console.error('[Bob] Error:', error);
            addBobMessage('❌ Error: ' + error, 'error');
        }
    </script>

    <!--- Generate WebSocket clients using cfwebsocket tag --->
    <cfwebsocket
        name="aliceClient"
        onMessage="aliceHandleMessage"
        onOpen="aliceHandleOpen"
        onClose="aliceHandleClose"
        onError="aliceHandleError">

    <cfwebsocket
        name="bobClient"
        onMessage="bobHandleMessage"
        onOpen="bobHandleOpen"
        onClose="bobHandleClose"
        onError="bobHandleError">

    <script>
        // Helper functions
        function formatMessage(msg) {
            if (typeof msg === 'string') {
                return msg;
            }
            var text = msg.text || msg.message || JSON.stringify(msg);

            // Show premium feature indicators
            var extras = [];
            if (msg.attachment) {
                extras.push('📎 ' + msg.attachment);
            }
            if (msg.formatted === true) {
                extras.push('🎨 Formatted');
            }
            if (msg.tier) {
                extras.push('👤 ' + msg.tier);
            }

            return text + (extras.length > 0 ? ' [' + extras.join(', ') + ']' : '');
        }

        function addAliceMessage(text, type) {
            addMessageToDiv('aliceMessages', text, type);
        }

        function addBobMessage(text, type) {
            addMessageToDiv('bobMessages', text, type);
        }

        function addMessageToDiv(divId, text, type) {
            var messagesDiv = document.getElementById(divId);
            var div = document.createElement('div');
            div.className = 'message ' + (type || '');
            div.innerHTML = new Date().toLocaleTimeString() + ' - ' + text;
            messagesDiv.appendChild(div);
            div.scrollIntoView();
        }

        function clearAliceMessages() {
            document.getElementById('aliceMessages').innerHTML = '';
        }

        function clearBobMessages() {
            document.getElementById('bobMessages').innerHTML = '';
        }

        // Alice actions
        function aliceConnect() {
            aliceClient.openConnection();
        }

        function aliceDisconnect() {
            aliceClient.closeConnection();
        }

        function aliceSubscribe() {
            var channel = document.getElementById('aliceChannel').value;

            // Check if already subscribed
            if (aliceChannels.indexOf(channel) >= 0) {
                addAliceMessage('⚠️ Already subscribed to ' + channel, 'warning');
                return;
            }

            try {
                aliceClient.subscribe(channel, {
                    userId: 'alice',
                    tier: 'free',
                    username: 'Alice'
                }, function(err, result) {
                    if (err) {
                        addAliceMessage('❌ Subscribe error: ' + err, 'error');
                    } else {
                        aliceChannels.push(channel);
                        addAliceMessage('✅ Subscribed to ' + channel + ' (Total: ' + aliceChannels.join(', ') + ')', 'success');
                    }
                });
                addAliceMessage('📤 Subscribing to ' + channel + '...');
            } catch (e) {
                addAliceMessage('❌ Error: ' + e.message, 'error');
            }
        }

        function aliceSendMessage() {
            var channel = document.getElementById('aliceChannel').value;

            if (aliceChannels.indexOf(channel) < 0) {
                alert('You must subscribe to ' + channel + ' first!');
                return;
            }

            var messageText = document.getElementById('aliceMessage').value;
            if (!messageText) {
                alert('Enter a message!');
                return;
            }

            var message = {
                text: messageText,
                userId: 'alice',
                tier: 'free',
                timestamp: new Date().toISOString()
            };

            // Add premium features if checked
            if (document.getElementById('aliceAttachment').checked) {
                message.attachment = 'alice_document.pdf';
                message.isPremiumFeature = true;
            }
            if (document.getElementById('aliceFormatting').checked) {
                message.formatted = true;
                message.isPremiumFeature = true;
            }

            try {
                aliceClient.publish(channel, message);
                addAliceMessage('📤 Sent to ' + channel);
            } catch (e) {
                addAliceMessage('❌ Error: ' + e.message, 'error');
            }
        }

        // Bob actions
        function bobConnect() {
            bobClient.openConnection();
        }

        function bobDisconnect() {
            bobClient.closeConnection();
        }

        function bobSubscribe() {
            var channel = document.getElementById('bobChannel').value;

            // Check if already subscribed
            if (bobChannels.indexOf(channel) >= 0) {
                addBobMessage('⚠️ Already subscribed to ' + channel, 'warning');
                return;
            }

            try {
                bobClient.subscribe(channel, {
                    userId: 'bob',
                    tier: 'premium',
                    username: 'Bob'
                }, function(err, result) {
                    if (err) {
                        addBobMessage('❌ Subscribe error: ' + err, 'error');
                    } else {
                        bobChannels.push(channel);
                        addBobMessage('✅ Subscribed to ' + channel + ' (Total: ' + bobChannels.join(', ') + ')', 'success');
                    }
                });
                addBobMessage('📤 Subscribing to ' + channel + '...');
            } catch (e) {
                addBobMessage('❌ Error: ' + e.message, 'error');
            }
        }

        function bobSendMessage() {
            var channel = document.getElementById('bobChannel').value;

            if (bobChannels.indexOf(channel) < 0) {
                alert('You must subscribe to ' + channel + ' first!');
                return;
            }

            var messageText = document.getElementById('bobMessage').value;
            if (!messageText) {
                alert('Enter a message!');
                return;
            }

            var message = {
                text: messageText,
                userId: 'bob',
                tier: 'premium',
                timestamp: new Date().toISOString()
            };

            // Add premium features if checked
            if (document.getElementById('bobAttachment').checked) {
                message.attachment = 'bob_presentation.pptx';
                message.isPremiumFeature = true;
            }
            if (document.getElementById('bobFormatting').checked) {
                message.formatted = true;
                message.isPremiumFeature = true;
            }

            try {
                bobClient.publish(channel, message);
                addBobMessage('📤 Sent to ' + channel);
            } catch (e) {
                addBobMessage('❌ Error: ' + e.message, 'error');
            }
        }

        // Display client info on load
        console.log('=== CFWEBSOCKET Clients Generated ===');
        console.log('Alice client (free tier):', aliceClient);
        console.log('Bob client (premium tier):', bobClient);
    </script>
</body>
</html>
