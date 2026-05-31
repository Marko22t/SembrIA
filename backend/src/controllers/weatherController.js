import Anthropic from '@anthropic-ai/sdk';
import { CLAUDE_MODEL } from '../config/env.js';

const apiKey = process.env.ANTHROPIC_API_KEY;
let anthropic = null;

if (apiKey && !apiKey.startsWith('sk-ant-api03-tu-api-key')) {
  anthropic = new Anthropic({ apiKey });
}

let weatherCache = null;
let weatherCacheTime = 0;
const CACHE_MS = 60 * 60 * 1000; // 1 hora

function generarClimaLocal(temp, rain, wind) {
  if (rain > 0) {
    return {
      alerta: 'Lluvia activa: no pulverices en las próximas 6 horas',
      nivel: 'ALERTA',
      consejo:
        'Riesgo de dispersión de roya en soya del Norte Integrado. Revisa parcelas con humedad alta.'
    };
  }
  if (temp > 30) {
    return {
      alerta: 'Calor extremo: alta evaporación y riesgo de trips',
      nivel: 'PRECAUCION',
      consejo: 'Riega al amanecer o al atardecer en Santa Cruz para ahorrar agua.'
    };
  }
  if (wind > 20) {
    return {
      alerta: 'Viento fuerte: suspende fumigaciones hoy',
      nivel: 'PRECAUCION',
      consejo: 'Evita deriva de agroquímicos sobre lotes vecinos en el área cruceña.'
    };
  }
  return {
    alerta: 'Condiciones favorables para labores de campo',
    nivel: 'NORMAL',
    consejo:
      'Buen día para fertilización foliar y monitoreo de plagas en cultivos de Santa Cruz.'
  };
}

function parsearClimaJSON(texto) {
  try {
    const m = texto.match(/\{[\s\S]*\}/);
    if (m) return JSON.parse(m[0]);
  } catch (_) {}
  return null;
}

export const getSantaCruzWeather = async (req, res) => {
  res.set('Cache-Control', 'no-store, no-cache, must-revalidate');

  const forzar = req.query.refresh === '1';

  if (!forzar && weatherCache && Date.now() - weatherCacheTime < CACHE_MS) {
    return res.status(200).json({
      ...weatherCache,
      desde_cache: true
    });
  }

  try {
    const ahora = new Date();
    const horaLocal = ahora.toLocaleString('es-BO', {
      timeZone: 'America/La_Paz',
      hour: '2-digit',
      minute: '2-digit',
      day: '2-digit',
      month: 'short'
    });

    const meteoUrl =
      'https://api.open-meteo.com/v1/forecast?' +
      'latitude=-17.78&longitude=-63.18' +
      '&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m&timezone=America/La_Paz';

    let weatherData = {
      temp: 24.5,
      humidity: 78,
      precipitation: 0,
      windSpeed: 12
    };

    try {
      const response = await fetch(`${meteoUrl}&_=${Date.now()}`, { cache: 'no-store' });
      if (response.ok) {
        const json = await response.json();
        if (json.current) {
          weatherData = {
            temp: json.current.temperature_2m,
            humidity: json.current.relative_humidity_2m,
            precipitation: json.current.precipitation,
            windSpeed: json.current.wind_speed_10m
          };
        }
      }
    } catch (fetchError) {
      console.warn('Open-Meteo no disponible:', fetchError.message);
    }

    let agroClima = generarClimaLocal(
      weatherData.temp,
      weatherData.precipitation,
      weatherData.windSpeed
    );

    if (anthropic) {
      try {
        const prompt = `Eres un agrónomo experto en Santa Cruz, Bolivia.
Clima actual: temperatura ${weatherData.temp}°C, humedad ${weatherData.humidity}%, precipitación ${weatherData.precipitation}mm, viento ${weatherData.windSpeed}km/h.

Responde ÚNICAMENTE JSON sin markdown:
{"alerta":"texto corto max 100 caracteres","nivel":"NORMAL|PRECAUCION|ALERTA","consejo":"una oración práctica para agricultores cruceños hoy"}`;

        const response = await anthropic.messages.create({
          model: CLAUDE_MODEL,
          max_tokens: 200,
          temperature: 0.3,
          messages: [{ role: 'user', content: prompt }]
        });

        const parsed = parsearClimaJSON(response.content[0].text);
        if (parsed?.alerta) agroClima = parsed;
      } catch (aiError) {
        console.error('Clima Claude:', aiError.message);
      }
    }

    const payload = {
      coordenadas: { lat: -17.78, lon: -63.18 },
      zona: 'Santa Cruz de la Sierra, Bolivia',
      actualizado_en: ahora.toISOString(),
      actualizado_hora_local: horaLocal,
      clima_actual: {
        temperatura_celsius: weatherData.temp,
        humedad_relativa_porcentaje: weatherData.humidity,
        precipitacion_mm: weatherData.precipitation,
        viento_kmh: weatherData.windSpeed
      },
      alerta: agroClima.alerta,
      nivel: agroClima.nivel,
      consejo: agroClima.consejo,
      recomendacion_agronomica: `${agroClima.alerta}. ${agroClima.consejo}`
    };

    weatherCache = payload;
    weatherCacheTime = Date.now();

    return res.status(200).json(payload);
  } catch (error) {
    console.error('Error en controlador de clima:', error);
    return res.status(200).json({
      error_amigable: 'Clima no disponible en este momento',
      clima_actual: null,
      alerta: 'No pudimos cargar el clima',
      nivel: 'NORMAL',
      consejo: 'Intenta actualizar en unos minutos.'
    });
  }
};
