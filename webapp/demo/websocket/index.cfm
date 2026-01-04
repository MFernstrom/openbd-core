<!DOCTYPE html>
<!--
  WebSocket Chat Demo Application

  PURPOSE:
  Demonstrates OpenBD WebSocket functionality with a simple multi-room chat application.

  FEATURES:
  - Two chat rooms: Lobby and General
  - Auto-connect to Lobby on page load
  - Switch between rooms with full message history
  - Real-time message broadcasting
  - Username customization
  - Clean, modern UI

  FLOW:
  1. Page loads → User enters username
  2. Connect to WebSocket server
  3. Auto-subscribe to "Lobby" channel
  4. Load and display Lobby message history
  5. User can send messages or switch rooms
  6. When switching rooms:
     - Unsubscribe from current room
     - Subscribe to new room
     - Load new room's message history
  7. Messages are broadcast to all users in the same room

  WEBSOCKET PROTOCOL:
  - Subscribe: Send subscriberInfo with username and room
  - Publish: Send message object with username, text, and room
  - Receive: Get messages with username, text, timestamp, and room
-->
<html>
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>WebSocket Chat Demo</title>
	<style>
		* {
			margin: 0;
			padding: 0;
			box-sizing: border-box;
		}

		body {
			font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
			background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
			height: 100vh;
			display: flex;
			justify-content: center;
			align-items: center;
			padding: 20px;
		}
		
		#footer {
		  position: fixed;
		  left: 0;
		  bottom: 0;
		  width: 100%;
		  color: white;
		  text-align: center;
		}

		#loginScreen {
			background: white;
			padding: 40px;
			border-radius: 10px;
			box-shadow: 0 10px 40px rgba(0,0,0,0.2);
			text-align: center;
			max-width: 400px;
			width: 100%;
		}

		#loginScreen h1 {
			color: #667eea;
			margin-bottom: 10px;
		}

		#loginScreen p {
			color: #666;
			margin-bottom: 30px;
		}

		#loginScreen input {
			width: 100%;
			padding: 12px;
			border: 2px solid #e0e0e0;
			border-radius: 5px;
			font-size: 16px;
			margin-bottom: 15px;
			transition: border-color 0.3s;
		}

		#loginScreen input:focus {
			outline: none;
			border-color: #667eea;
		}

		#loginScreen button {
			width: 100%;
			padding: 12px;
			background: #667eea;
			color: white;
			border: none;
			border-radius: 5px;
			font-size: 16px;
			cursor: pointer;
			transition: background 0.3s;
		}

		#loginScreen button:hover {
			background: #5568d3;
		}

		#chatApp {
			display: none;
			background: white;
			width: 100%;
			max-width: 900px;
			height: 600px;
			border-radius: 10px;
			box-shadow: 0 10px 40px rgba(0,0,0,0.2);
			overflow: hidden;
			display: flex;
			flex-direction: column;
		}

		#chatHeader {
			background: #667eea;
			color: white;
			padding: 20px;
			display: flex;
			justify-content: space-between;
			align-items: center;
		}

		#chatHeader h1 {
			font-size: 20px;
		}

		#currentUser {
			font-size: 14px;
			opacity: 0.9;
		}

		#roomTabs {
			display: flex;
			background: #f5f5f5;
			border-bottom: 2px solid #e0e0e0;
		}

		.roomTab {
			flex: 1;
			padding: 15px;
			text-align: center;
			cursor: pointer;
			background: #f5f5f5;
			border: none;
			font-size: 16px;
			transition: all 0.3s;
			position: relative;
		}

		.roomTab:hover {
			background: #e8e8e8;
		}

		.roomTab.active {
			background: white;
			color: #667eea;
			font-weight: bold;
		}

		.roomTab.active::after {
			content: '';
			position: absolute;
			bottom: -2px;
			left: 0;
			right: 0;
			height: 2px;
			background: #667eea;
		}

		#messagesContainer {
			flex: 1;
			overflow-y: auto;
			padding: 20px;
			background: #fafafa;
		}

		.message {
			margin-bottom: 15px;
			animation: slideIn 0.3s ease-out;
		}

		@keyframes slideIn {
			from {
				opacity: 0;
				transform: translateY(10px);
			}
			to {
				opacity: 1;
				transform: translateY(0);
			}
		}

		.message .header {
			display: flex;
			align-items: center;
			margin-bottom: 5px;
		}

		.message .username {
			font-weight: bold;
			color: #667eea;
			margin-right: 10px;
		}

		.message .time {
			font-size: 12px;
			color: #999;
		}

		.message .text {
			color: #333;
			line-height: 1.4;
			padding: 10px 15px;
			background: white;
			border-radius: 5px;
			display: inline-block;
			max-width: 80%;
		}

		.systemMessage {
			text-align: center;
			color: #999;
			font-style: italic;
			margin: 10px 0;
			font-size: 14px;
		}

		#messageInput {
			display: flex;
			padding: 20px;
			background: white;
			border-top: 1px solid #e0e0e0;
		}

		#messageInput input {
			flex: 1;
			padding: 12px;
			border: 2px solid #e0e0e0;
			border-radius: 5px;
			font-size: 14px;
			margin-right: 10px;
		}

		#messageInput input:focus {
			outline: none;
			border-color: #667eea;
		}

		#messageInput button {
			padding: 12px 30px;
			background: #667eea;
			color: white;
			border: none;
			border-radius: 5px;
			cursor: pointer;
			font-size: 14px;
			transition: background 0.3s;
		}

		#messageInput button:hover {
			background: #5568d3;
		}

		#messageInput button:disabled {
			background: #ccc;
			cursor: not-allowed;
		}

		#statusIndicator {
			width: 10px;
			height: 10px;
			border-radius: 50%;
			background: #28a745;
			margin-left: 10px;
			display: inline-block;
		}

		#statusIndicator.disconnected {
			background: #dc3545;
		}

		.hidden {
			display: none !important;
		}
	</style>
