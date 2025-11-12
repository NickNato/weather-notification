import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Mock de registros de clima recebidos do backend (ordene por data, mais antigo primeiro)
List<Map<String, dynamic>> getRegistrosClimaMock() => [
  {
    'condicao': 'Sol',
    'temperatura': 25,
    'umidade': 40,
    'data': '2025-11-12 07:00'
  },
  {
    'condicao': 'Chuva',
    'temperatura': 34,
    'umidade': 80,
    'data': '2025-11-12 09:00'
  },
  {
    'condicao': 'Nublado',
    'temperatura': 29,
    'umidade': 55,
    'data': '2025-11-12 10:00'
  }
];

// == Funções de negócio ==
Map<String, dynamic>? acharExtrapolado(
    List<Map<String, dynamic>> registros, List<int> limites) {
  if (registros.length < 2 || limites.isEmpty) return null;

  final tempPrimeiro = registros.first['temperatura'] as int;

  for (int i = 1; i < registros.length; i++) {
    final tempAtual = registros[i]['temperatura'] as int;
    final variacao = (tempPrimeiro - tempAtual).abs();
    for (final limite in limites) {
      if (variacao > limite) {
        return registros[i]; // retorna só o primeiro que extrapolar
      }
    }
  }
  return null;
}

void mostrarModalExtrapolacao(BuildContext context, Map<String, dynamic> registro) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Variação Extrapolada!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Condição: ${registro['condicao']}"),
          Text("Temperatura: ${registro['temperatura']}°C"),
          Text("Umidade: ${registro['umidade']}%"),
          Text("Data: ${registro['data']}"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

void checarEAlertar(BuildContext context, List<Map<String, dynamic>> registros, List<int> limites) {
  final violador = acharExtrapolado(registros, limites);
  if (violador != null) {
    mostrarModalExtrapolacao(context, violador);
  }
}

// == App UI ==
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: PainelInicial());
  }
}

class PainelInicial extends StatefulWidget {
  @override
  State<PainelInicial> createState() => _PainelInicialState();
}

class _PainelInicialState extends State<PainelInicial> {
  List<int> itens = [];
  int valorAtual = 10;
  List<Map<String, dynamic>> registrosClima = [];

  @override
  void initState() {
    super.initState();
    carregarMockClima();
  }

  void carregarMockClima() {
    registrosClima = getRegistrosClimaMock();
    setState(() {});
    checarEAlertar(context, registrosClima, itens);
  }

  void adicionarItem() {
    setState(() {
      itens.add(valorAtual);
    });
    checarEAlertar(context, registrosClima, itens);
  }

  void removerItem(int idx) {
    setState(() {
      itens.removeAt(idx);
    });
    checarEAlertar(context, registrosClima, itens);
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
      appBar: AppBar(title: const Text("Painel Clima")),
      body: Column(
        children: [
          Expanded(child: topo(registrosClima)),
          Row(
            children: [
              Expanded(child: painelEsquerdo(itens, removerItem)),
              Expanded(child: painelDireito(valorAtual, atualizarValor, adicionarItem)),
            ],
          ),
        ],
      ),
    );
  }
}

// == Widgets ==
Widget topo(List<Map<String, dynamic>> registros) {
  if (registros.isEmpty) {
    return Container(
      color: Colors.deepPurple,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: const Text("Carregando clima...",
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }
  final clima = registros.first;
  return Container(
    color: Colors.deepPurple,
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Clima Base",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text("Condição: ${clima['condicao']}", style: const TextStyle(color: Colors.white)),
        Text("Temperatura: ${clima['temperatura']}°C", style: const TextStyle(color: Colors.white)),
        Text("Umidade: ${clima['umidade']}%", style: const TextStyle(color: Colors.white)),
        Text("Data: ${clima['data']}", style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

Widget painelEsquerdo(List<int> itens, Function(int) removerItem) {
  return Container(
    margin: const EdgeInsets.all(8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
    ),
    child: ListView.builder(
      itemCount: itens.length,
      itemBuilder: (ctx, i) =>
        ListTile(
          title: Text("Limite: ${itens[i]}"),
          trailing: InkWell(
            child: const Icon(Icons.close, color: Colors.red),
            onTap: () => removerItem(i),
          ),
        ),
    ),
  );
}

Widget painelDireito(
  int valor, Function(int) atualizarValor, Function adicionarItem) {
  return Container(
    margin: const EdgeInsets.all(8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Valor Selecionado"),
        Text("$valor", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () => atualizarValor(valor - 1), child: const Text("-1")),
            const SizedBox(width: 20),
            ElevatedButton(onPressed: () => atualizarValor(valor + 1), child: const Text("+1")),
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