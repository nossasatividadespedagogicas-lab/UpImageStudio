# Up!Image Studio — projeto Flutter multiplataforma

Este projeto é uma base inicial para Android e computador (Windows/macOS/Linux, conforme suporte do Flutter).

## Funcionalidades implementadas no protótipo
- Interface com abas: Criar arte, Painel/PDF e Chat.
- Campo de prompt e escolha de estilo.
- Importação de uma imagem pronta.
- Seleção de 4, 6, 10 ou 20 páginas.
- Papel A4, A3 ou A5.
- Ajuste de sobreposição.
- Geração de PDF de impressão com folhas numeradas.
- Geração de PDF separado com mapa e tutorial de montagem.
- Cliente HTTP para conectar geração de imagem e Chat a um backend.

## O que exige integração externa
**Geração de imagens e Chat:** o aplicativo chama:
- `POST /v1/images/generate` com `{ "prompt": "..." }`, esperando `{ "imageBase64": "..." }`.
- `POST /v1/chat` com `{ "message": "..." }`, esperando `{ "reply": "..." }`.

É necessário desenvolver e hospedar um backend que autentique o usuário e chame um provedor de IA. Nunca inclua uma chave secreta de API no aplicativo Android/desktop. O backend não está incluído nesta base.

## Importante sobre a divisão do painel
O protótipo distribui a arte em grades:
- 4 folhas: 2 colunas × 2 linhas
- 6 folhas: 2 × 3
- 10 folhas: 2 × 5
- 20 folhas: 4 × 5

O recorte de cada folha inclui uma área extra baseada na sobreposição configurada. Antes de produção, é necessário validar as medidas físicas, marcas de corte e alinhamento com impressoras reais. O layout de grade é uma primeira versão; a opção de definir largura/altura física final do painel e cálculo automático de grade deve ser aprimorada.

## Qualidade de impressão
O PDF incorpora recortes PNG da imagem fornecida. Isso não cria detalhes que não existem no original. Para obter nitidez real, a arte de origem precisa ter resolução suficiente; o modo de super-resolução por IA ainda precisa ser integrado e validado.

## Como executar
1. Instale Flutter SDK e Android Studio.
2. Para desktop, habilite o target correspondente no Flutter (por exemplo, Windows).
3. Extraia o ZIP e abra a pasta no VS Code ou Android Studio.
4. Execute `flutter pub get`.
5. Android: `flutter run`.
6. Windows: `flutter config --enable-windows-desktop` e `flutter run -d windows`.

Este é um protótipo de código-fonte. Não é um APK/EXE compilado e ainda requer testes de impressão e integração do backend de IA.
