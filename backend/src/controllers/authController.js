import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { supabase } from '../config/supabase.js';
import { formatUsuarioPlan } from '../services/planService.js';

const CAMPOS_USUARIO =
  'id, nombre, email, zona_santa_cruz, cultivo_principal, created_at, plan, diagnosticos_hoy, fecha_reset_contador';

const JWT_SECRET = process.env.JWT_SECRET || 'secreto-super-seguro-para-jwt-cropdoctor-2026';

// 1. REGISTRO DE PRODUCTOR
export const register = async (req, res) => {
  try {
    const { nombre, email, password, zona_santa_cruz, cultivo_principal } = req.body;

    if (!nombre || !email || !password || !zona_santa_cruz || !cultivo_principal) {
      return res.status(400).json({ error: 'Todos los campos son obligatorios.' });
    }

    // Verificar si el email ya existe
    const { data: existingUser, error: checkError } = await supabase
      .from('usuarios')
      .select('id')
      .eq('email', email)
      .maybeSingle();

    if (checkError) {
      throw checkError;
    }

    if (existingUser) {
      return res.status(400).json({ error: 'El correo electrónico ya está registrado.' });
    }

    // Encriptar contraseña
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    // Insertar en base de datos
    const { data: newUser, error: insertError } = await supabase
      .from('usuarios')
      .insert([
        {
          nombre,
          email,
          password_hash,
          zona_santa_cruz,
          cultivo_principal
        }
      ])
      .select(CAMPOS_USUARIO)
      .single();

    if (insertError) {
      throw insertError;
    }

    // Firmar Token JWT
    const token = jwt.sign(
      { id: newUser.id, nombre: newUser.nombre, email: newUser.email },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(201).json({
      message: 'Usuario registrado exitosamente.',
      token,
      usuario: formatUsuarioPlan(newUser)
    });
  } catch (error) {
    console.error('Error en registro:', error);
    return res.status(500).json({ error: 'Ocurrió un error en el servidor al registrar el usuario.' });
  }
};

// 2. INICIO DE SESIÓN
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Correo y contraseña son requeridos.' });
    }

    // Buscar usuario en base de datos
    const { data: usuario, error: fetchError } = await supabase
      .from('usuarios')
      .select('*')
      .eq('email', email)
      .maybeSingle();

    if (fetchError) {
      throw fetchError;
    }

    if (!usuario) {
      return res.status(401).json({ error: 'Credenciales inválidas (usuario no encontrado).' });
    }

    // Validar contraseña
    const isMatch = await bcrypt.compare(password, usuario.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Credenciales inválidas (contraseña incorrecta).' });
    }

    // Firmar Token JWT
    const token = jwt.sign(
      { id: usuario.id, nombre: usuario.nombre, email: usuario.email },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      message: 'Inicio de sesión exitoso.',
      token,
      usuario: formatUsuarioPlan(usuario)
    });
  } catch (error) {
    console.error('Error en login:', error);
    return res.status(500).json({ error: 'Ocurrió un error en el servidor al iniciar sesión.' });
  }
};
