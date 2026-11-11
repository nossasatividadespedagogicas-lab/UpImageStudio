import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'services/ai_service.dart';
import 'services/panel_pdf_service.dart';

void main() => runApp(const UpImageStudioApp());

class UpImageStudioApp extends StatelessWidget {
  const UpImageStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0878DB);
    return MaterialApp(
      title: 'Up!Image Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F8FC),
      ),
      home: const StudioHome(),
    );
  }
}

class StudioHome extends StatefulWidget {
  const StudioHome({super.key});

  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  final _prompt = TextEditingController();
  final _chat = TextEditingController();
  final _ai = AiService(
    // Configure a URL do seu servidor. Nunca coloque uma chave de API aqui.
    baseUrl: const String.fromEnvironment(
      'UPIMAGE_API_URL',
      defaultValue: 'https://SEU-SERVIDOR.example.com',
    ),
  );

  Uint8List? _artBytes;
  String? _artName;
  String _style = 'Colorido e lúdico';
  int _pages = 4;
  int _overlap = 5;
  String _paper = 'A4';
  bool _busy = false;
  String _status = 'Descreva o painel que deseja criar ou selecione uma arte pronta.';
  String _chatReply =
      'Olá! Sou o assistente do Up!Image. A conexão com o serviço de IA será ativada quando o servidor estiver configurado.';

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _artBytes = result.files.single.bytes!;
      _artName = result.files.single.name;
      _status = 'Arte carregada: $_artName';
    });
  }

  Future<void> _generateArt() async {
    if (_prompt.text.trim().isEmpty) {
      setState(() => _status = 'Escreva uma descrição para gerar a arte.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Enviando prompt para o serviço de geração de imagens...';
    });
    try {
      final bytes = await _ai.generateImage(
        prompt: '${_prompt.text.trim()}. Estilo: $_style. Arte limpa, composição organizada, texto legível em português.',
      );
      setState(() {
        _artBytes = bytes;
        _artName = 'upimage_arte_gerada.png';
        _status = 'Imagem recebida. Confira a arte antes de montar o painel.';
      });
    } catch (e) {
      setState(() => _status =
          'Não foi possível gerar a imagem. Configure o backend de IA conforme o README. Detalhe: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _upscaleImage() async {
    final originalBytes = _artBytes;

    if (originalBytes == null) {
      setState(() {
        _status = 'Selecione uma imagem antes de aumentar a resolução.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Aumentando a resolução da imagem...';
    });

    try {
      final original = img.decodeImage(originalBytes);

      if (original == null) {
        throw Exception('Não foi possível ler a imagem.');
      }

      final newHeight =
          (original.height * 3840 / original.width).round();

      final resized = img.copyResize(
        original,
        width: 3840,
        height: newHeight,
);

      final pngBytes = Uint8List.fromList(img.encodePng(resized));

      setState(() {
        _artBytes = pngBytes;
        _artName = 'upimage_3840px.png';
        _status = 'Imagem ampliada para 3840 pixels de largura.';
      });
    } catch (e) {
      setState(() {
        _status = 'Não foi possível ampliar a imagem: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _exportPanel() async {
    final bytes = _artBytes;
    if (bytes == null) {
      setState(() => _status = 'Gere ou selecione uma imagem antes de montar o painel.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Preparando PDF dividido em $_pages páginas...';
    });
    try {
      final result = await PanelPdfService.build(
        imageBytes: bytes,
        pageCount: _pages,
        paper: _paper,
        overlapMm: _overlap,
      );
      if (!mounted) return;
     await Printing.sharePdf(
  bytes: result.pdf,
  filename: 'UpImage_painel_${_pages}_paginas.pdf',
);
      setState(() => _status =
          'PDF de impressão e tutorial de montagem preparados. Use a opção de salvar/compartilhar.');
    } catch (e) {
      setState(() => _status = 'Erro ao montar os PDFs: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _sendChat() async {
    final message = _chat.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _chatReply = 'Enviando mensagem...';
      _busy = true;
    });
    try {
      final answer = await _ai.chat(message);
      setState(() => _chatReply = answer);
    } catch (e) {
      setState(() => _chatReply =
          'O Chat ainda precisa de um backend de IA configurado. Consulte o README. Detalhe: $e');
    } finally {
      setState(() => _busy = false);
      _chat.clear();
    }
  }

  @override
  void dispose() {
    _prompt.dispose();
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
   length: 4,   
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Up!Image Studio', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Criação de painéis pedagógicos', style: TextStyle(fontSize: 11)),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.auto_awesome), text: 'Criar arte'),
              Tab(icon: Icon(Icons.dashboard_customize), text: 'Painel / PDF'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
              Tab(icon: Icon(Icons.auto_fix_high), text: 'Restaurar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCreateTab(),
            _buildPanelTab(),
            _buildChatTab(),
            _buildRestoreTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('O que vamos criar?', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _prompt,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ex.: Painel pedagógico sobre os números de 0 a 30, com letras grandes, cores alegres e elementos escolares...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _style,
          decoration: const InputDecoration(labelText: 'Estilo visual', border: OutlineInputBorder()),
          items: const ['Colorido e lúdico', 'Moderno e organizado', 'Aquarela', '3D infantil', 'Minimalista']
              .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _style = v ?? _style),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _generateArt,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Gerar imagem pelo prompt'),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Ou selecionar uma imagem pronta'),
        ),
        if (_artBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_artBytes!, fit: BoxFit.contain),
          ),
          Text(_artName ?? 'Imagem selecionada', textAlign: TextAlign.center),
        ],
        const SizedBox(height: 12),
        _StatusBox(status: _status),
      ],
    );
  }

  Widget _buildPanelTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Transforme a arte em um painel', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('O painel será dividido em folhas numeradas, com sobreposição para facilitar a montagem.'),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _pages,
          decoration: const InputDecoration(labelText: 'Quantidade de páginas A4', border: OutlineInputBorder()),
          items: const [4, 6, 10, 20].map((n) => DropdownMenuItem(value: n, child: Text('$n páginas'))).toList(),
          onChanged: (v) => setState(() => _pages = v ?? 4),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _paper,
          decoration: const InputDecoration(labelText: 'Papel', border: OutlineInputBorder()),
          items: const ['A4', 'A3', 'A5'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _paper = v ?? 'A4'),
        ),
        const SizedBox(height: 12),
        Text('Sobreposição entre folhas: $_overlap mm'),
        Slider(
          value: _overlap.toDouble(),
          min: 0,
          max: 15,
          divisions: 15,
          label: '$_overlap mm',
          onChanged: (v) => setState(() => _overlap = v.round()),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Prévia da divisão', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _PageGrid(count: _pages),
              const SizedBox(height: 8),
              Text('Cada folha recebe numeração e o PDF de montagem mostra a ordem de colagem.'),
            ]),
          ),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _exportPanel,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Gerar PDF + tutorial de montagem'),
        ),
        const SizedBox(height: 12),
        _StatusBox(status: _status),
      ],
    );
  }

  Widget _buildChatTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Chat Up!Image', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_chatReply))),
        const SizedBox(height: 12),
        TextField(
          controller: _chat,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Pergunte sobre painéis, prompts, impressão ou montagem...',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _sendChat,
          icon: const Icon(Icons.send),
          label: const Text('Enviar mensagem'),
        ),
      ],
    );
  }
    Widget _buildRestoreTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Restaurar e Melhorar Imagens',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Selecione uma imagem para preparar a melhoria de qualidade.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _pickImage,
          icon: const Icon(Icons.image_search),
          label: const Text('Selecionar imagem'),
        ),
        if (_artBytes != null) ...[
          const SizedBox(height: 16),
          Image.memory(_artBytes!, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(_artName ?? 'Imagem selecionada'),
        ],
        const SizedBox(height: 12),
        _StatusBox(status: _status),
      ],
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(padding: const EdgeInsets.all(12), child: Text(status)),
      );
}

class _PageGrid extends StatelessWidget {
  const _PageGrid({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final cols = count == 4 || count == 6 ? 2 : 4;
    final rows = (count / cols).ceil();
    return Column(
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(cols, (c) {
            final n = r * cols + c + 1;
            if (n > count) return const Expanded(child: SizedBox());
            return Expanded(
              child: Container(
                margin: const EdgeInsets.all(2),
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  border: Border.all(color: Colors.blue.shade400),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(child: Text('$n', style: const TextStyle(fontWeight: FontWeight.bold))),
              ),
            );
          }),
        );
      }),
    );
  }
}
