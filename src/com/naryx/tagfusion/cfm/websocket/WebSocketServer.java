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

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.Channel;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.http.HttpObjectAggregator;
import io.netty.handler.codec.http.HttpServerCodec;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;

import java.net.BindException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import com.naryx.tagfusion.cfm.engine.cfEngine;

/**
 * WebSocket server using Netty for handling WebSocket connections.
 *
 * This is a singleton server that listens on a configurable port for WebSocket
 * connections. It handles the WebSocket handshake and routes messages to the
 * appropriate handlers.
 *
 * Architecture:
 * - Boss EventLoopGroup: Accepts new connections (single thread)
 * - Worker EventLoopGroup: Handles I/O for established connections (multi-threaded)
 * - Pipeline: HTTP codec -> WebSocket protocol handler -> Custom handler
 *
 * Phase 1: Basic server that echoes messages
 * Phase 2+: Will add channel management, subscriptions, etc.
 */
public class WebSocketServer {

	private static WebSocketServer instance;

	private EventLoopGroup bossGroup;
	private EventLoopGroup workerGroup;
	private ServerBootstrap bootstrap;
	private Channel serverChannel;
	private int port;
	private volatile boolean running = false;

	// Connection tracking
	private AtomicInteger connectionCount = new AtomicInteger(0);
	private static final int MAX_CONNECTIONS = 10000;

	// WebSocket path
	private static final String WEBSOCKET_PATH = "/openbd/ws";

	/**
	 * Private constructor for singleton pattern
	 */
	private WebSocketServer() {
	}

	/**
	 * Get the singleton instance of the WebSocket server
	 *
	 * @return the WebSocketServer instance
	 */
	public static synchronized WebSocketServer getInstance() {
		if (instance == null) {
			instance = new WebSocketServer();
		}
		return instance;
	}

	/**
	 * Start the WebSocket server on the specified port
	 *
	 * @param port the port to bind to
	 * @throws Exception if server fails to start
	 */
	public synchronized void start(int port) throws Exception {
		if (running) {
			throw new IllegalStateException("WebSocket server is already running on port " + this.port);
		}

		this.port = port;
		cfEngine.log("[WebSocket] Initializing Netty server on port " + port + "...");

		try {
			// Boss group accepts connections (1 thread is sufficient)
			cfEngine.log("[WebSocket] Creating boss event loop group (1 thread)...");
			bossGroup = new NioEventLoopGroup(1);

			// Worker group handles I/O for connections (default: 2 * CPU cores)
			cfEngine.log("[WebSocket] Creating worker event loop group...");
			workerGroup = new NioEventLoopGroup();

			// Configure server bootstrap
			cfEngine.log("[WebSocket] Configuring server bootstrap...");
			bootstrap = new ServerBootstrap();
			bootstrap.group(bossGroup, workerGroup)
					.channel(NioServerSocketChannel.class)
					.childHandler(new ChannelInitializer<SocketChannel>() {
						@Override
						protected void initChannel(SocketChannel ch) throws Exception {
							ChannelPipeline pipeline = ch.pipeline();

							// HTTP codec for WebSocket handshake
							pipeline.addLast(new HttpServerCodec());

							// Aggregates HTTP message fragments into complete message
							pipeline.addLast(new HttpObjectAggregator(65536));

							// WebSocket protocol handler (performs handshake automatically)
							pipeline.addLast(new WebSocketServerProtocolHandler(WEBSOCKET_PATH));

							// Our custom business logic handler (Phase 1: echo)
							pipeline.addLast(new WebSocketChannelHandler(WebSocketServer.this));
						}
					})
					.option(ChannelOption.SO_BACKLOG, 128)
					.childOption(ChannelOption.SO_KEEPALIVE, true);

			// Bind and start accepting connections
			cfEngine.log("[WebSocket] Binding to port " + port + "...");
			ChannelFuture future = bootstrap.bind(port).sync();
			serverChannel = future.channel();
			running = true;

			cfEngine.log("[WebSocket] Server started successfully!");
			cfEngine.log("[WebSocket] Listening on port " + port + " at path " + WEBSOCKET_PATH);
			cfEngine.log("[WebSocket] Max connections: " + MAX_CONNECTIONS);

		} catch (Exception e) {
			cleanup();

			// Check if this is a bind exception (port already in use)
			if (e.getCause() instanceof BindException || e.getMessage().contains("Address already in use")) {
				cfEngine.log("[WebSocket] ERROR: Port " + port + " is already in use. WebSocket server not started.");
				cfEngine.log("[WebSocket] Please check for other applications using this port, or change server.websocket.port in bluedragon.xml");
			} else {
				cfEngine.log("[WebSocket] ERROR: Failed to start WebSocket server: " + e.getMessage());
				e.printStackTrace();
			}
			throw e;
		}
	}

	/**
	 * Stop the WebSocket server gracefully
	 *
	 * Gives existing connections up to 5 seconds to finish before forcefully closing.
	 */
	public synchronized void stop() {
		if (!running) {
			return;
		}

		try {
			// Close server channel (no new connections accepted)
			if (serverChannel != null) {
				serverChannel.close().sync();
			}

			cfEngine.log("[WebSocket] Server stopping (" + connectionCount.get() + " active connections)...");

			// Shutdown event loop groups gracefully
			// Quiet period: 0 seconds, timeout: 5 seconds
			if (workerGroup != null) {
				workerGroup.shutdownGracefully(0, 5, TimeUnit.SECONDS);
			}
			if (bossGroup != null) {
				bossGroup.shutdownGracefully(0, 5, TimeUnit.SECONDS);
			}

			running = false;
			cfEngine.log("[WebSocket] Server stopped");

		} catch (InterruptedException e) {
			cfEngine.log("[WebSocket] ERROR: Interrupted while stopping server: " + e.getMessage());
			Thread.currentThread().interrupt();
		} catch (Exception e) {
			cfEngine.log("[WebSocket] ERROR: Error stopping WebSocket server: " + e.getMessage());
		} finally {
			cleanup();
		}
	}

	/**
	 * Clean up resources
	 */
	private void cleanup() {
		bossGroup = null;
		workerGroup = null;
		bootstrap = null;
		serverChannel = null;
		running = false;
	}

	/**
	 * Check if the server is currently running
	 *
	 * @return true if server is running, false otherwise
	 */
	public boolean isRunning() {
		return running;
	}

	/**
	 * Get the port the server is running on
	 *
	 * @return the port number, or 0 if not running
	 */
	public int getPort() {
		return port;
	}

	/**
	 * Increment the connection count
	 *
	 * @return true if connection allowed (under limit), false if rejected
	 */
	public boolean incrementConnectionCount() {
		int count = connectionCount.incrementAndGet();
		if (count > MAX_CONNECTIONS) {
			connectionCount.decrementAndGet();
			cfEngine.log("[WebSocket] Connection rejected: server at capacity (" + MAX_CONNECTIONS + " max)");
			return false;
		}
		return true;
	}

	/**
	 * Decrement the connection count
	 */
	public void decrementConnectionCount() {
		connectionCount.decrementAndGet();
	}

	/**
	 * Get the current number of active connections
	 *
	 * @return number of active connections
	 */
	public int getConnectionCount() {
		return connectionCount.get();
	}

	/**
	 * Get the maximum allowed connections
	 *
	 * @return maximum connections
	 */
	public int getMaxConnections() {
		return MAX_CONNECTIONS;
	}
}
