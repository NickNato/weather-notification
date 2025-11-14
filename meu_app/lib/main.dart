import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// =====================
// FUNÇÃO PARA BUSCAR CLIMA DO ESTADO
// =====================


// Usuário e senha da API
const String usuario = "InterfaceApp";
const String senha = "climatempo123";

// Gera o header Basic Auth
Map<String, String> basicAuthHeader() {
  String basicAuth = 'Basic ' + base64Encode(utf8.encode('$usuario:$senha'));
  return {
    'Authorization': basicAuth,
    'Content-Type': 'application/json',
  };
}

Future<List<Map<String, dynamic>>> buscarClima(String estado) async {
  final url = Uri.parse("http://192.168.1.10:5000/clima/$estado/");
  final resp = await http.get(url, headers: basicAuthHeader());

  if (resp.statusCode == 200) {
    final dados = jsonDecode(resp.body);

    if (dados is List) {
      return dados.cast<Map<String, dynamic>>();
    } else {
      throw Exception("A API não retornou uma lista válida");
    }
  } else {
    if (resp.statusCode == 401) {
      throw Exception("Autenticação falhou ao buscar clima.");
    }
    throw Exception("Erro ao buscar clima: ${resp.statusCode}");
  }
}



Future<Map<String, dynamic>?> buscarAlerta(String estado) async {
  try {
    final url = Uri.parse("http://192.168.1.10:5000/alert/$estado/");
    final resp = await http.get(url, headers: basicAuthHeader());

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      return null;
    }
  } catch (e) {
    print("Erro ao buscar alerta: $e");
    return null;
  }
}

// =====================
// parsers
// =====================
int parseInt(dynamic valor) {
  if (valor is int) return valor;
  if (valor is String) return int.tryParse(valor) ?? 0;
  return 0;
}

void showAlertaModal(BuildContext context, Map<String, dynamic> alerta) {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange[700],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                blurRadius: 15,
                color: Colors.black.withOpacity(0.3),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.white),
              const SizedBox(height: 15),
              Text(
                alerta["mensagem"] ?? "Alerta",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Nível: ${alerta["nivel"]?.toUpperCase() ?? "desconhecido"}",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Fechar"),
              ),
            ],
          ),
        ),
      );
    },
  );
}


// =====================
// FUNÇÃO PARA ENCONTRAR REGISTRO DE EXTRAPOLAÇÃO
// =====================
Map<String, dynamic>? encontrarRegistroExtrapolacao(
  List<Map<String, dynamic>> lista,
  int limite,
) {
  if (lista.length < 2) return null;

  // cria uma COPIA para não ferrar a lista original
  final copia = List<Map<String, dynamic>>.from(lista);

  // garante que está ordenada pela data
  copia.sort((a, b) => a['data'].compareTo(b['data']));

  final atual = copia.last; 
  final tempAtual = atual['temperatura'];

  for (var item in copia) {
    final diff = (tempAtual - item['temperatura']).abs();
  print(  diff);
  print(  limite);
  print(  tempAtual);
  print(  item['temperatura']);


    if (diff >= limite) {
      return item; // extrapolação detectada
    }
  }

  return null;
}
// =====================
// FUNÇÃO PARA MOSTRAR O MODAL DE EXTRAPOLAÇÃO
// =====================
void mostrarModalExtrapolacao(
  BuildContext context,
  Map<String, dynamic> registro,
  Function(Map<String, dynamic>) onDetectar
) {
  onDetectar(registro);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Alerta de Variação brusca de temperatura!"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Condição: ${registro['condicao']}"),
         Text(
  "Temperatura: ${registro['temperatura']}°C",
  style: TextStyle(
    color: registro['temperatura'] < 20
        ? Colors.blue
        : registro['temperatura'] <= 26
            ? Colors.black
            : Colors.red,
    fontWeight: FontWeight.bold,
  ),
),
          Text("Umidade: ${registro['umidade']}%"),
          Text("Data: ${registro['data']}"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Ok"),
        ),
      ],
    ),
  );
}

// =====================
// FUNÇÃO PARA DISPARAR CHECAGEM O FLUXO
// =====================
void verificarExtrapolacaoEAlertar(
  BuildContext context,
  List<Map<String, dynamic>> lista,
  int limite,
  Function(Map<String, dynamic>) onDetectar,
) {
  final registro = encontrarRegistroExtrapolacao(lista, limite);
  if (registro != null) {
    mostrarModalExtrapolacao(context, registro, onDetectar);
  }
}


// =====================
// APP ROOT
// =====================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Painel Inicial',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MenuInicial(),
    );
  }
}


void mostrarErro(BuildContext context, String mensagem) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Erro"),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Ok"),
        ),
      ],
    ),
  );
}
// =====================
// TELA PRINCIPAL
// =====================
class MenuInicial extends StatefulWidget {
  const MenuInicial({super.key});

