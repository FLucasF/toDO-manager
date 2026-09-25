import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/quick_add.dart' show foldForSearch;
import '../../l10n/app_localizations.dart';

/// The list icon picker: search, categories (Pessoas e Corpo, Natureza, Comida,
/// Atividades, Viagem, Objetos, Símbolos, Bandeiras), "Aleatório" and "Redefinir". Returns the emoji,
/// '' for "Redefinir" (no icon), or null when closed.
Future<String?> showEmojiPicker(BuildContext context) => showDialog<String>(context: context, builder: (_) => const _EmojiPicker());

/// Each entry: the emoji, then the words that find it.
const _categories = <(IconData, List<String>)>[
  (
    Icons.emoji_emotions_outlined,
    [
      '😀 sorriso feliz',
      '😁 sorriso alegre',
      '😂 risada chorar',
      '😊 feliz contente',
      '😍 amor apaixonado',
      '🥰 amor carinho',
      '😎 legal oculos',
      '🤓 nerd estudo',
      '🤔 pensar duvida',
      '😴 sono dormir',
      '😷 doente saude',
      '🤒 doente febre',
      '🥳 festa aniversario',
      '😇 anjo',
      '😡 raiva bravo',
      '😭 chorar triste',
      '😱 medo susto',
      '🤯 cabeca explodindo',
      '🙏 obrigado orar',
      '👍 joinha ok',
      '👏 palmas',
      '💪 forca academia treino',
      '👋 ola tchau',
      '✌️ paz',
      '🤝 acordo parceria',
      '👀 olhos ver',
      '🧠 cerebro mente estudo',
      '❤️ coracao amor',
      '👶 bebe crianca',
      '👨‍👩‍👧 familia',
      '🧑‍💻 programador computador trabalho',
      '🧑‍🍳 cozinheiro',
      '🧑‍🎓 formatura estudante',
      '🧑‍⚕️ medico saude',
      '🧘 meditacao yoga',
      '🏃 correr corrida',
    ],
  ),
  (
    Icons.eco_outlined,
    [
      '🐶 cachorro cao pet',
      '🐱 gato pet',
      '🐭 rato',
      '🐰 coelho',
      '🦊 raposa',
      '🐻 urso',
      '🐼 panda',
      '🐨 coala',
      '🦁 leao',
      '🐮 vaca',
      '🐷 porco',
      '🐸 sapo',
      '🐵 macaco',
      '🐔 galinha',
      '🐧 pinguim',
      '🐦 passaro',
      '🦋 borboleta',
      '🐝 abelha',
      '🐞 joaninha',
      '🐢 tartaruga',
      '🐍 cobra',
      '🐙 polvo',
      '🐟 peixe',
      '🐬 golfinho',
      '🌱 planta broto',
      '🌳 arvore',
      '🌵 cacto',
      '🌸 flor cerejeira',
      '🌻 girassol',
      '🌹 rosa flor',
      '🍀 trevo sorte',
      '🍁 folha outono',
      '🌞 sol',
      '🌙 lua noite',
      '⭐ estrela',
      '🌈 arco-iris',
      '☁️ nuvem',
      '⛄ neve inverno',
      '🔥 fogo',
      '💧 agua gota',
    ],
  ),
  (
    Icons.restaurant_outlined,
    [
      '🍎 maca fruta',
      '🍌 banana',
      '🍇 uva',
      '🍓 morango',
      '🍉 melancia',
      '🍍 abacaxi',
      '🥑 abacate',
      '🍋 limao',
      '🥕 cenoura',
      '🥦 brocolis',
      '🌽 milho',
      '🍅 tomate',
      '🥔 batata',
      '🍞 pao padaria',
      '🧀 queijo',
      '🥚 ovo',
      '🍳 cozinhar ovo',
      '🥩 carne churrasco',
      '🍗 frango',
      '🍔 hamburguer lanche',
      '🍕 pizza',
      '🌭 cachorro-quente',
      '🌮 taco',
      '🍝 macarrao massa',
      '🍣 sushi',
      '🍜 lamen sopa',
      '🍰 bolo',
      '🎂 bolo aniversario',
      '🍫 chocolate',
      '🍪 biscoito',
      '🍩 rosquinha',
      '🍦 sorvete',
      '☕ cafe',
      '🍵 cha',
      '🥛 leite',
      '🍺 cerveja',
      '🍷 vinho',
      '🥤 refrigerante',
      '🧃 suco',
      '🛒 mercado compras',
    ],
  ),
  (
    Icons.sports_soccer_outlined,
    [
      '⚽ futebol bola',
      '🏀 basquete',
      '🏐 volei',
      '🎾 tenis',
      '🏓 pingue-pongue',
      '🏸 badminton',
      '🥊 boxe luta',
      '🏊 natacao piscina',
      '🚴 bicicleta ciclismo',
      '🏋️ academia peso musculacao',
      '🤸 ginastica',
      '⛹️ esporte',
      '🧗 escalada',
      '🏄 surfe',
      '⛷️ esqui',
      '🎯 alvo meta objetivo',
      '🎮 jogo videogame',
      '🎲 dado jogo tabuleiro',
      '🧩 quebra-cabeca',
      '♟️ xadrez',
      '🎨 arte pintura',
      '🎭 teatro',
      '🎬 filme cinema',
      '🎤 cantar microfone',
      '🎧 musica fone',
      '🎵 musica nota',
      '🎸 violao guitarra',
      '🎹 piano teclado',
      '🥁 bateria',
      '📚 livros leitura estudo',
      '🏆 trofeu vitoria',
      '🥇 medalha primeiro',
    ],
  ),
  (
    Icons.flight_outlined,
    [
      '✈️ aviao viagem voo',
      '🚗 carro',
      '🚕 taxi',
      '🚌 onibus',
      '🚆 trem',
      '🚇 metro',
      '🚲 bicicleta',
      '🛵 moto',
      '🚀 foguete lancamento',
      '⛵ barco veleiro',
      '🚢 navio cruzeiro',
      '🗺️ mapa',
      '🧭 bussola',
      '🏖️ praia ferias',
      '🏝️ ilha',
      '⛰️ montanha',
      '🏕️ acampamento',
      '🏙️ cidade',
      '🏠 casa lar',
      '🏡 casa jardim',
      '🏢 escritorio predio trabalho',
      '🏥 hospital',
      '🏫 escola',
      '🏦 banco',
      '🏨 hotel',
      '⛪ igreja',
      '🗽 estatua liberdade',
      '🗼 torre',
      '🌍 mundo terra',
      '🧳 mala bagagem',
      '⛽ gasolina posto',
      '🚦 semaforo transito',
    ],
  ),
  (
    Icons.lightbulb_outline,
    [
      '💡 ideia lampada',
      '📱 celular',
      '💻 computador notebook',
      '⌨️ teclado',
      '🖥️ monitor',
      '🖨️ impressora',
      '📷 camera foto',
      '🎥 video filmadora',
      '📺 televisao',
      '📻 radio',
      '⏰ despertador alarme',
      '⌛ tempo ampulheta',
      '📅 calendario data',
      '📆 agenda',
      '📌 alfinete fixar',
      '📎 clipe anexo',
      '✏️ lapis escrever',
      '🖊️ caneta',
      '📝 anotacao nota',
      '📒 caderno',
      '📓 caderno',
      '📖 livro',
      '🗂️ pastas arquivo',
      '📁 pasta',
      '📦 caixa pacote entrega',
      '📬 correio carta',
      '✉️ email envelope',
      '💼 maleta trabalho',
      '💰 dinheiro',
      '💳 cartao',
      '🧾 recibo conta',
      '🔑 chave',
      '🔒 cadeado seguranca',
      '🔧 ferramenta chave',
      '🔨 martelo',
      '🧰 caixa ferramentas',
      '🧹 vassoura limpeza',
      '🧺 cesto roupa',
      '🛏️ cama',
      '💊 remedio',
      '🎁 presente',
      '🎈 balao festa',
      '🕯️ vela',
      '🔔 sino notificacao',
      '🔍 lupa busca',
      '🧪 quimica ciencia',
      '🔬 microscopio',
      '🪴 vaso planta',
    ],
  ),
  (
    Icons.tag,
    [
      '✅ feito concluido',
      '☑️ caixa marcada',
      '✔️ certo',
      '❌ errado cancelar',
      '❗ importante atencao',
      '❓ pergunta duvida',
      '⚠️ aviso cuidado',
      '⛔ proibido',
      '🔴 vermelho',
      '🟠 laranja',
      '🟡 amarelo',
      '🟢 verde',
      '🔵 azul',
      '🟣 roxo',
      '⚫ preto',
      '⚪ branco',
      '❤️ vermelho coracao',
      '🧡 laranja coracao',
      '💛 amarelo coracao',
      '💚 verde coracao',
      '💙 azul coracao',
      '💜 roxo coracao',
      '🖤 preto coracao',
      '🤍 branco coracao',
      '⭐ estrela favorito',
      '✨ brilho',
      '💯 cem perfeito',
      '🔥 quente urgente',
      '♻️ reciclar',
      '➕ mais adicionar',
      '➖ menos',
      '🔁 repetir',
      '▶️ play iniciar',
      '⏸️ pausa',
      '⏹️ parar',
      '🔜 em breve',
      '🆕 novo',
      '🆗 ok',
      '#️⃣ hashtag numero',
      '💤 dormir',
    ],
  ),
  (
    Icons.flag_outlined,
    [
      '🏁 chegada bandeira',
      '🚩 bandeira vermelha',
      '🏳️ bandeira branca',
      '🏴 bandeira preta',
      '🏳️‍🌈 arco-iris orgulho',
      '🇧🇷 brasil',
      '🇵🇹 portugal',
      '🇺🇸 estados unidos eua',
      '🇬🇧 reino unido inglaterra',
      '🇪🇸 espanha',
      '🇫🇷 franca',
      '🇮🇹 italia',
      '🇩🇪 alemanha',
      '🇯🇵 japao',
      '🇨🇳 china',
      '🇰🇷 coreia',
      '🇦🇷 argentina',
      '🇨🇱 chile',
      '🇺🇾 uruguai',
      '🇵🇾 paraguai',
      '🇲🇽 mexico',
      '🇨🇦 canada',
      '🇦🇺 australia',
      '🇮🇳 india',
    ],
  ),
];

