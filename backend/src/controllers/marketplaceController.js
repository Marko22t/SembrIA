import { supabase } from '../config/supabase.js';

// 1. OBTENER PRODUCTOS CON FILTROS
export const getProducts = async (req, res) => {
  try {
    const { categoria, zona, precio_max } = req.query;

    let query = supabase.from('productos').select('*');

    if (categoria && categoria !== 'Todos') {
      query = query.eq('categoria', categoria);
    }

    if (zona) {
      // Productos de la zona del productor o disponibles en todo Santa Cruz
      query = query.or(
        `zona_disponible.eq.${zona},zona_disponible.eq.Santa Cruz - General`
      );
    }

    if (precio_max) {
      query = query.lte('precio_bob', parseFloat(precio_max));
    }

    const { data: products, error: fetchError } = await query;

    if (fetchError) {
      throw fetchError;
    }

    return res.status(200).json(products || []);
  } catch (error) {
    console.error('Error al obtener productos:', error);
    return res.status(500).json({ error: 'Ocurrió un error al obtener los productos del catálogo.' });
  }
};

// 2. OBTENER DETALLE DE UN PRODUCTO
export const getProductById = async (req, res) => {
  try {
    const { id } = req.params;

    const { data: product, error: fetchError } = await supabase
      .from('productos')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (fetchError) {
      throw fetchError;
    }

    if (!product) {
      return res.status(404).json({ error: 'El producto agrícola solicitado no existe.' });
    }

    return res.status(200).json(product);
  } catch (error) {
    console.error('Error al obtener producto por ID:', error);
    return res.status(500).json({ error: 'Error interno del servidor al consultar el insumo.' });
  }
};

// 3. AGREGAR PRODUCTO AL CATÁLOGO (PROTEGIDO - SOLO VENDEDORES)
export const addProduct = async (req, res) => {
  try {
    const { nombre, descripcion, precio_bob, categoria, imagen_url, vendedor, stock, zona_disponible } =
      req.body;
    const usuario_id = req.user.id;

    if (!nombre || !descripcion || !precio_bob || !categoria) {
      return res.status(400).json({ error: 'Faltan campos obligatorios para dar de alta el producto.' });
    }

    const { data: usuarioRow } = await supabase
      .from('usuarios')
      .select('nombre')
      .eq('id', usuario_id)
      .maybeSingle();

    const nombreVendedor = vendedor || usuarioRow?.nombre || req.user.nombre || 'Productor';

    const { data: newProduct, error: insertError } = await supabase
      .from('productos')
      .insert([
        {
          nombre,
          descripcion,
          precio_bob: parseFloat(precio_bob),
          categoria,
          imagen_url: imagen_url || 'placeholder.png',
          vendedor: nombreVendedor,
          stock: stock ? parseInt(stock) : 10,
          zona_disponible: zona_disponible || 'Santa Cruz - General',
          usuario_id
        }
      ])
      .select('*')
      .single();

    if (insertError) {
      throw insertError;
    }

    return res.status(201).json({
      message: 'Producto añadido exitosamente al marketplace cruceño.',
      producto: newProduct
    });
  } catch (error) {
    console.error('Error al añadir producto:', error);
    return res.status(500).json({ error: 'Ocurrió un error en el servidor al añadir el insumo.' });
  }
};

// 4. REGISTRAR UN PEDIDO (COMPRA DIRECTA / MICROCRÉDITO PRE-APROBADO)
export const createOrder = async (req, res) => {
  try {
    const { usuario_id, producto_id, cantidad } = req.body;

    if (!usuario_id || !producto_id || !cantidad) {
      return res.status(400).json({ error: 'Faltan parámetros requeridos (usuario_id, producto_id, cantidad).' });
    }

    // Verificar stock, precio y dueño del producto (vendedor)
    const { data: product, error: fetchError } = await supabase
      .from('productos')
      .select('stock, nombre, precio_bob, usuario_id')
      .eq('id', producto_id)
      .maybeSingle();

    if (fetchError) {
      throw fetchError;
    }

    if (!product) {
      return res.status(444).json({ error: 'El producto que desea adquirir no está en inventario.' });
    }

    if (product.stock < cantidad) {
      return res.status(400).json({ error: `Stock insuficiente para ${product.nombre}. Solo quedan ${product.stock} unidades disponibles.` });
    }

    // Crear pedido: usuario_id = comprador, vendedor_id = dueño del producto
    const { data: newOrder, error: insertError } = await supabase
      .from('pedidos')
      .insert([
        {
          usuario_id,
          producto_id,
          cantidad: parseInt(cantidad, 10),
          estado: 'Pendiente',
          vendedor_id: product.usuario_id || null,
          precio_unitario: product.precio_bob,
          nombre_producto: product.nombre
        }
      ])
      .select('*')
      .single();

    if (insertError) {
      throw insertError;
    }

    // Descontar stock del producto
    const { error: updateError } = await supabase
      .from('productos')
      .update({ stock: product.stock - cantidad })
      .eq('id', producto_id);

    if (updateError) {
      console.error('Error al descontar stock:', updateError);
    }

    return res.status(201).json({
      message: '¡Compra y microcrédito pre-aprobado exitosamente!',
      pedido: newOrder
    });
  } catch (error) {
    console.error('Error al procesar compra:', error);
    return res.status(500).json({ error: 'Ocurrió un error interno al formalizar su pedido.' });
  }
};

// 5. OBTENER HISTORIAL DE PEDIDOS DE UN PRODUCTOR
export const getOrdersByUser = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({ error: 'El ID de usuario es obligatorio.' });
    }

    // Hacemos un join de pedidos con productos, trayendo los snapshots si el producto se elimina
    const { data: orders, error: fetchError } = await supabase
      .from('pedidos')
      .select(`
        id,
        cantidad,
        estado,
        created_at,
        precio_unitario,
        nombre_producto,
        productos (
          id,
          nombre,
          precio_bob,
          categoria,
          vendedor
        )
      `)
      .eq('usuario_id', userId)
      .order('created_at', { ascending: false });

    if (fetchError) {
      throw fetchError;
    }

    return res.status(200).json(orders || []);
  } catch (error) {
    console.error('Error al obtener pedidos por usuario:', error);
    return res.status(500).json({ error: 'Error al consultar el historial de compras del productor.' });
  }
};
