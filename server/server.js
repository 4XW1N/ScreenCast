const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const PORT = process.env.PORT || 8888;

const wss = new WebSocket.Server({ port: PORT });

// Store connected clients
const senders = new Map();    // Android devices (senders)
const receivers = new Map();  // iPad devices (receivers)

console.log(`ScreenCast signaling server started on port ${PORT}`);

wss.on('connection', (ws, req) => {
    const clientId = uuidv4();
    const clientIp = req.socket.remoteAddress;
    let clientType = null; // 'sender' or 'receiver'
    let pairedClient = null;

    console.log(`New connection: ${clientId} from ${clientIp}`);

    ws.on('message', (data) => {
        try {
            const message = JSON.parse(data.toString());
            handleMessage(ws, clientId, message);
        } catch (err) {
            console.error('Invalid message:', err);
            ws.send(JSON.stringify({ type: 'error', message: 'Invalid JSON' }));
        }
    });

    ws.on('close', () => {
        handleDisconnect(clientId, clientType, pairedClient);
    });

    ws.on('error', (err) => {
        console.error(`Client ${clientId} error:`, err);
    });

    function handleMessage(ws, clientId, message) {
        switch (message.type) {
            case 'register':
                handleRegister(ws, clientId, message);
                break;
            case 'offer':
            case 'answer':
            case 'ice-candidate':
                handleRelay(message, pairedClient);
                break;
            case 'ready':
                handleReady(message, pairedClient);
                break;
            case 'ping':
                ws.send(JSON.stringify({ type: 'pong' }));
                break;
            default:
                console.log(`Unknown message type: ${message.type}`);
        }
    }

    function handleRegister(ws, clientId, message) {
        clientType = message.clientType; // 'sender' or 'receiver'

        if (clientType === 'sender') {
            senders.set(clientId, { ws, paired: null });
            console.log(`Sender registered: ${clientId}`);
            
            // Try to pair with waiting receiver
            const waitingReceiver = findWaitingReceiver();
            if (waitingReceiver) {
                pairClients(clientId, waitingReceiver);
            } else {
                ws.send(JSON.stringify({ type: 'waiting', message: 'Waiting for receiver...' }));
            }
        } else if (clientType === 'receiver') {
            receivers.set(clientId, { ws, paired: null });
            console.log(`Receiver registered: ${clientId}`);

            // Try to pair with waiting sender
            const waitingSender = findWaitingSender();
            if (waitingSender) {
                pairClients(waitingSender, clientId);
            } else {
                ws.send(JSON.stringify({ type: 'waiting', message: 'Waiting for sender...' }));
            }
        } else {
            ws.send(JSON.stringify({ type: 'error', message: 'Invalid clientType. Use "sender" or "receiver"' }));
        }
    }

    function findWaitingSender() {
        for (const [id, client] of senders) {
            if (client.paired === null) return id;
        }
        return null;
    }

    function findWaitingReceiver() {
        for (const [id, client] of receivers) {
            if (client.paired === null) return id;
        }
        return null;
    }

    function pairClients(senderId, receiverId) {
        const sender = senders.get(senderId);
        const receiver = receivers.get(receiverId);

        if (!sender || !receiver) return;

        sender.paired = receiverId;
        receiver.paired = senderId;
        pairedClient = clientType === 'sender' ? receiverId : senderId;

        console.log(`Paired: ${senderId} <-> ${receiverId}`);

        // Notify both clients
        sender.ws.send(JSON.stringify({ 
            type: 'paired', 
            role: 'sender',
            peerId: receiverId 
        }));
        receiver.ws.send(JSON.stringify({ 
            type: 'paired', 
            role: 'receiver',
            peerId: senderId 
        }));
    }

    function handleRelay(message, pairedClientId) {
        if (!pairedClientId) return;

        const targetMap = clientType === 'sender' ? receivers : senders;
        const target = targetMap.get(pairedClientId);

        if (target && target.ws.readyState === WebSocket.OPEN) {
            target.ws.send(JSON.stringify(message));
        }
    }

    function handleReady(message, pairedClientId) {
        if (!pairedClientId) return;

        const targetMap = clientType === 'sender' ? receivers : senders;
        const target = targetMap.get(pairedClientId);

        if (target && target.ws.readyState === WebSocket.OPEN) {
            target.ws.send(JSON.stringify({
                type: 'ready',
                width: message.width,
                height: message.height,
                dpi: message.dpi
            }));
        }
    }

    function handleDisconnect(clientId, clientType, pairedClientId) {
        console.log(`Disconnect: ${clientId} (${clientType})`);

        // Notify paired client
        if (pairedClientId) {
            const targetMap = clientType === 'sender' ? receivers : senders;
            const target = targetMap.get(pairedClientId);
            if (target && target.ws.readyState === WebSocket.OPEN) {
                target.ws.send(JSON.stringify({ type: 'peer-disconnected' }));
            }
            // Clear pairing
            if (clientType === 'sender') {
                const sender = senders.get(clientId);
                if (sender) sender.paired = null;
                const receiver = receivers.get(pairedClientId);
                if (receiver) receiver.paired = null;
            } else {
                const receiver = receivers.get(clientId);
                if (receiver) receiver.paired = null;
                const sender = senders.get(pairedClientId);
                if (sender) sender.paired = null;
            }
        }

        // Remove from registry
        if (clientType === 'sender') {
            senders.delete(clientId);
        } else if (clientType === 'receiver') {
            receivers.delete(clientId);
        }
    }
});

// Health check endpoint
const http = require('http');
const healthServer = http.createServer((req, res) => {
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
            status: 'ok', 
            senders: senders.size, 
            receivers: receivers.size 
        }));
    } else {
        res.writeHead(404);
        res.end();
    }
});

healthServer.listen(PORT + 1, () => {
    console.log(`Health check server on port ${PORT + 1}`);
});