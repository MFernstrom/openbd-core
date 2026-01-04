<!---
  Chat History Listener for Demo Chat Application

  PURPOSE:
  This component stores chat message history for each room in the server scope,
  allowing users to see full conversation history when switching between rooms.

  FLOW:
  1. When initialized, creates server.chatHistory structure if it doesn't exist
  2. beforePublish() - Adds timestamp and username to messages before broadcast
  3. Stores messages in server.chatHistory[channelName] array
  4. Messages are kept in memory for the lifetime of the server

  FEATURES:
  - Automatic message timestamping
  - Username validation and sanitization
  - Message history storage per channel/room
  - Thread-safe message storage using named locks
  - Uses SERVER scope (accessible from WebSocket context)

  USAGE:
  Messages should be sent from the client as:
  {
    username: "Bob",
    text: "Hello everyone!",
    room: "Lobby"
  }

  The listener transforms them to:
  {
    username: "Bob",
    text: "Hello everyone!",
    room: "Lobby",
    timestamp: 1704380400000,
    timeFormatted: "14:20:00"
  }
--->
<cfcomponent extends="OPENBD.websocket.ChannelListener"
             displayname="ChatHistoryListener"
             hint="Stores chat history for demo rooms">

	<!---
	  Initialize the chat history storage
	  Called when the component is first loaded
	--->
	<cffunction name="init" returntype="any" access="public" output="false">
		<!--- Use SERVER scope instead of APPLICATION - it's available in WebSocket context --->
		<cflock name="chatHistory" type="exclusive" timeout="5">
			<cfif NOT structKeyExists(server, "chatHistory")>
				<cfset server.chatHistory = {}>
			</cfif>
		</cflock>
		<cfreturn this>
	</cffunction>


	<!---
	  beforePublish - Add timestamp and store message in history

	  This hook is called before broadcasting a message to subscribers.
	  We use it to:
	  1. Add server-side timestamp to ensure consistency
	  2. Format the timestamp for display
	  3. Sanitize/validate the message
	  4. Store the message in server.chatHistory

	  @publisherInfo - Information about who is publishing (includes connectionId, subscriberInfo)
	  @message - The message being published (struct with username, text, room)
	  @return struct - The enhanced message with timestamp
	--->
	<cffunction name="beforePublish" returntype="any" access="public" output="false">
		<cfargument name="publisherInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<!--- Create a copy to avoid modifying the original --->
		<cfset var enhancedMessage = duplicate(arguments.message)>

		<!--- Add server-side timestamp --->
		<cfset var now = now()>
		<cfset enhancedMessage.timestamp = now.getTime()>
		<cfset enhancedMessage.timeFormatted = timeFormat(now, "HH:mm:ss")>

		<!--- Validate username (use "Anonymous" if missing) --->
		<cfif NOT structKeyExists(enhancedMessage, "username") OR
		      len(trim(enhancedMessage.username)) EQ 0>
			<cfset enhancedMessage.username = "Anonymous">
		<cfelse>
			<!--- Sanitize username: remove extra whitespace and limit length --->
			<cfset enhancedMessage.username = left(trim(enhancedMessage.username), 50)>
		</cfif>

		<!--- Sanitize message text --->
		<cfif structKeyExists(enhancedMessage, "text")>
			<cfset enhancedMessage.text = trim(enhancedMessage.text)>
		</cfif>

		<!--- Determine which room/channel to store this in --->
		<cfset var channelName = "Lobby"> <!--- Default channel --->
		<cfif structKeyExists(enhancedMessage, "room") AND len(enhancedMessage.room) GT 0>
			<cfset channelName = enhancedMessage.room>
		</cfif>

		<!--- Store message in history --->
		<!--- Use SERVER scope - available in WebSocket context --->
		<cflock name="chatHistory" type="exclusive" timeout="5">
			<!--- Ensure chatHistory exists --->
			<cfif NOT structKeyExists(server, "chatHistory")>
				<cfset server.chatHistory = {}>
			</cfif>

			<!--- Ensure this channel's history array exists --->
			<cfif NOT structKeyExists(server.chatHistory, channelName)>
				<cfset server.chatHistory[channelName] = []>
			</cfif>

			<!--- Add message to history (keep last 100 messages per room) --->
			<cfset arrayAppend(server.chatHistory[channelName], enhancedMessage)>

			<!--- Trim history if it gets too large (keep last 100 messages) --->
			<cfif arrayLen(server.chatHistory[channelName]) GT 100>
				<cfset arrayDeleteAt(server.chatHistory[channelName], 1)>
			</cfif>
		</cflock>

		<!--- Log the message for debugging --->
		<cflog text="[ChatDemo] Message stored in #channelName#: #enhancedMessage.username# - #enhancedMessage.text#"
		       type="information">

		<!--- Return the enhanced message for broadcasting --->
		<cfreturn enhancedMessage>
	</cffunction>

</cfcomponent>
