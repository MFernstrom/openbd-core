/*
 *  Copyright (C) 2000 - 2025 TagServlet Ltd
 *
 *  This file is part of Open BlueDragon (OpenBD) CFML Server Engine.
 *
 *  OpenBD is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  Free Software Foundation,version 3.
 *
 *  OpenBD is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with OpenBD.  If not, see http://www.gnu.org/licenses/
 *
 *  Additional permission under GNU GPL version 3 section 7
 *
 *  If you modify this Program, or any covered work, by linking or combining
 *  it with any of the JARS listed in the README.txt (or a modified version of
 *  (that library), containing parts covered by the terms of that JAR, the
 *  licensors of this Program grant you additional permission to convey the
 *  resulting work.
 *  README.txt @ http://www.openbluedragon.org/license/README.txt
 *
 *  http://openbd.org/
 */
package com.naryx.tagfusion.cfm.websocket;

import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;

import java.nio.channels.ClosedChannelException;
import java.util.Collections;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

import com.naryx.tagfusion.cfm.engine.cfEngine;
import com.naryx.tagfusion.cfm.engine.cfSession;
import com.naryx.tagfusion.cfm.engine.cfStructData;

/**
 * Represents a single WebSocket connection from a client.
 *
 * This class wraps the Netty ChannelHandlerContext and provides a clean
 * abstraction for managing the connection state, sending messages, and
 * associating with cfSession.
 *
 * Thread-safe: Multiple threads may send messages or update state concurrently.
 *
 * Phase 1: Basic connection with send/receive
 * Phase 2+: Will track channel subscriptions and subscriber info
 */
public class WebSocketConnection {

	private final String connectionId;
	private final ChannelHandlerContext ctx;
	private final AtomicBoolean connected;

	// Session association (for authentication/authorization)
	private volatile cfSession session;

	// Channel subscriptions (Phase 2+)
	private final Set<String> subscribedChannels;
	private volatile cfStructData subscriberInfo;

	/**
	 * Constructor
	 *
	 * @param ctx the Netty channel handler context
	 */
	public WebSocketConnection(ChannelHandlerContext ctx) {
		this.connectionId = UUID.randomUUID().toString();
		this.ctx = ctx;
		this.connected = new AtomicBoolean(true);
		this.subscribedChannels = ConcurrentHashMap.newKeySet();
	}

	/**
	 * Get the unique connection ID
	 *
	 * @return the connection ID (UUID)
	 */
	public String getConnectionId() {
		return connectionId;
	}

	/**
	 * Check if the connection is currently active
	 *
	 * @return true if connected, false otherwise
	 */
	public boolean isConnected() {
		return connected.get() && ctx.channel().isActive();
	}

	/**
	 * Send a text message to the client
	 *
	 * This method is non-blocking and will log errors if send fails.
	 *
	 * @param message the text message to send
	 */
	public void sendMessage(String message) {
		if (!connected.get()) {
			cfEngine.log("[WebSocket] Attempted to send message to closed connection: " + connectionId);
			return;
		}

		if (message == null) {
			cfEngine.log("[WebSocket] Attempted to send null message to: " + connectionId);
			return;
		}

		try {
			TextWebSocketFrame frame = new TextWebSocketFrame(message);

			ctx.writeAndFlush(frame).addListener(new ChannelFutureListener() {
				@Override
				public void operationComplete(ChannelFuture future) {
					if (!future.isSuccess()) {
						Throwable cause = future.cause();

						if (cause instanceof ClosedChannelException) {
							// Client disconnected - this is normal, don't spam logs
							connected.set(false);
						} else {
							cfEngine.log("[WebSocket] Failed to send message to " + connectionId +
							             ": " + cause.getMessage());
							close();
						}
					}
				}
			});

		} catch (Exception e) {
			cfEngine.log("[WebSocket] Error sending message to " + connectionId + ": " + e.getMessage());
			close();
		}
	}

	/**
	 * Close the connection
	 *
	 * This method is idempotent - safe to call multiple times.
	 */
	public void close() {
		if (connected.compareAndSet(true, false)) {
			try {
				if (ctx.channel().isActive()) {
					ctx.close();
				}
			} catch (Exception e) {
				cfEngine.log("[WebSocket] Error closing connection " + connectionId + ": " + e.getMessage());
			}
		}
	}

