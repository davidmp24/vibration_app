// functions/index.js (Versão Final com Região Especificada)

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendVibrationNotification = onDocumentCreated(
  // NOVO E MUITO IMPORTANTE: Especificamos a região aqui
  {
    region: "southamerica-east1",
    document: "vibration_requests/{requestId}",
  },
  async (event) => {
    logger.log(
      "Novo pedido de vibração recebido:",
      event.params.requestId,
    );

    const requestData = event.data.data();
    if (!requestData) {
      logger.error("Dados do pedido não encontrados.");
      return;
    }

    const recipientId = requestData.recipientId;
    const patternString = requestData.pattern;

    const recipientDocRef = admin.firestore()
      .collection("presence").doc(recipientId);
    const recipientDoc = await recipientDocRef.get();

    if (!recipientDoc.exists) {
      logger.error(
        `Destinatário com ID ${recipientId} não encontrado.`,
      );
      return;
    }

    const recipientData = recipientDoc.data();
    const fcmToken = recipientData.fcmToken;

    if (!fcmToken) {
      logger.error(
        `Destinatário ${recipientId} não possui um fcmToken salvo.`,
      );
      return;
    }

    const payload = {
      data: {
        pattern: patternString,
      },
    };

    try {
      logger.log(`Enviando notificação para o token: ${fcmToken}`);
      const response = await admin.messaging().sendToDevice(fcmToken, payload);
      logger.log("Notificação enviada com sucesso:", response);
    } catch (error) {
      logger.error("Erro ao enviar notificação:", error);
    }
  },
);