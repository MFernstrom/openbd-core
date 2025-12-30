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

import com.naryx.tagfusion.cfm.engine.cfData;
import com.naryx.tagfusion.cfm.engine.cfEngine;
import com.naryx.tagfusion.cfm.engine.cfStructData;
import com.naryx.tagfusion.expression.function.string.deserializejson;
import com.naryx.tagfusion.expression.function.string.serializejson;

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
	 * Phase 2: Parse JSON and route to channel manager
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

			// Parse JSON message
			cfStructData jsonMessage = parseJSON(message);
			if (jsonMessage == null) {
				sendError("Invalid JSON format");
				return;
			}

			// Get message type
			String type = getString(jsonMessage, "type");
			if (type == null) {
				sendError("Missing 'type' field in message");
				return;
			}

			// Route to appropriate handler
			switch (type.toLowerCase()) {
				case "subscribe":
					handleSubscribe(jsonMessage);
					break;

				case "publish":
					handlePublish(jsonMessage);
					break;

				case "unsubscribe":
					handleUnsubscribe(jsonMessage);
					break;

				default:
					sendError("Unknown message type: " + type);
			}

		} catch (Exception e) {
			cfEngine.log("[WebSocket] Error handling message: " + e.getMessage());
			e.printStackTrace();
			sendError("Internal server error");
		}
	}

	/**
	 * Handle subscribe message
	 *
	 * Expected JSON: {"type":"subscribe", "channelName":"...", "subscriberInfo":{...}}
	 */
	private void handleSubscribe(cfStructData message) {
		String channelName = getString(message, "channelName");
		if (channelName == null) {
			sendError("Missing 'channelName' field");
			return;
		}

		// Get optional subscriber info
		cfStructData subscriberInfo = getStruct(message, "subscriberInfo");

		// Subscribe via channel manager
		WebSocketChannelManager manager = WebSocketChannelManager.getInstance();
		boolean success = manager.subscribe(channelName, connection, subscriberInfo);

		if (success) {
			// Send success response
			sendResponse("subscribed", channelName, null);
		} else {
			sendError("Failed to subscribe to channel: " + channelName);
		}
	}

	/**
	 * Handle publish message
	 *
	 * Expected JSON: {"type":"publish", "channelName":"...", "message":{...}}
	 */
	private void handlePublish(cfStructData message) {
		String channelName = getString(message, "channelName");
		if (channelName == null) {
			sendError("Missing 'channelName' field");
			return;
		}

		// Get the message data (can be any type)
		Object messageData = message.getData("message");
		if (messageData == null) {
			sendError("Missing 'message' field");
			return;
		}

		// Publish via channel manager (hooks will be invoked inside)
		WebSocketChannelManager manager = WebSocketChannelManager.getInstance();
		boolean success = manager.publish(channelName, connection, messageData);

		if (!success) {
			sendError("Failed to publish to channel: " + channelName);
		}
	}

	/**
	 * Handle unsubscribe message
	 *
	 * Expected JSON: {"type":"unsubscribe", "channelName":"..."}
	 */
	private void handleUnsubscribe(cfStructData message) {
		String channelName = getString(message, "channelName");
		if (channelName == null) {
			sendError("Missing 'channelName' field");
			return;
		}

		// Unsubscribe via channel manager
		WebSocketChannelManager manager = WebSocketChannelManager.getInstance();
		boolean success = manager.unsubscribe(channelName, connection);

		if (success) {
			sendResponse("unsubscribed", channelName, null);
		} else {
			sendError("Failed to unsubscribe from channel: " + channelName);
		}
	}

	/**
	 * Send a response message to the client
	 */
	private void sendResponse(String type, String channelName, String message) {
		StringBuilder json = new StringBuilder();
		json.append("{\"type\":\"").append(escapeJSON(type)).append("\"");

		if (channelName != null) {
			json.append(",\"channelName\":\"").append(escapeJSON(channelName)).append("\"");
		}

		if (message != null) {
			json.append(",\"message\":\"").append(escapeJSON(message)).append("\"");
		}

		json.append("}");

		connection.sendMessage(json.toString());
	}

	/**
	 * Send an error message to the client
	 */
	private void sendError(String errorMessage) {
		String json = "{\"type\":\"error\",\"message\":\"" + escapeJSON(errorMessage) + "\"}";
		connection.sendMessage(json);
	}

	/**
	 * Parse JSON string to cfStructData
	 */
	private cfStructData parseJSON(String json) {
		try {
			Object result = deserializejson.getCfDataFromJSon(json, false);
			return (result instanceof cfStructData) ? (cfStructData) result : null;
		} catch (Exception e) {
			cfEngine.log("[WebSocket] JSON parse error: " + e.getMessage());
			return null;
		}
	}

	/**
	 * Get string value from struct
	 */
	private String getString(cfStructData struct, String key) {
		try {
			Object value = struct.getData(key);
			return (value != null) ? value.toString() : null;
		} catch (Exception e) {
			return null;
		}
	}

	/**
	 * Get struct value from struct
	 */
	private cfStructData getStruct(cfStructData struct, String key) {
		try {
			Object value = struct.getData(key);
			return (value instanceof cfStructData) ? (cfStructData) value : null;
		} catch (Exception e) {
			return null;
		}
	}

	/**
	 * Serialize object to JSON string using OpenBD's serializejson
	 */
	private String serializeJSON(Object obj) {
		try {
			if (obj == null) {
				return "null";
			}

			// If it's already a cfData type, serialize it properly
			if (obj instanceof cfData) {
				StringBuilder buffer = new StringBuilder();
				serializejson serializer = new serializejson();
				serializer.encodeJSON(buffer, (cfData)obj, false,
				                     serializejson.CaseType.MAINTAIN,
				                     serializejson.DateType.LONG);
				return buffer.toString();
			}

			// For non-cfData types, do simple serialization
			if (obj instanceof String) {
				return "\"" + escapeJSON(obj.toString()) + "\"";
			} else if (obj instanceof Number || obj instanceof Boolean) {
				return obj.toString();
			} else {
				return "\"" + escapeJSON(obj.toString()) + "\"";
			}
		} catch (Exception e) {
			cfEngine.log("[WebSocket] Error serializing to JSON: " + e.getMessage());
			return "null";
		}
	}

	/**
	 * Escape JSON string
	 */
	private String escapeJSON(String str) {
		if (str == null) return "";
		return str.replace("\\", "\\\\")
		          .replace("\"", "\\\"")
		          .replace("\n", "\\n")
		          .replace("\r", "\\r")
		          .replace("\t", "\\t");
	}

	/**
	 * Handle connection close
	 *
	 * Cleans up resources and decrements connection count
	 */
	private void handleClose() {
		if (connection != null) {
			// Unsubscribe from all channels
			WebSocketChannelManager manager = WebSocketChannelManager.getInstance();
			manager.unsubscribeAll(connection);

			connection.close();
			connection = null;
		}

		// Decrement server connection count
		server.decrementConnectionCount();
	}
}
