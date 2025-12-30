<!---
  Example Channel Listener with Authentication

  This CFC demonstrates the allowSubscribe() hook by implementing
  simple authentication logic. Only clients with a valid "authToken"
  in their subscriberInfo are allowed to subscribe.

  Phase 3, Stage 3: allowSubscribe() hook demo
--->
<cfcomponent extends="ChannelListener" displayname="AuthChannelListener" hint="Channel listener with authentication">

	<!---
	  allowSubscribe - Only allow subscription if client has valid auth token

	  This is a simple demo - in production you would:
	  - Verify the token against a database or session
	  - Check user permissions
	  - Validate IP address, etc.

	  @subscriberInfo - Struct sent by client (should contain authToken)
	  @return boolean - true to allow, false to deny
	--->
	<cffunction name="allowSubscribe" returntype="boolean" access="public" output="false">
		<cfargument name="subscriberInfo" type="struct" required="true">

		<!--- Check if authToken is present --->
		<cfif NOT structKeyExists(arguments.subscriberInfo, "authToken")>
			<cflog text="[WebSocket] Subscription denied: No authToken provided" type="warning">
			<cfreturn false>
		</cfif>

		<!--- Check if authToken is valid (for demo, we accept "SECRET123") --->
		<cfset var authToken = arguments.subscriberInfo.authToken>

		<cfif authToken eq "SECRET123">
			<cflog text="[WebSocket] Subscription allowed: Valid authToken" type="information">
			<cfreturn true>
		<cfelse>
			<cflog text="[WebSocket] Subscription denied: Invalid authToken: #authToken#" type="warning">
			<cfreturn false>
		</cfif>
	</cffunction>

</cfcomponent>
