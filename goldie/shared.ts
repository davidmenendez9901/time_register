// Shared by the iOS (goldie.config.ts) and Android (android/goldie.config.ts)
// goldie configs: copy, theme and scene order. Each config only picks its
// device, its demo build and its flow directory, because argent's iOS runner
// cannot see Flutter widgets (see .argent/flows/ios/store-01-home.yaml).

export const APP_ROOT = "/Users/d/Projects/time_register";

export const base = {
  appRoot: APP_ROOT,
  locales: ["es-ES"],
  appearance: "light",

  frame: { variant: "17-pro-blue" },

  theme: {
    background:
      "linear-gradient(160deg, #E4EEFF 0%, #F3F7FF 55%, #FFFFFF 100%)",
    headlineColor: "#0E1B2A",
    subheadColor: "#51627A",
    fontFamily: '-apple-system, "SF Pro Display", system-ui, sans-serif',
    copyHeightRatio: 0.24,
    deviceWidthRatio: 0.84,
    template: "editorial",
    layout: "classic",
  },

  store: {
    name: "Time Register",
    subtitle: { "es-ES": "Tus horas y pagos, claros" },
    developer: "David Menendez Acosta",
    category: "Productividad",
    rating: 4.8,
    ratingCount: "Nueva",
    ageRating: "4+",
    price: "Gratis",
    description: {
      "es-ES":
        "Time Register es la forma más simple de registrar tus horas de trabajo y saber exactamente cuánto vas a cobrar. Pensada para quienes cobran por hora: trabajadores por turnos, freelancers y consultores.\n\nFicha entrada y salida con el cronómetro en vivo, marca qué te pagaron, organiza por cliente con su propia tarifa y mira tus semanas y meses en gráficas.\n\nSin cuentas, sin anuncios y sin conexión: tus datos se quedan en tu teléfono.",
    },
  },

  scenes: [
    {
      kind: "screenshot",
      id: "home",
      flow: "store-01-home",
      headline: { "es-ES": "Tu jornada, a la vista" },
      subhead: { "es-ES": "Ficha tu turno y mira al instante cuánto llevas." },
    },
    {
      kind: "screenshot",
      id: "entry",
      flow: "store-02-entry",
      headline: { "es-ES": "Registra horas en segundos" },
      subhead: { "es-ES": "Horas, almuerzo y ganancias, calculadas solas." },
    },
    {
      kind: "screenshot",
      id: "summary",
      flow: "store-03-summary",
      headline: { "es-ES": "Sabe cuánto te deben" },
      subhead: { "es-ES": "Lo pendiente, la semana y el mes de un vistazo." },
    },
    {
      kind: "screenshot",
      id: "stats",
      flow: "store-04-stats",
      headline: { "es-ES": "Mira crecer tu trabajo" },
      subhead: { "es-ES": "Semanas y meses, en horas o en dinero." },
    },
    {
      kind: "screenshot",
      id: "jobs",
      flow: "store-05-jobs",
      headline: { "es-ES": "Cada cliente, su tarifa" },
      subhead: { "es-ES": "Organiza tus trabajos con su color y su precio." },
    },
    {
      kind: "preview",
      id: "preview",
      segments: [
        { id: "open", flow: "store-preview-01-open" },
        { id: "entry", flow: "store-preview-02-entry" },
        { id: "summary", flow: "store-preview-03-summary" },
        { id: "stats", flow: "store-preview-04-stats", holdSeconds: 1.5 },
      ],
    },
  ],
};
