<!---
  WebSocket Chat Demo - Status & Manual Initialization

  PURPOSE:
  This page shows the current status of the chat application and provides
  manual control over initialization. With Application.cfc in place,
  channels are automatically registered on app start, so this page is
  mainly for troubleshooting and manual reinitialization.

  FLOW:
  1. Display current application status
  2. Show channel registration status
  3. Provide option to manually reinitialize if needed
  4. Display current message history stats

  USAGE:
  - Visit to check application status
  - Use "?reinit=true" URL parameter to force reinitialization
  - View debug info with "?debug=true"

  NOTE:
  Application.cfc automatically initializes channels on first request,
  so visiting index.html directly will work without coming here first.
--->
<!DOCTYPE html>
<html>
<head>
	<title>WebSocket Chat Demo - Status</title>
	<style>
		body {
			font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
			max-width: 800px;
			margin: 40px auto;
			padding: 20px;
			background-color: #f5f5f5;
		}
		h1 {
			color: #333;
			border-bottom: 3px solid #007bff;
			padding-bottom: 10px;
		}
		.status-box {
			padding: 15px;
			margin: 15px 0;
			border-radius: 5px;
			border-left: 5px solid #ccc;
		}
		.success {
			background-color: #d4edda;
			border-left-color: #28a745;
			color: #155724;
		}
		.error {
			background-color: #f8d7da;
			border-left-color: #dc3545;
			color: #721c24;
		}
		.info {
			background-color: #d1ecf1;
			border-left-color: #17a2b8;
			color: #0c5460;
		}
		.next-step {
			background-color: #fff;
			padding: 20px;
			border-radius: 5px;
			margin-top: 30px;
			box-shadow: 0 2px 4px rgba(0,0,0,0.1);
		}
		code {
			background-color: #f8f9fa;
			padding: 2px 6px;
			border-radius: 3px;
			font-family: 'Courier New', monospace;
		}
		.btn {
			display: inline-block;
			padding: 10px 20px;
			background-color: #007bff;
			color: white;
			text-decoration: none;
			border-radius: 5px;
			margin-top: 10px;
		}
		.btn:hover {
			background-color: #0056b3;
		}
	</style>
</head>
<body>
	<h1>WebSocket Chat Demo - Status</h1>

	<!--- Check application status --->
	<!--- Chat history is in SERVER scope, status tracking in APPLICATION scope --->
	<cflock name="chatHistory" type="readonly" timeout="5">
		<cfset appInitialized = structKeyExists(server, "chatHistory")>
		<cfset lobbyMessages = 0>
		<cfset generalMessages = 0>

		<cfif appInitialized>
			<cfset lobbyMessages = structKeyExists(server.chatHistory, "Lobby") ? arrayLen(server.chatHistory["Lobby"]) : 0>
			<cfset generalMessages = structKeyExists(server.chatHistory, "General") ? arrayLen(server.chatHistory["General"]) : 0>
		</cfif>
	</cflock>

	<cflock scope="application" type="readonly" timeout="5">
		<cfset channelsRegistered = structKeyExists(application, "channelsRegistered") AND application.channelsRegistered>
		<cfset initTime = structKeyExists(application, "initTime") ? application.initTime : "">
	</cflock>

	<!--- Application Status --->
	<h2>Application Status</h2>
	<cfif appInitialized>
		<div class="status-box success">
			✅ <strong>Application Initialized</strong><br>
			<cfif initTime NEQ "">
				Initialized at: <cfoutput>#dateFormat(initTime, "yyyy-mm-dd")# #timeFormat(initTime, "HH:mm:ss")#</cfoutput>
			</cfif>
		</div>
	<cfelse>
		<div class="status-box error">
			❌ <strong>Application Not Initialized</strong><br>
			The application has not been initialized yet. Visit <a href="index.html">index.html</a> to trigger initialization.
		</div>
	</cfif>

	<!--- Channel Status --->
	<h2>Channel Status</h2>
	<cfif channelsRegistered>
		<div class="status-box success">
			✅ <strong>Channels Registered</strong><br>
			Both "Lobby" and "General" channels are registered with ChatHistoryListener
		</div>
	<cfelse>
		<div class="status-box info">
			ℹ️ <strong>Channels Status Unknown</strong><br>
			Channels may be registered but status tracking is not available.
		</div>
	</cfif>

	<!--- Message History Stats --->
	<cfif appInitialized>
		<h2>Message History</h2>
		<div class="status-box info">
			<strong>Current Messages:</strong><br>
			<ul style="margin: 10px 0 0 20px;">
				<li>Lobby: <cfoutput>#lobbyMessages#</cfoutput> messages</li>
				<li>General: <cfoutput>#generalMessages#</cfoutput> messages</li>
			</ul>
		</div>
	</cfif>

	<!--- Actions --->
	<div class="next-step">
		<h2>Actions</h2>

		<h3>Start Chatting:</h3>
		<a href="index.html" class="btn">Open Chat Application →</a>

		<h3 style="margin-top: 20px;">Troubleshooting:</h3>
		<p>If you're experiencing issues, you can reinitialize the application:</p>
		<a href="?reinit=true" class="btn" style="background-color: #ffc107; color: #000;">Reinitialize Application</a>

		<p style="margin-top: 15px; font-size: 14px; color: #666;">
			<strong>Note:</strong> Reinitialization will restart the application and clear all message history.
		</p>

		<h3 style="margin-top: 20px;">Debug:</h3>
		<a href="?debug=true" class="btn" style="background-color: #6c757d;">View Debug Info</a>
	</div>

	<!--- Debug Information --->
	<cfif structKeyExists(url, "debug") AND url.debug EQ true>
		<div class="status-box info">
			<h3>Debug Information</h3>
			<p><strong>Chat History Storage (SERVER scope):</strong></p>
			<cflock name="chatHistory" type="readonly" timeout="5">
				<cfdump var="#server.chatHistory#" label="server.chatHistory">
			</cflock>
		</div>
	</cfif>

</body>
</html>
