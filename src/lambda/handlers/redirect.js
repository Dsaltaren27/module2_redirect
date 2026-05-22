const { GetCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { docClient } = require("../utils/dynamodb");

const TABLE_URLS = process.env.TABLE_NAME;
const TABLE_STATS = process.env.TABLE_STATS_NAME;

exports.handler = async (event) => {
  try {
    const { shortCode } = event.pathParameters || {};

    if (!shortCode) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ error: "Falta el código de redirección" }),
      };
    }

    const { Item } = await docClient.send(new GetCommand({
      TableName: TABLE_URLS,
      Key: { shortCode: shortCode },
    }));

    // Validar si el código existe en la base de datos
    if (!Item || !Item.longUrl) {
      return {
        statusCode: 404,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: "El código no existe o ha expirado" }),
      };
    }

    // Registro automático en la tabla de estadísticas
    try {
      // API Gateway HTTP API (payload 2.0) usa requestContext.http.sourceIp
      // API Gateway REST API usa requestContext.identity.sourceIp
      const ip =
        event.requestContext?.http?.sourceIp ||
        event.requestContext?.identity?.sourceIp ||
        "0.0.0.0";

      // API Gateway HTTP API convierte los headers a minúsculas
      const userAgent =
        event.headers?.["user-agent"] ||
        event.headers?.["User-Agent"] ||
        "Unknown";

      const timestamp = new Date().toISOString();

      await docClient.send(new PutCommand({
        TableName: TABLE_STATS,
        Item: {
          shortCode: shortCode,
          timestamp: timestamp,
          ip: ip,
          userAgent: userAgent,
        },
      }));

    } catch (statsError) {
      // No interrumpir la redirección si falla el registro de estadísticas
      console.error("Error al registrar estadísticas:", statsError);
    }

    // Status 302 le dice al navegador que redirija a la URL almacenada
    return {
      statusCode: 302,
      headers: {
        "Location": Item.longUrl,
        "Access-Control-Allow-Origin": "*",
        "Cache-Control": "no-cache",
      },
      body: null,
    };

  } catch (error) {
    console.error("Error en Redirección:", error);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        message: "Error interno en el servidor",
        detail: error.message,
      }),
    };
  }
};
