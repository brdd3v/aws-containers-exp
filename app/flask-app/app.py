import socket
import flask


app = flask.Flask(__name__)


@app.route("/")
@app.route("/home")
@app.route("/index")
def root():
    hostname = socket.gethostname()
    ip_addr = socket.gethostbyname(hostname)
    data = {"Framework": "Flask",
            "Version": flask.__version__,
            "Host IP": ip_addr,
            "Host Name": hostname}
    return flask.render_template("index.html", data=data)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
