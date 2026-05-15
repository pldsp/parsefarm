from flask import Flask, request, Response
import os
import json
import secrets
import base64
import time

app = Flask(__name__)

# This is YOUR master password to create new keys. Do not give this out!
MASTER_ADMIN_KEY = "owner_secret_123"
DB_FILE = "keys_db.json"

# Initialize the database if it doesn't exist
def load_keys():
    if not os.path.exists(DB_FILE):
        with open(DB_FILE, "w") as f:
            json.dump(["parsefarm_admin"], f)
    with open(DB_FILE, "r") as f:
        try:
            return json.load(f)
        except:
            return []

def save_keys(keys):
    with open(DB_FILE, "w") as f:
        json.dump(keys, f)

# Basic XOR encryption for the payload
def encrypt_payload(payload_string, key_string):
    payload_bytes = payload_string.encode('utf-8')
    key_bytes = key_string.encode('utf-8')
    res = bytearray()
    for i, b in enumerate(payload_bytes):
        res.append(b ^ key_bytes[i % len(key_bytes)])
    return base64.b64encode(res).decode('utf-8')

# Endpoint for Roblox to authenticate and get the script
@app.route('/api/get_script', methods=['GET'])
def get_script():
    # LEVEL 7: PULSE SECURITY
    pulse = request.headers.get('X-Parsefarm-Pulse')
    try:
        # The client sends current time XOR'd with a secret
        # We check if it's within a 10-second window
        decoded_pulse = int(pulse) ^ 0xAF42
        current_time = int(time.time())
        if abs(current_time - decoded_pulse) > 10:
            return Response("PULSE_EXPIRED", status=403)
    except:
        return Response("PULSE_MALFORMED", status=403)

    auth_header = request.headers.get('X-Parsefarm-Auth')
    if auth_header != "SecureLoader_V1":
        return Response("Failed to connect to server, check the version", mimetype='text/plain')

    key = request.args.get('key')
    valid_keys = load_keys()
    
    if key in valid_keys:
        try:
            with open("obfuscated_main.luau", "r", encoding="utf-8") as f:
                raw_code = f.read()
                # Encrypt the lua code using the user's specific key
                encrypted = encrypt_payload(raw_code, key)
                response = Response(encrypted, mimetype='text/plain')
                response.headers['X-Parsefarm-Offset'] = "399DK39XKDS9FWKF92FK4G8SD"
                return response
        except Exception as e:
            return Response("Error loading script from server.", status=500)
    else:
        return Response("INVALID_KEY", mimetype='text/plain')

# Endpoint for YOU to generate a new key for a customer
@app.route('/api/generate', methods=['GET'])
def generate_key():
    admin_key = request.args.get('admin')
    
    if admin_key != MASTER_ADMIN_KEY:
        return Response("Unauthorized: Invalid Master Key", status=401)
        
    new_key = "PF-" + secrets.token_hex(6)
    
    keys = load_keys()
    keys.append(new_key)
    save_keys(keys)
    
    html = f"""
    <h2>Success!</h2>
    <p>New Premium Key Generated: <b>{new_key}</b></p>
    <p>Total Active Keys: {len(keys)}</p>
    """
    return Response(html, mimetype='text/html')

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
