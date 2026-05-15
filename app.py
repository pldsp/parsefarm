from flask import Flask, request, Response
import os
import json
import secrets

app = Flask(__name__)

# This is YOUR master password to create new keys. Do not give this out!
MASTER_ADMIN_KEY = "owner_secret_123"
DB_FILE = "keys_db.json"

# Initialize the database if it doesn't exist
def load_keys():
    if not os.path.exists(DB_FILE):
        with open(DB_FILE, "w") as f:
            json.dump(["parsefarm_admin"], f) # The default key we made earlier
    with open(DB_FILE, "r") as f:
        try:
            return json.load(f)
        except:
            return []

def save_keys(keys):
    with open(DB_FILE, "w") as f:
        json.dump(keys, f)

# Endpoint for Roblox to authenticate and get the script
@app.route('/api/get_script', methods=['GET'])
def get_script():
    # Require custom loader header to prevent raw browser/HttpSpy execution
    auth_header = request.headers.get('X-Parsefarm-Auth')
    if auth_header != "SecureLoader_V1":
        return Response("Failed to connect to server, check the version", mimetype='text/plain')

    key = request.args.get('key')
    valid_keys = load_keys()
    
    if key in valid_keys:
        try:
            with open("parsefarm_main.luau", "r", encoding="utf-8") as f:
                return Response(f.read(), mimetype='text/plain')
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
        
    # Generate a random 16-character premium key (e.g. PF-a1b2c3d4e5f6)
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
