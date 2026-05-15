const { GetCommand } = require("@aws-sdk/lib-dynamodb");
const { docClient } = require("../utils/dynamodb");

exports.handler = async (event) => {
  try {
    const { shortCode } = event.pathParameters || {};

    if (!shortCode) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Falta el código de redirección" }),
      };
    }

    const params = {
      TableName: process.env.TABLE_NAME, 
      Key: {
        shortCode: shortCode,
      },
    };

    const { Item } = await docClient.send(new GetCommand(params));

    // Validar si el código existe en la base de datos
    if (!Item || !Item.longUrl) {
      return {
        statusCode: 404,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: "El código no existe o ha expirado" }),
      };
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