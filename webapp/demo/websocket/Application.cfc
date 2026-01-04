<!---
  Application.cfc for WebSocket Chat Demo

  PURPOSE:
  Manages application lifecycle for the chat demo, including automatic
  channel initialization on application startup.

  FLOW:
  1. onApplicationStart() - Called when application first starts
     - Registers "Lobby" and "General" channels
     - Attaches ChatHistoryListener to both channels
     - Initializes application.chatHistory storage
  2. onApplicationEnd() - Called when application shuts down
     - Cleanup (optional)

  FEATURES:
  - Automatic channel registration on app start
  - Centralized application settings
  - Session management for user tracking
  - Proper error handling with logging

  PRODUCTION READY:
  This structure is suitable for production deployment with minimal changes.
  Simply add authentication, database persistence, and additional security.
--->
<cfcomponent output="false">

	<!--- Application Settings --->
	<cfset this.name = "WebSocketChatDemo">
	<cfset this.applicationTimeout = createTimeSpan(0, 2, 0, 0)> <!--- 2 hours --->
	<cfset this.sessionManagement = true>
	<cfset this.sessionTimeout = createTimeSpan(0, 0, 30, 0)> <!--- 30 minutes --->
	<cfset this.setClientCookies = true>


	<!---
	  onApplicationStart - Initialize WebSocket channels and storage

	  This method is called once when the application first starts.
	  It sets up the WebSocket infrastructure needed for the chat application.

	  FLOW:
	  1. Initialize chat history storage in application scope
	  2. Register "Lobby" channel with ChatHistoryListener
	  3. Register "General" channel with ChatHistoryListener
	  4. Log success/failure for debugging

	  @return boolean - true to continue application startup
	--->
	<cffunction name="onApplicationStart" returntype="boolean" output="false"
	            hint="Initialize WebSocket channels on application startup">

		<cflog text="[ChatDemo] Application starting - initializing WebSocket channels"
		       type="information">

		<!--- Initialize the chat history storage structure --->
		<!--- Use SERVER scope so it's accessible from WebSocket context --->
		<cftry>
			<cflock name="chatHistory" type="exclusive" timeout="10">
				<cfset server.chatHistory = {}>
				<cfset server.chatHistory["Lobby"] = []>
				<cfset server.chatHistory["General"] = []>
			</cflock>

			<!--- Track initialization time in application scope for status page --->
			<cflock scope="application" type="exclusive" timeout="5">
				<cfset application.initTime = now()>
				<cfset application.channelsRegistered = false>
			</cflock>

			<cflog text="[ChatDemo] Chat history storage initialized in SERVER scope"
			       type="information">

			<cfcatch>
				<cflog text="[ChatDemo] ERROR initializing chat history: #cfcatch.message#"
				       type="error">
				<!--- Continue anyway, channels might still work --->
			</cfcatch>
		</cftry>

		<!--- Register Lobby Channel --->
		<cftry>
			<cfset var lobbyResult = wsRegisterChannel(
				channelName: "Lobby",
				listener: "demo.websocket.ChatHistoryListener"
			)>

			<cfif lobbyResult>
				<cflog text="[ChatDemo] Successfully registered 'Lobby' channel with ChatHistoryListener"
				       type="information">
			<cfelse>
				<cflog text="[ChatDemo] 'Lobby' channel already registered (may be from previous initialization)"
				       type="warning">
			</cfif>

			<cfcatch>
				<cflog text="[ChatDemo] ERROR registering Lobby channel: #cfcatch.message# - #cfcatch.detail#"
				       type="error">
				<!--- Don't fail app startup, but log the error --->
			</cfcatch>
		</cftry>

		<!--- Register General Channel --->
		<cftry>
			<cfset var generalResult = wsRegisterChannel(
				channelName: "General",
				listener: "demo.websocket.ChatHistoryListener"
			)>

			<cfif generalResult>
				<cflog text="[ChatDemo] Successfully registered 'General' channel with ChatHistoryListener"
				       type="information">
			<cfelse>
				<cflog text="[ChatDemo] 'General' channel already registered (may be from previous initialization)"
				       type="warning">
			</cfif>

			<!--- Mark channels as successfully registered --->
			<cflock scope="application" type="exclusive" timeout="5">
				<cfset application.channelsRegistered = true>
			</cflock>

			<cfcatch>
				<cflog text="[ChatDemo] ERROR registering General channel: #cfcatch.message# - #cfcatch.detail#"
				       type="error">
			</cfcatch>
		</cftry>

		<cflog text="[ChatDemo] Application initialization complete"
		       type="information">

		<!--- Return true to allow application to start --->
		<cfreturn true>
	</cffunction>


	<!---
	  onSessionStart - Initialize session variables for new user

	  Called when a new session starts (user first visits the app).
	  You can track user-specific data here if needed.

	  @return void
	--->
	<cffunction name="onSessionStart" returntype="void" output="false"
	            hint="Initialize session for new user">

		<!--- Initialize session tracking --->
		<cfset session.sessionStartTime = now()>
		<cfset session.messageCount = 0>

		<cflog text="[ChatDemo] New session started: #session.sessionId#"
		       type="information">
	</cffunction>


	<!---
	  onRequestStart - Called before each page request

	  Use this for debugging or to provide a way to reinitialize
	  the application without restarting the server.

	  @targetPage - The page being requested
	  @return boolean - true to continue processing the request
	--->
	<cffunction name="onRequestStart" returntype="boolean" output="false"
	            hint="Process before each request">
		<cfargument name="targetPage" type="string" required="true">

		<!--- Allow URL parameter to reinitialize application --->
		<cfif structKeyExists(url, "reinit") AND url.reinit EQ true>
			<cflock scope="application" type="exclusive" timeout="10">
				<cfset applicationStop()>
			</cflock>
			<cflocation url="#arguments.targetPage#" addtoken="false">
		</cfif>

		<!--- Continue processing --->
		<cfreturn true>
	</cffunction>


	<!---
	  onApplicationEnd - Cleanup when application stops

	  Called when the application times out or server shuts down.
	  Use this for cleanup tasks if needed.

	  @return void
	--->
	<cffunction name="onApplicationEnd" returntype="void" output="false"
	            hint="Cleanup on application shutdown">
		<cfargument name="applicationScope" type="struct" required="true">

		<cflog text="[ChatDemo] Application ending - cleanup complete"
		       type="information">
	</cffunction>


	<!---
	  onError - Global error handler

	  Catches unhandled errors in the application.
	  Logs the error and displays a friendly message.

	  @exception - The exception object
	  @eventName - The event that caused the error
	  @return void
	--->
	<cffunction name="onError" returntype="void" output="true"
	            hint="Handle uncaught errors">
		<cfargument name="exception" type="any" required="true">
		<cfargument name="eventName" type="string" required="true">

		<!--- Log the error --->
		<cflog text="[ChatDemo] ERROR in #arguments.eventName#: #arguments.exception.message#"
		       type="error">

		<!--- Display friendly error page --->
		<cfoutput>
			<html>
			<head><title>Error - WebSocket Chat Demo</title></head>
			<body style="font-family: Arial; padding: 40px; background: ##f5f5f5;">
				<div style="background: white; padding: 30px; border-radius: 10px; max-width: 600px; margin: 0 auto;">
					<h1 style="color: ##dc3545;">An Error Occurred</h1>
					<p>We're sorry, but something went wrong with the chat application.</p>

					<div style="background: ##f8d7da; padding: 15px; border-radius: 5px; margin: 20px 0;">
						<strong>Error:</strong> #arguments.exception.message#
					</div>

					<p>
						<a href="index.html" style="color: ##007bff;">Return to Chat</a> |
						<a href="init.cfm" style="color: ##007bff;">Reinitialize Channels</a>
					</p>

					<cfif structKeyExists(url, "debug") AND url.debug>
						<hr>
						<h3>Debug Information</h3>
						<cfdump var="#arguments.exception#" label="Exception Details">
					</cfif>
				</div>
			</body>
			</html>
		</cfoutput>
	</cffunction>

</cfcomponent>
