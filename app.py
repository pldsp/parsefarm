from flask import Flask, request, Response
import os

app = Flask(__name__)

VALID_KEY = "parsefarm_admin"

@app.route('/api/get_script', methods=['GET'])
def get_script():
    key = request.args.get('key')
    if key == VALID_KEY:
        try:
            with open("parsefarm_main.luau", "r", encoding="utf-8") as f:
                return Response(f.read(), mimetype='text/plain')
        except Exception as e:
            return Response("Error loading script from server.", status=500)
    else:
        return Response("INVALID_KEY", mimetype='text/plain')

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
