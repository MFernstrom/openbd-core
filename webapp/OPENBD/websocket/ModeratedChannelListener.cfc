<!---
  Example Channel Listener with Publish Control

  This CFC demonstrates the allowPublish() and beforePublish() hooks
  by implementing moderation and message transformation.

  Phase 3, Stage 4: allowPublish() and beforePublish() hooks demo
--->
<cfcomponent extends="ChannelListener" displayname="ModeratedChannelListener" hint="Channel listener with publish moderation">

	<!---
	  allowPublish - Only allow users with "moderator" role to publish

	  @publisherInfo - Struct with connectionId and subscriberInfo
	  @return boolean - true to allow, false to deny
	--->
	<cffunction name="allowPublish" returntype="boolean" access="public" output="false">
		<cfargument name="publisherInfo" type="struct" required="true">

		<!--- Check if subscriberInfo has a role field --->
		<cfif structKeyExists(arguments.publisherInfo, "subscriberInfo") AND
		      structKeyExists(arguments.publisherInfo.subscriberInfo, "role")>

			<cfset var role = arguments.publisherInfo.subscriberInfo.role>

			<!--- Only moderators can publish --->
			<cfif role eq "moderator">
				<cflog text="[WebSocket] Publish allowed: User is moderator" type="information">
				<cfreturn true>
			<cfelse>
				<cflog text="[WebSocket] Publish denied: User role is '#role#', needs 'moderator'" type="warning">
				<cfreturn false>
			</cfif>
		<cfelse>
			<cflog text="[WebSocket] Publish denied: No role specified" type="warning">
			<cfreturn false>
		</cfif>
	</cffunction>


	<!---
	  beforePublish - Add timestamp and sanitize message before broadcasting

	  This demonstrates message transformation:
	  - Adds server-side timestamp
	  - Sanitizes/validates content
	  - Adds moderator badge

	  @publisherInfo - Struct with connectionId and subscriberInfo
	  @message - The message to be published
	  @return struct - The transformed message
	--->
	<cffunction name="beforePublish" returntype="any" access="public" output="false">
		<cfargument name="publisherInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<!--- Create a copy of the message to transform --->
		<cfset var transformedMessage = duplicate(arguments.message)>

		<!--- Add server-side timestamp --->
		<cfset transformedMessage.serverTimestamp = now().getTime()>

		<!--- Add formatted timestamp --->
		<cfset transformedMessage.serverTime = dateFormat(now(), "HH:mm:ss")>

		<!--- Add moderator badge if user is moderator --->
		<cfif structKeyExists(arguments.publisherInfo.subscriberInfo, "role") AND
		      arguments.publisherInfo.subscriberInfo.role eq "moderator">
			<cfset transformedMessage.badge = "MODERATOR">
		</cfif>

		<!--- Sanitize text if present (remove HTML tags for demo) --->
		<cfif structKeyExists(transformedMessage, "text")>
			<!--- Simple sanitization: remove < and > characters --->
			<cfset transformedMessage.text = replace(transformedMessage.text, "<", "&lt;", "ALL")>
			<cfset transformedMessage.text = replace(transformedMessage.text, ">", "&gt;", "ALL")>

			<!--- Add content length --->
			<cfset transformedMessage.textLength = len(transformedMessage.text)>
		</cfif>

		<cflog text="[WebSocket] Message transformed by beforePublish()" type="information">

		<cfreturn transformedMessage>
	</cffunction>

</cfcomponent>
