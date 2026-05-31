/**
 * Abre WhatsApp con mensaje pre-cargado para una publicación P2P.
 * @param {string} numero - Número del vendedor (con o sin código país)
 * @param {object} publicacion - Publicación P2P
 */
export const abrirWhatsApp = (numero, publicacion) => {
  const numeroLimpio = numero.replace(/[\s\-()+]/g, '');

  const numeroFinal = numeroLimpio.startsWith('0')
    ? '591' + numeroLimpio.slice(1)
    : numeroLimpio.startsWith('591')
      ? numeroLimpio
      : numeroLimpio.length <= 8
        ? '591' + numeroLimpio
        : numeroLimpio;

  const precioTexto = publicacion.es_gratis
    ? 'Gratis'
    : `${publicacion.precio_bob} BOB`;

  const mensaje = encodeURIComponent(
    `Hola! Vi tu publicación en CropDoctor Agro 🌿\n` +
      `*${publicacion.titulo}*\n` +
      `Precio: ${precioTexto}\n` +
      `Zona: ${publicacion.zona_santa_cruz}\n\n` +
      `¿Todavía está disponible?`
  );

  window.open(`https://wa.me/${numeroFinal}?text=${mensaje}`, '_blank', 'noopener,noreferrer');
};
