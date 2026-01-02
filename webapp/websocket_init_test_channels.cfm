<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Initialize Test WebSocket Channels</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
        }
        .result {
            padding: 15px;
            margin: 10px 0;
            border-radius: 4px;
            font-weight: bold;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .info {
            background-color: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        pre {
            background-color: #f4f4f4;
            padding: 10px;
            border-radius: 4px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <h1>Initialize Test WebSocket Channels</h1>
    <p>This page registers basic test channels for WebSocket testing.</p>

    <cfset results = []>

    <!--- Channel 1: Simple test channel with no listener --->
    <cftry>
        <cfset wsRegisterChannel("testChannel")>
        <cfset arrayAppend(results, {
            success: true,
            channel: "testChannel",
            message: "Registered basic test channel (no listener)"
        })>
        <cfcatch type="any">
            <cfset arrayAppend(results, {
                success: false,
                channel: "testChannel",
                message: "Error: " & cfcatch.message
            })>
        </cfcatch>
    </cftry>

    <!--- Channel 2: Another simple test channel --->
    <cftry>
        <cfset wsRegisterChannel("chatChannel")>
        <cfset arrayAppend(results, {
            success: true,
            channel: "chatChannel",
            message: "Registered chat test channel (no listener)"
        })>
        <cfcatch type="any">
            <cfset arrayAppend(results, {
                success: false,
                channel: "chatChannel",
                message: "Error: " & cfcatch.message
            })>
        </cfcatch>
    </cftry>

    <!--- Channel 3: Notification channel --->
    <cftry>
        <cfset wsRegisterChannel("notificationChannel")>
        <cfset arrayAppend(results, {
            success: true,
            channel: "notificationChannel",
            message: "Registered notification channel (no listener)"
        })>
        <cfcatch type="any">
            <cfset arrayAppend(results, {
                success: false,
                channel: "notificationChannel",
                message: "Error: " & cfcatch.message
            })>
        </cfcatch>
    </cftry>

    <!--- Channel 4-6: Premium channels with listener --->
    <cftry>
        <cfset wsRegisterChannel("lobby", "OPENBD.websocket.PremiumChatListener")>
        <cfset arrayAppend(results, {
            success: true,
            channel: "lobby",
            message: "Registered lobby channel with PremiumChatListener"
        })>
        <cfcatch type="any">
            <cfset arrayAppend(results, {
                success: false,
                channel: "lobby",
                message: "Error: " & cfcatch.message & " (Detail: " & cfcatch.detail & ")"
            })>
        </cfcatch>
    </cftry>

    <cftry>
        <cfset wsRegisterChannel("premium", "OPENBD.websocket.PremiumChatListener")>
        <cfset arrayAppend(results, {
            success: true,
            channel: "premium",
            message: "Registered premium channel with PremiumChatListener"
        })>
        <cfcatch type="any">
            <cfset arrayAppend(results, {
                success: false,
                channel: "premium",
                message: "Error: " & cfcatch.message & " (Detail: " & cfcatch.detail & ")"
            })>
        </cfcatch>
    </cftry>

    <cftry>
        <cfset wsRegisterChannel("vip", "OPENBD.websocket.PremiumChatListener")>
        <cfset arrayAppend(results, {
            success: true,
            channel: "vip",
            message: "Registered vip channel with PremiumChatListener"
        })>
        <cfcatch type="any">
            <cfset arrayAppend(results, {
                success: false,
                channel: "vip",
                message: "Error: " & cfcatch.message & " (Detail: " & cfcatch.detail & ")"
            })>
        </cfcatch>
    </cftry>

    <!--- Display results --->
    <h2>Registration Results</h2>
    <cfloop array="#results#" index="result">
        <div class="result <cfif result.success>success<cfelse>error</cfif>">
            <strong><cfoutput>#result.channel#</cfoutput></strong>:
            <cfoutput>#result.message#</cfoutput>
        </div>
    </cfloop>

    <!--- List all registered channels --->
    <h2>All Registered Channels</h2>
    <cftry>
        <cfset allChannels = wsGetAllChannels()>
        <div class="info">
            Found <cfoutput>#arrayLen(allChannels)#</cfoutput> registered channel(s)
        </div>
        <pre><cfoutput>#serializeJSON(allChannels, true)#</cfoutput></pre>

        <cfcatch type="any">
            <div class="error">
                Error getting channels: <cfoutput>#cfcatch.message#</cfoutput>
            </div>
        </cfcatch>
    </cftry>

    <hr>
    <div class="info">
        <strong>Next Steps:</strong>
        <ul>
            <li>Channels are now registered and ready for testing</li>
            <li>Go to <a href="websocket_test_cfwebsocket.cfm">websocket_test_cfwebsocket.cfm</a> to test basic functionality</li>
            <li>Go to <a href="websocket_test_cfwebsocket_premium.cfm">websocket_test_cfwebsocket_premium.cfm</a> to test premium chat</li>
        </ul>
        <p><strong>Note:</strong> Channels persist in memory for the lifetime of the server. If you restart the server, you'll need to run this page again to re-register channels.</p>
    </div>
</body>
</html>
