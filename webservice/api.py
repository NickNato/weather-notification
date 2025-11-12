# importações
from flask import Flask, jsonify
import random
import datetime
from flask_cors import CORS


# Definição das rotas
def register_routes(app):

    # Rota para obter simulação de alertas climáticos
    @app.route("/alert/<string:local>/", methods=["GET"])
    def alert(local):
        # estados aceitos
        if local.upper() not in ["PA", "BA", "RJ", "SP", "CE"]:
            return jsonify({"error": "Local nao encontrado"}), 404
        # 50% de chance de não haver alerta
        if random.choice([True, False]) is False:
            return jsonify({"mensagem": f"Nenhum alerta de clima severo para {local.upper()}."}), 200
        # corpo do alerta
        alerta = {
            "local": local,
            "mensagem": f"Alerta de clima severo para {local.upper()}! Fique atento às condições meteorológicas.",
            "nivel": random.choice(["baixo", "moderado", "alto", "extremo"]),
            "data": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        return jsonify(alerta), 200
    

    # Rota para obter dados climáticos
    @app.route("/clima/<string:local>/", methods=["GET"])
    # função logica para a rota clima
    def clima(local):
        dados_clima = []
        if local.upper() not in ["PA", "BA", "RJ", "SP", "CE"]:
            return jsonify({"error": "Local nao encontrado"}), 404

        # loop para mockagen de dados climaticos temporais 
        dt = 30  # minutos
        data_base = datetime.datetime.now()
        for i in range(6):
            data_item = data_base + datetime.timedelta(minutes=dt * i)
            dados = {
                "local": local,
                "data": data_item.strftime("%Y-%m-%d %H:%M:%S"),
                "temperatura": random.randint(12, 45),
                "umidade": random.randint(35, 68),
                "condicao": random.choice(["nublado", "chuvoso", "tempestuoso"])
            }
            dados_clima.append(dados)
        
        print(dados_clima)
        return jsonify(dados_clima), 200

# Criação do aplicativo Flask
def create_app():
    app = Flask(__name__)
    CORS(app)
    register_routes(app)
    return app
# Execução do aplicativo
def main():
    app = create_app()
    app.run(host="0.0.0.0", port=5000)

# Inicio do programa
if __name__ == "__main__":
    main()        

