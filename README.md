# Projeto Demo Ônibus (Validador Bluetooth)

Projeto de faculdade demonstrando um sistema simplificado de pagamento de passagem de ônibus utilizando comunicação **Bluetooth Low Energy (BLE)**.

A aplicação é dividida em dois módulos principais:
1.  **Modo Passageiro**: Permite ao usuário "pagar" uma passagem quando está próximo ao validador (motorista).
2.  **Modo Motorista**: Transforma o celular em um "validador" que fica ativo aguardando notificação de pagamento dos passageiros.

---

## ✨ Funcionalidades Principais

* **Modo Passageiro:**
    * Tela de saldo e botão para adicionar créditos (simulado).
    * Scanner BLE (`flutter_blue_plus`) que procura ativamente pelo sinal do validador (serviço UUID específico).
    * Habilita o botão de pagamento apenas quando o sinal do validador está forte (RSSI > -70), simulando proximidade.
    * Ao pagar, para de escanear e começa a "anunciar" (`ble_peripheral`) um "PING de pagamento" (outro serviço UUID) por 1 segundo, informando seu nome.
    * Tela de sucesso com recibo da transação.

* **Modo Motorista (Validador):**
    * Inicia um "anúncio" (advertising) BLE (`ble_peripheral`) se identificando como o "ValidadorOnibus" (serviço UUID principal).
    * Simultaneamente, inicia um scanner BLE (`flutter_blue_plus`) para "ouvir" os "PINGs de pagamento" (serviço UUID de ping).
    * Ao detectar um ping, registra o pagamento em uma lista com o nome do passageiro (extraído do `advName`), valor e hora.
    * Interface reativa que mostra o status do validador (Ativo, Procurando, Erro).

* **Geral:**
    * Tela de senha inicial (hardcoded "123") para acesso.
    * Gerenciamento de permissões de Bluetooth e Localização (`permission_handler`).

---

## 🛠️ Tecnologias Utilizadas

* **Flutter & Dart**
* **flutter_blue_plus**: Para escanear dispositivos BLE (usado em ambos os modos).
* **ble_peripheral**: Para anunciar serviços BLE (usado em ambos os modos).
* **permission_handler**: Para solicitar e verificar permissões de Bluetooth e Localização em tempo de execução.


**Importante:** Para testar, você precisará de **dois dispositivos físicos** (emuladores geralmente não têm suporte completo a BLE).
* Um rodará o app no "Modo Motorista".
* O outro rodará o app no "Modo Passageiro".
* Ambos precisam estar com Bluetooth e Localização ativados.

---

## 👨‍💻 Autor

Desenvolvido inicialmente por **Guilherme Moreira Dias** como parte de um projeto acadêmico.

Distribuído sob a **Licença MIT**. Veja o arquivo `LICENSE` para mais detalhes.