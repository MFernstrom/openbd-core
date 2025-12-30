<!---
  Example Channel Listener with Room-Based Filtering

  This CFC demonstrates the canSendMessage() and beforeSendMessage() hooks
  by implementing room-based message filtering and per-subscriber customization.

  Phase 3, Stage 5: canSendMessage() and beforeSendMessage() hooks demo
--->
<cfcomponent extends="ChannelListener" displayname="RoomChannelListener" hint="Channel listener with room-based filtering">

	<!---
	  canSendMessage - Only send messages to subscribers in the same room

	  This implements room-based chat where messages are only delivered
	  to users in the same room as the sender.

	  @subscriberInfo - Struct of the potential recipient
	  @message - The message being broadcast
	  @return boolean - true to send to this subscriber, false to filter out
	--->
	<cffunction name="canSendMessage" returntype="boolean" access="public" output="false">
		<cfargument name="subscriberInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<!--- If message has a room specified, only send to users in that room --->
		<cfif structKeyExists(arguments.message, "room") AND
		      len(arguments.message.room) GT 0>

			<!--- Check if subscriber has a room --->
			<cfif structKeyExists(arguments.subscriberInfo, "room")>

				<!--- Only send if rooms match --->
				<cfif arguments.subscriberInfo.room eq arguments.message.room>
					<cflog text="[WebSocket] Message for room '#arguments.message.room#' sent to subscriber in same room" type="information">
					<cfreturn true>
				<cfelse>
					<cflog text="[WebSocket] Message for room '#arguments.message.room#' filtered out - subscriber in room '#arguments.subscriberInfo.room#'" type="information">
					<cfreturn false>
				</cfif>
			<cfelse>
				<!--- Subscriber not in any room, don't send room-specific messages --->
				<cflog text="[WebSocket] Message for room '#arguments.message.room#' filtered out - subscriber not in any room" type="warning">
				<cfreturn false>
			</cfif>
		</cfif>

		<!--- If no room specified, send to everyone (broadcast message) --->
		<cfreturn true>
	</cffunction>


	<!---
	  beforeSendMessage - Customize message for each subscriber

	  This demonstrates per-subscriber message transformation:
	  - Hides email addresses from other users (privacy)
	  - Adds "isYou" flag if message is from this subscriber
	  - Shows different content based on subscriber role

	  @subscriberInfo - Struct of the recipient
	  @message - The message to be sent
	  @return struct - The customized message for this specific subscriber
	--->
	<cffunction name="beforeSendMessage" returntype="any" access="public" output="false">
		<cfargument name="subscriberInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<!--- Create a copy of the message to customize --->
		<cfset var customMessage = duplicate(arguments.message)>

		<!--- Feature 1: Add "isYou" flag if this is the sender's own message --->
		<cfif structKeyExists(customMessage, "fromUserId") AND
		      structKeyExists(arguments.subscriberInfo, "userId") AND
		      customMessage.fromUserId eq arguments.subscriberInfo.userId>

			<cfset customMessage.isYou = true>
			<cflog text="[WebSocket] Added 'isYou' flag for sender" type="information">
		<cfelse>
			<cfset customMessage.isYou = false>
		</cfif>

		<!--- Feature 2: Privacy - hide email from non-sender users --->
		<cfif structKeyExists(customMessage, "email") AND len(customMessage.email) GT 0>

			<!--- Only show email to the sender --->
			<cfif NOT customMessage.isYou>
				<cfset customMessage.email = "[HIDDEN]">
				<cflog text="[WebSocket] Email hidden from non-sender" type="information">
			</cfif>
		</cfif>

		<!--- Feature 3: Privacy - hide phone number from non-admin users --->
		<cfif structKeyExists(customMessage, "phoneNumber") AND len(customMessage.phoneNumber) GT 0>

			<!--- Only show phone to admins or the sender --->
			<cfset var isAdmin = structKeyExists(arguments.subscriberInfo, "role") AND
			                     arguments.subscriberInfo.role eq "admin">

			<cfif NOT (customMessage.isYou OR isAdmin)>
				<cfset customMessage.phoneNumber = "[ADMIN ONLY]">
				<cflog text="[WebSocket] Phone number hidden from non-admin" type="information">
			</cfif>
		</cfif>

		<!--- Feature 4: Add recipient-specific metadata --->
		<cfset customMessage.viewedBy = arguments.subscriberInfo.userId>
		<cfset customMessage.viewTime = now().getTime()>

		<cfreturn customMessage>
	</cffunction>

</cfcomponent>