class _EmojiPicker extends StatefulWidget {
  const _EmojiPicker();

  @override
  State<_EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<_EmojiPicker> {
  final _search = TextEditingController();
  int _category = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _emoji(String entry) => entry.split(' ').first;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final query = foldForSearch(_search.text.trim());
    final names = [t.emojiPeople, t.emojiNature, t.emojiFood, t.emojiActivities, t.emojiTravel, t.emojiObjects, t.emojiSymbols, t.emojiFlags];
    final shown = query.isEmpty
        ? _categories[_category].$2
        : [
            for (final (_, entries) in _categories)
              for (final e in entries)
                if (foldForSearch(e.substring(_emoji(e).length)).contains(query)) e,
          ];
    return Dialog(
      child: SizedBox(
        width: 380,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: t.emojiSearch,
                  filled: true,
                  fillColor: tt.fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (query.isEmpty)
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < _categories.length; i++)
                      IconButton(
                        tooltip: names[i],
                        visualDensity: VisualDensity.compact,
                        icon: Icon(_categories[i].$1, size: 18, color: i == _category ? tt.primary : tt.textTertiary),
                        onPressed: () => setState(() => _category = i),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                query.isEmpty ? names[_category] : t.emojiResults,
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 8,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final e in shown)
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => Navigator.pop(context, _emoji(e)),
                      child: Center(child: Text(_emoji(e), style: const TextStyle(fontSize: 22))),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.shuffle, size: 16),
                    label: Text(t.emojiRandom),
                    onPressed: () {
                      final all = [for (final (_, entries) in _categories) ...entries];
                      Navigator.pop(context, _emoji(all[math.Random().nextInt(all.length)]));
                    },
                  ),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context, ''), child: Text(t.emojiReset)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