</head>
<body>
	<!-- Login Screen -->
	<div id="loginScreen">
		<h1>WebSocket Chat Demo</h1>
		<p>Enter your username to join the chat</p>
		<input type="text" id="usernameInput" placeholder="Enter your username" maxlength="50">
		<button onclick="connect()">Join Chat</button>
	</div>

	<!-- Chat Application -->
	<div id="chatApp" class="hidden">
		<!-- Header -->
		<div id="chatHeader">
			<div>
				<h1>WebSocket Chat Demo</h1>
				<div id="currentUser"></div>
			</div>
			<div style="display: flex; align-items: center;">
				<span id="connectionStatus">Connected</span>
				<span id="statusIndicator"></span>
			</div>
		</div>

		<!-- Room Tabs -->
		<div id="roomTabs">
			<button class="roomTab active" data-room="Lobby" onclick="switchRoom('Lobby')">
				Lobby
			</button>
			<button class="roomTab" data-room="General" onclick="switchRoom('General')">
				General
			</button>
		</div>

		<!-- Messages Area -->
		<div id="messagesContainer"></div>

		<!-- Message Input -->
		<div id="messageInput">
			<input type="text" id="messageText" placeholder="Type your message..." maxlength="500">
			<button onclick="sendMessage()">Send</button>
		</div>
	</div>
	
	<div id="footer">
	  	<cfset channelsRegistered = structKeyExists(application, "channelsRegistered") AND application.channelsRegistered>
		<p>
			<cfif channelsRegistered>
				✅ <strong>Websocket Channels Registered</strong><br>
				Both "Lobby" and "General" channels are registered with ChatHistoryListener
			<cfelse>
				ℹ️ <strong>Channels Status Unknown</strong><br>
				Channels may be registered but status tracking is not available.
			</cfif>
		</p>
		<p>
			Example application. Do not use in production.
		</p>
	</div>

	<script>
		// ===== APPLICATION STATE =====
		let ws = null;                    // WebSocket connection
		let username = '';                // Current user's username
		let currentRoom = 'Lobby';        // Currently active room
		let subscribedChannel = null;     // Currently subscribed channel name
		let subscriptionRetries = {};     // Track retry attempts per channel

		// ===== WEBSOCKET CONNECTION =====

		/**
		 * Connect to WebSocket server and join the chat
		 * Called when user clicks "Join Chat" button
		 *
		 * Flow:
		 * 1. Validate username
		 * 2. Create WebSocket connection
		 * 3. Set up event handlers (open, message, close, error)
		 * 4. Wait for connection to open, then delay 500ms before subscribing
		 *    (allows time for channels to register on first app start)
		 */
		function connect() {
			// Get and validate username
			username = document.getElementById('usernameInput').value.trim();
			if (!username) {
				alert('Please enter a username');
				return;
			}

			// Create WebSocket connection
			// OpenBD WebSocket endpoint: ws://hostname:8580/openbd/ws
			const wsUrl = 'ws://' + window.location.hostname + ':8580/openbd/ws';
			ws = new WebSocket(wsUrl);

			// Connection opened - subscribe to Lobby
			ws.onopen = function() {
				updateConnectionStatus(true);

				// Show chat UI, hide login
				document.getElementById('loginScreen').classList.add('hidden');
				document.getElementById('chatApp').classList.remove('hidden');
				document.getElementById('footer').classList.add('hidden');
				document.getElementById('currentUser').textContent = 'Logged in as: ' + username;

				// Small delay to allow channels to register on first app start
				setTimeout(function() {
					subscribeToRoom('Lobby');
				}, 500);
			};

			// Message received from server
			ws.onmessage = function(event) {
				handleMessage(event.data);
			};

			// Connection closed
			ws.onclose = function() {
				updateConnectionStatus(false);
				addSystemMessage('Disconnected from server');
			};

			// Connection error
			ws.onerror = function(error) {
				console.error('WebSocket error:', error);
				addSystemMessage('Connection error occurred');
			};
		}

		/**
		 * Update connection status indicator in UI
		 */
		function updateConnectionStatus(connected) {
			const statusIndicator = document.getElementById('statusIndicator');
			const statusText = document.getElementById('connectionStatus');

			if (connected) {
				statusIndicator.classList.remove('disconnected');
				statusText.textContent = 'Connected';
			} else {
				statusIndicator.classList.add('disconnected');
				statusText.textContent = 'Disconnected';
			}
		}

		// ===== ROOM MANAGEMENT =====

		/**
		 * Subscribe to a WebSocket channel/room
		 *
		 * Flow:
		 * 1. Send subscribe message with subscriberInfo
		 * 2. subscriberInfo includes username and room for filtering
		 * 3. Server-side listener can use this info for authorization/filtering
		 * 4. If subscription fails (channel not ready), retry with exponential backoff
		 */
		function subscribeToRoom(room) {
			if (!ws || ws.readyState !== WebSocket.OPEN) {
				console.error('WebSocket not connected');
				return;
			}

			// Build subscribe message
			const subscribeMsg = {
				type: 'subscribe',
				channelName: room,
				subscriberInfo: {
					username: username,
					room: room  // Used by server-side filtering
				}
			};

			// Send subscribe request
			ws.send(JSON.stringify(subscribeMsg));
			subscribedChannel = room;

			// Load message history for this room
			loadMessageHistory(room);
		}

		/**
		 * Unsubscribe from current channel
		 */
		function unsubscribeFromRoom() {
			if (!ws || ws.readyState !== WebSocket.OPEN || !subscribedChannel) {
				return;
			}

			// Build unsubscribe message
			const unsubscribeMsg = {
				type: 'unsubscribe',
				channelName: subscribedChannel
			};

			// Send unsubscribe request
			ws.send(JSON.stringify(unsubscribeMsg));

			subscribedChannel = null;
		}

		/**
		 * Switch to a different room
		 * Called when user clicks on room tabs
		 *
		 * Flow:
		 * 1. Unsubscribe from current room
		 * 2. Clear message display
		 * 3. Subscribe to new room
		 * 4. Load new room's message history
		 * 5. Update UI (active tab)
		 */
		function switchRoom(newRoom) {
			if (newRoom === currentRoom) {
				return; // Already in this room
			}

			// Unsubscribe from current room
			unsubscribeFromRoom();

			// Update current room
			currentRoom = newRoom;

			// Clear retry counter for new room
			delete subscriptionRetries[newRoom];

			// Clear messages
			document.getElementById('messagesContainer').innerHTML = '';

			// Subscribe to new room
			subscribeToRoom(newRoom);

			// Update tab UI
			document.querySelectorAll('.roomTab').forEach(tab => {
				if (tab.dataset.room === newRoom) {
					tab.classList.add('active');
				} else {
					tab.classList.remove('active');
				}
			});
		}

		// ===== MESSAGE HANDLING =====

		/**
		 * Send a chat message
		 * Called when user clicks Send button or presses Enter
		 *
		 * Flow:
		 * 1. Get message text from input
		 * 2. Build message object with username, text, room
		 * 3. Send as publish message to current channel
		 * 4. Server-side listener adds timestamp and stores in history
		 */
		function sendMessage() {
			const input = document.getElementById('messageText');
			const text = input.value.trim();

			if (!text) {
				return; // Don't send empty messages
			}

			if (!ws || ws.readyState !== WebSocket.OPEN) {
				addSystemMessage('Cannot send message: not connected');
				return;
			}

			// Build message object
			const message = {
				username: username,
				text: text,
				room: currentRoom
			};

			// Build publish message
			const publishMsg = {
				type: 'publish',
				channelName: currentRoom,
				message: message
			};

			// Send to server
			ws.send(JSON.stringify(publishMsg));

			// Clear input
			input.value = '';
		}

		/**
		 * Handle incoming WebSocket messages
		 * Called by ws.onmessage event handler
		 *
		 * Flow:
		 * 1. Parse JSON message
		 * 2. Check message type (broadcast, subscribe-ack, etc.)
		 * 3. For broadcast messages, display in chat
		 */
		function handleMessage(data) {
			try {
				const msg = JSON.parse(data);

				// Handle different message types
				if (msg.type === 'message' && msg.message) {
					// This is a chat message broadcast
					displayMessage(msg.message);
				} else if (msg.type === 'subscribed') {
					// Clear retry counter on success
					delete subscriptionRetries[msg.channelName];
					addSystemMessage('Connected to ' + msg.channelName);
				} else if (msg.type === 'unsubscribed') {
					// Unsubscription confirmed
				} else if (msg.type === 'error') {
					// Check if this is a subscription error (channel not found)
					if (msg.message && msg.message.toLowerCase().indexOf('subscribe') !== -1) {
						// Likely a channel registration issue, retry subscription
						const channelToRetry = currentRoom;
						const retries = subscriptionRetries[channelToRetry] || 0;

						if (retries < 3) {
							subscriptionRetries[channelToRetry] = retries + 1;

							// Retry after a delay
							setTimeout(function() {
								subscribeToRoom(channelToRetry);
							}, 1000 * (retries + 1)); // Exponential backoff
						} else {
							addSystemMessage('Error: ' + (msg.message || 'Unknown error'));
							addSystemMessage('Unable to connect to channel. Please refresh the page.');
						}
					} else {
						addSystemMessage('Error: ' + (msg.message || 'Unknown error'));
					}
				}
			} catch (e) {
				console.error('Error parsing message:', e);
			}
		}

		/**
		 * Display a chat message in the UI
		 */
		function displayMessage(message) {
			const container = document.getElementById('messagesContainer');

			// Create message element
			const msgDiv = document.createElement('div');
			msgDiv.className = 'message';

			// Format time
			const time = message.timeFormatted || new Date().toLocaleTimeString();

			// Build message HTML
			msgDiv.innerHTML = `
				<div class="header">
					<span class="username">${escapeHtml(message.username)}</span>
					<span class="time">${time}</span>
				</div>
				<div class="text">${escapeHtml(message.text)}</div>
			`;

			// Add to container
			container.appendChild(msgDiv);

			// Auto-scroll to bottom
			container.scrollTop = container.scrollHeight;
		}

		/**
		 * Add a system message (join/leave notifications, errors, etc.)
		 */
		function addSystemMessage(text) {
			const container = document.getElementById('messagesContainer');

			const msgDiv = document.createElement('div');
			msgDiv.className = 'systemMessage';
			msgDiv.textContent = text;

			container.appendChild(msgDiv);
			container.scrollTop = container.scrollHeight;
		}

		/**
		 * Escape HTML to prevent XSS attacks
		 */
		function escapeHtml(text) {
			const div = document.createElement('div');
			div.textContent = text;
			return div.innerHTML;
		}

		// ===== MESSAGE HISTORY =====

		/**
		 * Load message history for a room from the server
		 * Uses AJAX to fetch history from getHistory.cfm
		 *
		 * Flow:
		 * 1. Fetch history from server via AJAX
		 * 2. Parse JSON response (array of messages)
		 * 3. Display each message in order
		 */
		function loadMessageHistory(room) {
			// Fetch history from server
			fetch('getHistory.cfm?room=' + encodeURIComponent(room))
				.then(response => response.json())
				.then(messages => {
					// Display each message
					messages.forEach(message => {
						displayMessage(message);
					});
				})
				.catch(error => {
					console.error('Error loading history:', error);
					addSystemMessage('Could not load message history');
				});
		}

		// ===== KEYBOARD SHORTCUTS =====

		// Send message on Enter key
		document.addEventListener('DOMContentLoaded', function() {
			document.getElementById('messageText').addEventListener('keypress', function(e) {
				if (e.key === 'Enter') {
					sendMessage();
				}
			});

			document.getElementById('usernameInput').addEventListener('keypress', function(e) {
				if (e.key === 'Enter') {
					connect();
				}
			});
		});
	</script>

</body>
</html>
