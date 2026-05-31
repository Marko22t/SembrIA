import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'secreto-super-seguro-para-jwt-cropdoctor-2026';

export const protect = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ error: 'No autorizado, no se proporcionó ningún token.' });
    }

    // Verificar firma del token
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Adjuntar la información decodificada del usuario a la request
    req.user = decoded;
    next();
  } catch (error) {
    console.error('Error de autenticación por JWT:', error);
    return res.status(401).json({ error: 'Acceso no autorizado. Token inválido o expirado.' });
  }
};
