# VibraLink  vib_app

![Feito com Flutter](https://img.shields.io/badge/Feito%20com-Flutter-%2302569B?style=for-the-badge&logo=flutter)
![Plataforma](https://img.shields.io/badge/Plataforma-Android-brightgreen?style=for-the-badge&logo=android)

Um aplicativo Android que permite a dois usuários se comunicarem de forma discreta e minimalista através de padrões de vibração enviados em tempo real.

---

## 💡 Conceito

A ideia do **VibraLink** é oferecer um canal de comunicação alternativo que não depende de som ou de atenção visual constante. É perfeito para situações onde o silêncio é necessário ou para criar uma forma de contato particular entre duas pessoas. Ao invés de mensagens de texto, os usuários enviam e recebem "toques" vibratórios, criando uma nova camada de interação digital.

---

## ✨ Funcionalidades

* **Descoberta de Usuários em Tempo Real:** Uma tela de "lobby" mostra quais usuários estão online e disponíveis para se conectar.
* **Canais de Comunicação Privados:** Ao selecionar um usuário, um canal de comunicação 1-para-1 é estabelecido de forma segura.
* **Envio de Vibração Contínua:** Pressione e segure um botão para que o aparelho do outro usuário vibre continuamente.
* **Envio de Padrões de Vibração:** Envie uma sequência customizada de vibrações (ex: 3 toques curtos).
* **Comunicação Instantânea:** Utiliza o Cloud Firestore do Firebase para garantir que os sinais sejam enviados e recebidos com o mínimo de latência.
* **Interface Simples e Direta:** Foco total na funcionalidade principal, sem distrações.

---

## 📷 Telas do Aplicativo

| Tela de Lobby                                        | Tela de Comunicação                                      |
| ---------------------------------------------------- | -------------------------------------------------------- |
| ![Tela de Lobby](link_para_sua_imagem_de_lobby.png)  | ![Tela de Comunicação](link_para_sua_imagem_de_chat.png) |

---

## ⬇️ Download e Instalação

Como este aplicativo não está na Google Play Store, ele precisa ser instalado manualmente.

**Opção de Download:**

<div align="center">
  <a href="https://github.com/davidmp24/vibration_app/releases/download/v1.1/Vibration.1.1.apk">
    <img src="https://img.shields.io/badge/Baixar%20APK-v1.0.0-blue?style=for-the-badge&logo=android" alt="Download APK">
  </a>
</div>

<br>

**Como Instalar:**

1.  Clique no botão acima para baixar o arquivo `app-release.apk`.
2.  Abra o arquivo baixado no seu celular.
3.  O Android pedirá permissão para instalar aplicativos de "fontes desconhecidas". Você precisa **habilitar essa permissão** para poder instalar o app.
4.  Siga os passos da instalação e, ao final, abra o aplicativo!

---

## 🛠️ Tecnologias Utilizadas

* **Flutter:** Framework principal para o desenvolvimento da interface e lógica do app.
* **Firebase (Cloud Firestore):** Backend em tempo real para gerenciar a presença dos usuários e a troca de mensagens de vibração.
* **`vibration`:** Pacote para controlar o motor de vibração do dispositivo.
* **`shared_preferences`:** Para salvar localmente o ID e nome do usuário.
* **`url_launcher`:** Para abrir links externos (como o do rodapé).
* **`uuid`:** Para gerar identificadores únicos para os usuários.

---

## 👨‍💻 Desenvolvedor

Desenvolvido com ❤️ por **[David MP](https://github.com/davidmp24)**.