  @override
  State<MenuInicial> createState() => _MenuInicialState();
}

class _MenuInicialState extends State<MenuInicial> {
  List<String> itens = [];
  int valorAtual = 10;
  List<Map<String, dynamic>>? clima;

  // Estados para seleção
  final List<String> estados = ["PA", "BA", "RJ", "SP", "CE", "MG"];
  String estadoSelecionado = "PA";

  @override
  void initState() {
    super.initState();
    carregarClima();
  }
  void adicionarNotificacao(Map<String, dynamic> registro) {
  final hora = registro['data']; // já vem no formato da API
  final temp = registro['temperatura'];

  setState(() {
    itens.add("$hora — ${temp}°C");
  });
}

  // =====================
  // FUNÇÃO PARA CARREGAR CLIMA E CHAMAR CHECAGEM DE EXTRAPOLAÇÃO
  // =====================
Future<void> carregarClima() async {
    try {
      clima = await buscarClima(estadoSelecionado);
      setState(() {});
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Erro"),
          content: Text("Erro ao carregar clima: $e"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    }
  }


Future<void> aoTrocarEstado(String novoEstado) async {
    setState(() => estadoSelecionado = novoEstado);

    await carregarClima();

    final alerta = await buscarAlerta(novoEstado);
    if (alerta != null && alerta.containsKey("nivel")) {
      showAlertaModal(context, alerta);
    }
  }
  void removerItem(int index) {
    setState(() {
      itens.removeAt(index);
    });
  }

void adicionarItem() {
  if (clima == null) return;

  verificarExtrapolacaoEAlertar(
    context,
    clima!,             
    valorAtual,
    adicionarNotificacao,
  );
}


  void atualizarValor(int novo) {
    if (novo >= 10 && novo <= 50) {
      setState(() {
        valorAtual = novo;
      


      });
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      backgroundColor: Colors.deepPurple,
      title: const Text('Menu Inicial', style: TextStyle(color: Colors.white)),
      centerTitle: true,
    ),
    body: Column(
      children: [
        // DROPDOWN DE ESTADO
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButton<String>(
            value: estadoSelecionado,
            items: estados.map((String e) {
              return DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              );
            }).toList(),
            onChanged: (String? novoEstado) {
              if (novoEstado != null) {
                aoTrocarEstado(novoEstado); // chama a função que atualiza clima e alerta
              }
            },
          ),
        ),
        Expanded(flex: 2, child: topo(clima)),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(child: painelEsquerdo(itens, removerItem)),
              Expanded(
                child: painelDireito(
                  valorAtual,
                  atualizarValor,
                  adicionarItem,
                  clima, // caso queira usar o clima no painel direito
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}

// =====================
// PAINEL SUPERIOR
// =====================
Widget topo(List<Map<String, dynamic>>? clima) {
  if (clima == null || clima.isEmpty) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const Text(
        'Carregando clima...',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  final atual = clima.last;

  return Container(
    decoration: const BoxDecoration(
      color: Colors.deepPurple,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
    ),
    padding: const EdgeInsets.all(16),
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Clima Atual',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Condição: ${atual['condicao']}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Text(
          "Temperatura: ${atual['temperatura']}°C",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Text(
          "Umidade: ${atual['umidade']}%",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Text(
          "Data: ${atual['data']}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    ),
  );
}

// =====================
// PAINEL ESQUERDO
// =====================
Widget painelEsquerdo(List<String> itens, Function(int) removerItem) {
  return Container(
    margin: const EdgeInsets.all(8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2))
      ],
    ),
    child: ListView.builder(
      itemCount: itens.length,
      itemBuilder: (ctx, i) {
        return itemClima(itens[i], () => removerItem(i));
      },
    ),
  );
}

// =====================
// PAINEL DIREITO
// =====================
Widget painelDireito(
  int valor,
  Function(int) atualizarValor,
  Function adicionarItem,
  clima,
) {
  return Container(
    margin: const EdgeInsets.all(8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(-2, 2))
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Ajuste de temperatura: ", style: TextStyle(fontSize: 18)),
        Text(
          "$valor °C",
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => atualizarValor(valor - 1),
              child: const Text("-1"),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () => atualizarValor(valor + 1),
              child: const Text("+1"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
  onPressed: (clima == null || clima!.isEmpty) ? null : () => adicionarItem(),
  child: const Text("Aplicar"),
),
      ],
    ),
  );
}

// =====================
// ITEM DO PAINEL ESQUERDO
// =====================
Widget itemClima(String texto, VoidCallback onRemove) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: const Offset(1, 1),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        InkWell(
          onTap: onRemove,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "(X)",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}