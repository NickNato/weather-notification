# importações
from flask import Flask, jsonify, request
import random
import datetime
from flask_cors import CORS
import base64

USERNAME = "InterfaceApp"
PASSWORD = "climatempo123"

def check_auth(auth_header):
    if not auth_header:
        return False
    try:
        # auth_header vem no formato "Basic base64string"
        scheme, credentials = auth_header.split()
        if scheme.lower() != "basic":
            return False
        decoded = base64.b64decode(credentials).decode("utf-8")
        user, pwd = decoded.split(":")
        return user == USERNAME and pwd == PASSWORD
    except Exception:
        return False


def require_basic_auth(f):
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization")
        if not check_auth(auth_header):
            return jsonify({"error": "Autenticacao falhou"}), 401
        return f(*args, **kwargs)
    wrapper.__name__ = f.__name__  # necessário para o Flask reconhecer a função
    return wrapper

# Definição das rotas
def register_routes(app):

    # Rota para obter simulação de alertas climáticos
    @app.route("/alert/<string:local>/", methods=["GET"])
    @require_basic_auth
    def alert(local):
        # estados aceitos
        if local.upper() not in ["PA", "BA", "RJ", "SP", "CE"]:
            return jsonify({"error": "Local nao encontrado"}), 404
        # 50% de chance de não haver alerta
        if random.choice([True, False]) is False:
            return jsonify({"mensagem": f"Nenhum alerta de clima severo para {local.upper()}."}), 200
        # corpo do alerta
        estado_ext = {
            "PA": "Pará",
            "BA": "Bahia",
            "RJ": "Rio de Janeiro",
            "SP": "São Paulo",
            "CE": "Ceará"
        }[local.upper()]
        alerta = {
            "local": local,
            "mensagem": f"Alerta de mudança de clima no estado do {estado_ext}! Fique atento às condições meteorológicas.",
            # "nivel": random.choice(["extremo"]),
            "nivel": random.choice(["baixo", "moderado", "alto", "extremo"]),

            "data": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        return jsonify(alerta), 200
    

    # Rota para obter dados climáticos
    @app.route("/clima/<string:local>/", methods=["GET"])
    @require_basic_auth
    # função logica para a rota clima
    def clima(local):
        dados_clima = []
        if local.upper() not in ["PA", "BA", "RJ", "SP", "CE"]:
            return jsonify({"error": "Local nao encontrado"}), 404

        # loop para mockagen de dados climaticos temporais 
        dt = 30  # minutos
        data_base = datetime.datetime.now()
        for i in range(8):
            data_item = data_base + datetime.timedelta(minutes=dt * i)
            dados = {
                "local": local,
                "data": data_item.strftime("%Y-%m-%d %H:%M:%S"),
                "temperatura": random.randint(12, 45),
                "umidade": random.randint(35, 68),
                "condicao": random.choice(["nublado", "chuvoso", "tempestuoso"])
            }
            dados_clima.append(dados)
        dados_clima = list(reversed(dados_clima))
        
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

