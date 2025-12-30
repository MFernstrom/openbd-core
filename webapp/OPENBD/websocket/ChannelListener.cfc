<!---
  Base Channel Listener Component for WebSocket Channels

  This component provides the base implementation of the 5 lifecycle hooks
  that control WebSocket channel behavior. Extend this component and override
  the methods you need to customize channel behavior.

  Phase 3: Channel Listener CFC Support

  Lifecycle Hooks:
  1. allowSubscribe(subscriberInfo)      - Authorization check before subscription
  2. allowPublish(publisherInfo)         - Authorization check before publishing
  3. beforePublish(publisherInfo, msg)   - Transform/validate message before broadcast
  4. canSendMessage(subscriberInfo, msg) - Per-subscriber filtering
  5. beforeSendMessage(subscriberInfo, msg) - Per-subscriber transformation

  Example Usage:
    <cfcomponent extends="OPENBD.websocket.ChannelListener">
        <cffunction name="allowSubscribe" returntype="boolean">
            <cfargument name="subscriberInfo" type="struct" required="true">
            <!--- Only allow if user is authenticated --->
            <cfreturn structKeyExists(session, "userId")>
        </cffunction>
    </cfcomponent>
--->
<cfcomponent displayname="ChannelListener" hint="Base class for WebSocket channel listeners">

	<!---
	  allowSubscribe - Authorization check before subscription

	  Called when a client attempts to subscribe to this channel.
	  Return false to reject the subscription.

	  @subscriberInfo - Struct sent by client during subscribe (may include userId, room, etc.)
	  @return boolean - true to allow subscription, false to reject
	--->
	<cffunction name="allowSubscribe" returntype="boolean" access="public" output="false"
	            hint="Authorization check before allowing subscription">
		<cfargument name="subscriberInfo" type="struct" required="true">

		<!--- Default implementation: allow all subscriptions --->
		<cfreturn true>
	</cffunction>


	<!---
	  allowPublish - Authorization check before publishing

	  Called when a client attempts to publish a message to this channel.
	  Return false to reject the publish attempt.

	  @publisherInfo - Struct with connectionId and subscriberInfo of the publisher
	  @return boolean - true to allow publish, false to reject
	--->
	<cffunction name="allowPublish" returntype="boolean" access="public" output="false"
	            hint="Authorization check before allowing message publication">
		<cfargument name="publisherInfo" type="struct" required="true">

		<!--- Default implementation: allow all publishing --->
		<cfreturn true>
	</cffunction>


	<!---
	  beforePublish - Transform or validate message before broadcasting

	  Called after allowPublish() succeeds, before broadcasting to subscribers.
	  Use this to add timestamps, sanitize content, validate structure, etc.

	  @publisherInfo - Struct with connectionId and subscriberInfo of the publisher
	  @message - The message to be published (any type: struct, string, etc.)
	  @return any - The transformed message (or original if no changes needed)
	--->
	<cffunction name="beforePublish" returntype="any" access="public" output="false"
	            hint="Transform or validate message before broadcasting">
		<cfargument name="publisherInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<!--- Default implementation: return message unchanged --->
		<cfreturn arguments.message>
	</cffunction>


	<!---
	  canSendMessage - Per-subscriber message filtering

	  Called for EACH subscriber to determine if they should receive this message.
	  Use this for room-based filtering, private messages, permissions, etc.

	  @subscriberInfo - Struct of the potential recipient's subscriber info
	  @message - The message being broadcast
	  @return boolean - true to send to this subscriber, false to skip
	--->
	<cffunction name="canSendMessage" returntype="boolean" access="public" output="false"
	            hint="Determine if a specific subscriber should receive this message">
		<cfargument name="subscriberInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<!--- Default implementation: send to all subscribers --->
		<cfreturn true>
	</cffunction>


	<!---
	  beforeSendMessage - Per-subscriber message transformation

	  Called for EACH subscriber before sending (after canSendMessage returns true).
	  Use this to customize message content per subscriber (hide private fields, etc.)

	  @subscriberInfo - Struct of the recipient's subscriber info
	  @message - The message to be sent
	  @return any - The transformed message for this specific subscriber
	--->
	<cffunction name="beforeSendMessage" returntype="any" access="public" output="false"
	            hint="Transform message for a specific subscriber before sending">
		<cfargument name="subscriberInfo" type="struct" required="true">
		<cfargument name="message" type="any" required="true">

		<!--- Default implementation: return message unchanged --->
		<cfreturn arguments.message>
	</cffunction>

</cfcomponent>
