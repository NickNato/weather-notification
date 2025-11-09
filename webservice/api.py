from flask import Flask, jsonify
import random
import datetime
from flask_cors import CORS

def register_routes(app):

    @app.route("/clima/<string:local>/", methods=["GET"])
    def clima(local):
        dados_clima = []
        if local.upper() not in ["PA", "BA", "RJ", "SP", "CE"]:
            return jsonify({"error": "Local nao encontrado"}), 404

        dt = 30  # minutos
        data_base = datetime.datetime.now()
        for i in range(6):
            data_item = data_base + datetime.timedelta(minutes=dt * i)
            dados = {
                "local": local,
                "data": data_item.strftime("%Y-%m-%d %H:%M:%S"),
                "temperatura": random.randint(27, 39),
                "umidade": random.randint(35, 68),
                "condicao": random.choice(["nublado", "chuvoso", "tempestuoso"])
            }
            dados_clima.append(dados)
        
        print(dados_clima)
        return jsonify(dados_clima), 200


def create_app():
    app = Flask(__name__)
    CORS(app)
    register_routes(app)
    return app
def main():
    app = create_app()
    app.run(host="0.0.0.0", port=5000)
if __name__ == "__main__":
    main()        