	/**
	 * Associate this connection with a cfSession
	 *
	 * Used for authentication and accessing session variables in
	 * Channel Listener CFCs.
	 *
	 * @param session the cfSession to associate
	 */
	public void associateSession(cfSession session) {
		this.session = session;
		if (session != null) {
			cfEngine.log("[WebSocket] Connection " + connectionId +
			             " associated with session " + session.getSessionID());
		}
	}

	/**
	 * Get the associated cfSession
	 *
	 * @return the cfSession, or null if not associated
	 */
	public cfSession getSession() {
		return session;
	}

	/**
	 * Set subscriber info (custom metadata from client)
	 *
	 * This is sent by the client during subscribe and can contain
	 * any application-specific data (user ID, preferences, etc.)
	 *
	 * Phase 2+
	 *
	 * @param info the subscriber info struct
	 */
	public void setSubscriberInfo(cfStructData info) {
		this.subscriberInfo = info;
	}

	/**
	 * Get subscriber info
	 *
	 * Phase 2+
	 *
	 * @return the subscriber info struct, or null
	 */
	public cfStructData getSubscriberInfo() {
		return subscriberInfo;
	}

	/**
	 * Subscribe to a channel
	 *
	 * Phase 2+
	 *
	 * @param channelName the channel name
	 */
	public void subscribeToChannel(String channelName) {
		subscribedChannels.add(channelName);
	}

	/**
	 * Unsubscribe from a channel
	 *
	 * Phase 2+
	 *
	 * @param channelName the channel name
	 */
	public void unsubscribeFromChannel(String channelName) {
		subscribedChannels.remove(channelName);
	}

	/**
	 * Check if subscribed to a channel
	 *
	 * Phase 2+
	 *
	 * @param channelName the channel name
	 * @return true if subscribed, false otherwise
	 */
	public boolean isSubscribedToChannel(String channelName) {
		return subscribedChannels.contains(channelName);
	}

	/**
	 * Get all subscribed channels
	 *
	 * Phase 2+
	 *
	 * @return unmodifiable set of channel names
	 */
	public Set<String> getSubscribedChannels() {
		return Collections.unmodifiableSet(subscribedChannels);
	}

	/**
	 * Get the number of channels subscribed to
	 *
	 * Phase 2+
	 *
	 * @return channel count
	 */
	public int getSubscribedChannelCount() {
		return subscribedChannels.size();
	}

	/**
	 * Create a synthetic "server publisher" connection for server-side publishing.
	 *
	 * This creates a special WebSocketConnection that represents the server itself
	 * when publishing messages via wsPublish(). Since there's no actual WebSocket
	 * connection from a client, this creates a minimal connection object.
	 *
	 * The connection will have a fixed ID of "SERVER" and will not be able to
	 * send messages (since there's no real connection).
	 *
	 * @return a server publisher connection
	 */
	public static WebSocketConnection createServerPublisher() {
		// Create a minimal connection with null context
		WebSocketConnection serverConn = new WebSocketConnection(null);

		// Override the connection ID to identify this as a server publisher
		// We'll use reflection to set the final field, or we can modify the constructor
		// For simplicity, let's create a special constructor
		return new ServerPublisherConnection();
	}

	/**
	 * Special subclass for server-side publishing
	 */
	private static class ServerPublisherConnection extends WebSocketConnection {
		private static final String SERVER_ID = "SERVER";

		public ServerPublisherConnection() {
			super(null);  // No actual channel context
		}

		@Override
		public String getConnectionId() {
			return SERVER_ID;
		}

		@Override
		public boolean isConnected() {
			return true;  // Always "connected" for server publishing
		}

		@Override
		public void sendMessage(String message) {
			// No-op: server doesn't send to itself
		}

		@Override
		public void close() {
			// No-op: can't close server
		}
	}

	@Override
	public String toString() {
		return "WebSocketConnection{" +
		       "id=" + connectionId +
		       ", connected=" + connected.get() +
		       ", channels=" + subscribedChannels.size() +
		       ", hasSession=" + (session != null) +
		       '}';
	}
}
