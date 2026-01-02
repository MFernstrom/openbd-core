<cfcomponent extends="ChannelListener" output="false">
	<!---
		PremiumChatListener: Comprehensive Channel Listener demonstrating all 5 hooks

		This is a real-world example of a premium chat system with:
		- Authentication and tier validation
		- Rate limiting and ban checking
		- Message sanitization and server timestamps
		- Room-based filtering
		- Per-subscriber customization based on tier and preferences
	--->

	<!--- Hook 1: allowSubscribe(subscriberInfo) --->
	<cffunction name="allowSubscribe" returntype="boolean" access="public" output="false">
		<cfargument name="subscriberInfo" type="struct" required="true">

		<!--- Require authentication --->
		<cfif NOT structKeyExists(arguments.subscriberInfo, "userId") OR
		      len(trim(arguments.subscriberInfo.userId)) EQ 0>
			<cfreturn false>
		</cfif>

		<!--- Require valid tier (free, premium, vip) --->
		<cfif NOT structKeyExists(arguments.subscriberInfo, "tier")>
			<cfreturn false>
		</cfif>

		<cfset var tier = arguments.subscriberInfo.tier>
		<cfif tier NEQ "free" AND tier NEQ "premium" AND tier NEQ "vip">
			<cfreturn false>
		</cfif>

		<!--- Check if user is banned --->
		<cfif structKeyExists(arguments.subscriberInfo, "banned") AND
		      arguments.subscriberInfo.banned EQ true>
			<cfreturn false>
		</cfif>

		<!--- VIP room requires VIP tier --->
		<cfif structKeyExists(arguments.subscriberInfo, "room") AND
		      arguments.subscriberInfo.room EQ "vip">
			<cfif tier NEQ "vip">
				<cfreturn false>
			</cfif>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!--- Hook 2: allowPublish(publisherInfo) --->
	<cffunction name="allowPublish" returntype="boolean" access="public" output="false">
		<cfargument name="publisherInfo" type="struct" required="true">

		<cfset var subInfo = arguments.publisherInfo.subscriberInfo>

		<!--- Check if banned --->
		<cfif structKeyExists(subInfo, "banned") AND subInfo.banned EQ true>
			<cfreturn false>
		</cfif>

		<!--- Free tier users can only publish to 'lobby' --->
		<cfif structKeyExists(subInfo, "tier") AND subInfo.tier EQ "free">
			<cfif structKeyExists(subInfo, "room") AND subInfo.room NEQ "lobby">
				<cfreturn false>
			</cfif>
		</cfif>

		<!--- Rate limiting: Check last publish timestamp --->
		<cfif structKeyExists(subInfo, "lastPublishTime")>
			<cfset var timeSinceLastPublish = getTickCount() - subInfo.lastPublishTime>

			<!--- Free: 5 seconds between messages --->
			<cfif subInfo.tier EQ "free" AND timeSinceLastPublish LT 5000>
				<cfreturn false>
			</cfif>

			<!--- Premium: 2 seconds between messages --->
			<cfif subInfo.tier EQ "premium" AND timeSinceLastPublish LT 2000>
				<cfreturn false>
			</cfif>

			<!--- VIP: 1 second between messages --->
			<cfif subInfo.tier EQ "vip" AND timeSinceLastPublish LT 1000>
				<cfreturn false>
			</cfif>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!--- Hook 3: beforePublish(publisherInfo, message) --->
	<cffunction name="beforePublish" returntype="any" access="public" output="false">
		<cfargument name="publisherInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<cfset var transformedMessage = duplicate(arguments.message)>
		<cfset var subInfo = arguments.publisherInfo.subscriberInfo>

		<!--- Add server timestamp --->
		<cfset transformedMessage.serverTime = now().getTime()>
		<cfset transformedMessage.serverTimeFormatted = dateFormat(now(), "yyyy-mm-dd") & " " & timeFormat(now(), "HH:mm:ss")>

		<!--- Sanitize text content (remove HTML, scripts) --->
		<cfif structKeyExists(transformedMessage, "text")>
			<cfset transformedMessage.text = replace(transformedMessage.text, "<", "&lt;", "ALL")>
			<cfset transformedMessage.text = replace(transformedMessage.text, ">", "&gt;", "ALL")>
			<cfset transformedMessage.text = replace(transformedMessage.text, "script", "[removed]", "ALL")>

			<!--- Enforce message length limits based on tier --->
			<cfset var maxLength = 100>
			<cfif subInfo.tier EQ "premium">
				<cfset maxLength = 500>
			<cfelseif subInfo.tier EQ "vip">
				<cfset maxLength = 2000>
			</cfif>

			<cfif len(transformedMessage.text) GT maxLength>
				<cfset transformedMessage.text = left(transformedMessage.text, maxLength) & "... [truncated]">
				<cfset transformedMessage.truncated = true>
			</cfif>
		</cfif>

		<!--- Add tier badge --->
		<cfif subInfo.tier EQ "vip">
			<cfset transformedMessage.badge = "VIP">
		<cfelseif subInfo.tier EQ "premium">
			<cfset transformedMessage.badge = "PREMIUM">
		</cfif>

		<!--- Update last publish time (for rate limiting) --->
		<cfset subInfo.lastPublishTime = getTickCount()>

		<cfreturn transformedMessage>
	</cffunction>

	<!--- Hook 4: canSendMessage(subscriberInfo, message) --->
	<cffunction name="canSendMessage" returntype="boolean" access="public" output="false">
		<cfargument name="subscriberInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<!--- Room-based filtering: Only send to users in the same room --->
		<cfif structKeyExists(arguments.message, "room") AND len(arguments.message.room) GT 0>
			<cfif structKeyExists(arguments.subscriberInfo, "room")>
				<cfif arguments.subscriberInfo.room NEQ arguments.message.room>
					<cfreturn false>
				</cfif>
			<cfelse>
				<cfreturn false>
			</cfif>
		</cfif>

		<!--- User blocked list --->
		<cfif structKeyExists(arguments.subscriberInfo, "blockedUsers") AND
		      structKeyExists(arguments.message, "fromUserId")>
			<cfif listFindNoCase(arguments.subscriberInfo.blockedUsers, arguments.message.fromUserId) GT 0>
				<cfreturn false>
			</cfif>
		</cfif>

		<!--- NOTE: Premium feature filtering happens in beforeSendMessage() --->
		<!--- Free users receive the message but see "[PREMIUM FEATURE - Upgrade to view]" --->
		<!--- This allows the message to reach everyone in the room with appropriate filtering --->

		<cfreturn true>
	</cffunction>

	<!--- Hook 5: beforeSendMessage(subscriberInfo, message) --->
	<cffunction name="beforeSendMessage" returntype="any" access="public" output="false">
		<cfargument name="subscriberInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<cfset var customMessage = duplicate(arguments.message)>

		<!--- Mark sender's own messages --->
		<cfif structKeyExists(customMessage, "fromUserId") AND
		      structKeyExists(arguments.subscriberInfo, "userId") AND
		      customMessage.fromUserId EQ arguments.subscriberInfo.userId>
			<cfset customMessage.isYou = true>
		<cfelse>
			<cfset customMessage.isYou = false>
		</cfif>

		<!--- Privacy: Hide email addresses from non-sender --->
		<cfif structKeyExists(customMessage, "email") AND NOT customMessage.isYou>
			<cfset customMessage.email = "[HIDDEN]">
		</cfif>

		<!--- Privacy: Hide phone numbers (show only to VIPs and sender) --->
		<cfif structKeyExists(customMessage, "phoneNumber")>
			<cfset var isVip = arguments.subscriberInfo.tier EQ "vip">
			<cfif NOT customMessage.isYou AND NOT isVip>
				<cfset customMessage.phoneNumber = "[VIP ONLY]">
			</cfif>
		</cfif>

		<!--- Hide premium features from free users --->
		<cfif arguments.subscriberInfo.tier EQ "free">
			<cfif structKeyExists(customMessage, "attachment")>
				<cfset customMessage.attachment = "[PREMIUM FEATURE - Upgrade to view]">
			</cfif>

			<cfif structKeyExists(customMessage, "richText")>
				<cfset customMessage.richText = "[PREMIUM FEATURE]">
			</cfif>
		</cfif>

		<!--- Add recipient tier info for display purposes --->
		<cfset customMessage.viewerTier = arguments.subscriberInfo.tier>

		<!--- Timestamp for this specific viewer --->
		<cfset customMessage.viewedAt = now().getTime()>

		<cfreturn customMessage>
	</cffunction>

</cfcomponent>
