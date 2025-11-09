import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> buscarClima() async {
  final url = Uri.parse("http://192.168.1.10:5000/clima/SP/");

  final resp = await http.get(url);

  if (resp.statusCode == 200) {
    final lista = jsonDecode(resp.body); // vem lista

    if (lista is List && lista.isNotEmpty) {
      return lista.first; // pega só o primeiro registro
    } else {
      throw Exception("Lista vazia ou inválida");
    }
  } else {
    throw Exception("Erro ao buscar clima: ${resp.statusCode}");
  }
}

void main() {
  runApp(const MyApp());
}



int calcularMaiorVariacao(List<dynamic> lista) {
  if (lista.length < 2) return 0;

  // extrai só as temperaturas
  List<int> temps = lista.map<int>((e) => e['temperatura'] as int).toList();

  int menor = temps.reduce((a, b) => a < b ? a : b);
  int maior = temps.reduce((a, b) => a > b ? a : b);

  return (maior - menor).abs();
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

// =====================
// TELA PRINCIPAL
// =====================
class MenuInicial extends StatefulWidget {
  const MenuInicial({super.key});

  @override
  State<MenuInicial> createState() => _MenuInicialState();
}

class _MenuInicialState extends State<MenuInicial> {
  List<int> itens = [];
  int valorAtual = 10;

Map<String, dynamic>? clima;

@override
void initState() {
  super.initState();
  carregarClima();
}

Future<void> carregarClima() async {
  try {
    final dados = await buscarClima();
    setState(() {
      clima = dados;
    });
    
  } catch (e) {
    print("Erro: $e");
  }
}
void removerItem(int index) {
  setState(() {
    itens.removeAt(index);
  });
}
  void adicionarItem() {
    setState(() {
      itens.add(valorAtual);
    });
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
Widget topo(Map<String, dynamic>? clima) {
  if (clima == null) {
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
          "Condição: ${clima['condicao']}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Text(
          "Temperatura: ${clima['temperatura']}°C",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Text(
          "Umidade: ${clima['umidade']}%",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Text(
          "Data: ${clima['data']}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    ),
  );
}


// =====================
// PAINEL ESQUERDO
// =====================
Widget painelEsquerdo(List<int> itens, Function(int) removerItem) {
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
        return itemClima(
          itens[i],
          () => removerItem(i), // remove pelo índice
        );
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
        const Text("Valor Selecionado", style: TextStyle(fontSize: 18)),
        Text(
          "$valor",
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
          onPressed: () => adicionarItem(),
          child: const Text("Adicionar no Painel Esquerdo"),
        ),
      ],
    ),
  );
}

Widget itemClima(int valor, VoidCallback onRemove) {
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
            "Clima há Notificar: $valor",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Botão de remover (X)
        InkWell(
          onTap: onRemove,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "(x)",
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
