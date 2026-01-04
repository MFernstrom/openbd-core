<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Simple WebSocket Example - Using cfwebsocket</title>
	<link rel="stylesheet" href="style.css">
</head>
<body>
	<div class="container">
		<h1>Simple WebSocket Example</h1>
		<p class="subtitle">Using the <code>&lt;cfwebsocket&gt;</code> tag for easy WebSocket integration</p>

		<!-- Connection Status -->
		<div class="section">
			<h2>Connection Status</h2>
			<div id="status" class="status disconnected">Disconnected</div>
		</div>

		<!-- Connection Controls -->
		<div class="section">
			<h2>1. Connect to WebSocket</h2>
			<div class="info">
				First, establish a connection to the WebSocket server using <code>simpleWS.openConnection()</code>
			</div>
			<button id="connectBtn" onclick="connect()">Connect</button>
			<button id="disconnectBtn" onclick="disconnect()" disabled>Disconnect</button>
		</div>

		<!-- Subscribe Controls -->
		<div class="section">
			<h2>2. Subscribe to Channel</h2>
			<div class="info">
				Subscribe to the <code>notifications</code> channel to receive messages using <code>simpleWS.subscribe()</code>
			</div>
			<button id="subscribeBtn" onclick="subscribeToChannel()" disabled>Subscribe to "notifications"</button>
			<button id="unsubscribeBtn" onclick="unsubscribeFromChannel()" disabled>Unsubscribe</button>
		</div>

		<!-- Publish Controls -->
		<div class="section">
			<h2>3. Publish a Message</h2>
			<div class="info">
				Send a message to all subscribers using <code>simpleWS.publish()</code>
			</div>
			<input type="text" id="messageInput" placeholder="Type your message here..." disabled>
			<button id="publishBtn" onclick="publishMessage()" disabled>Publish Message</button>
		</div>

		<!-- Messages Display -->
		<div class="section">
			<h2>4. Received Messages</h2>
			<div id="messages"></div>
		</div>

		<div class="section">
			<h2>About cfwebsocket</h2>
			<div class="info">
				<strong>The <code>&lt;cfwebsocket&gt;</code> tag simplifies WebSocket usage!</strong><br>
				It automatically generates a JavaScript object with methods for connection, subscription, and messaging.<br>
				<br>
				<strong>Available methods on <code>simpleWS</code>:</strong>
				<ul style="margin: 10px 0; padding-left: 20px;">
					<li><code>openConnection()</code> - Connect to WebSocket server</li>
					<li><code>closeConnection()</code> - Disconnect from server</li>
					<li><code>subscribe(channel, info, callback)</code> - Subscribe to a channel</li>
					<li><code>unsubscribe(channel)</code> - Unsubscribe from a channel</li>
					<li><code>publish(channel, message)</code> - Publish a message</li>
				</ul>
			</div>
		</div>
	</div>

	<script>
		// Track subscription state
		let isSubscribed = false;
		const CHANNEL_NAME = 'notifications';

		// DOM elements
		const statusDiv = document.getElementById('status');
		const connectBtn = document.getElementById('connectBtn');
		const disconnectBtn = document.getElementById('disconnectBtn');
		const subscribeBtn = document.getElementById('subscribeBtn');
		const unsubscribeBtn = document.getElementById('unsubscribeBtn');
		const messageInput = document.getElementById('messageInput');
		const publishBtn = document.getElementById('publishBtn');
		const messagesDiv = document.getElementById('messages');

		/**
		 * Event handler functions for cfwebsocket
		 * These MUST be defined BEFORE the cfwebsocket tag
		 */

		/**
		 * Called when a message is received from a subscribed channel
		 * @param {string} channelName - The channel the message came from
		 * @param {object} message - The message content
		 */
		function handleWsMessage(channelName, message) {
			console.log('Received message on channel:', channelName, message);
			addMessage('Channel Message', `[${channelName}] ${JSON.stringify(message, null, 2)}`);
		}

		/**
		 * Called when WebSocket connection is established
		 * @param {object} event - The connection event
		 */
		function handleWsOpen(event) {
			console.log('WebSocket connected', event);
			updateStatus('Connected', true);
			addMessage('System', '✅ Connected to WebSocket server via cfwebsocket tag!');
		}

		/**
		 * Called when WebSocket connection is closed
		 * @param {object} event - The close event
		 */
		function handleWsClose(event) {
			console.log('WebSocket disconnected', event);
			updateStatus('Disconnected', false);
			addMessage('System', '🔌 Disconnected from WebSocket server');
			isSubscribed = false;
			updateButtons();
		}

		/**
		 * Called when a WebSocket error occurs
		 * @param {object} error - The error object
		 */
		function handleWsError(error) {
			console.error('WebSocket error:', error);
			addMessage('Error', '❌ WebSocket error: ' + JSON.stringify(error));
		}
	</script>

	<!---
		CFWEBSOCKET TAG
		This tag generates a JavaScript WebSocket client object.
		Event handlers must be defined before this tag.
	--->
	<cfwebsocket
		name="simpleWS"
		onMessage="handleWsMessage"
		onOpen="handleWsOpen"
		onClose="handleWsClose"
		onError="handleWsError">

	<script>
		/**
		 * Application functions that use the cfwebsocket-generated object
		 */

		/**
		 * Connect to the WebSocket server
		 * Uses the cfwebsocket openConnection() method
		 */
		function connect() {
			addMessage('System', 'Connecting to WebSocket server...');
			try {
				simpleWS.openConnection();
			} catch (error) {
				addMessage('Error', 'Failed to connect: ' + error.message);
				console.error('Connection error:', error);
			}
		}

		/**
		 * Disconnect from the WebSocket server
		 * Uses the cfwebsocket closeConnection() method
		 */
		function disconnect() {
			try {
				simpleWS.closeConnection();
			} catch (error) {
				addMessage('Error', 'Failed to disconnect: ' + error.message);
			}
		}

		/**
		 * Subscribe to the notifications channel
		 * Uses the cfwebsocket subscribe() method
		 */
		function subscribeToChannel() {
			addMessage('System', `Subscribing to "${CHANNEL_NAME}" channel...`);

			try {
				simpleWS.subscribe(
					CHANNEL_NAME,
					{
						userAgent: navigator.userAgent,
						timestamp: new Date().toISOString()
					},
					function(err, result) {
						if (err) {
							addMessage('Error', `❌ Subscribe error: ${err}`);
							console.error('Subscribe error:', err);
						} else {
							addMessage('System', `✅ Successfully subscribed to "${CHANNEL_NAME}"`);
							isSubscribed = true;
							updateButtons();
						}
					}
				);
			} catch (error) {
				addMessage('Error', 'Failed to subscribe: ' + error.message);
				console.error('Subscribe error:', error);
			}
		}

		/**
		 * Unsubscribe from the notifications channel
		 * Uses the cfwebsocket unsubscribe() method
		 */
		function unsubscribeFromChannel() {
			addMessage('System', `Unsubscribing from "${CHANNEL_NAME}" channel...`);

			try {
				simpleWS.unsubscribe(CHANNEL_NAME);
				addMessage('System', `✅ Successfully unsubscribed from "${CHANNEL_NAME}"`);
				isSubscribed = false;
				updateButtons();
			} catch (error) {
				addMessage('Error', 'Failed to unsubscribe: ' + error.message);
				console.error('Unsubscribe error:', error);
			}
		}

		/**
		 * Publish a message to the notifications channel
		 * Uses the cfwebsocket publish() method
		 */
		function publishMessage() {
			const messageText = messageInput.value.trim();

			if (!messageText) {
				alert('Please enter a message to publish.');
				return;
			}

			if (!isSubscribed) {
				addMessage('Error', 'Not subscribed to the channel. Subscribe first!');
				return;
			}

			try {
				simpleWS.publish(CHANNEL_NAME, {
					text: messageText,
					timestamp: new Date().toISOString(),
					userAgent: navigator.userAgent
				});

				addMessage('System', `📤 Published message to "${CHANNEL_NAME}"`);
				messageInput.value = '';
			} catch (error) {
				addMessage('Error', 'Failed to publish: ' + error.message);
				console.error('Publish error:', error);
			}
		}

		/**
		 * Helper function: Add a message to the display
		 * @param {string} sender - Who/what sent the message
		 * @param {string} content - The message content
		 */
		function addMessage(sender, content) {
			const messageDiv = document.createElement('div');
			messageDiv.className = 'message';

			const timeDiv = document.createElement('div');
			timeDiv.className = 'time';
			timeDiv.textContent = `[${new Date().toLocaleTimeString()}] ${sender}`;

			const contentDiv = document.createElement('div');
			contentDiv.className = 'content';
			contentDiv.textContent = content;

			messageDiv.appendChild(timeDiv);
			messageDiv.appendChild(contentDiv);
			messagesDiv.appendChild(messageDiv);

			// Auto-scroll to bottom
			messagesDiv.scrollTop = messagesDiv.scrollHeight;
		}

		/**
		 * Helper function: Update the connection status display
		 * @param {string} text - Status text to display
		 * @param {boolean} connected - Whether we're connected
		 */
		function updateStatus(text, connected) {
			statusDiv.textContent = text;
			statusDiv.className = 'status ' + (connected ? 'connected' : 'disconnected');
			updateButtons();
		}

		/**
		 * Helper function: Update button enabled/disabled states
		 */
		function updateButtons() {
			// Check if simpleWS exists and has a connection
			const isConnected = typeof simpleWS !== 'undefined' &&
			                    simpleWS.ws &&
			                    simpleWS.ws.readyState === WebSocket.OPEN;

			connectBtn.disabled = isConnected;
			disconnectBtn.disabled = !isConnected;
			subscribeBtn.disabled = !isConnected || isSubscribed;
			unsubscribeBtn.disabled = !isConnected || !isSubscribed;
			messageInput.disabled = !isConnected || !isSubscribed;
			publishBtn.disabled = !isConnected || !isSubscribed;
		}

		// Allow Enter key to publish message
		messageInput.addEventListener('keypress', function(event) {
			if (event.key === 'Enter' && !publishBtn.disabled) {
				publishMessage();
			}
		});

		// Initial message
		addMessage('System', 'Welcome! The cfwebsocket tag has created the "simpleWS" object. Click "Connect" to begin.');

		// Log the cfwebsocket object for debugging
		console.log('=== CFWEBSOCKET Tag Generated ===');
		console.log('simpleWS object:', simpleWS);
		console.log('Available methods:', Object.keys(simpleWS).filter(k => typeof simpleWS[k] === 'function'));
	</script>
</body>
</html>
