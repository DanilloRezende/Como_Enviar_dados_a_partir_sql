from flask import Flask, jsonify, request

app = Flask(__name__)

lotes = [
    
]

# Consulta de dados para validar se os comandos sp_OACreate 
# com o método get funcionaram.]
# Consulta todos.
@app.route('/terminal', methods=["GET"])
def obter_lote():
    return jsonify(lotes)

# Consultar um lote específico
@app.route('/terminal/<int:LOTE>', methods=["GET"])
def obter_um_lote(LOTE):
    for lote in lotes:
        if lote.get('LOTE') == LOTE:
            return jsonify(lote)

# Criar novo registro
@app.route('/incluir', methods=['POST'])
def incluir_novo_registro():
    print((request.data).decode("utf-8")) 
    novo_registro = request.get_json()
    
    lotes.append(novo_registro)


app.run(port=5000, host='localhost', debug=True)

