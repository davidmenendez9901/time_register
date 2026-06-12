// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Registro de Tiempo';

  @override
  String get homeTab => 'Inicio';

  @override
  String get summaryTab => 'Resumen';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get weeklySummary => 'Resumen Semanal';

  @override
  String get outstanding => 'Pendiente';

  @override
  String get toCollect => 'Por Cobrar';

  @override
  String get thisWeek => 'Esta Semana';

  @override
  String get performance => 'Rendimiento';

  @override
  String get thisMonth => 'Este Mes';

  @override
  String get viewSummary => 'Ver Resumen';

  @override
  String get noEntriesFilter => 'No hay entradas con este filtro';

  @override
  String weekOf(String date) {
    return 'Semana del $date';
  }

  @override
  String get markAsPaid => 'Marcar como Pagado';

  @override
  String get markAsUnpaid => 'Marcar como No Pagado';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get settings => 'Ajustes';

  @override
  String get general => 'General';

  @override
  String get hourlyRate => 'Tarifa por Hora';

  @override
  String get defaultRate => 'Tarifa por Defecto';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeAndColor => 'Tema y Colores';

  @override
  String get appInfo => 'Info de la App';

  @override
  String get version => 'Versión';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get help => 'Ayuda';

  @override
  String get contactSupport => 'Contactar Soporte';

  @override
  String get about => 'Acerca de';

  @override
  String get mode => 'Modo';

  @override
  String get colors => 'Colores';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get deleteEntry => 'Eliminar Entrada';

  @override
  String get deleteEntryConfirm =>
      '¿Estás seguro de que quieres eliminar esta entrada?';

  @override
  String get undo => 'DESHACER';

  @override
  String get noEntries => 'No hay entradas aún';

  @override
  String get addWorkEntry => 'Agregar Entrada';

  @override
  String get editWorkEntry => 'Editar Entrada';

  @override
  String get saveEntry => 'Guardar Entrada';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get date => 'Fecha';

  @override
  String get startTime => 'Hora Inicio';

  @override
  String get endTime => 'Hora Fin';

  @override
  String get lunchBreak => 'Hora de Almuerzo';

  @override
  String get deductLunch => 'Deducir 0.5 horas';

  @override
  String get rateForEntry => 'Tarifa para esta entrada';

  @override
  String get defaultRateFromSettings => 'Tarifa por defecto de ajustes';

  @override
  String get totalHours => 'Total Horas';

  @override
  String get estimatedEarnings => 'Ganancias Estimadas';

  @override
  String get enterRate => 'Por favor ingrese una tarifa';

  @override
  String get validRate => 'Por favor ingrese un número válido';

  @override
  String get endTimeAfterStart =>
      'La hora fin debe ser después de la hora inicio';

  @override
  String get hours => 'Horas';

  @override
  String get earnings => 'Ganancias';

  @override
  String get allEntries => 'Todas';

  @override
  String get paidOnly => 'Pagadas';

  @override
  String get unpaidOnly => 'No Pagadas';

  @override
  String get paidStatus => 'Esta entrada ha sido pagada';

  @override
  String get unpaidStatus => 'Esta entrada no ha sido pagada aún';

  @override
  String errorMsg(String message) {
    return 'Error: $message';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get editHourlyRate => 'Editar Tarifa por Hora';

  @override
  String get enterHourlyRate => 'Ingrese su tarifa por hora';

  @override
  String get enterRateValidation => 'Por favor ingrese una tarifa';

  @override
  String get enterValidNumberValidation =>
      'Por favor ingrese un número válido positivo';

  @override
  String get rateUpdated => 'Tarifa por hora actualizada exitosamente';

  @override
  String get appearanceSubtitle =>
      'Personaliza tu experiencia con diferentes temas y modos claro/oscuro.';

  @override
  String get hourlyRateSubtitle =>
      'Esta tarifa se aplicará a nuevas entradas. Las existentes mantendrán su tarifa original.';

  @override
  String get perHour => 'por hora';

  @override
  String get appDescription => 'Rastrea tus horas de trabajo y ganancias';

  @override
  String get howToUse => 'Cómo Usar';

  @override
  String get howToUseSubtitle => 'Aprende cómo rastrear tus horas de trabajo';

  @override
  String get gotIt => '¡Entendido!';

  @override
  String get helpAddWorkEntryTitle => '1. Agregar Entrada';

  @override
  String get helpAddWorkEntryDesc =>
      'Toca el botón + en el inicio para registrar tus horas diarias.';

  @override
  String get helpSetTimesTitle => '2. Establecer Horas';

  @override
  String get helpSetTimesDesc =>
      'Selecciona hora de inicio y fin. Activa almuerzo para deducir 0.5 horas.';

  @override
  String get helpViewSummaryTitle => '3. Ver Resumen';

  @override
  String get helpViewSummaryDesc =>
      'Revisa la pestaña Resumen para ver tus ganancias y horas semanales.';

  @override
  String get helpUpdateRateTitle => '4. Actualizar Tarifa';

  @override
  String get helpUpdateRateDesc =>
      'Cambia tu tarifa en Ajustes. Nuevas entradas usarán la nueva tarifa.';

  @override
  String get lunchStart => 'Inicio del Almuerzo';

  @override
  String get lunchEnd => 'Fin del Almuerzo';

  @override
  String get descriptionNote => 'Descripción / Nota';

  @override
  String get descriptionHint =>
      'Agrega detalles sobre esta entrada de trabajo...';

  @override
  String get lunchWithinShift =>
      'El almuerzo debe estar dentro del turno de trabajo';

  @override
  String get endsNextDay => 'Termina al día siguiente';

  @override
  String get paid => 'Pagado';

  @override
  String get unpaid => 'No Pagado';

  @override
  String get markedAsPaid => 'Marcado como pagado';

  @override
  String get markedAsUnpaid => 'Marcado como no pagado';

  @override
  String get currency => 'Moneda';

  @override
  String get editCurrency => 'Editar Símbolo de Moneda';

  @override
  String get enterCurrencySymbol =>
      'Ingresa el símbolo que se muestra junto a los montos';

  @override
  String get enterSymbolValidation => 'Ingresa un símbolo';

  @override
  String get currencyUpdated => 'Símbolo de moneda actualizado';

  @override
  String get currencySubtitle =>
      'Este símbolo se muestra junto a todos los montos en la app.';

  @override
  String get statsTab => 'Estadísticas';

  @override
  String get lastWeeksChart => 'Últimas 8 semanas';

  @override
  String get lastMonthsChart => 'Últimos 6 meses';

  @override
  String get earningsByJobChart => 'Ganancias por trabajo (este mes)';

  @override
  String get noChartData =>
      'Aún no hay datos suficientes. Agrega entradas de trabajo para ver tus estadísticas.';

  @override
  String get deductions => 'Deducciones';

  @override
  String get deductionsSubtitle =>
      'Estima impuestos u otras deducciones como porcentaje de tus ganancias. Si está deshabilitado, las deducciones no se muestran en ninguna parte de la app.';

  @override
  String get enableDeductions => 'Habilitar deducciones';

  @override
  String get deductionRate => 'Porcentaje de deducción';

  @override
  String get editDeductionRate => 'Editar Porcentaje de Deducción';

  @override
  String get enterPercentValidation => 'Ingresa un porcentaje entre 0 y 100';

  @override
  String get net => 'Neto';

  @override
  String get estimatedNet => 'Neto estimado';

  @override
  String get deductionsUpdated => 'Deducciones actualizadas';

  @override
  String get jobs => 'Trabajos / Clientes';

  @override
  String get jobsSubtitle => 'Gestiona trabajos y sus tarifas por hora';

  @override
  String get addJob => 'Agregar Trabajo';

  @override
  String get editJob => 'Editar Trabajo';

  @override
  String get jobName => 'Nombre';

  @override
  String get enterNameValidation => 'Ingresa un nombre';

  @override
  String get jobRateOptional => 'Tarifa por hora (opcional)';

  @override
  String get jobRateHelper =>
      'Reemplaza la tarifa por defecto para este trabajo';

  @override
  String get jobColor => 'Color';

  @override
  String get deleteJob => 'Eliminar Trabajo';

  @override
  String get deleteJobConfirm =>
      '¿Eliminar este trabajo? Sus entradas se conservarán, sin trabajo asignado.';

  @override
  String get noJobs =>
      'Aún no hay trabajos. Agrega uno para organizar tus entradas por cliente.';

  @override
  String get job => 'Trabajo';

  @override
  String get noJob => 'Sin trabajo';

  @override
  String get archiveJob => 'Archivado (oculto para nuevas entradas)';

  @override
  String get defaultRateLabel => 'Tarifa por defecto';

  @override
  String get clockIn => 'Fichar Entrada';

  @override
  String get clockOut => 'Fichar Salida';

  @override
  String get shiftInProgress => 'Turno en curso';

  @override
  String shiftStartedAt(String time) {
    return 'Iniciado a las $time';
  }

  @override
  String get dataSection => 'Datos';

  @override
  String get backupData => 'Respaldar Datos';

  @override
  String get backupSubtitle =>
      'Guarda todas tus entradas y ajustes en un archivo';

  @override
  String get restoreData => 'Restaurar Datos';

  @override
  String get restoreSubtitle =>
      'Carga entradas y ajustes desde un archivo de respaldo';

  @override
  String get restoreConfirmTitle => '¿Restaurar desde respaldo?';

  @override
  String get restoreConfirmMsg =>
      'Esto reemplazará TODAS las entradas y ajustes actuales con el contenido del respaldo. No se puede deshacer.';

  @override
  String get restore => 'Restaurar';

  @override
  String get restoreSuccess => 'Respaldo restaurado correctamente';

  @override
  String get restoreInvalidFile =>
      'El archivo seleccionado no es un respaldo válido de Time Register';

  @override
  String get export => 'Exportar';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get workReport => 'Reporte de Trabajo';

  @override
  String generatedOn(String date) {
    return 'Generado el $date';
  }

  @override
  String get nothingToExport => 'No hay entradas para exportar';

  @override
  String get total => 'Total';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get privacyPolicySubtitle => 'Cómo se manejan tus datos';

  @override
  String get privacyPolicyContent =>
      'Time Register no recolecta, transmite ni comparte ningún dato personal.\n\nTodo lo que ingresas (entradas de trabajo, tarifas, notas y ajustes) se guarda únicamente en una base de datos local en tu dispositivo. La app no se conecta a internet, no tiene analíticas y no muestra publicidad.\n\nDesinstalar la app elimina permanentemente todos sus datos. La política completa está disponible en el repositorio del proyecto en GitHub.';
}
