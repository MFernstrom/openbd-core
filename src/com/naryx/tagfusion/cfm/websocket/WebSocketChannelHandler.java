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

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.handler.codec.http.websocketx.CloseWebSocketFrame;
import io.netty.handler.codec.http.websocketx.PingWebSocketFrame;
import io.netty.handler.codec.http.websocketx.PongWebSocketFrame;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.handler.codec.http.websocketx.WebSocketFrame;

import com.naryx.tagfusion.cfm.engine.cfEngine;

/**
 * Netty channel handler for WebSocket connections.
 *
 * This handler sits in the Netty pipeline and receives WebSocket frame events.
 * It delegates to WebSocketConnection for business logic.
 *
 * Phase 1: Handles basic WebSocket frames and echoes messages back
 * Phase 2+: Will parse JSON protocol and route to channel manager
 *
 * Supported frame types:
 * - TextWebSocketFrame: UTF-8 text messages (JSON protocol)
 * - CloseWebSocketFrame: Connection close request
 * - PingWebSocketFrame: Keep-alive ping (responds with pong)
 * - PongWebSocketFrame: Keep-alive pong (no action needed)
 */
public class WebSocketChannelHandler extends SimpleChannelInboundHandler<WebSocketFrame> {

	private final WebSocketServer server;
	private WebSocketConnection connection;

	/**
	 * Constructor
	 *
	 * @param server the WebSocket server instance
	 */
	public WebSocketChannelHandler(WebSocketServer server) {
		this.server = server;
	}

	/**
	 * Called when a new connection is established
	 *
	 * @param ctx the channel handler context
	 */
	@Override
	public void channelActive(ChannelHandlerContext ctx) throws Exception {
		// Check if server is at capacity
		if (!server.incrementConnectionCount()) {
			// Reject connection - server at capacity
			ctx.writeAndFlush(new CloseWebSocketFrame(1008, "Server at capacity"));
			ctx.close();
			return;
		}

		// Create connection wrapper
		connection = new WebSocketConnection(ctx);

		cfEngine.log("[WebSocket] New connection: " + connection.getConnectionId() +
		             " (total: " + server.getConnectionCount() + ")");

		super.channelActive(ctx);
	}

	/**
	 * Called when a WebSocket frame is received
	 *
	 * @param ctx the channel handler context
	 * @param frame the WebSocket frame
	 */
	@Override
	protected void channelRead0(ChannelHandlerContext ctx, WebSocketFrame frame) throws Exception {
		if (frame instanceof TextWebSocketFrame) {
			// Text message received
			String message = ((TextWebSocketFrame) frame).text();
			handleTextMessage(message);

		} else if (frame instanceof CloseWebSocketFrame) {
			// Client requested close
			cfEngine.log("[WebSocket] Close frame received: " + connection.getConnectionId());
			handleClose();

		} else if (frame instanceof PingWebSocketFrame) {
			// Respond to ping with pong (keep-alive)
			ctx.writeAndFlush(new PongWebSocketFrame(frame.content().retain()));

		} else if (frame instanceof PongWebSocketFrame) {
			// Pong received (no action needed)
			// This is a response to our ping if we were sending them

		} else {
			// Unsupported frame type
			cfEngine.log("[WebSocket] Unsupported frame type: " + frame.getClass().getName() +
			             " from " + connection.getConnectionId());
		}
	}

	/**
	 * Called when connection is closed
	 *
	 * @param ctx the channel handler context
	 */
	@Override
	public void channelInactive(ChannelHandlerContext ctx) throws Exception {
		cfEngine.log("[WebSocket] Connection closed: " +
		             (connection != null ? connection.getConnectionId() : "unknown") +
		             " (total: " + (server.getConnectionCount() - 1) + ")");

		handleClose();
		super.channelInactive(ctx);
	}

	/**
	 * Called when an exception occurs in the channel
	 *
	 * @param ctx the channel handler context
	 * @param cause the exception that occurred
	 */
	@Override
	public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
		cfEngine.log("[WebSocket] Error: " + cause.getMessage() +
		             (connection != null ? " (connection: " + connection.getConnectionId() + ")" : ""));

		// Close the connection on error
		ctx.close();
	}

	/**
	 * Handle text message received from client
	 *
	 * Phase 1: Simple echo
	 * Phase 2: Will parse JSON and route to appropriate handler
	 *
	 * @param message the text message received
	 */
	private void handleTextMessage(String message) {
		try {
			if (connection == null) {
				cfEngine.log("[WebSocket] ERROR: Received message but connection is null");
				return;
			}

			cfEngine.log("[WebSocket] Received from " + connection.getConnectionId() + ": " +
			             (message.length() > 100 ? message.substring(0, 100) + "..." : message));

			// Phase 1: Simple echo back to client
			connection.sendMessage("Echo: " + message);

			// TODO Phase 2: Parse JSON protocol and route to channel manager
			// Example:
			// JSONObject json = new JSONObject(message);
			// String type = json.getString("type");
			// switch (type) {
			//     case "subscribe":
			//         handleSubscribe(json);
			//         break;
			//     case "publish":
			//         handlePublish(json);
			//         break;
			//     case "unsubscribe":
			//         handleUnsubscribe(json);
			//         break;
			//     default:
			//         sendError("Unknown message type: " + type);
			// }

		} catch (Exception e) {
			cfEngine.log("[WebSocket] Error handling message: " + e.getMessage());

			// Send error back to client (Phase 2 will use JSON protocol)
			if (connection != null) {
				connection.sendMessage("{\"type\":\"error\",\"message\":\"Invalid message format\"}");
			}
		}
	}

	/**
	 * Handle connection close
	 *
	 * Cleans up resources and decrements connection count
	 */
	private void handleClose() {
		if (connection != null) {
			connection.close();

			// TODO Phase 2: Unsubscribe from all channels
			// TODO Phase 2: Remove from connection manager

			connection = null;
		}

		// Decrement server connection count
		server.decrementConnectionCount();
	}
}
