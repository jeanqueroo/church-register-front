// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get menuHome => 'Inicio';

  @override
  String get menuRegistration => 'Registro de nuevos creyentes';

  @override
  String get menuCellGroup => 'Célula';

  @override
  String get menuLeaderGroup => 'Registro de líderes';

  @override
  String get menuNewCell => 'Crear célula';

  @override
  String get menuCellDashboard => 'Estadísticas de células';

  @override
  String get menuBaptismGroup => 'Bautismo';

  @override
  String get menuBaptismCalendar => 'Calendario de bautismo';

  @override
  String get menuBaptismDashboard => 'Estadísticas de bautismo';

  @override
  String get menuNewMember => 'Nuevo creyente';

  @override
  String get menuMembers => 'Ver nuevos creyentes';

  @override
  String get menuByLeader => 'Ver nuevos creyentes por líder';

  @override
  String get menuMyMembers => 'Mis nuevos creyentes';

  @override
  String get menuMyAssignedCell => 'Mi célula';

  @override
  String get menuNewLeader => 'Crear líder';

  @override
  String get menuLeaders => 'Ver líderes';

  @override
  String get menuMySupervisedLeaders => 'Mis líderes asignados';

  @override
  String get menuVisitsDashboard => 'Dashboard de visitas';

  @override
  String get menuPastoralDashboard => 'Dashboard pastoral';

  @override
  String get menuSupervisorLeaders => 'Líderes por supervisor';

  @override
  String get menuLeaderDashboard => 'Estadísticas de líderes';

  @override
  String get menuChurches => 'Iglesias';

  @override
  String get menuAdmins => 'Administradores';

  @override
  String get menuNewAdmin => 'Nuevo administrador';

  @override
  String get menuNotifications => 'Notificaciones';

  @override
  String get menuMyAccount => 'Mi cuenta';

  @override
  String get menuRegisterNewMember => 'Registro de nuevo creyente';

  @override
  String get quickNewMemberTitle => 'Registro de nuevo creyente';

  @override
  String get quickNewMemberSubtitle => 'Formulario de nuevo creyente';

  @override
  String get quickViewMembersTitle => 'Ver nuevos creyentes';

  @override
  String get quickViewMembersSubtitle =>
      'Lista de nuevos creyentes registrados';

  @override
  String get quickMembersByLeaderTitle => 'Ver nuevos creyentes por líder';

  @override
  String get quickMembersByLeaderSubtitle =>
      'Nuevos creyentes asignados a cada líder';

  @override
  String get quickMyMembersTitle => 'Mis nuevos creyentes';

  @override
  String get quickMyMembersSubtitle => 'Creyentes asignados a tu visita';

  @override
  String get quickMyAssignedCellTitle => 'Mi célula asignada';

  @override
  String get quickMyAssignedCellSubtitle => 'Datos de la célula y discípulos';

  @override
  String get quickRegisterLeaderTitle => 'Registro de líderes';

  @override
  String get quickRegisterLeaderSubtitle => 'Datos del liderazgo';

  @override
  String get quickNewCellTitle => 'Crear célula';

  @override
  String get quickNewCellSubtitle => 'Registrar un nuevo grupo celular';

  @override
  String get quickViewCellsTitle => 'Ver células';

  @override
  String get quickViewCellsSubtitle => 'Lista de células registradas';

  @override
  String get quickBaptismCalendarTitle => 'Calendario de bautismo';

  @override
  String get quickBaptismCalendarSubtitle =>
      'Ver fechas de bautismo programadas';

  @override
  String get quickBaptismDashboardTitle => 'Estadísticas de bautismo';

  @override
  String get quickBaptismDashboardSubtitle =>
      'Bautizados desde registro de creyente';

  @override
  String get baptismDashboardTitle => 'Estadísticas de bautismo';

  @override
  String get baptismDashboardDenied =>
      'No tienes permiso para ver las estadísticas de bautismo.';

  @override
  String get baptismDashboardLoadError =>
      'No se pudieron cargar las estadísticas de bautismo.';

  @override
  String get baptismDashboardBaptizedInPeriod => 'Bautizados en el periodo';

  @override
  String get baptismDashboardBaptizedInYear => 'Bautizados en el año';

  @override
  String get baptismDashboardBaptizedInMonth => 'Bautizados en el mes';

  @override
  String get baptismDashboardNewBelieversAmongBaptized =>
      'Nuevos creyentes entre los bautizados (registro de creyente)';

  @override
  String get baptismDashboardSelectYear => 'Año';

  @override
  String get baptismDashboardSelectMonth => 'Mes';

  @override
  String get baptismDashboardAllMonths => 'Todo el año';

  @override
  String baptismDashboardChartTitleYear(int year) {
    return 'Bautizados por mes en $year';
  }

  @override
  String get baptismDashboardChartTitle => 'Bautizados por periodo';

  @override
  String get baptismDashboardListTitleYear => 'Bautizados en el año';

  @override
  String baptismDashboardListTitleMonth(String month) {
    return 'Bautizados en $month';
  }

  @override
  String get baptismDashboardListTitle => 'Bautizados en el periodo';

  @override
  String get baptismDashboardListSelectMonth =>
      'Selecciona un mes para ver los bautizados.';

  @override
  String baptismDashboardListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bautizados',
      one: '1 bautizado',
    );
    return '$_temp0';
  }

  @override
  String get baptismDashboardListEmpty => 'No hay bautizados en este periodo.';

  @override
  String baptismDashboardPeriodLastMonths(int count) {
    return 'Últimos $count meses';
  }

  @override
  String baptismDashboardPeriodLastYears(int count) {
    return 'Últimos $count años';
  }

  @override
  String get baptismDashboardConversionHint =>
      'La tasa de bautismo cuenta solo creyentes registrados desde «Registro de creyente» (no desde célula ni bautismo directo). El gráfico usa la fecha de bautismo confirmada.';

  @override
  String get cellDashboardTitle => 'Estadísticas de células';

  @override
  String get cellDashboardDenied =>
      'No tienes permiso para ver las estadísticas de células.';

  @override
  String get cellDashboardLoadError =>
      'No se pudieron cargar las estadísticas de células.';

  @override
  String get cellDashboardCreatedInYear => 'Células creadas en el año';

  @override
  String get cellDashboardCreatedInMonth => 'Células creadas en el mes';

  @override
  String cellDashboardChartTitleYear(int year) {
    return 'Células creadas por mes en $year';
  }

  @override
  String cellDashboardListTitleMonth(String month) {
    return 'Células creadas en $month';
  }

  @override
  String get cellDashboardListSelectMonth =>
      'Selecciona un mes para ver las células creadas.';

  @override
  String cellDashboardListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count células',
      one: '1 célula',
    );
    return '$_temp0';
  }

  @override
  String get cellDashboardListEmpty =>
      'No hay células creadas en este periodo.';

  @override
  String get leaderDashboardTitle => 'Estadísticas de líderes';

  @override
  String get leaderDashboardDenied =>
      'No tienes permiso para ver las estadísticas de líderes.';

  @override
  String get leaderDashboardLoadError =>
      'No se pudieron cargar las estadísticas de líderes.';

  @override
  String get leaderDashboardCreatedInYear => 'Líderes creados en el año';

  @override
  String get leaderDashboardCreatedInMonth => 'Líderes creados en el mes';

  @override
  String get leaderDashboardFromRegisterLeader => 'Desde registro de líderes';

  @override
  String get leaderDashboardFromCell => 'Desde célula';

  @override
  String leaderDashboardChartTitleYear(int year) {
    return 'Líderes creados por mes en $year';
  }

  @override
  String leaderDashboardListTitleMonth(String month) {
    return 'Líderes creados en $month';
  }

  @override
  String get leaderDashboardListSelectMonth =>
      'Selecciona un mes para ver los líderes creados.';

  @override
  String leaderDashboardListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count líderes',
      one: '1 líder',
    );
    return '$_temp0';
  }

  @override
  String get leaderDashboardListEmpty =>
      'No hay líderes creados en este periodo.';

  @override
  String get leaderRegistrationSourceRegisterLeader => 'Registro de líderes';

  @override
  String get leaderRegistrationSourceRegisterCell => 'Célula';

  @override
  String get quickViewLeadersTitle => 'Ver líderes';

  @override
  String get quickViewLeadersSubtitle => 'Lista de líderes registrados';

  @override
  String get quickMySupervisedLeadersTitle => 'Mis líderes asignados';

  @override
  String get quickMySupervisedLeadersSubtitle => 'Líderes bajo tu supervisión';

  @override
  String get quickVisitsDashboardTitle => 'Dashboard de visitas';

  @override
  String get quickVisitsDashboardSubtitle =>
      'Gráficas de visitas por día, mes y año';

  @override
  String get quickPastoralDashboardTitle => 'Dashboard pastoral';

  @override
  String get quickPastoralDashboardSubtitle =>
      'Seguimiento, nuevos creyentes y oración';

  @override
  String get quickSupervisorLeadersTitle => 'Líderes por supervisor';

  @override
  String get quickSupervisorLeadersSubtitle =>
      'Asignar cartera de líderes a cada supervisor';

  @override
  String get quickChurchesTitle => 'Iglesias';

  @override
  String get quickChurchesSubtitle => 'Ver, editar y registrar sedes';

  @override
  String get quickAdminsTitle => 'Administradores';

  @override
  String get quickAdminsSubtitle => 'Ver, editar y bloquear cuentas';

  @override
  String get quickNewAdminTitle => 'Nuevo administrador';

  @override
  String get quickNewAdminSubtitle => 'Asignar iglesia al administrador';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get menuTooltip => 'Menú';

  @override
  String get welcome => 'Bienvenido';

  @override
  String homeWelcomeName(String name) {
    return '👋 Bienvenido, $name';
  }

  @override
  String get homeSummaryTitle => 'Resumen';

  @override
  String homeMembersCount(int count) {
    return '👥 Miembros asignados: $count';
  }

  @override
  String homeLeadersCount(int count) {
    return '👥 Líderes asignados: $count';
  }

  @override
  String homeSummaryMembersCount(int count) {
    return '👥 Miembros: $count';
  }

  @override
  String homeSummaryNewBelieversCount(int count) {
    return '👥 Nuevo creyentes: $count';
  }

  @override
  String homeSummaryLeadersCount(int count) {
    return '👥 Líderes y supervisores: $count';
  }

  @override
  String homeSummaryDisciplesCount(int count) {
    return '👥 Discípulos asignados: $count';
  }

  @override
  String homeSummaryAssignedNewBelieversCount(int count) {
    return '👥 Nuevo creyentes asignados: $count';
  }

  @override
  String homeChurchMembersCount(String churchName, int count) {
    return '👥 Miembros de la iglesia $churchName: $count';
  }

  @override
  String homeChurchLeadersCount(String churchName, int count) {
    return '👥 Líderes de la iglesia $churchName: $count';
  }

  @override
  String get homeTodayTitle => 'Hoy';

  @override
  String get homeCellBirthdaysTitle => 'Cumpleaños del día de mi célula';

  @override
  String get homeBirthdaysEmpty => 'No hay cumpleaños hoy en tu célula.';

  @override
  String get homeQuickActionsTitle => 'Acciones rápidas';

  @override
  String get homeWelcomeSubtitle => 'Gracias por liderar con propósito.';

  @override
  String get homeSummarySeeDetail => 'Ver detalle';

  @override
  String get homeStatMembersTitle => 'Miembros';

  @override
  String get homeStatMembersSubtitle => 'Total de miembros activos';

  @override
  String get homeStatNewBelieversTitle => 'Nuevo creyentes';

  @override
  String get homeStatNewBelieversSubtitle => 'Nuevos creyentes registrados';

  @override
  String get homeStatLeadersTitle => 'Líderes';

  @override
  String get homeStatLeadersSubtitle => 'Líderes registrados y activos';

  @override
  String get homeStatCellsTitle => 'Células';

  @override
  String get homeStatCellsSubtitle => 'Células activas';

  @override
  String get homeStatBaptismsTitle => 'Bautismos';

  @override
  String get homeStatBaptismsSubtitle => 'Bautismos programados';

  @override
  String get homeStatDisciplesTitle => 'Discípulos';

  @override
  String get homeStatDisciplesSubtitle => 'Discípulos asignados';

  @override
  String get homeStatMyDisciplesTitle => 'Mis discípulos';

  @override
  String get homeStatMyDisciplesSubtitle => 'En tu célula asignada';

  @override
  String get homeStatMyNewBelieversTitle => 'Mis nuevos creyentes';

  @override
  String get homeStatMyNewBelieversSubtitle => 'Asignados a tu liderazgo';

  @override
  String get homeStatMyAssignedLeadersTitle => 'Mis líderes asignados';

  @override
  String get homeStatMyAssignedLeadersSubtitle => 'Líderes bajo tu supervisión';

  @override
  String get homeNavBelievers => 'Creyentes';

  @override
  String get homeNavLeaders => 'Líderes';

  @override
  String get homeNavCells => 'Células';

  @override
  String get homeNavMore => 'Más';

  @override
  String get homeRegisterAttendanceTitle => 'Registrar asistencia';

  @override
  String get homeRegisterAttendanceSubtitle =>
      'Selecciona tu célula para registrar asistencia';

  @override
  String get homeDashboardLoadError =>
      'No se pudo cargar el resumen del inicio.';

  @override
  String get user => 'Usuario';

  @override
  String get noAccessForRole =>
      'No hay accesos disponibles para tu rol. Contacta al administrador.';

  @override
  String get leaderAccountNotLinked =>
      'Tu cuenta de líder no está vinculada a un registro.';

  @override
  String get leaderRecordNotFound => 'No se encontró tu ficha de líder.';

  @override
  String get retry => 'Reintentar';

  @override
  String get profileLoadError => 'No se pudo cargar tu perfil de usuario.';

  @override
  String get loginSubtitle => 'Inicia sesión para continuar';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get emailRequired => 'Ingresa tu correo';

  @override
  String get emailInvalid => 'Correo no válido';

  @override
  String get passwordRequired => 'Ingresa tu contraseña';

  @override
  String get passwordMinLength => 'Mínimo 6 caracteres';

  @override
  String get passwordRegistrationMinLength => 'Mínimo 8 caracteres';

  @override
  String get passwordRegistrationNeedsLetter =>
      'Debe incluir al menos una letra';

  @override
  String get passwordRegistrationNeedsNumber =>
      'Debe incluir al menos un número';

  @override
  String get passwordRegistrationNeedsSpecial =>
      'Debe incluir al menos un carácter especial';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get loginUnexpectedError => 'Error inesperado al iniciar sesión.';

  @override
  String get forgotPasswordEnterEmail =>
      'Ingresa tu correo para recuperar la contraseña';

  @override
  String get forgotPasswordEmailSent =>
      'Revisa tu correo para restablecer la contraseña';

  @override
  String get forgotPasswordSendFailed =>
      'No se pudo enviar el correo de recuperación.';

  @override
  String get myAccount => 'Mi cuenta';

  @override
  String get systemRoles => 'Roles en el sistema';

  @override
  String get personalData => 'Datos personales';

  @override
  String get personalDataSubtitleFull =>
      'Nombre, dirección, documento y teléfono';

  @override
  String get personalDataSubtitleName => 'Nombre de tu perfil';

  @override
  String get churchData => 'Datos de la iglesia';

  @override
  String get churchDataSubtitle => 'Consulta los datos de tu sede';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get changePasswordSubtitle => 'Actualiza la clave de acceso';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Español, inglés o idioma del sistema';

  @override
  String get languageSettingsTitle => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get languageSystemSubtitle => 'Usa la configuración de tu dispositivo';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get theme => 'Tema';

  @override
  String get themeSubtitle => 'Claro, oscuro o según el sistema';

  @override
  String get themeSettingsTitle => 'Tema de la app';

  @override
  String get themeSystem => 'Según el sistema';

  @override
  String get themeSystemSubtitle => 'Usa la configuración de tu dispositivo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeColorSection => 'Paleta de colores';

  @override
  String get themeModeSection => 'Modo de visualización';

  @override
  String get templateManantial => 'Manantial';

  @override
  String get templateManantialSubtitle =>
      'Azul profundo y dorado — recomendado';

  @override
  String get templateWhatsapp => 'Verde mensajería';

  @override
  String get templateWhatsappSubtitle =>
      'Estilo WhatsApp, el anterior de la app';

  @override
  String get templatePeace => 'Paz';

  @override
  String get templatePeaceSubtitle => 'Índigo suave y tonos calmados';

  @override
  String get templateTraditional => 'Tradicional';

  @override
  String get templateTraditionalSubtitle => 'Vino y crema, elegante';

  @override
  String get roleSuperAdmin => 'Super administrador';

  @override
  String get roleAdmin => 'Administrador de iglesia';

  @override
  String get roleRegistrar => 'Registrador';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleLeader => 'Líder';

  @override
  String get authInvalidEmail => 'El correo electrónico no es válido.';

  @override
  String get authUserDisabled => 'Esta cuenta ha sido deshabilitada.';

  @override
  String get authUserNotFound => 'No existe una cuenta con este correo.';

  @override
  String get authWrongPassword => 'Correo o contraseña incorrectos.';

  @override
  String get authEmailInUse => 'Ya existe una cuenta con este correo.';

  @override
  String get authWeakPassword =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authRequiresRecentLogin =>
      'Por seguridad, vuelve a iniciar sesión e intenta de nuevo.';

  @override
  String get authTooManyRequests => 'Demasiados intentos. Intenta más tarde.';

  @override
  String get authNetworkError => 'Sin conexión. Revisa tu internet.';

  @override
  String get authOperationNotAllowed =>
      'El registro por correo no está habilitado en Firebase.';

  @override
  String get authGenericError => 'Error de autenticación. Intenta de nuevo.';

  @override
  String get memberRegisterTitle => 'Registro de nuevo creyente';

  @override
  String get memberEditTitle => 'Editar creyente';

  @override
  String get memberNoPermissionRegister =>
      'No tienes permiso para registrar creyentes.';

  @override
  String get memberNoPermissionEdit =>
      'No tienes permiso para editar creyentes.';

  @override
  String get memberFormDate => 'Fecha';

  @override
  String get memberEntrySource => '¿Dónde entró el creyente? *';

  @override
  String get memberEntrySourceRequired => 'Selecciona dónde entró el creyente';

  @override
  String get memberDetailEntrySource => 'Dónde entró';

  @override
  String get memberDetailLeadershipStatus => 'Estado pastoral';

  @override
  String get memberDetailAssignmentKind => 'Tipo de asignación';

  @override
  String get memberAssignmentPastoral => 'Nuevo creyente';

  @override
  String get memberAssignmentCell => 'Discípulo de célula';

  @override
  String get memberDetailSectionJourney => 'Recorrido';

  @override
  String get memberDetailRegistrationSource => 'Registrado desde';

  @override
  String get memberDetailPastoralAssignedAt => 'Asignado a líder';

  @override
  String get memberDetailNewBelieverAt => 'Registrado como nuevo creyente';

  @override
  String get memberDetailCellAssignedAt => 'Asignado a célula';

  @override
  String get memberDetailBaptizedAt => 'Fecha de bautismo';

  @override
  String get memberDetailJourneyComplete =>
      'Registro de creyente → célula → bautismo';

  @override
  String get memberDetailHistoryTitle => 'Historial de cambios';

  @override
  String get memberRegistrationSourceRegisterMember => 'Registro de creyente';

  @override
  String get memberRegistrationSourceRegisterMemberCell =>
      'Registro de creyente en célula';

  @override
  String get memberRegistrationSourceRegisterCellMember => 'Registro en célula';

  @override
  String get memberRegistrationSourceRegisterBaptismBeliever =>
      'Registro para bautismo';

  @override
  String get memberHistoryEventRegistered => 'Registro creado';

  @override
  String get memberHistoryEventPastoralAssigned => 'Asignado a líder';

  @override
  String get memberHistoryEventCellAssigned => 'Asignado a célula';

  @override
  String get memberHistoryEventCellUnassigned => 'Retirado de célula';

  @override
  String get memberHistoryEventBaptizedConfirmed => 'Bautismo confirmado';

  @override
  String get memberDetailAssignedCell => 'Célula asignada';

  @override
  String get entrySourceCampaignOutside => 'Campaña fuera de la iglesia';

  @override
  String get entrySourceCell => 'Célula';

  @override
  String get entrySourceHospital => 'Hospital';

  @override
  String get entrySourceEvangelism => 'Evangelismo';

  @override
  String get entrySourceMotherChurch => 'Iglesia madre';

  @override
  String get entrySourceDaughterChurch => 'Iglesia hija';

  @override
  String get memberSectionPersonalData => 'DATOS PERSONALES';

  @override
  String get memberFirstName => 'Nombre *';

  @override
  String get memberFirstNameRequired => 'Ingresa el nombre';

  @override
  String get memberLastName => 'Apellidos *';

  @override
  String get memberLastNameRequired => 'Ingresa los apellidos';

  @override
  String get memberIdDocumentType => 'Documento';

  @override
  String get memberIdDocumentNumber => 'Número de documento';

  @override
  String get idDocumentDni => 'DNI';

  @override
  String get idDocumentPassport => 'Pasaporte';

  @override
  String get idDocumentOther => 'Otro';

  @override
  String get memberGenderRequired => 'Género *';

  @override
  String get memberGender => 'Género';

  @override
  String get memberIncludeAddress => 'Incluir dirección';

  @override
  String get memberAddressRequiredForLeader =>
      'Requerida para asignar un líder automático';

  @override
  String get memberAddressOptional =>
      'Opcional: datos de domicilio del creyente';

  @override
  String get memberPhone => 'Teléfono *';

  @override
  String get memberPhoneRequired => 'Ingresa el teléfono';

  @override
  String get memberBirthDate => 'Fecha de nacimiento *';

  @override
  String get memberBirthDateRequired => 'Selecciona la fecha de nacimiento';

  @override
  String get memberSelectDate => 'Seleccionar fecha';

  @override
  String get memberClearDate => 'Quitar fecha';

  @override
  String get memberAge => 'Edad *';

  @override
  String memberAgeYears(int age) {
    return '$age años';
  }

  @override
  String get memberOccupation => 'Ocupación *';

  @override
  String get memberOccupationRequired => 'Ingresa la ocupación';

  @override
  String get memberMaritalStatus => 'Estado civil *';

  @override
  String get memberMaritalStatusRequired => 'Selecciona el estado civil';

  @override
  String get memberSectionCellSchedule => 'HORARIO PARA CÉLULA';

  @override
  String get memberCellDay => 'Día';

  @override
  String get memberCellTime => 'Horario';

  @override
  String get memberSelectTime => 'Seleccionar hora';

  @override
  String get memberCellZone => 'Zona';

  @override
  String get memberSectionVisit => 'VISITA';

  @override
  String get memberWantsVisit => 'Desea ser visitado';

  @override
  String get memberWantsVisitSubtitle =>
      'Indica si la persona solicita una visita domiciliaria';

  @override
  String get memberSectionObservations => 'OBSERVACIONES';

  @override
  String get memberObservationsHint => 'Notas adicionales...';

  @override
  String get memberVolunteer => 'Voluntario';

  @override
  String get memberSaving => 'Guardando...';

  @override
  String get memberSaveChanges => 'Guardar cambios';

  @override
  String get memberRegisterButton => 'Registrar creyente';

  @override
  String get memberSectionAssignedLeader => 'LÍDER ASIGNADO';

  @override
  String get memberManualLeader => 'Elegir líder manualmente';

  @override
  String get memberManualLeaderSubtitle =>
      'Busca y elige un líder escribiendo su nombre';

  @override
  String get memberAutoLeaderSubtitle =>
      'Se asignará el líder más cercano del mismo género';

  @override
  String get memberNoLeaderSubtitle =>
      'Sin líder hasta que actives visita o elijas uno';

  @override
  String get memberNoLeadersAvailable =>
      'No hay líderes con rol de líder en la app. Asigna el rol Líder al registrar un líder.';

  @override
  String get memberSelectLeader => 'Selecciona un líder';

  @override
  String get memberSelectLeaderFromList => 'Selecciona un líder de la lista';

  @override
  String get memberGenderForAutoLeader =>
      'Selecciona el género para asignar un líder automático';

  @override
  String get memberCompatibleLeadersHint =>
      'Mostrando líderes compatibles con el género seleccionado.';

  @override
  String get memberNoChurchAssigned =>
      'Tu cuenta no tiene iglesia asignada. Contacta al administrador.';

  @override
  String get memberAddressRequiredAutoLeader =>
      'Activa \"Incluir dirección\" y selecciona una dirección del buscador para asignar un líder automático.';

  @override
  String get memberAddressGeocodeFailed =>
      'No se pudo ubicar la dirección. Selecciónala del autocompletado.';

  @override
  String get memberUpdatedSuccess => 'Creyente actualizado correctamente';

  @override
  String get memberRegisteredSuccess => 'Creyente registrado correctamente';

  @override
  String memberRegisteredWithLeader(
    String leader,
    String cell,
    String distance,
  ) {
    return 'Creyente registrado. Líder: $leader$cell$distance';
  }

  @override
  String get memberRegisteredNoNearbyLeader =>
      'Creyente registrado. No hay líder del mismo género con dirección cercana.';

  @override
  String get memberSaveUnexpectedError => 'Error inesperado al guardar.';

  @override
  String memberCellCodeSuffix(String code) {
    return ' (Célula $code)';
  }

  @override
  String memberDistanceKm(String km) {
    return ' · $km km';
  }

  @override
  String get genderMale => 'Hombre (H)';

  @override
  String get genderFemale => 'Mujer (M)';

  @override
  String get maritalSingle => 'Soltero/a';

  @override
  String get maritalMarried => 'Casado/a';

  @override
  String get maritalConcubino => 'Concubino/a';

  @override
  String get maritalDivorced => 'Divorciado/a';

  @override
  String get maritalWidowed => 'Viudo/a';

  @override
  String get weekdayMonday => 'Lunes';

  @override
  String get weekdayTuesday => 'Martes';

  @override
  String get weekdayWednesday => 'Miércoles';

  @override
  String get weekdayThursday => 'Jueves';

  @override
  String get weekdayFriday => 'Viernes';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get addressSection => 'DIRECCIÓN';

  @override
  String get addressSearchRequired => 'Buscar dirección *';

  @override
  String get addressSearchOptional => 'Buscar dirección';

  @override
  String get addressSearchHint => 'Escribe y elige una sugerencia...';

  @override
  String get addressSearchTapToChange =>
      'Toca aquí para cambiar la dirección...';

  @override
  String get addressChangeButton => 'Cambiar dirección';

  @override
  String get addressSearchAndSelect => 'Busca y selecciona una dirección';

  @override
  String get addressMustPickFromList =>
      'Debes elegir una dirección de la lista';

  @override
  String get addressAutoFilledHint => 'Se completa al buscar dirección';

  @override
  String get addressStreetRequired => 'Calle *';

  @override
  String get addressStreetOptional => 'Calle';

  @override
  String get addressNumber => 'Número';

  @override
  String get addressPostalCode => 'Código postal';

  @override
  String get addressNeighborhood => 'Barrio';

  @override
  String get addressLocality => 'Localidad / Partido';

  @override
  String get addressStateProvince => 'Estado / Provincia';

  @override
  String get leaderSearchLabel => 'Buscar líder *';

  @override
  String get leaderSearchHint => 'Escribe letras del nombre o célula...';

  @override
  String get leaderSearchClear => 'Quitar líder';

  @override
  String leaderCellLabel(String code) {
    return 'Célula $code';
  }

  @override
  String get firestorePermissionDenied =>
      'No tienes permiso para esta operación.';

  @override
  String get firestoreUnavailable =>
      'Firestore no está disponible. Revisa tu conexión.';

  @override
  String get firestoreNotFound => 'El integrante ya no existe.';

  @override
  String get firestoreGenericError =>
      'Error al procesar la solicitud. Intenta de nuevo.';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get memberDetailSectionPersonal => 'Datos personales';

  @override
  String get memberDetailSectionAddress => 'Dirección';

  @override
  String get memberDetailSectionLeader => 'Líder asignado';

  @override
  String get memberDetailSectionCellSchedule => 'Horario para célula';

  @override
  String get memberDetailSectionObservations => 'Observaciones';

  @override
  String get memberDetailSectionRegistration => 'Registro';

  @override
  String get memberDetailFirstName => 'Nombre';

  @override
  String get memberDetailLastName => 'Apellidos';

  @override
  String get memberDetailGender => 'Género';

  @override
  String get memberDetailPhone => 'Teléfono';

  @override
  String get memberDetailIdDocument => 'Documento';

  @override
  String get memberDetailIdDocumentNumber => 'Número de documento';

  @override
  String get memberDetailBirthDate => 'Fecha de nacimiento';

  @override
  String get memberDetailAge => 'Edad';

  @override
  String get memberDetailOccupation => 'Ocupación';

  @override
  String get memberDetailMaritalStatus => 'Estado civil';

  @override
  String get memberDetailWantsVisit => 'Desea ser visitado';

  @override
  String get memberDetailLeaderName => 'Nombre';

  @override
  String get memberDetailCell => 'Célula';

  @override
  String get memberDetailDistance => 'Distancia';

  @override
  String memberDetailDistanceKm(String km) {
    return '$km km';
  }

  @override
  String get memberDetailCellDay => 'Día';

  @override
  String get memberDetailCellTime => 'Horario';

  @override
  String get memberDetailCellZone => 'Zona';

  @override
  String get memberDetailFormDate => 'Fecha del formulario';

  @override
  String get memberDetailVolunteer => 'Voluntario';

  @override
  String get memberDetailRegisteredBy => 'Registrado por';

  @override
  String get memberDetailDeleteTitle => 'Eliminar integrante';

  @override
  String memberDetailDeleteConfirm(String name) {
    return '¿Eliminar a $name? Esta acción no se puede deshacer.';
  }

  @override
  String get memberDetailDeletedSuccess => 'Integrante eliminado';

  @override
  String get memberDetailRegisterVisit => 'Registrar visita';

  @override
  String get memberDetailEditMember => 'Editar integrante';

  @override
  String get memberDetailDeleteMember => 'Eliminar integrante';

  @override
  String get memberVisitsTitle => 'Visitas registradas';

  @override
  String get memberVisitsLoadError => 'No se pudieron cargar las visitas.';

  @override
  String get memberVisitsEmpty => 'Aún no hay visitas registradas.';

  @override
  String get memberVisitsNeedsFollowUp => ' · Requiere seguimiento';

  @override
  String visitDuration(String value) {
    return 'Duración: $value';
  }

  @override
  String visitPrayer(String value) {
    return 'Oración: $value';
  }

  @override
  String visitRequests(String value) {
    return 'Peticiones: $value';
  }

  @override
  String visitFollowUp(String value) {
    return 'Seguimiento: $value';
  }

  @override
  String visitSpiritualState(String value) {
    return 'Estado: $value';
  }

  @override
  String get visitPlaceHome => 'Casa';

  @override
  String get visitPlaceHospital => 'Hospital';

  @override
  String get visitPlaceWork => 'Trabajo';

  @override
  String get visitPlaceChurch => 'Iglesia';

  @override
  String get visitPlaceVideoCall => 'Videollamada';

  @override
  String get spiritualNewBeliever => 'Nuevo creyente';

  @override
  String get spiritualInDiscipleship => 'En discipulado';

  @override
  String get spiritualActiveMember => 'Miembro activo';

  @override
  String get spiritualDistant => 'Alejado';

  @override
  String get spiritualFrequentVisitor => 'Visitante frecuente';

  @override
  String get membersMapNoLocationSnack =>
      'Este integrante no tiene ubicación en el mapa';

  @override
  String get membersMapNavigationFailed => 'No se pudo abrir la navegación';

  @override
  String get membersMapRequestsVisit => 'Solicita visita';

  @override
  String membersMapDistanceFromLeader(String km) {
    return '$km km del líder';
  }

  @override
  String get membersMapGetDirections => 'Cómo llegar';

  @override
  String get membersMapViewDetail => 'Ver detalle';

  @override
  String get membersMapLeaderLabel => 'Líder';

  @override
  String get membersMapEmptyTitle => 'Sin ubicaciones en el mapa';

  @override
  String get membersMapEmptySubtitle =>
      'Los integrantes necesitan dirección con coordenadas para aparecer en el mapa.';

  @override
  String membersMapMissingLocationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count integrantes sin ubicación en el mapa',
      one: '1 integrante sin ubicación en el mapa',
    );
    return '$_temp0';
  }

  @override
  String membersMapLeaderMarker(String name) {
    return 'Marcador morado: $name (líder)';
  }

  @override
  String get commonBack => 'Volver';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaving => 'Guardando...';

  @override
  String get commonNew => 'Nuevo';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonUnblock => 'Desbloquear';

  @override
  String get commonBlock => 'Bloquear';

  @override
  String get commonBlocked => 'Bloqueado';

  @override
  String get commonBlockedFem => 'Bloqueada';

  @override
  String get commonUnblocked => 'Desbloqueado';

  @override
  String get commonUnblockedFem => 'Desbloqueada';

  @override
  String get commonNoMatches => 'No hay coincidencias';

  @override
  String get commonNoName => '(Sin nombre)';

  @override
  String get commonLoadListError => 'No se pudo cargar la lista.';

  @override
  String get commonExportError =>
      'No se pudo exportar el listado. Intenta de nuevo.';

  @override
  String commonDeleteConfirm(String name) {
    return '¿Eliminar a $name? Esta acción no se puede deshacer.';
  }

  @override
  String get accessDeniedTitle => 'Acceso restringido';

  @override
  String get accessDeniedDefault => 'No tienes permiso para ver esta sección.';

  @override
  String get blockedAccountUserTitle => 'Cuenta bloqueada';

  @override
  String get blockedAccountChurchTitle => 'Iglesia bloqueada';

  @override
  String get blockedAccountUserMessage =>
      'Tu usuario fue suspendido. Contacta al super administrador para reactivar tu acceso.';

  @override
  String get blockedAccountChurchMessage =>
      'La iglesia asignada a tu cuenta está bloqueada. No puedes usar el sistema hasta que el super administrador la reactive.';

  @override
  String get membersListTitle => 'Nuevos creyentes';

  @override
  String get membersListExportExcel => 'Descargar Excel';

  @override
  String get membersListDeleteTitle => 'Eliminar creyente';

  @override
  String get membersListDeleted => 'Creyente eliminado';

  @override
  String get membersListLoadError =>
      'No se pudo cargar la lista.\nVerifica Firestore en Firebase Console.';

  @override
  String get membersListEmptyTitle => 'Aún no hay nuevos creyentes registrados';

  @override
  String get membersListEmptySubtitle =>
      'Pulsa \"Nuevo\" para registrar al primero.';

  @override
  String get membersListSearchHint =>
      'Buscar por nombre, teléfono, líder o localidad…';

  @override
  String get membersListEndOfList => 'Fin de la lista';

  @override
  String membersListLeaderPrefix(String name) {
    return 'Líder: $name';
  }

  @override
  String membersListDatePrefix(String date) {
    return 'Fecha: $date';
  }

  @override
  String get membersByLeaderTitle => 'Ver nuevos creyentes por líder';

  @override
  String get membersByLeaderEmpty => 'No hay creyentes registrados';

  @override
  String membersByLeaderAssignedCount(int assigned, int total) {
    return '$assigned de $total creyentes con líder asignado';
  }

  @override
  String membersByLeaderMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count creyentes',
      one: '1 creyente',
    );
    return '$_temp0';
  }

  @override
  String membersByLeaderRegistrationDate(String date) {
    return 'Registro: $date';
  }

  @override
  String get leaderAssignedTitle => 'Mis nuevos creyentes';

  @override
  String get leaderAssignedTabList => 'Lista';

  @override
  String get leaderAssignedTabMap => 'Mapa';

  @override
  String leaderAssignedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuevos creyentes asignados',
      one: '1 nuevo creyente asignado',
    );
    return '$_temp0';
  }

  @override
  String leaderAssignedCellSuffix(String code) {
    return '· Célula $code';
  }

  @override
  String get leaderAssignedEmptyTitle => 'Sin nuevos creyentes asignados';

  @override
  String get leaderAssignedEmptySubtitle =>
      'Los nuevos creyentes asignados a tu liderazgo aparecerán aquí.';

  @override
  String get leaderAssignedNoMapLocation => 'Sin ubicación en mapa';

  @override
  String get leaderAssignedRegisterVisit => 'Registrar visita';

  @override
  String get leaderAssignedLoadError => 'No se pudo cargar los integrantes.';

  @override
  String get leadersListTitle => 'Líderes';

  @override
  String get leadersBlockTitle => 'Bloquear líder';

  @override
  String get leadersUnblockTitle => 'Desbloquear líder';

  @override
  String leadersBlockConfirm(String name) {
    return '¿Bloquear a \"$name\"? No podrá iniciar sesión ni asignarse a nuevos integrantes hasta que lo desbloquees.';
  }

  @override
  String leadersUnblockConfirm(String name) {
    return '¿Desbloquear a \"$name\" y permitir el acceso de nuevo?';
  }

  @override
  String get leadersBlocked => 'Líder bloqueado';

  @override
  String get leadersUnblocked => 'Líder desbloqueado';

  @override
  String leadersShowBlocked(int count) {
    return 'Mostrar bloqueados ($count)';
  }

  @override
  String leadersHideBlocked(int count) {
    return 'Ocultar bloqueados ($count)';
  }

  @override
  String get leadersAllBlocked => 'Todos los líderes están bloqueados';

  @override
  String get leadersListLoadError =>
      'No se pudo cargar la lista. Verifica Firestore y las reglas de la colección \"leaders\".';

  @override
  String get leadersListEmpty => 'Aún no hay líderes registrados';

  @override
  String get leadersListSearchHint =>
      'Buscar por nombre, teléfono, correo o célula…';

  @override
  String get leadersListEndOfList => 'Fin de la lista';

  @override
  String leadersListCellPrefix(String code) {
    return 'Célula $code';
  }

  @override
  String get leadersListViewMembers => 'Ver integrantes asignados a visitar';

  @override
  String get leadersListViewLeader => 'Ver líder';

  @override
  String get leaderDetailEditLeader => 'Editar líder';

  @override
  String get leaderDetailBlockLeader => 'Bloquear líder';

  @override
  String get leaderDetailUnblockLeader => 'Desbloquear líder';

  @override
  String get leaderDetailViewMembers => 'Ver integrantes asignados a visitar';

  @override
  String get leaderDetailSectionLeadership => 'Datos del liderazgo';

  @override
  String get leaderDetailSectionCellContact => 'Contacto';

  @override
  String get leaderDetailSectionRoles => 'Roles en la app';

  @override
  String get leaderDetailLastName => 'Apellido';

  @override
  String get leaderDetailFirstNames => 'Nombres';

  @override
  String get leaderDetailChurchOffice => 'Cargo en la iglesia';

  @override
  String get leaderDetailMobile => 'Celular / Móvil';

  @override
  String get leaderDetailPermissions => 'Permisos';

  @override
  String get leadersMapNoLocationSnack =>
      'Este líder no tiene ubicación en el mapa';

  @override
  String get leadersMapEmptyTitle => 'Sin ubicaciones en el mapa';

  @override
  String get leadersMapEmptySubtitle =>
      'Los líderes necesitan dirección con coordenadas para aparecer en el mapa.';

  @override
  String leadersMapMissingLocationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count líderes sin ubicación en el mapa',
      one: '1 líder sin ubicación en el mapa',
    );
    return '$_temp0';
  }

  @override
  String get leadersMapViewLeader => 'Ver líder';

  @override
  String get supervisorMyLeadersTitle => 'Mis líderes asignados';

  @override
  String get supervisorMyLeadersDenied =>
      'No tienes permiso para ver tus líderes asignados.';

  @override
  String supervisorMyLeadersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count líderes bajo tu supervisión',
      one: '1 líder bajo tu supervisión',
    );
    return '$_temp0';
  }

  @override
  String get supervisorMyLeadersSearchHint => 'Buscar líder';

  @override
  String get supervisorMyLeadersEmptyTitle => 'Sin líderes asignados';

  @override
  String get supervisorMyLeadersEmptySubtitle =>
      'El administrador te asignará líderes cuando corresponda.';

  @override
  String get supervisorMyLeadersNoSearchResults =>
      'Ningún líder coincide con la búsqueda.';

  @override
  String get supervisorMyLeadersViewMembers => 'Creyentes';

  @override
  String get supervisorAssignmentsTitle => 'Líderes por supervisor';

  @override
  String get supervisorAssignmentsDeniedSupervisor =>
      'Los supervisores no pueden acceder a esta pantalla. Usa «Mis líderes asignados» para ver tu cartera.';

  @override
  String get supervisorAssignmentsDeniedAdmin =>
      'Solo el administrador puede asignar líderes a supervisores.';

  @override
  String get supervisorAssignmentsNoSupervisors =>
      'No hay supervisores en tu iglesia';

  @override
  String get supervisorAssignmentsNoSupervisorsHint =>
      'Al registrar un líder, asigna el rol Supervisor en la app.';

  @override
  String get supervisorAssignmentsSelectSupervisor => 'Selecciona supervisor *';

  @override
  String supervisorAssignmentsAssignedLeaders(int count) {
    return 'Líderes asignados ($count)';
  }

  @override
  String get supervisorAssignmentsSearchLeader => 'Buscar líder';

  @override
  String get supervisorAssignmentsNoLeaders =>
      'No hay líderes registrados en tu iglesia.';

  @override
  String get supervisorAssignmentsNoLeaderMatches =>
      'Ningún líder coincide con la búsqueda.';

  @override
  String get supervisorAssignmentsNoLeadersAvailable =>
      'No hay líderes disponibles para asignar.';

  @override
  String get supervisorAssignmentsSelectSupervisorError =>
      'Selecciona un supervisor';

  @override
  String supervisorAssignmentsConflict(String name) {
    return 'No se puede guardar: un líder ya pertenece a $name';
  }

  @override
  String get supervisorAssignmentsSaved => 'Líderes asignados correctamente';

  @override
  String get dashboardVisitsTitle => 'Dashboard de visitas';

  @override
  String get dashboardPastoralTitle => 'Dashboard pastoral';

  @override
  String get dashboardVisitsDenied =>
      'No tienes permiso para ver el dashboard de visitas.';

  @override
  String get dashboardPastoralDenied =>
      'No tienes permiso para ver el dashboard pastoral.';

  @override
  String get dashboardAdminMissingChurch =>
      'Tu cuenta de administrador no tiene iglesia asignada. Contacta al super administrador o agrega \"superadmin\" en roles en Firebase.';

  @override
  String get dashboardScopeAllChurches => 'Todas las iglesias';

  @override
  String get dashboardScopeYourChurch => 'Tu iglesia';

  @override
  String get dashboardScopeYourLeaders => 'Tus líderes asignados';

  @override
  String get dashboardChurchLabel => 'Iglesia';

  @override
  String get dashboardNoAssignedLeadersTitle => 'Sin líderes asignados';

  @override
  String get dashboardNoAssignedLeadersVisits =>
      'Cuando el administrador te asigne líderes, verás aquí las estadísticas de sus visitas.';

  @override
  String get dashboardNoAssignedLeadersPastoral =>
      'Cuando el administrador te asigne líderes, verás aquí el seguimiento pastoral.';

  @override
  String get dashboardTotalPeriod => 'Total en el período';

  @override
  String get dashboardLeadersWithVisits => 'Líderes con visitas';

  @override
  String dashboardLeadersWithVisitsCount(int count) {
    return '$count líderes con visitas';
  }

  @override
  String get dashboardVisitCount => 'Número de visitas';

  @override
  String get dashboardTopVisitPlaces => 'Lugares de visita más frecuentes';

  @override
  String get dashboardByVisitPlace => 'Por lugar de la visita';

  @override
  String get dashboardTopPrayerRequests => 'Peticiones de oración más comunes';

  @override
  String get dashboardPrayerRequestsSubtitle =>
      'Textos repetidos en el período';

  @override
  String get dashboardNoPrayerRequests =>
      'No hay peticiones de oración registradas en este período.';

  @override
  String get dashboardVisitsByLeader => 'Visitas por líder';

  @override
  String get dashboardPeriodLast14Days => 'Últimos 14 días';

  @override
  String get dashboardPeriodLast12Months => 'Últimos 12 meses';

  @override
  String get dashboardPeriodLast6Months => 'Últimos 6 meses';

  @override
  String get dashboardPeriodLast5Years => 'Últimos 5 años';

  @override
  String get dashboardFollowUpTitle => 'Personas que requieren seguimiento';

  @override
  String get dashboardFollowUpSubtitle => 'Marcadas en visitas del período';

  @override
  String dashboardFollowUpCount(int count) {
    return '$count persona(s)';
  }

  @override
  String get dashboardFollowUpEmpty =>
      'No hay personas con seguimiento pendiente en este período.';

  @override
  String dashboardVisitOnDate(String date) {
    return 'Visita: $date';
  }

  @override
  String dashboardLeaderPrefix(String name) {
    return 'Líder: $name';
  }

  @override
  String get dashboardMemberNotFound => 'No se encontró el integrante.';

  @override
  String get dashboardNewMembersTitle => 'Nuevos creyentes';

  @override
  String dashboardNewMembersCount(int count) {
    return '$count registrados en el período';
  }

  @override
  String get dashboardPrayerVisitsTitle => 'Visitas con oración';

  @override
  String get dashboardPrayerVisitsEmpty =>
      'Sin visitas en el período seleccionado.';

  @override
  String dashboardPrayerVisitsSummary(int withPrayer, int total) {
    return '$withPrayer de $total visitas incluyeron oración.';
  }

  @override
  String get dashboardNoData => 'Sin datos para mostrar';

  @override
  String get chartPeriodDay => 'Por día';

  @override
  String get chartPeriodMonth => 'Por mes';

  @override
  String get chartPeriodYear => 'Por año';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsLeaderNotLinked =>
      'Tu cuenta no está vinculada a un líder. Contacta al administrador.';

  @override
  String get notificationsMarkRead => 'Marcar leídas';

  @override
  String get notificationsDismissAll => 'Quitar todas';

  @override
  String get notificationsDismissAllConfirmTitle =>
      '¿Quitar todas las alertas?';

  @override
  String get notificationsDismissAllConfirmMessage =>
      'Las alertas desaparecerán de tu lista. Esta acción no se puede deshacer.';

  @override
  String get notificationsLoadError =>
      'No se pudieron cargar las notificaciones. Revisa las reglas de Firestore.';

  @override
  String get notificationsEmptyTitle => 'No tienes notificaciones';

  @override
  String get notificationsEmptySubtitle =>
      'Cuando te asignen un integrante nuevo, aparecerá aquí.';

  @override
  String get notificationsMemberUnavailable =>
      'El integrante ya no está disponible.';

  @override
  String notificationsToday(String time) {
    return 'Hoy $time';
  }

  @override
  String notificationsYesterday(String time) {
    return 'Ayer $time';
  }

  @override
  String get notificationNewMemberTitle => 'Nuevo creyente asignado';

  @override
  String notificationNewMemberBody(String name) {
    return 'Se te asignó a $name. Toca para ver el detalle.';
  }

  @override
  String get notificationMemberFallback => 'Integrante';

  @override
  String get notificationCellCapacityTitle => 'Célula con más de 12 discípulos';

  @override
  String notificationCellCapacityBody(String cell, int count) {
    return 'La célula $cell tiene $count discípulos asignados.';
  }

  @override
  String get notificationCellSplitNotRequired =>
      'Esta célula ya no supera 12 discípulos. No es necesario dividirla.';

  @override
  String get splitCellTitle => 'Multiplicar célula';

  @override
  String get splitCellSourceCellLabel => 'Célula origen';

  @override
  String get splitCellNewCellSection => 'Nueva célula';

  @override
  String get splitCellSelectLeaderHelper => 'Líder de la nueva célula';

  @override
  String get splitCellSelectLeaderHelperHint =>
      'Elige un asistente de la célula origen como líder';

  @override
  String get splitCellNoHelpers =>
      'Esta célula no tiene asistentes. Asigna asistentes en Mi célula antes de dividir.';

  @override
  String get splitCellSelectMembers => 'Discípulos para la nueva célula';

  @override
  String splitCellSelectMembersHint(int max) {
    return 'Selecciona hasta $max discípulos de la célula origen';
  }

  @override
  String splitCellMembersMaxReached(int max) {
    return 'Máximo $max discípulos para la nueva célula';
  }

  @override
  String get splitCellLeaderRequired =>
      'Selecciona un asistente como líder de la nueva célula';

  @override
  String get splitCellMembersRequired =>
      'Selecciona al menos un discípulo para la nueva célula';

  @override
  String get splitCellLeaderBusy => 'Ese asistente ya es líder de otra célula';

  @override
  String get splitCellSuccess =>
      'Nueva célula creada y discípulos transferidos';

  @override
  String get splitCellCreateAction => 'Crear nueva célula';

  @override
  String get splitCellLoadError => 'No se pudo cargar la célula origen';

  @override
  String get splitCellLeaderAccountSection => 'Cuenta de líder';

  @override
  String get splitCellLeaderAccountHint =>
      'Se creará un usuario de acceso para el asistente seleccionado como líder de la nueva célula.';

  @override
  String get splitCellLeaderAlreadyHasAccount =>
      'Este asistente ya tiene cuenta de líder en el sistema.';

  @override
  String get splitCellLeaderAccountRequired =>
      'Ingresa correo y contraseña para crear la cuenta del líder';

  @override
  String get splitCellLeaderBlocked =>
      'Ese asistente está bloqueado como líder y no puede liderar una célula';

  @override
  String get memberLeadershipPromotedToLeader => 'Pasó a líder';

  @override
  String get memberLeadershipPromotedToVolunteer => 'Pasó a registrador';

  @override
  String get memberLeadershipCreatedAsLeader => 'Creado como líder';

  @override
  String get menuCellsOverCapacity => 'Células para multiplicar';

  @override
  String get cellsOverCapacityTitle => 'Células con más de 12 discípulos';

  @override
  String get cellsOverCapacityDenied =>
      'No tienes permiso para dividir células';

  @override
  String get cellsOverCapacityNoChurch => 'No hay iglesia asignada a tu cuenta';

  @override
  String get cellsOverCapacityLoadError => 'No se pudieron cargar las células';

  @override
  String get cellsOverCapacityEmpty => 'No hay células que superen el límite';

  @override
  String cellsOverCapacityEmptySubtitle(int max) {
    return 'Todas las células tienen $max discípulos o menos';
  }

  @override
  String cellsOverCapacityIntro(int max) {
    return 'Estas células superan $max discípulos. Toca una para crear una nueva célula y transferir discípulos.';
  }

  @override
  String cellsOverCapacityLeaderLabel(String name) {
    return 'Líder: $name';
  }

  @override
  String get cellMemberCapacityAdminNotified =>
      'Discípulo registrado. Se alertó al administrador: la célula supera 12 discípulos.';

  @override
  String get cellMemberRegisterLeaderOnlyAtCapacity =>
      'Con 12 o más discípulos, solo el líder de la célula puede registrar un discípulo nuevo.';

  @override
  String get menuAdminNotifications => 'Alertas de la iglesia';

  @override
  String get adminNotificationsTitle => 'Alertas de la iglesia';

  @override
  String get adminNotificationsDenied =>
      'No tienes permiso para ver las alertas de la iglesia';

  @override
  String get adminNotificationsEmptyTitle => 'No hay alertas';

  @override
  String get adminNotificationsEmptySubtitle =>
      'Recibirás avisos aquí cuando una célula supere 12 discípulos.';

  @override
  String get visitRegDenied =>
      'Solo el líder puede registrar visitas a sus integrantes.';

  @override
  String get visitRegTitle => 'Registrar visita';

  @override
  String get visitRegPrayerFollowUpRequired =>
      'Indica si se realizó oración y si necesita seguimiento.';

  @override
  String get visitRegInvalidMember =>
      'El integrante no tiene identificador válido.';

  @override
  String get visitRegSaved => 'Visita registrada';

  @override
  String get visitRegSaveFailed => 'No se pudo registrar la visita.';

  @override
  String get visitRegSelectOption => 'Selecciona una opción';

  @override
  String get visitRegDate => 'Fecha de la visita *';

  @override
  String get visitRegPlace => 'Lugar de la visita *';

  @override
  String get visitRegSelectPlace => 'Selecciona el lugar';

  @override
  String get visitRegDuration => 'Duración aproximada de la visita';

  @override
  String get visitRegDurationHint => 'Ej: 30 min, 1 hora';

  @override
  String get visitRegPrayerTitle => 'Se realizó oración *';

  @override
  String get visitRegPrayerRequests => 'Peticiones de oración';

  @override
  String get visitRegPrayerRequestsHint =>
      'Opcional: motivos o peticiones compartidas';

  @override
  String get visitRegFollowUpTitle => 'Necesita seguimiento *';

  @override
  String get visitRegSpiritualState => 'Estado espiritual (opcional)';

  @override
  String get visitRegSpiritualUnspecified => 'Sin especificar';

  @override
  String get visitRegComment => 'Comentario *';

  @override
  String get visitRegCommentHint => 'Resumen de la visita, temas tratados...';

  @override
  String get visitRegCommentRequired => 'Escribe un comentario';

  @override
  String get visitRegSaveButton => 'Guardar visita';

  @override
  String get addressAutocompleteApiKey =>
      'Configura la API key de Google Maps en maps_api_key.dart';

  @override
  String get addressAutocompleteLoadError =>
      'No se pudieron cargar sugerencias de Google Maps.';

  @override
  String get leaderNoLeaderAssigned => 'Sin líder asignado';

  @override
  String get leaderFallbackName => 'Líder';

  @override
  String get serviceGenericError => 'Error inesperado. Intenta de nuevo.';

  @override
  String get serviceUnavailable =>
      'Servicio no disponible. Revisa tu conexión.';

  @override
  String get servicePermissionDenied =>
      'No tienes permiso para esta operación.';

  @override
  String get visitServicePermissionDenied =>
      'No tienes permiso para registrar visitas.';

  @override
  String get visitServiceSaveError =>
      'Error al guardar la visita. Intenta de nuevo.';

  @override
  String get visitDashboardPermissionDenied =>
      'No tienes permiso para ver el dashboard de visitas.';

  @override
  String get visitDashboardIndexBuilding =>
      'El índice de visitas se está creando en Firebase. Espera unos minutos e intenta de nuevo.';

  @override
  String get visitDashboardIndexMissing =>
      'Falta un índice en Firestore para visitas. Ejecuta: firebase deploy --only firestore:indexes';

  @override
  String get visitDashboardDateFormatError =>
      'Error al formatear fechas en el gráfico. Reinicia la app e intenta de nuevo.';

  @override
  String visitDashboardLoadUnexpected(String code) {
    return 'Error inesperado al cargar visitas ($code).';
  }

  @override
  String visitDashboardLoadError(String message) {
    return 'Error al cargar visitas: $message';
  }

  @override
  String get churchOfficePastor => 'Pastor';

  @override
  String get churchOfficeLeader => 'Líderes';

  @override
  String get churchOfficeJuniorElder => 'Anciano menor';

  @override
  String get churchOfficeElder => 'Anciano';

  @override
  String get churchOfficeSeniorElder => 'Anciano mayor';

  @override
  String get churchOfficeVolunteer => 'Voluntario';

  @override
  String get assignableRolesRegistrarExclusive =>
      'El rol Registrador es exclusivo: no se puede combinar con otros.';

  @override
  String get assignableRolesVolunteerOnly =>
      'Como voluntario, solo se puede asignar el rol Registrador.';

  @override
  String get assignableRolesHint =>
      'Marca los permisos de acceso en la aplicación. Puedes combinar Líder y Supervisor en la misma cuenta. El rol Registrador debe ir solo.';

  @override
  String get adminsDenied =>
      'Solo el super administrador puede gestionar administradores.';

  @override
  String get adminsTitle => 'Administradores';

  @override
  String get adminsNoChurch => 'Sin iglesia asignada';

  @override
  String adminsChurchLabel(String id) {
    return 'Iglesia ($id)';
  }

  @override
  String get adminsBlockTitle => 'Bloquear administrador';

  @override
  String get adminsUnblockTitle => 'Desbloquear administrador';

  @override
  String adminsBlockConfirm(String name) {
    return '¿Bloquear a \"$name\"? No podrá iniciar sesión hasta que lo desbloquees.';
  }

  @override
  String adminsUnblockConfirm(String name) {
    return '¿Desbloquear a \"$name\" y permitir el acceso de nuevo?';
  }

  @override
  String get adminsBlocked => 'Administrador bloqueado';

  @override
  String get adminsUnblocked => 'Administrador desbloqueado';

  @override
  String get adminsLoadError =>
      'No se pudo cargar los administradores. Verifica Firestore y el índice de la colección \"users\".';

  @override
  String get adminsEmpty => 'Aún no hay administradores registrados';

  @override
  String get adminsRegister => 'Registrar administrador';

  @override
  String get adminsSearchHint => 'Buscar por nombre, correo o iglesia…';

  @override
  String adminsShowBlocked(int count) {
    return 'Mostrar bloqueados ($count)';
  }

  @override
  String adminsHideBlocked(int count) {
    return 'Ocultar bloqueados ($count)';
  }

  @override
  String get adminsAllBlocked => 'Todos los administradores están bloqueados';

  @override
  String get churchesDenied =>
      'Solo el super administrador puede gestionar iglesias.';

  @override
  String get churchesTitle => 'Iglesias';

  @override
  String get churchesBlockTitle => 'Bloquear iglesia';

  @override
  String get churchesUnblockTitle => 'Desbloquear iglesia';

  @override
  String churchesBlockConfirm(String name) {
    return '¿Bloquear \"$name\"? No se podrá asignar a nuevos administradores hasta que la desbloquees.';
  }

  @override
  String churchesUnblockConfirm(String name) {
    return '¿Desbloquear \"$name\" y volver a permitir su uso?';
  }

  @override
  String get churchesBlocked => 'Iglesia bloqueada';

  @override
  String get churchesUnblocked => 'Iglesia desbloqueada';

  @override
  String get churchesLoadError =>
      'No se pudo cargar las iglesias. Verifica Firestore y las reglas de la colección \"churches\".';

  @override
  String get churchesEmpty => 'Aún no hay iglesias registradas';

  @override
  String get churchesRegister => 'Registrar iglesia';

  @override
  String get churchesSearchHint => 'Buscar por nombre o dirección…';

  @override
  String churchesShowBlocked(int count) {
    return 'Mostrar bloqueadas ($count)';
  }

  @override
  String churchesHideBlocked(int count) {
    return 'Ocultar bloqueadas ($count)';
  }

  @override
  String get churchesAllBlocked => 'Todas las iglesias están bloqueadas';

  @override
  String get churchRegLoadError => 'No se pudo cargar los datos de la iglesia.';

  @override
  String get churchRegPickAddress =>
      'Elige una dirección de la lista para ubicarla en el mapa';

  @override
  String churchRegImageError(String error) {
    return 'No se pudo seleccionar la imagen: $error';
  }

  @override
  String get churchRegSaved => 'Iglesia registrada';

  @override
  String get churchRegUpdated => 'Datos de la iglesia guardados';

  @override
  String get churchRegNewTitle => 'Nueva iglesia';

  @override
  String get churchRegViewTitle => 'Datos de la iglesia';

  @override
  String get churchRegEditTitle => 'Editar iglesia';

  @override
  String get churchRegCreateDenied =>
      'Solo el super administrador puede crear iglesias.';

  @override
  String get churchRegViewDenied =>
      'No tienes permiso para ver los datos de esta iglesia.';

  @override
  String get churchRegEditDenied =>
      'No tienes permiso para editar los datos de esta iglesia.';

  @override
  String get churchRegBlocked =>
      'Esta iglesia está bloqueada. Contacta al super administrador para reactivarla.';

  @override
  String get churchRegLogo => 'LOGO';

  @override
  String get churchRegLogoOptional => 'LOGO (opcional)';

  @override
  String get churchRegLogoHint =>
      'Puedes guardar sin logo; se usará el predeterminado.';

  @override
  String get churchRegUploadLogo => 'Subir logo';

  @override
  String get churchRegRemoveLogo => 'Quitar';

  @override
  String get churchRegSectionInfo => 'INFORMACIÓN';

  @override
  String get churchRegName => 'Nombre de la iglesia';

  @override
  String get churchRegNameRequired => 'Nombre de la iglesia *';

  @override
  String get churchRegNameValidation => 'Ingresa el nombre';

  @override
  String get churchRegAddressSection => 'Dirección';

  @override
  String get churchSearchLabel => 'Iglesia *';

  @override
  String get churchSearchClear => 'Quitar selección';

  @override
  String get churchSearchTitle => 'Seleccionar iglesia';

  @override
  String get churchSearchHint => 'Buscar por nombre o dirección…';

  @override
  String get churchSearchEmpty => 'No hay iglesias disponibles';

  @override
  String churchSearchNoMatches(String query) {
    return 'No hay coincidencias para \"$query\"';
  }

  @override
  String get changePasswordTitle => 'Cambiar contraseña';

  @override
  String get changePasswordCurrent => 'Contraseña actual *';

  @override
  String get changePasswordNew => 'Nueva contraseña *';

  @override
  String get changePasswordConfirm => 'Confirmar contraseña *';

  @override
  String get changePasswordCurrentRequired => 'Ingresa tu contraseña actual';

  @override
  String get changePasswordNewRequired => 'Ingresa la nueva contraseña';

  @override
  String get changePasswordConfirmRequired => 'Confirma la nueva contraseña';

  @override
  String get changePasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get changePasswordSuccess => 'Contraseña actualizada';

  @override
  String get changePasswordSubmit => 'Actualizar contraseña';

  @override
  String get editPersonalDataTitle => 'Datos personales';

  @override
  String get editPersonalDataSaved => 'Datos guardados';

  @override
  String get editPersonalDataRoles => 'Roles en el sistema';

  @override
  String get editPersonalDataPhoto => 'Foto de perfil';

  @override
  String get editPersonalDataPhotoHint => 'Opcional. Se muestra en tu cuenta.';

  @override
  String get editPersonalDataUploadPhoto => 'Subir foto';

  @override
  String get editPersonalDataChangePhoto => 'Cambiar foto';

  @override
  String get editPersonalDataRemovePhoto => 'Quitar';

  @override
  String editPersonalDataImageError(String error) {
    return 'No se pudo seleccionar la imagen: $error';
  }

  @override
  String get pushChannelName => 'Asignación de integrantes';

  @override
  String get pushChannelDescription => 'Avisos cuando te asignan un integrante';

  @override
  String get authCreateUserFailed => 'No se pudo crear el usuario';

  @override
  String get firestoreLeaderNotFound => 'El líder ya no existe.';

  @override
  String get leaderRegNewTitle => 'Nuevo líder';

  @override
  String get leaderRegEditTitle => 'Editar líder';

  @override
  String get leaderRegSelectChurchOffice => 'Selecciona el cargo en la iglesia';

  @override
  String get leaderRegSelectAtLeastOneRole =>
      'Selecciona al menos un rol en la app';

  @override
  String get leaderRegSuccessWithLogin =>
      'Líder registrado. Puede ingresar con su correo y contraseña.';

  @override
  String get leaderRegUpdatedSuccess => 'Líder actualizado correctamente';

  @override
  String get leaderRegEditDenied =>
      'Solo el administrador puede editar líderes.';

  @override
  String get leaderRegRegisterDenied =>
      'No tienes permiso para registrar líderes.';

  @override
  String get leaderRegSectionChurchOffice => 'CARGO EN LA IGLESIA';

  @override
  String get leaderRegChurchOffice => 'Cargo *';

  @override
  String get leaderRegSelectChurchOfficeField => 'Selecciona el cargo';

  @override
  String get leaderRegNoAccessAccountHint =>
      'Sin cuenta de acceso: los roles se aplicarán cuando se cree el usuario.';

  @override
  String get leaderRegCell => 'Célula';

  @override
  String get leaderRegCellHint => 'Ej: Ñ10, E4, L4';

  @override
  String get cellRegTitle => 'Nueva célula';

  @override
  String get cellEditTitle => 'Editar célula';

  @override
  String get cellEditSuccess => 'Célula actualizada';

  @override
  String get cellEditDenied => 'No tienes permiso para editar células';

  @override
  String get cellRegSectionData => 'Datos de la célula';

  @override
  String get cellRegSectionMeeting => 'Reunión de la célula';

  @override
  String get cellRegMeetingDay => 'Día de la semana';

  @override
  String get cellRegMeetingDayRequired =>
      'Selecciona el día de reunión de la célula';

  @override
  String get cellRegSectionLeader => 'Líder asignado';

  @override
  String get cellRegLeaderRequired => 'Selecciona el líder de la célula';

  @override
  String get cellRegLeaderWrongChurch =>
      'Ese líder pertenece a otra iglesia y no puede asignarse a esta célula';

  @override
  String get cellRegCode => 'Código de célula';

  @override
  String get cellRegCodeHint => 'Ej: Ñ10, E4, L4';

  @override
  String get cellRegCodeRequired => 'Ingresa el código de la célula';

  @override
  String get cellRegCodeDuplicate =>
      'Ya existe una célula con ese código en esta iglesia';

  @override
  String get cellRegName => 'Nombre (opcional)';

  @override
  String get cellRegAlias => 'Alias';

  @override
  String get cellRegAliasHint => 'Ej: celula.norte.mb';

  @override
  String get cellRegAliasHelper => 'Alias bancario para transferencias';

  @override
  String get cellRegAliasEmpty => 'Sin alias';

  @override
  String get cellRegAliasEditAction => 'Editar alias';

  @override
  String get cellRegAliasSaveSuccess => 'Alias actualizado';

  @override
  String get cellRegNotes => 'Notas (opcional)';

  @override
  String get cellRegSuccess => 'Célula registrada';

  @override
  String get cellRegDenied => 'No tienes permiso para registrar células';

  @override
  String get cellRegSectionDisciples => 'Discípulos (opcional)';

  @override
  String cellRegDisciplesHint(int max) {
    return 'Agrega hasta $max discípulos nuevos o selecciona los que aún no tienen célula asignada';
  }

  @override
  String get cellRegSelectExistingDisciple => 'Seleccionar existente';

  @override
  String get cellRegSelectDiscipleTitle => 'Seleccionar discípulo';

  @override
  String get cellRegSelectDiscipleHint =>
      'Solo aparecen discípulos registrados sin célula asignada en tu iglesia';

  @override
  String get cellRegSelectDiscipleRequiresChurch =>
      'No se pueden seleccionar discípulos sin una iglesia asignada a tu cuenta';

  @override
  String get cellRegSelectDiscipleSearchHint =>
      'Buscar por nombre, teléfono o célula';

  @override
  String get cellRegSelectDiscipleEmpty =>
      'No hay discípulos sin célula asignada. Regístralos desde Célula → Registrar discípulo';

  @override
  String get cellRegSelectDiscipleLoadError =>
      'No se pudieron cargar los discípulos';

  @override
  String cellRegDiscipleFromCell(String cell) {
    return 'Célula: $cell';
  }

  @override
  String get cellRegDiscipleAlreadySelected => 'Este discípulo ya fue agregado';

  @override
  String get cellRegDiscipleExistingBadge => 'Existente';

  @override
  String get cellRegDiscipleUnassignedBadge => 'Sin célula';

  @override
  String get cellDiscipleUnassignedHint =>
      'Se guardará sin célula asignada. Podrás asignarlo al crear o editar una célula.';

  @override
  String get cellDiscipleUnassignedSuccess =>
      'Discípulo registrado sin célula asignada';

  @override
  String cellRegDisciplesCount(int current, int max) {
    return '$current de $max';
  }

  @override
  String get cellRegDisciplesEmpty => 'Aún no agregaste discípulos';

  @override
  String get cellRegAddDisciple => 'Agregar discípulo';

  @override
  String get cellRegEditDisciple => 'Editar discípulo';

  @override
  String cellRegDisciplesMaxReached(int max) {
    return 'Máximo $max discípulos al registrar la célula';
  }

  @override
  String cellRegSuccessWithDisciples(int count) {
    return 'Célula registrada con $count discípulo(s)';
  }

  @override
  String get menuViewCells => 'Ver células';

  @override
  String get menuViewCellAttendanceReport => 'Asistencia de discípulos';

  @override
  String get menuCellAbsenceByLeader => 'Inasistencias por líder';

  @override
  String get menuCellAttendanceSessions => 'Mis asistencias';

  @override
  String get menuRegisterCellDisciple => 'Registrar discípulo';

  @override
  String get cellDisciplePickCellTitle => 'Seleccionar célula';

  @override
  String get cellDisciplePickCellHint =>
      'Elige la célula donde registrar el discípulo';

  @override
  String get cellsListTitle => 'Células';

  @override
  String get cellsListSearchHint =>
      'Buscar por código, nombre, líder o dirección';

  @override
  String get cellsListEmpty => 'No hay células registradas';

  @override
  String get cellsListLoadError => 'No se pudieron cargar las células';

  @override
  String cellsListFilterOverCapacity(int max) {
    return 'Más de $max discípulos';
  }

  @override
  String cellsListMemberCount(int count) {
    return '$count discípulos';
  }

  @override
  String get cellDiscipleTitle => 'Registrar discípulo';

  @override
  String get cellDiscipleForCell => 'Célula';

  @override
  String get cellDiscipleDenied =>
      'No tienes permiso para registrar discípulos';

  @override
  String get cellDiscipleSuccess => 'Discípulo registrado';

  @override
  String get cellDiscipleCellMissing => 'No se encontró la célula';

  @override
  String get cellDiscipleEmailOptional =>
      'Opcional (sin cuenta de acceso a la app)';

  @override
  String get cellDiscipleEmailLabel => 'Correo electrónico (opcional)';

  @override
  String get cellDiscipleEmailHelper =>
      'Solo para contacto. No crea cuenta ni sirve para iniciar sesión en el sistema.';

  @override
  String get cellDiscipleChurchOfficeLabel => 'Cargo en la iglesia *';

  @override
  String get cellDiscipleChurchOfficeHelper =>
      'Selecciona el cargo que ocupa el discípulo en la iglesia';

  @override
  String get cellDiscipleAdd => 'Registrar discípulo';

  @override
  String get cellDiscipleListTitle => 'Discípulos';

  @override
  String get cellDiscipleListEmpty => 'Aún no hay discípulos en esta célula';

  @override
  String cellDiscipleListCount(int count) {
    return '$count discípulo(s)';
  }

  @override
  String get cellDiscipleDeleteTitle => 'Eliminar discípulo';

  @override
  String get cellDiscipleDeleted => 'Discípulo eliminado';

  @override
  String get cellHelpersTitle => 'Asistentes de la célula';

  @override
  String cellHelpersHint(int max) {
    return 'Selecciona hasta $max discípulos de esta célula como asistentes';
  }

  @override
  String get cellHelpersEmpty => 'Aún no hay asistentes asignados';

  @override
  String get cellHelpersSelectAction => 'Seleccionar asistentes';

  @override
  String cellHelpersCount(int current, int max) {
    return '$current de $max';
  }

  @override
  String cellHelpersMaxReached(int max) {
    return 'Máximo $max asistentes por célula';
  }

  @override
  String get cellHelpersSaved => 'Asistentes actualizados';

  @override
  String get cellHelpersBadge => 'Asistente';

  @override
  String get cellAttendanceRegisterTitle => 'Registrar asistencia';

  @override
  String get cellAttendancePickCellTitle => 'Registrar asistencia';

  @override
  String get cellAttendancePickCellHint =>
      'Selecciona la célula para registrar la asistencia de la reunión';

  @override
  String get cellAttendanceNoOwnCell => 'No tienes célula asignada';

  @override
  String get cellAttendanceDenied =>
      'Solo el líder asignado a la célula puede registrar asistencia';

  @override
  String get cellAttendanceNoDisciples =>
      'Asigna discípulos a la célula antes de registrar asistencia';

  @override
  String get cellAttendanceLeaderRequired =>
      'La célula debe tener un líder asignado para registrar asistencia';

  @override
  String get cellAttendanceMembersLoadError =>
      'No se pudieron cargar los discípulos de la célula';

  @override
  String get cellAttendanceSectionWhen => 'Fecha y hora';

  @override
  String get cellAttendanceSectionWhere => 'Lugar';

  @override
  String get cellAttendanceSectionRoll => 'Asistencia de discípulos';

  @override
  String get cellAttendanceSectionRollHint =>
      'Marca quién asistió a la reunión de la célula';

  @override
  String get cellAttendanceSessionDate => 'Fecha de la reunión';

  @override
  String get cellAttendanceSessionTime => 'Hora';

  @override
  String get cellAttendanceSessionPlace => 'Lugar de la reunión';

  @override
  String get cellAttendanceSessionPlaceHint =>
      'Dirección o referencia del lugar';

  @override
  String get cellAttendancePlaceRequired => 'Ingresa el lugar de la reunión';

  @override
  String cellAttendanceDayDiffersInfo(String registeredDay, String actualDay) {
    return 'La reunión fue un $actualDay, pero la célula está registrada los $registeredDay.';
  }

  @override
  String get cellAttendanceDayChangeSwitch =>
      'Registrar con día diferente para este encuentro';

  @override
  String get cellAttendanceDayChangeSwitchHint =>
      'Solo aplica a esta reunión, no cambia el día habitual de la célula';

  @override
  String get cellAttendanceDayChangeReason => 'Motivo del cambio de día';

  @override
  String get cellAttendanceDayReasonRequired =>
      'Indica por qué se realizó en un día diferente';

  @override
  String get cellAttendanceLocationDiffersInfo =>
      'El lugar es diferente al registrado en la célula.';

  @override
  String get cellAttendanceLocationChangeSwitch =>
      'Registrar con lugar diferente para este encuentro';

  @override
  String get cellAttendanceLocationChangeSwitchHint =>
      'Solo aplica a esta reunión, no cambia la dirección habitual de la célula';

  @override
  String get cellAttendanceLocationChangeReason => 'Motivo del cambio de lugar';

  @override
  String get cellAttendanceLocationReasonRequired =>
      'Indica por qué se realizó en otro lugar';

  @override
  String get cellAttendanceSectionNotes => 'Información adicional';

  @override
  String get cellAttendanceOfferingCollected => 'Ofrenda recogida';

  @override
  String get cellAttendanceOfferingCollectedHint =>
      'Monto o detalle (opcional)';

  @override
  String get cellAttendanceOfferingAliasTitle => 'Alias para la ofrenda';

  @override
  String cellAttendanceOfferingAliasInfo(String alias) {
    return 'Transferir a: $alias';
  }

  @override
  String get cellAttendanceOfferingAliasMissing =>
      'Esta célula aún no tiene alias de transferencias';

  @override
  String get cellAttendanceObservations => 'Observaciones';

  @override
  String get cellAttendanceObservationsHint =>
      'Notas sobre la reunión (opcional)';

  @override
  String cellAttendanceOfferingSummary(String amount) {
    return 'Ofrenda: $amount';
  }

  @override
  String get cellAttendanceMarkAllPresent => 'Todos presentes';

  @override
  String get cellAttendanceMarkAllAbsent => 'Ninguno presente';

  @override
  String get cellAttendanceSaveAction => 'Guardar asistencia';

  @override
  String get cellAttendanceSaved => 'Asistencia registrada';

  @override
  String get cellAttendanceUpdated => 'Asistencia actualizada';

  @override
  String get cellAttendanceDeleted => 'Asistencia eliminada';

  @override
  String get cellAttendanceEditTitle => 'Editar asistencia';

  @override
  String get cellAttendanceEditAction => 'Editar';

  @override
  String get cellAttendanceUpdateAction => 'Guardar cambios';

  @override
  String get cellAttendanceDeleteTitle => 'Eliminar asistencia';

  @override
  String get cellAttendanceDeleteAction => 'Eliminar';

  @override
  String cellAttendanceDeleteConfirm(String date) {
    return '¿Eliminar la asistencia del $date?';
  }

  @override
  String get cellAttendanceSessionsTitle => 'Mis asistencias';

  @override
  String get cellAttendanceSessionsPickCellTitle => 'Mis asistencias';

  @override
  String get cellAttendanceSessionsPickCellHint =>
      'Selecciona la célula para ver y gestionar asistencias registradas';

  @override
  String get cellAttendanceSessionsDateRangeTitle => 'Rango de fechas';

  @override
  String cellAttendanceSessionsFromDate(String date) {
    return 'Desde $date';
  }

  @override
  String cellAttendanceSessionsToDate(String date) {
    return 'Hasta $date';
  }

  @override
  String get cellAttendanceSessionsEmpty =>
      'No hay asistencias registradas en este rango de fechas';

  @override
  String get cellAttendanceManageDenied =>
      'No tienes permiso para gestionar asistencias de esta célula';

  @override
  String get cellAttendanceHistoryTitle => 'Asistencias recientes';

  @override
  String cellAttendanceHistoryRecentCount(int count) {
    return 'Últimas $count';
  }

  @override
  String cellAttendancePresentCount(int present, int total) {
    return '$present de $total presentes';
  }

  @override
  String get cellAttendanceDayChangedBadge => 'Día diferente';

  @override
  String get cellAttendanceLocationChangedBadge => 'Lugar diferente';

  @override
  String get cellAttendanceReportTitle => 'Asistencia de discípulos';

  @override
  String get cellAttendanceReportPickCellTitle => 'Asistencia por célula';

  @override
  String get cellAttendanceReportPickCellHint =>
      'Selecciona una célula para ver la asistencia de sus discípulos';

  @override
  String get cellAttendanceReportNoOwnCell => 'No tienes célula asignada';

  @override
  String get cellAttendanceReportDenied =>
      'No tienes permiso para ver el reporte de asistencia';

  @override
  String cellAttendanceReportSessionCount(int count) {
    return '$count reuniones registradas';
  }

  @override
  String cellAttendanceReportFilteredSessionCount(int filtered, int total) {
    return '$filtered de $total reuniones en el rango';
  }

  @override
  String get cellAttendanceReportWeekFilterTitle => 'Rango de semanas';

  @override
  String get cellAttendanceReportWeekFrom => 'Desde semana';

  @override
  String get cellAttendanceReportWeekTo => 'Hasta semana';

  @override
  String get cellAttendanceReportWeekAll => 'Todas';

  @override
  String cellAttendanceReportWeekPreset(int count) {
    return 'Últimas $count sem.';
  }

  @override
  String get cellAttendanceReportLegendTitle =>
      'Alertas por inasistencias seguidas';

  @override
  String get cellAttendanceReportLegendExcellent =>
      'Verde: 0 o 1 inasistencia seguida';

  @override
  String get cellAttendanceReportLegendWarning =>
      'Amarillo: 2 inasistencias seguidas';

  @override
  String get cellAttendanceReportLegendCritical =>
      'Rojo: 3 o más inasistencias seguidas';

  @override
  String get cellAbsenceByLeaderTitle => 'Inasistencias por líder';

  @override
  String get cellAbsenceByLeaderDenied =>
      'Solo el administrador puede ver este reporte';

  @override
  String get cellAbsenceByLeaderNoChurch =>
      'Tu cuenta no tiene una iglesia asignada';

  @override
  String get cellAbsenceByLeaderLoadError =>
      'No se pudo cargar el reporte de inasistencias';

  @override
  String get cellAbsenceByLeaderEmpty =>
      'No hay células con líder asignado en tu iglesia';

  @override
  String cellAbsenceByLeaderCellLabel(String code) {
    return 'Célula $code';
  }

  @override
  String cellAbsenceByLeaderCriticalCount(int count) {
    return '$count discípulos con 3+ inasistencias seguidas';
  }

  @override
  String cellAbsenceByLeaderTotalCritical(int count) {
    return 'Total: $count discípulos en alerta roja';
  }

  @override
  String get cellAbsenceByLeaderLeaderOk =>
      'Ningún discípulo con 3 o más inasistencias seguidas';

  @override
  String get cellAttendanceReportMembersTitle => 'Discípulos';

  @override
  String get cellAttendanceReportEmpty =>
      'No hay discípulos en esta célula o aún no hay asistencias registradas';

  @override
  String cellAttendanceReportMemberStats(
    int present,
    int consecutive,
    int total,
  ) {
    return '$present presentes · $consecutive seguidas · $total listas';
  }

  @override
  String get cellMemberAssignTitle => 'Discípulos de la célula';

  @override
  String get cellMemberAssignAction => 'Asignar discípulos';

  @override
  String get cellDetailAssignDisciplesAction => 'Asignar discípulos';

  @override
  String get cellMemberAssignAdd => 'Agregar discípulo';

  @override
  String get cellMemberRegisterNew => 'Registrar discípulo nuevo';

  @override
  String get cellMemberRegisterTitle => 'Registrar discípulo en la célula';

  @override
  String get cellMemberFormHint =>
      'Registro de discípulos para esta célula. Si solicita visita, se asignará el líder de la célula.';

  @override
  String get cellMemberFormSubmit => 'Registrar en la célula';

  @override
  String get cellMemberWantsVisitSubtitle =>
      'Si desea visita, se asignará automáticamente el líder de esta célula';

  @override
  String get cellMemberIsNewBelieverSubtitle =>
      'Actívalo si el discípulo se registra como nuevo creyente';

  @override
  String cellMemberVisitLeaderHint(String leader, String cell) {
    return 'Se asignará a $leader como líder (célula $cell)';
  }

  @override
  String get cellMemberVisitNoLeader =>
      'Esta célula no tiene líder asignado. Asigna un líder a la célula o desactiva la visita.';

  @override
  String get cellClaimLeadershipTitle => 'Sin líder titular';

  @override
  String get cellClaimLeadershipSubtitle =>
      'Esta célula no tiene líder asignado. Puedes asignarte para registrar visitas y discípulos.';

  @override
  String get cellClaimLeadershipAction => 'Asignarme como líder';

  @override
  String get cellClaimLeadershipSuccess =>
      'Ya eres el líder titular de esta célula.';

  @override
  String get cellClaimLeadershipAlreadyAssigned =>
      'Ya lideras otra célula. Un líder solo puede tener una célula titular.';

  @override
  String get cellClaimLeadershipDenied =>
      'No tienes permiso para asignarte como líder de esta célula.';

  @override
  String cellMemberRegisteredWithCellLeader(
    String name,
    String cell,
    String leader,
  ) {
    return '$name registrado en $cell con visita asignada a $leader';
  }

  @override
  String get myAssignedCellTitle => 'Mi célula';

  @override
  String get myAssignedCellDenied =>
      'No tienes permiso para ver la célula asignada';

  @override
  String get myAssignedCellLoadError =>
      'No se pudo cargar la información de la célula';

  @override
  String get myAssignedCellNoLeaderProfile =>
      'Tu cuenta de líder no está vinculada a un perfil de líder en el sistema';

  @override
  String get myAssignedCellEmpty => 'No tienes célula asignada';

  @override
  String myAssignedCellLeaderLabel(String name) {
    return 'Líder: $name';
  }

  @override
  String cellMemberRegisteredAndAssigned(String name, String cell) {
    return '$name registrado y asignado a $cell';
  }

  @override
  String cellMemberAssignHint(String cell) {
    return 'Asigna discípulos sin célula a $cell. La asignación a célula es independiente del líder asignado al discípulo.';
  }

  @override
  String get cellMemberListTitle => 'Discípulos';

  @override
  String get cellMemberListEmpty =>
      'Aún no hay discípulos asignados a esta célula';

  @override
  String get cellMemberSelectTitle => 'Seleccionar discípulos';

  @override
  String get cellMemberSelectHint =>
      'Solo aparecen discípulos asignados al líder de esta célula desde el registro pastoral y sin otra célula asignada';

  @override
  String cellMemberSelectConfirm(int count) {
    return 'Asignar $count';
  }

  @override
  String get cellMemberSelectRequiresChurch =>
      'No se pueden asignar discípulos sin una iglesia asignada a tu cuenta';

  @override
  String get cellMemberSelectSearchHint =>
      'Buscar por nombre, teléfono o líder';

  @override
  String get cellMemberSelectEmpty =>
      'No hay discípulos del líder de esta célula disponibles para asignar';

  @override
  String cellMemberSelectMaxReached(int max) {
    return 'Máximo $max discípulo(s) por célula';
  }

  @override
  String cellMemberSelectLimitHint(int max, int total) {
    return 'Puedes seleccionar hasta $max discípulo(s). La célula admite $total como máximo.';
  }

  @override
  String cellMemberAssignLimitReached(int max) {
    return 'La célula ya tiene el máximo de $max discípulos. No se pueden asignar más.';
  }

  @override
  String cellMemberAssignLimitPartial(int assigned, int requested, int max) {
    return 'Se asignaron $assigned de $requested: la célula tiene un máximo de $max discípulos.';
  }

  @override
  String get cellMemberSelectLoadError =>
      'No se pudieron cargar los discípulos';

  @override
  String cellMemberAssigned(String name) {
    return '$name asignado a la célula';
  }

  @override
  String cellMemberAssignedMultiple(int count) {
    return '$count discípulos asignados a la célula';
  }

  @override
  String get cellMemberUnassignTitle => 'Quitar de la célula';

  @override
  String cellMemberUnassignConfirm(String name) {
    return '¿Quitar a $name de esta célula?';
  }

  @override
  String get cellMemberUnassignAction => 'Quitar';

  @override
  String cellMemberAssignGenderHint(String gender) {
    return 'Solo se pueden asignar discípulos del mismo sexo que el líder de la célula ($gender).';
  }

  @override
  String get cellMemberAssignLeaderGenderMissing =>
      'El líder de la célula no tiene sexo registrado. Completa su perfil antes de asignar discípulos.';

  @override
  String get cellMemberAssignCellLeaderRequired =>
      'La célula debe tener un líder asignado para seleccionar discípulos.';

  @override
  String get cellMemberAssignGenderMismatch =>
      'Solo puedes asignar discípulos del mismo sexo que el líder de la célula.';

  @override
  String get cellMemberAssignLeaderExcluded =>
      'No se pueden asignar líderes como discípulos de la célula.';

  @override
  String cellMemberSelectEmptyGender(String gender) {
    return 'No hay discípulos del líder de esta célula del mismo sexo ($gender) disponibles para asignar.';
  }

  @override
  String cellMemberSelectGenderHint(String gender) {
    return 'Solo aparecen discípulos del líder de esta célula, del mismo sexo ($gender), registrados desde el registro pastoral y sin otra célula.';
  }

  @override
  String cellMemberRegisterGenderLocked(String gender) {
    return 'Debe ser $gender, igual que el líder de la célula.';
  }

  @override
  String cellMemberUnassigned(String name) {
    return '$name ya no está asignado a esta célula';
  }

  @override
  String get baptismCalendarTitle => 'Calendario de bautismo';

  @override
  String get baptismCalendarRegisterTitle => 'Registrar fecha de bautismo';

  @override
  String get baptismCalendarAdd => 'Registrar fecha';

  @override
  String get baptismCalendarTime => 'Hora (opcional)';

  @override
  String get baptismCalendarTimeHint => 'Ej: 10:00';

  @override
  String get baptismCalendarLocation => 'Lugar (opcional)';

  @override
  String get baptismCalendarNotes => 'Notas (opcional)';

  @override
  String get baptismCalendarSuccess => 'Fecha de bautismo registrada';

  @override
  String get baptismCalendarDeleted => 'Fecha de bautismo eliminada';

  @override
  String get baptismCalendarDenied =>
      'No tienes permiso para ver el calendario de bautismo';

  @override
  String get baptismCalendarLoadError =>
      'No se pudo cargar el calendario de bautismo';

  @override
  String get baptismCalendarEmpty => 'No hay bautismos programados';

  @override
  String get baptismCalendarSelectDay => 'Selecciona un día del calendario';

  @override
  String baptismCalendarDayTitle(String date) {
    return 'Bautismos del $date';
  }

  @override
  String get baptismCalendarDayEmpty =>
      'No hay bautismos programados para este día';

  @override
  String get baptismCalendarUpcoming => 'Próximos bautismos';

  @override
  String get baptismCalendarDeleteTitle => 'Eliminar fecha de bautismo';

  @override
  String baptismCalendarDeleteConfirm(String date) {
    return '¿Eliminar el bautismo programado para el $date?';
  }

  @override
  String get baptismCalendarAssignMembersAction => 'Asignar creyentes';

  @override
  String get baptismCalendarAssignMembersTitle =>
      'Integrantes para el bautismo';

  @override
  String get baptismCalendarAssignMembersHint =>
      'Marca los creyentes sin bautizar que se bautizarán en esta fecha';

  @override
  String get baptismCalendarAssignMembersSearchHint =>
      'Buscar por nombre o teléfono';

  @override
  String get baptismCalendarAssignMembersEmpty =>
      'No hay creyentes sin bautizar disponibles para asignar';

  @override
  String get memberIsBaptized => 'Bautizado';

  @override
  String get memberIsBaptizedSubtitle =>
      'Si está marcado, no aparecerá en el calendario de bautismo';

  @override
  String get baptismCalendarAssignMembersLoadError =>
      'No se pudieron cargar los integrantes';

  @override
  String baptismCalendarAssignMembersConfirm(int count) {
    return 'Guardar ($count)';
  }

  @override
  String baptismCalendarAssignedCount(int count) {
    return '$count integrante(s) asignado(s)';
  }

  @override
  String baptismCalendarMembersAssigned(int count) {
    return '$count integrante(s) asignado(s) al bautismo';
  }

  @override
  String get baptismCalendarAddForDay => 'Programar bautismo este día';

  @override
  String get baptismCalendarUpdated => 'Bautismo actualizado';

  @override
  String get baptismCalendarSelectEvent => 'Evento del día';

  @override
  String get baptismCalendarMembersSection => 'Integrantes asignados';

  @override
  String get baptismCalendarMembersEmpty => 'Aún no hay integrantes asignados';

  @override
  String get baptismCalendarDeleteAction => 'Eliminar bautismo';

  @override
  String get baptismCalendarCreateBelieverToBaptize =>
      'Crear nuevo creyente a bautizar';

  @override
  String get baptismCalendarRegisterBelieverTitle =>
      'Registrar creyente a bautizar';

  @override
  String get baptismCalendarRegisterBelieverButton => 'Registrar creyente';

  @override
  String get baptismCalendarBelieverCreatedScheduleFirst =>
      'Creyente registrado. Programa el bautismo del día para asignarlo.';

  @override
  String baptismCalendarBelieverCreatedAndAssigned(String name) {
    return '$name registrado y asignado al bautismo';
  }

  @override
  String get baptismCalendarBelieverAlreadyBaptized =>
      'El creyente ya está marcado como bautizado';

  @override
  String baptismCalendarBelieverAlreadyAssigned(String name) {
    return '$name ya está asignado a este bautismo';
  }

  @override
  String get baptismCalendarPastReadOnlyHint =>
      'Este bautismo ya pasó. No se puede modificar; solo confirmar quiénes se bautizaron.';

  @override
  String get baptismCalendarConfirmBaptizedSection => 'Confirmar bautizados';

  @override
  String get baptismCalendarConfirmBaptizedHint =>
      'Marca los creyentes que se bautizaron en esta fecha';

  @override
  String get baptismCalendarConfirmBaptizedAction => 'Guardar confirmación';

  @override
  String baptismCalendarConfirmBaptizedSuccess(int count) {
    return '$count creyente(s) confirmado(s) como bautizados';
  }

  @override
  String get baptismCalendarRemoveMemberTitle => 'Quitar del bautismo';

  @override
  String baptismCalendarRemoveMemberConfirm(String name) {
    return '¿Quitar a $name de este bautismo?';
  }

  @override
  String get baptismCalendarRemoveMemberAction => 'Quitar';

  @override
  String baptismCalendarRemoveMemberSuccess(String name) {
    return '$name ya no está asignado a este bautismo';
  }

  @override
  String get leaderRegMobileRequired => 'Ingresa el celular';

  @override
  String get leaderRegSectionAppAccess => 'ACCESO A LA APP';

  @override
  String get leaderRegEmailLoginHint =>
      'El líder ingresará con su correo como usuario.';

  @override
  String get leaderRegEmailLabel => 'Correo (usuario de acceso)';

  @override
  String get leaderRegEmailLabelRequired => 'Correo (usuario de acceso) *';

  @override
  String get leaderRegEmailLockedHelper =>
      'La cuenta ya fue creada; el correo no se puede cambiar aquí';

  @override
  String get leaderRegEmailLoginHelper => 'Será el usuario para iniciar sesión';

  @override
  String get leaderRegEmailRequired => 'Ingresa el correo del líder';

  @override
  String get leaderRegPasswordRequired => 'Ingresa una contraseña';

  @override
  String get leaderRegSubmitButton => 'Registrar líder';

  @override
  String get leaderRegLastName => 'Apellido *';

  @override
  String get leaderRegLastNameRequired => 'Ingresa el apellido';

  @override
  String get leaderRegFirstNames => 'Nombres *';

  @override
  String get leaderRegFirstNamesRequired => 'Ingresa los nombres';

  @override
  String get leaderRegBirthDate => 'Fecha de nacimiento';

  @override
  String get leaderRegAge => 'Edad';

  @override
  String get adminRegNewTitle => 'Nuevo administrador';

  @override
  String get adminRegEditTitle => 'Editar administrador';

  @override
  String get adminRegNoChurches =>
      'No hay iglesias activas. Crea una o desbloquea una existente.';

  @override
  String get adminRegCreateChurch => 'Crear iglesia';

  @override
  String get adminRegSelectChurch => 'Selecciona una iglesia';

  @override
  String get adminRegNewChurch => 'Nueva iglesia';

  @override
  String get adminRegChurchCreated =>
      'Iglesia creada. Selecciónala en la lista.';

  @override
  String get adminRegSelectChurchForAdmin =>
      'Selecciona la iglesia para este administrador.';

  @override
  String get adminRegUpdated => 'Administrador actualizado';

  @override
  String get adminRegSuccess => 'Administrador registrado correctamente';

  @override
  String get adminRegSaveProfileError => 'Error al guardar el perfil.';

  @override
  String adminRegRegisterError(String error) {
    return 'Error al registrar: $error';
  }

  @override
  String get adminRegEditDenied =>
      'Solo el super administrador puede editar administradores.';

  @override
  String get adminRegRegisterDenied =>
      'Solo el super administrador puede registrar administradores de iglesia.';

  @override
  String get adminRegSectionAccount => 'CUENTA';

  @override
  String get adminRegEmailLockedHelper =>
      'El correo de inicio de sesión no se puede cambiar desde aquí.';

  @override
  String get adminRegSectionChurch => 'IGLESIA ASIGNADA';

  @override
  String get adminRegChurchHint =>
      'Este administrador solo gestionará la iglesia seleccionada.';

  @override
  String get adminRegPasswordRequired => 'Ingresa la contraseña';

  @override
  String get adminRegRegisterButton => 'Registrar administrador';

  @override
  String get editPersonalDataSectionName => 'NOMBRE';

  @override
  String get editPersonalDataSectionContact => 'CONTACTO';

  @override
  String get churchServiceStorageNotConfigured =>
      'Firebase Storage no está activo en el proyecto. En Firebase Console → Storage, pulsa \"Comenzar\", elige ubicación y vuelve a subir el logo.';

  @override
  String get churchServicePermissionDenied =>
      'No tienes permiso para gestionar iglesias.';

  @override
  String get churchServiceNotFound => 'La iglesia ya no existe.';

  @override
  String get churchServiceUploadUnauthorized =>
      'No autorizado para subir el logo. Revisa las reglas de Storage.';

  @override
  String get churchServiceAppCheckError =>
      'App Check no configurado. En desarrollo: busca en logcat \"App Check debug token\", regístralo en Firebase Console → App Check → Android, cierra la app y vuelve a abrirla.';

  @override
  String get churchServiceAppCheckThrottled =>
      'App Check bloqueado por demasiados intentos. Espera 15 minutos, registra el token de depuración en Firebase Console, o desactiva temporalmente App Check en Storage.';

  @override
  String churchServiceSaveError(String message) {
    return 'Error al guardar: $message';
  }

  @override
  String get userProfileAdminPermissionDenied =>
      'No tienes permiso para gestionar administradores.';

  @override
  String userProfileError(String message) {
    return 'Error: $message';
  }

  @override
  String get supervisorServicePermissionDenied =>
      'No tienes permiso para asignar líderes a supervisores.';
}
