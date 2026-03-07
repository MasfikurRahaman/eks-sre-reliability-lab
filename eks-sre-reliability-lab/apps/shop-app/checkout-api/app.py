from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/api/checkout", methods=["POST"])
def checkout():

    product = request.json

    return jsonify({
        "status":"success",
        "message":"Order placed",
        "product": product
    })

@app.route("/health")
def health():
    return {"status":"ok"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
