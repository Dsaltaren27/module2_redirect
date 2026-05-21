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

// registro automático en la tabla de estadísticas
    try{
      const ip = event.requestContext?.identity?.sourceIp || 
                 event.requestContext?.http?.sourceIp || "0.0.0.0";

      const userAgent = event.headers?.["User-Agent"] || 
                        event.headers?.["User-Agent"] || "Unknown";

      const timestamp = new Date().toISOString();

// Insertar el registro de acceso en la tabla de estadísticas 
      await docClient.send(new PutCommand({
        TableName: TABLE_STATS,
        Item: {
          shortCode: shortCode,          // Partition Key de tu tabla de estadísticas
          timestamp: timestamp,          // Sort Key de tu tabla de estadísticas
          ip: ip,
          userAgent: userAgent
        }
      }));


    } catch (statsError) {
      console.error("Error al registrar estadísticas:", statsError);
      // No interrumpir la redirección si falla el registro de estadísticas
    }



    // El status 302 le dice al navegador que| redirija a la URL proporcionada
    return {
      statusCode: 302,
      headers: {
        "Location": Item.longUrl,
        "Access-Control-Allow-Origin": "*", 
        "Cache-Control": "no-cache"        
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
        detail: error.message 
      }),
    };
  }
};