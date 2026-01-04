<!---
  Get Chat History API Endpoint

  PURPOSE:
  Returns the message history for a specific chat room as JSON.

  FLOW:
  1. Receives room name via URL parameter (?room=Lobby)
  2. Retrieves message history from server.chatHistory
  3. Returns array of messages as JSON

  USAGE:
  GET /demo/websocket/getHistory.cfm?room=Lobby

  RESPONSE:
  [
    {
      "username": "Alice",
      "text": "Hello!",
      "room": "Lobby",
      "timestamp": 1704380400000,
      "timeFormatted": "14:20:00"
    },
    ...
  ]
--->
<cfsilent>
	<!--- Get the room name from URL parameter --->
	<cfparam name="url.room" default="Lobby">

	<!--- Retrieve message history for the room --->
	<cflock name="chatHistory" type="readonly" timeout="5">
		<cfif structKeyExists(server, "chatHistory") AND
		      structKeyExists(server.chatHistory, url.room)>
			<cfset messageHistory = server.chatHistory[url.room]>
		<cfelse>
			<!--- No history found, return empty array --->
			<cfset messageHistory = []>
		</cfif>
	</cflock>

	<!--- Set content type to JSON --->
	<cfcontent type="application/json" reset="true">
</cfsilent><!--- Output the history as JSON --->
<cfoutput>#serializeJSON(messageHistory)#</cfoutput>
