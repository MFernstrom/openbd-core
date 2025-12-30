<!DOCTYPE html>
<html>
<head>
    <title>Stage 6: wsRegisterChannel() with Listener Parameter</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 20px auto;
            padding: 20px;
        }
        .test-result {
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
            border-left: 4px solid #ccc;
        }
        .success {
            background-color: #d4edda;
            border-left-color: #28a745;
            color: #155724;
        }
        .error {
            background-color: #f8d7da;
            border-left-color: #dc3545;
            color: #721c24;
        }
        .info {
            background-color: #d1ecf1;
            border-left-color: #17a2b8;
            color: #0c5460;
        }
        pre {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 4px;
            overflow-x: auto;
        }
        h2 {
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 5px;
        }
    </style>
</head>
<body>
    <h1>Stage 6: wsRegisterChannel() with Listener Parameter Test</h1>

    <p>This test verifies that wsRegisterChannel() now supports an optional listener parameter.</p>

    <h2>Test 1: Backwards Compatibility (No Listener)</h2>
    <cfset testChannel1 = "simpleChannel_" & createUUID()>
    <cftry>
        <cfset result1 = wsRegisterChannel(channelName: testChannel1)>
        <div class="test-result success">
            ✅ <strong>SUCCESS</strong>: Registered channel '<cfoutput>#testChannel1#</cfoutput>' without listener
            <br>Return value: <cfoutput>#result1#</cfoutput>
        </div>
        <cfcatch>
            <div class="test-result error">
                ❌ <strong>FAILED</strong>: <cfoutput>#cfcatch.message# - #cfcatch.detail#</cfoutput>
            </div>
        </cfcatch>
    </cftry>

    <h2>Test 2: Register with Valid Listener CFC</h2>
    <cfset testChannel2 = "authChannel_" & createUUID()>
    <cftry>
        <cfset result2 = wsRegisterChannel(
            channelName: testChannel2,
            listener: "OPENBD.websocket.AuthChannelListener"
        )>
        <div class="test-result success">
            ✅ <strong>SUCCESS</strong>: Registered channel '<cfoutput>#testChannel2#</cfoutput>' with AuthChannelListener
            <br>Return value: <cfoutput>#result2#</cfoutput>
        </div>
        <cfcatch>
            <div class="test-result error">
                ❌ <strong>FAILED</strong>: <cfoutput>#cfcatch.message# - #cfcatch.detail#</cfoutput>
            </div>
        </cfcatch>
    </cftry>

    <h2>Test 3: Register with Invalid CFC Path</h2>
    <cfset testChannel3 = "invalidChannel_" & createUUID()>
    <cftry>
        <cfset result3 = wsRegisterChannel(
            channelName: testChannel3,
            listener: "OPENBD.websocket.NonExistentListener"
        )>
        <div class="test-result error">
            ❌ <strong>UNEXPECTED</strong>: Should have failed but succeeded!
            <br>Return value: <cfoutput>#result3#</cfoutput>
        </div>
        <cfcatch>
            <div class="test-result success">
                ✅ <strong>EXPECTED ERROR</strong>: Correctly rejected invalid CFC path
                <br>Error: <cfoutput>#cfcatch.message#</cfoutput>
            </div>
        </cfcatch>
    </cftry>

    <h2>Test 4: Register Duplicate Channel (Should Return False)</h2>
    <cfset testChannel4 = "duplicateChannel_" & createUUID()>
    <cftry>
        <cfset result4a = wsRegisterChannel(channelName: testChannel4)>
        <cfset result4b = wsRegisterChannel(channelName: testChannel4)>

        <div class="test-result <cfoutput>#result4a ? 'success' : 'error'#</cfoutput>">
            First registration: <cfoutput>#result4a ? 'SUCCESS (true)' : 'FAILED (false)'#</cfoutput>
        </div>
        <div class="test-result <cfoutput>#!result4b ? 'success' : 'error'#</cfoutput>">
            Second registration: <cfoutput>#!result4b ? 'SUCCESS (false = already exists)' : 'FAILED (true = should be false!)'#</cfoutput>
        </div>
        <cfcatch>
            <div class="test-result error">
                ❌ <strong>FAILED</strong>: <cfoutput>#cfcatch.message# - #cfcatch.detail#</cfoutput>
            </div>
        </cfcatch>
    </cftry>

    <h2>Test 5: Register with ModeratedChannelListener</h2>
    <cfset testChannel5 = "moderatedChannel_" & createUUID()>
    <cftry>
        <cfset result5 = wsRegisterChannel(
            channelName: testChannel5,
            listener: "OPENBD.websocket.ModeratedChannelListener"
        )>
        <div class="test-result success">
            ✅ <strong>SUCCESS</strong>: Registered channel '<cfoutput>#testChannel5#</cfoutput>' with ModeratedChannelListener
            <br>Return value: <cfoutput>#result5#</cfoutput>
        </div>
        <cfcatch>
            <div class="test-result error">
                ❌ <strong>FAILED</strong>: <cfoutput>#cfcatch.message# - #cfcatch.detail#</cfoutput>
            </div>
        </cfcatch>
    </cftry>

    <h2>Test 6: Register with RoomChannelListener</h2>
    <cfset testChannel6 = "roomChannel_" & createUUID()>
    <cftry>
        <cfset result6 = wsRegisterChannel(
            channelName: testChannel6,
            listener: "OPENBD.websocket.RoomChannelListener"
        )>
        <div class="test-result success">
            ✅ <strong>SUCCESS</strong>: Registered channel '<cfoutput>#testChannel6#</cfoutput>' with RoomChannelListener
            <br>Return value: <cfoutput>#result6#</cfoutput>
        </div>
        <cfcatch>
            <div class="test-result error">
                ❌ <strong>FAILED</strong>: <cfoutput>#cfcatch.message# - #cfcatch.detail#</cfoutput>
            </div>
        </cfcatch>
    </cftry>

    <hr>

    <div class="test-result info">
        <strong>📋 Summary:</strong><br>
        Stage 6 adds production-ready API for wsRegisterChannel() with optional listener parameter.<br>
        <br>
        <strong>New Signature:</strong><br>
        <code>wsRegisterChannel(channelName [, listener])</code><br>
        <br>
        <strong>Parameters:</strong><br>
        • channelName (required): Name of the channel to register<br>
        • listener (optional): Path to Channel Listener CFC (e.g., "OPENBD.websocket.AuthChannelListener")<br>
        <br>
        <strong>Returns:</strong><br>
        • true: Channel registered successfully<br>
        • false: Channel already exists<br>
        • throws exception: Invalid CFC path or loading error
    </div>

    <hr>

    <div class="test-result info">
        <strong>🔍 Check Server Logs:</strong><br>
        Run this command to see the registration logs:<br>
        <pre>tail -30 webapp/WEB-INF/bluedragon/work/bluedragon.log</pre>
    </div>

</body>
</html>
