import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @menuHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get menuHome;

  /// No description provided for @menuNewMember.
  ///
  /// In es, this message translates to:
  /// **'Nuevo creyente'**
  String get menuNewMember;

  /// No description provided for @menuMembers.
  ///
  /// In es, this message translates to:
  /// **'Integrantes'**
  String get menuMembers;

  /// No description provided for @menuByLeader.
  ///
  /// In es, this message translates to:
  /// **'Por líder'**
  String get menuByLeader;

  /// No description provided for @menuMyMembers.
  ///
  /// In es, this message translates to:
  /// **'Mis integrantes'**
  String get menuMyMembers;

  /// No description provided for @menuNewLeader.
  ///
  /// In es, this message translates to:
  /// **'Nuevo líder'**
  String get menuNewLeader;

  /// No description provided for @menuLeaders.
  ///
  /// In es, this message translates to:
  /// **'Líderes'**
  String get menuLeaders;

  /// No description provided for @menuMySupervisedLeaders.
  ///
  /// In es, this message translates to:
  /// **'Mis líderes asignados'**
  String get menuMySupervisedLeaders;

  /// No description provided for @menuVisitsDashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard de visitas'**
  String get menuVisitsDashboard;

  /// No description provided for @menuPastoralDashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard pastoral'**
  String get menuPastoralDashboard;

  /// No description provided for @menuSupervisorLeaders.
  ///
  /// In es, this message translates to:
  /// **'Líderes por supervisor'**
  String get menuSupervisorLeaders;

  /// No description provided for @menuChurches.
  ///
  /// In es, this message translates to:
  /// **'Iglesias'**
  String get menuChurches;

  /// No description provided for @menuAdmins.
  ///
  /// In es, this message translates to:
  /// **'Administradores'**
  String get menuAdmins;

  /// No description provided for @menuNewAdmin.
  ///
  /// In es, this message translates to:
  /// **'Nuevo administrador'**
  String get menuNewAdmin;

  /// No description provided for @menuNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get menuNotifications;

  /// No description provided for @menuMyAccount.
  ///
  /// In es, this message translates to:
  /// **'Mi cuenta'**
  String get menuMyAccount;

  /// No description provided for @menuRegisterNewMember.
  ///
  /// In es, this message translates to:
  /// **'Registro de nuevo creyente'**
  String get menuRegisterNewMember;

  /// No description provided for @quickNewMemberTitle.
  ///
  /// In es, this message translates to:
  /// **'Registro de nuevo creyente'**
  String get quickNewMemberTitle;

  /// No description provided for @quickNewMemberSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Formulario de nuevo creyente'**
  String get quickNewMemberSubtitle;

  /// No description provided for @quickViewMembersTitle.
  ///
  /// In es, this message translates to:
  /// **'Ver creyentes'**
  String get quickViewMembersTitle;

  /// No description provided for @quickViewMembersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lista de integrantes registrados'**
  String get quickViewMembersSubtitle;

  /// No description provided for @quickMembersByLeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'Integrantes por líder'**
  String get quickMembersByLeaderTitle;

  /// No description provided for @quickMembersByLeaderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Miembros asignados a cada líder'**
  String get quickMembersByLeaderSubtitle;

  /// No description provided for @quickMyMembersTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis integrantes asignados'**
  String get quickMyMembersTitle;

  /// No description provided for @quickMyMembersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Integrantes bajo tu liderazgo'**
  String get quickMyMembersSubtitle;

  /// No description provided for @quickRegisterLeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar líder'**
  String get quickRegisterLeaderTitle;

  /// No description provided for @quickRegisterLeaderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Datos del liderazgo'**
  String get quickRegisterLeaderSubtitle;

  /// No description provided for @quickViewLeadersTitle.
  ///
  /// In es, this message translates to:
  /// **'Ver líderes'**
  String get quickViewLeadersTitle;

  /// No description provided for @quickViewLeadersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lista de líderes registrados'**
  String get quickViewLeadersSubtitle;

  /// No description provided for @quickMySupervisedLeadersTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis líderes asignados'**
  String get quickMySupervisedLeadersTitle;

  /// No description provided for @quickMySupervisedLeadersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Líderes bajo tu supervisión'**
  String get quickMySupervisedLeadersSubtitle;

  /// No description provided for @quickVisitsDashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Dashboard de visitas'**
  String get quickVisitsDashboardTitle;

  /// No description provided for @quickVisitsDashboardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gráficas de visitas por día, mes y año'**
  String get quickVisitsDashboardSubtitle;

  /// No description provided for @quickPastoralDashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Dashboard pastoral'**
  String get quickPastoralDashboardTitle;

  /// No description provided for @quickPastoralDashboardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento, nuevos creyentes y oración'**
  String get quickPastoralDashboardSubtitle;

  /// No description provided for @quickSupervisorLeadersTitle.
  ///
  /// In es, this message translates to:
  /// **'Líderes por supervisor'**
  String get quickSupervisorLeadersTitle;

  /// No description provided for @quickSupervisorLeadersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Asignar cartera de líderes a cada supervisor'**
  String get quickSupervisorLeadersSubtitle;

  /// No description provided for @quickChurchesTitle.
  ///
  /// In es, this message translates to:
  /// **'Iglesias'**
  String get quickChurchesTitle;

  /// No description provided for @quickChurchesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ver, editar y registrar sedes'**
  String get quickChurchesSubtitle;

  /// No description provided for @quickAdminsTitle.
  ///
  /// In es, this message translates to:
  /// **'Administradores'**
  String get quickAdminsTitle;

  /// No description provided for @quickAdminsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ver, editar y bloquear cuentas'**
  String get quickAdminsSubtitle;

  /// No description provided for @quickNewAdminTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo administrador'**
  String get quickNewAdminTitle;

  /// No description provided for @quickNewAdminSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Asignar iglesia al administrador'**
  String get quickNewAdminSubtitle;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @menuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get menuTooltip;

  /// No description provided for @welcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get welcome;

  /// No description provided for @user.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get user;

  /// No description provided for @noAccessForRole.
  ///
  /// In es, this message translates to:
  /// **'No hay accesos disponibles para tu rol. Contacta al administrador.'**
  String get noAccessForRole;

  /// No description provided for @leaderAccountNotLinked.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta de líder no está vinculada a un registro.'**
  String get leaderAccountNotLinked;

  /// No description provided for @leaderRecordNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró tu ficha de líder.'**
  String get leaderRecordNotFound;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @profileLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar tu perfil de usuario.'**
  String get profileLoadError;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @emailRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo no válido'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get passwordMinLength;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signIn;

  /// No description provided for @loginUnexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado al iniciar sesión.'**
  String get loginUnexpectedError;

  /// No description provided for @forgotPasswordEnterEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo para recuperar la contraseña'**
  String get forgotPasswordEnterEmail;

  /// No description provided for @forgotPasswordEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo para restablecer la contraseña'**
  String get forgotPasswordEmailSent;

  /// No description provided for @forgotPasswordSendFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el correo de recuperación.'**
  String get forgotPasswordSendFailed;

  /// No description provided for @myAccount.
  ///
  /// In es, this message translates to:
  /// **'Mi cuenta'**
  String get myAccount;

  /// No description provided for @systemRoles.
  ///
  /// In es, this message translates to:
  /// **'Roles en el sistema'**
  String get systemRoles;

  /// No description provided for @personalData.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get personalData;

  /// No description provided for @personalDataSubtitleFull.
  ///
  /// In es, this message translates to:
  /// **'Nombre, dirección y teléfono'**
  String get personalDataSubtitleFull;

  /// No description provided for @personalDataSubtitleName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de tu perfil'**
  String get personalDataSubtitleName;

  /// No description provided for @churchData.
  ///
  /// In es, this message translates to:
  /// **'Datos de la iglesia'**
  String get churchData;

  /// No description provided for @churchDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta los datos de tu sede'**
  String get churchDataSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Actualiza la clave de acceso'**
  String get changePasswordSubtitle;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Español, inglés o idioma del sistema'**
  String get languageSubtitle;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageSettingsTitle;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'Idioma del sistema'**
  String get languageSystem;

  /// No description provided for @languageSystemSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa la configuración de tu dispositivo'**
  String get languageSystemSubtitle;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @theme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Claro, oscuro o según el sistema'**
  String get themeSubtitle;

  /// No description provided for @themeSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tema de la app'**
  String get themeSettingsTitle;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Según el sistema'**
  String get themeSystem;

  /// No description provided for @themeSystemSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa la configuración de tu dispositivo'**
  String get themeSystemSubtitle;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @themeColorSection.
  ///
  /// In es, this message translates to:
  /// **'Paleta de colores'**
  String get themeColorSection;

  /// No description provided for @themeModeSection.
  ///
  /// In es, this message translates to:
  /// **'Modo de visualización'**
  String get themeModeSection;

  /// No description provided for @templateManantial.
  ///
  /// In es, this message translates to:
  /// **'Manantial'**
  String get templateManantial;

  /// No description provided for @templateManantialSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Azul profundo y dorado — recomendado'**
  String get templateManantialSubtitle;

  /// No description provided for @templateWhatsapp.
  ///
  /// In es, this message translates to:
  /// **'Verde mensajería'**
  String get templateWhatsapp;

  /// No description provided for @templateWhatsappSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Estilo WhatsApp, el anterior de la app'**
  String get templateWhatsappSubtitle;

  /// No description provided for @templatePeace.
  ///
  /// In es, this message translates to:
  /// **'Paz'**
  String get templatePeace;

  /// No description provided for @templatePeaceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Índigo suave y tonos calmados'**
  String get templatePeaceSubtitle;

  /// No description provided for @templateTraditional.
  ///
  /// In es, this message translates to:
  /// **'Tradicional'**
  String get templateTraditional;

  /// No description provided for @templateTraditionalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vino y crema, elegante'**
  String get templateTraditionalSubtitle;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In es, this message translates to:
  /// **'Super administrador'**
  String get roleSuperAdmin;

  /// No description provided for @roleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador de iglesia'**
  String get roleAdmin;

  /// No description provided for @roleRegistrar.
  ///
  /// In es, this message translates to:
  /// **'Registrador'**
  String get roleRegistrar;

  /// No description provided for @roleSupervisor.
  ///
  /// In es, this message translates to:
  /// **'Supervisor'**
  String get roleSupervisor;

  /// No description provided for @roleLeader.
  ///
  /// In es, this message translates to:
  /// **'Líder'**
  String get roleLeader;

  /// No description provided for @authInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico no es válido.'**
  String get authInvalidEmail;

  /// No description provided for @authUserDisabled.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ha sido deshabilitada.'**
  String get authUserDisabled;

  /// No description provided for @authUserNotFound.
  ///
  /// In es, this message translates to:
  /// **'No existe una cuenta con este correo.'**
  String get authUserNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos.'**
  String get authWrongPassword;

  /// No description provided for @authEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este correo.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get authWeakPassword;

  /// No description provided for @authRequiresRecentLogin.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, vuelve a iniciar sesión e intenta de nuevo.'**
  String get authRequiresRecentLogin;

  /// No description provided for @authTooManyRequests.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Intenta más tarde.'**
  String get authTooManyRequests;

  /// No description provided for @authNetworkError.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet.'**
  String get authNetworkError;

  /// No description provided for @authOperationNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'El registro por correo no está habilitado en Firebase.'**
  String get authOperationNotAllowed;

  /// No description provided for @authGenericError.
  ///
  /// In es, this message translates to:
  /// **'Error de autenticación. Intenta de nuevo.'**
  String get authGenericError;

  /// No description provided for @memberRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Registro de nuevo creyente'**
  String get memberRegisterTitle;

  /// No description provided for @memberEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar creyente'**
  String get memberEditTitle;

  /// No description provided for @memberNoPermissionRegister.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para registrar creyentes.'**
  String get memberNoPermissionRegister;

  /// No description provided for @memberNoPermissionEdit.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para editar creyentes.'**
  String get memberNoPermissionEdit;

  /// No description provided for @memberFormDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get memberFormDate;

  /// No description provided for @memberSectionPersonalData.
  ///
  /// In es, this message translates to:
  /// **'DATOS PERSONALES'**
  String get memberSectionPersonalData;

  /// No description provided for @memberFirstName.
  ///
  /// In es, this message translates to:
  /// **'Nombre *'**
  String get memberFirstName;

  /// No description provided for @memberFirstNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el nombre'**
  String get memberFirstNameRequired;

  /// No description provided for @memberLastName.
  ///
  /// In es, this message translates to:
  /// **'Apellidos *'**
  String get memberLastName;

  /// No description provided for @memberLastNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los apellidos'**
  String get memberLastNameRequired;

  /// No description provided for @memberIdDocumentType.
  ///
  /// In es, this message translates to:
  /// **'Documento'**
  String get memberIdDocumentType;

  /// No description provided for @memberIdDocumentNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de documento'**
  String get memberIdDocumentNumber;

  /// No description provided for @idDocumentDni.
  ///
  /// In es, this message translates to:
  /// **'DNI'**
  String get idDocumentDni;

  /// No description provided for @idDocumentPassport.
  ///
  /// In es, this message translates to:
  /// **'Pasaporte'**
  String get idDocumentPassport;

  /// No description provided for @idDocumentOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get idDocumentOther;

  /// No description provided for @memberGenderRequired.
  ///
  /// In es, this message translates to:
  /// **'Género *'**
  String get memberGenderRequired;

  /// No description provided for @memberGender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get memberGender;

  /// No description provided for @memberIncludeAddress.
  ///
  /// In es, this message translates to:
  /// **'Incluir dirección'**
  String get memberIncludeAddress;

  /// No description provided for @memberAddressRequiredForLeader.
  ///
  /// In es, this message translates to:
  /// **'Requerida para asignar un líder automático'**
  String get memberAddressRequiredForLeader;

  /// No description provided for @memberAddressOptional.
  ///
  /// In es, this message translates to:
  /// **'Opcional: datos de domicilio del creyente'**
  String get memberAddressOptional;

  /// No description provided for @memberPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono *'**
  String get memberPhone;

  /// No description provided for @memberPhoneRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el teléfono'**
  String get memberPhoneRequired;

  /// No description provided for @memberBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento *'**
  String get memberBirthDate;

  /// No description provided for @memberBirthDateRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la fecha de nacimiento'**
  String get memberBirthDateRequired;

  /// No description provided for @memberSelectDate.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get memberSelectDate;

  /// No description provided for @memberClearDate.
  ///
  /// In es, this message translates to:
  /// **'Quitar fecha'**
  String get memberClearDate;

  /// No description provided for @memberAge.
  ///
  /// In es, this message translates to:
  /// **'Edad *'**
  String get memberAge;

  /// No description provided for @memberAgeYears.
  ///
  /// In es, this message translates to:
  /// **'{age} años'**
  String memberAgeYears(int age);

  /// No description provided for @memberOccupation.
  ///
  /// In es, this message translates to:
  /// **'Ocupación *'**
  String get memberOccupation;

  /// No description provided for @memberOccupationRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la ocupación'**
  String get memberOccupationRequired;

  /// No description provided for @memberMaritalStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado civil *'**
  String get memberMaritalStatus;

  /// No description provided for @memberMaritalStatusRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el estado civil'**
  String get memberMaritalStatusRequired;

  /// No description provided for @memberSectionCellSchedule.
  ///
  /// In es, this message translates to:
  /// **'HORARIO PARA CÉLULA'**
  String get memberSectionCellSchedule;

  /// No description provided for @memberCellDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get memberCellDay;

  /// No description provided for @memberCellTime.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get memberCellTime;

  /// No description provided for @memberSelectTime.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hora'**
  String get memberSelectTime;

  /// No description provided for @memberCellZone.
  ///
  /// In es, this message translates to:
  /// **'Zona'**
  String get memberCellZone;

  /// No description provided for @memberSectionVisit.
  ///
  /// In es, this message translates to:
  /// **'VISITA'**
  String get memberSectionVisit;

  /// No description provided for @memberWantsVisit.
  ///
  /// In es, this message translates to:
  /// **'Desea ser visitado'**
  String get memberWantsVisit;

  /// No description provided for @memberWantsVisitSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Indica si la persona solicita una visita domiciliaria'**
  String get memberWantsVisitSubtitle;

  /// No description provided for @memberSectionObservations.
  ///
  /// In es, this message translates to:
  /// **'OBSERVACIONES'**
  String get memberSectionObservations;

  /// No description provided for @memberObservationsHint.
  ///
  /// In es, this message translates to:
  /// **'Notas adicionales...'**
  String get memberObservationsHint;

  /// No description provided for @memberVolunteer.
  ///
  /// In es, this message translates to:
  /// **'Voluntario'**
  String get memberVolunteer;

  /// No description provided for @memberSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get memberSaving;

  /// No description provided for @memberSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get memberSaveChanges;

  /// No description provided for @memberRegisterButton.
  ///
  /// In es, this message translates to:
  /// **'Registrar creyente'**
  String get memberRegisterButton;

  /// No description provided for @memberSectionAssignedLeader.
  ///
  /// In es, this message translates to:
  /// **'LÍDER ASIGNADO'**
  String get memberSectionAssignedLeader;

  /// No description provided for @memberManualLeader.
  ///
  /// In es, this message translates to:
  /// **'Elegir líder manualmente'**
  String get memberManualLeader;

  /// No description provided for @memberManualLeaderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Busca y elige un líder escribiendo su nombre'**
  String get memberManualLeaderSubtitle;

  /// No description provided for @memberAutoLeaderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se asignará el líder más cercano del mismo género'**
  String get memberAutoLeaderSubtitle;

  /// No description provided for @memberNoLeaderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sin líder hasta que actives visita o elijas uno'**
  String get memberNoLeaderSubtitle;

  /// No description provided for @memberNoLeadersAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay líderes con rol de líder en la app. Asigna el rol Líder al registrar un líder.'**
  String get memberNoLeadersAvailable;

  /// No description provided for @memberSelectLeader.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un líder'**
  String get memberSelectLeader;

  /// No description provided for @memberSelectLeaderFromList.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un líder de la lista'**
  String get memberSelectLeaderFromList;

  /// No description provided for @memberGenderForAutoLeader.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el género para asignar un líder automático'**
  String get memberGenderForAutoLeader;

  /// No description provided for @memberCompatibleLeadersHint.
  ///
  /// In es, this message translates to:
  /// **'Mostrando líderes compatibles con el género seleccionado.'**
  String get memberCompatibleLeadersHint;

  /// No description provided for @memberNoChurchAssigned.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no tiene iglesia asignada. Contacta al administrador.'**
  String get memberNoChurchAssigned;

  /// No description provided for @memberAddressRequiredAutoLeader.
  ///
  /// In es, this message translates to:
  /// **'Activa \"Incluir dirección\" y selecciona una dirección del buscador para asignar un líder automático.'**
  String get memberAddressRequiredAutoLeader;

  /// No description provided for @memberAddressGeocodeFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo ubicar la dirección. Selecciónala del autocompletado.'**
  String get memberAddressGeocodeFailed;

  /// No description provided for @memberUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Creyente actualizado correctamente'**
  String get memberUpdatedSuccess;

  /// No description provided for @memberRegisteredSuccess.
  ///
  /// In es, this message translates to:
  /// **'Creyente registrado correctamente'**
  String get memberRegisteredSuccess;

  /// No description provided for @memberRegisteredWithLeader.
  ///
  /// In es, this message translates to:
  /// **'Creyente registrado. Líder: {leader}{cell}{distance}'**
  String memberRegisteredWithLeader(
    String leader,
    String cell,
    String distance,
  );

  /// No description provided for @memberRegisteredNoNearbyLeader.
  ///
  /// In es, this message translates to:
  /// **'Creyente registrado. No hay líder del mismo género con dirección cercana.'**
  String get memberRegisteredNoNearbyLeader;

  /// No description provided for @memberSaveUnexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado al guardar.'**
  String get memberSaveUnexpectedError;

  /// No description provided for @memberCellCodeSuffix.
  ///
  /// In es, this message translates to:
  /// **' (Célula {code})'**
  String memberCellCodeSuffix(String code);

  /// No description provided for @memberDistanceKm.
  ///
  /// In es, this message translates to:
  /// **' · {km} km'**
  String memberDistanceKm(String km);

  /// No description provided for @genderMale.
  ///
  /// In es, this message translates to:
  /// **'Hombre (H)'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In es, this message translates to:
  /// **'Mujer (M)'**
  String get genderFemale;

  /// No description provided for @maritalSingle.
  ///
  /// In es, this message translates to:
  /// **'Soltero/a'**
  String get maritalSingle;

  /// No description provided for @maritalMarried.
  ///
  /// In es, this message translates to:
  /// **'Casado/a'**
  String get maritalMarried;

  /// No description provided for @maritalConcubino.
  ///
  /// In es, this message translates to:
  /// **'Concubino/a'**
  String get maritalConcubino;

  /// No description provided for @maritalDivorced.
  ///
  /// In es, this message translates to:
  /// **'Divorciado/a'**
  String get maritalDivorced;

  /// No description provided for @maritalWidowed.
  ///
  /// In es, this message translates to:
  /// **'Viudo/a'**
  String get maritalWidowed;

  /// No description provided for @weekdayMonday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get weekdaySunday;

  /// No description provided for @addressSection.
  ///
  /// In es, this message translates to:
  /// **'DIRECCIÓN'**
  String get addressSection;

  /// No description provided for @addressSearchRequired.
  ///
  /// In es, this message translates to:
  /// **'Buscar dirección *'**
  String get addressSearchRequired;

  /// No description provided for @addressSearchOptional.
  ///
  /// In es, this message translates to:
  /// **'Buscar dirección'**
  String get addressSearchOptional;

  /// No description provided for @addressSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe y elige una sugerencia...'**
  String get addressSearchHint;

  /// No description provided for @addressSearchTapToChange.
  ///
  /// In es, this message translates to:
  /// **'Toca aquí para cambiar la dirección...'**
  String get addressSearchTapToChange;

  /// No description provided for @addressChangeButton.
  ///
  /// In es, this message translates to:
  /// **'Cambiar dirección'**
  String get addressChangeButton;

  /// No description provided for @addressSearchAndSelect.
  ///
  /// In es, this message translates to:
  /// **'Busca y selecciona una dirección'**
  String get addressSearchAndSelect;

  /// No description provided for @addressMustPickFromList.
  ///
  /// In es, this message translates to:
  /// **'Debes elegir una dirección de la lista'**
  String get addressMustPickFromList;

  /// No description provided for @addressAutoFilledHint.
  ///
  /// In es, this message translates to:
  /// **'Se completa al buscar dirección'**
  String get addressAutoFilledHint;

  /// No description provided for @addressStreetRequired.
  ///
  /// In es, this message translates to:
  /// **'Calle *'**
  String get addressStreetRequired;

  /// No description provided for @addressStreetOptional.
  ///
  /// In es, this message translates to:
  /// **'Calle'**
  String get addressStreetOptional;

  /// No description provided for @addressNumber.
  ///
  /// In es, this message translates to:
  /// **'Número'**
  String get addressNumber;

  /// No description provided for @addressPostalCode.
  ///
  /// In es, this message translates to:
  /// **'Código postal'**
  String get addressPostalCode;

  /// No description provided for @addressNeighborhood.
  ///
  /// In es, this message translates to:
  /// **'Barrio'**
  String get addressNeighborhood;

  /// No description provided for @addressLocality.
  ///
  /// In es, this message translates to:
  /// **'Localidad / Partido'**
  String get addressLocality;

  /// No description provided for @addressStateProvince.
  ///
  /// In es, this message translates to:
  /// **'Estado / Provincia'**
  String get addressStateProvince;

  /// No description provided for @leaderSearchLabel.
  ///
  /// In es, this message translates to:
  /// **'Buscar líder *'**
  String get leaderSearchLabel;

  /// No description provided for @leaderSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe letras del nombre o célula...'**
  String get leaderSearchHint;

  /// No description provided for @leaderSearchClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar líder'**
  String get leaderSearchClear;

  /// No description provided for @leaderCellLabel.
  ///
  /// In es, this message translates to:
  /// **'Célula {code}'**
  String leaderCellLabel(String code);

  /// No description provided for @firestorePermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para esta operación.'**
  String get firestorePermissionDenied;

  /// No description provided for @firestoreUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Firestore no está disponible. Revisa tu conexión.'**
  String get firestoreUnavailable;

  /// No description provided for @firestoreNotFound.
  ///
  /// In es, this message translates to:
  /// **'El integrante ya no existe.'**
  String get firestoreNotFound;

  /// No description provided for @firestoreGenericError.
  ///
  /// In es, this message translates to:
  /// **'Error al procesar la solicitud. Intenta de nuevo.'**
  String get firestoreGenericError;

  /// No description provided for @commonYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @memberDetailSectionPersonal.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get memberDetailSectionPersonal;

  /// No description provided for @memberDetailSectionAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get memberDetailSectionAddress;

  /// No description provided for @memberDetailSectionLeader.
  ///
  /// In es, this message translates to:
  /// **'Líder asignado'**
  String get memberDetailSectionLeader;

  /// No description provided for @memberDetailSectionCellSchedule.
  ///
  /// In es, this message translates to:
  /// **'Horario para célula'**
  String get memberDetailSectionCellSchedule;

  /// No description provided for @memberDetailSectionObservations.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get memberDetailSectionObservations;

  /// No description provided for @memberDetailSectionRegistration.
  ///
  /// In es, this message translates to:
  /// **'Registro'**
  String get memberDetailSectionRegistration;

  /// No description provided for @memberDetailFirstName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get memberDetailFirstName;

  /// No description provided for @memberDetailLastName.
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get memberDetailLastName;

  /// No description provided for @memberDetailGender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get memberDetailGender;

  /// No description provided for @memberDetailPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get memberDetailPhone;

  /// No description provided for @memberDetailIdDocument.
  ///
  /// In es, this message translates to:
  /// **'Documento'**
  String get memberDetailIdDocument;

  /// No description provided for @memberDetailIdDocumentNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de documento'**
  String get memberDetailIdDocumentNumber;

  /// No description provided for @memberDetailBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get memberDetailBirthDate;

  /// No description provided for @memberDetailAge.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get memberDetailAge;

  /// No description provided for @memberDetailOccupation.
  ///
  /// In es, this message translates to:
  /// **'Ocupación'**
  String get memberDetailOccupation;

  /// No description provided for @memberDetailMaritalStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado civil'**
  String get memberDetailMaritalStatus;

  /// No description provided for @memberDetailWantsVisit.
  ///
  /// In es, this message translates to:
  /// **'Desea ser visitado'**
  String get memberDetailWantsVisit;

  /// No description provided for @memberDetailLeaderName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get memberDetailLeaderName;

  /// No description provided for @memberDetailCell.
  ///
  /// In es, this message translates to:
  /// **'Célula'**
  String get memberDetailCell;

  /// No description provided for @memberDetailDistance.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get memberDetailDistance;

  /// No description provided for @memberDetailDistanceKm.
  ///
  /// In es, this message translates to:
  /// **'{km} km'**
  String memberDetailDistanceKm(String km);

  /// No description provided for @memberDetailCellDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get memberDetailCellDay;

  /// No description provided for @memberDetailCellTime.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get memberDetailCellTime;

  /// No description provided for @memberDetailCellZone.
  ///
  /// In es, this message translates to:
  /// **'Zona'**
  String get memberDetailCellZone;

  /// No description provided for @memberDetailFormDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha del formulario'**
  String get memberDetailFormDate;

  /// No description provided for @memberDetailVolunteer.
  ///
  /// In es, this message translates to:
  /// **'Voluntario'**
  String get memberDetailVolunteer;

  /// No description provided for @memberDetailRegisteredBy.
  ///
  /// In es, this message translates to:
  /// **'Registrado por'**
  String get memberDetailRegisteredBy;

  /// No description provided for @memberDetailDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar integrante'**
  String get memberDetailDeleteTitle;

  /// No description provided for @memberDetailDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar a {name}? Esta acción no se puede deshacer.'**
  String memberDetailDeleteConfirm(String name);

  /// No description provided for @memberDetailDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Integrante eliminado'**
  String get memberDetailDeletedSuccess;

  /// No description provided for @memberDetailRegisterVisit.
  ///
  /// In es, this message translates to:
  /// **'Registrar visita'**
  String get memberDetailRegisterVisit;

  /// No description provided for @memberDetailEditMember.
  ///
  /// In es, this message translates to:
  /// **'Editar integrante'**
  String get memberDetailEditMember;

  /// No description provided for @memberDetailDeleteMember.
  ///
  /// In es, this message translates to:
  /// **'Eliminar integrante'**
  String get memberDetailDeleteMember;

  /// No description provided for @memberVisitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Visitas registradas'**
  String get memberVisitsTitle;

  /// No description provided for @memberVisitsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las visitas.'**
  String get memberVisitsLoadError;

  /// No description provided for @memberVisitsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay visitas registradas.'**
  String get memberVisitsEmpty;

  /// No description provided for @memberVisitsNeedsFollowUp.
  ///
  /// In es, this message translates to:
  /// **' · Requiere seguimiento'**
  String get memberVisitsNeedsFollowUp;

  /// No description provided for @visitDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración: {value}'**
  String visitDuration(String value);

  /// No description provided for @visitPrayer.
  ///
  /// In es, this message translates to:
  /// **'Oración: {value}'**
  String visitPrayer(String value);

  /// No description provided for @visitRequests.
  ///
  /// In es, this message translates to:
  /// **'Peticiones: {value}'**
  String visitRequests(String value);

  /// No description provided for @visitFollowUp.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento: {value}'**
  String visitFollowUp(String value);

  /// No description provided for @visitSpiritualState.
  ///
  /// In es, this message translates to:
  /// **'Estado: {value}'**
  String visitSpiritualState(String value);

  /// No description provided for @visitPlaceHome.
  ///
  /// In es, this message translates to:
  /// **'Casa'**
  String get visitPlaceHome;

  /// No description provided for @visitPlaceHospital.
  ///
  /// In es, this message translates to:
  /// **'Hospital'**
  String get visitPlaceHospital;

  /// No description provided for @visitPlaceWork.
  ///
  /// In es, this message translates to:
  /// **'Trabajo'**
  String get visitPlaceWork;

  /// No description provided for @visitPlaceChurch.
  ///
  /// In es, this message translates to:
  /// **'Iglesia'**
  String get visitPlaceChurch;

  /// No description provided for @visitPlaceVideoCall.
  ///
  /// In es, this message translates to:
  /// **'Videollamada'**
  String get visitPlaceVideoCall;

  /// No description provided for @spiritualNewBeliever.
  ///
  /// In es, this message translates to:
  /// **'Nuevo creyente'**
  String get spiritualNewBeliever;

  /// No description provided for @spiritualInDiscipleship.
  ///
  /// In es, this message translates to:
  /// **'En discipulado'**
  String get spiritualInDiscipleship;

  /// No description provided for @spiritualActiveMember.
  ///
  /// In es, this message translates to:
  /// **'Miembro activo'**
  String get spiritualActiveMember;

  /// No description provided for @spiritualDistant.
  ///
  /// In es, this message translates to:
  /// **'Alejado'**
  String get spiritualDistant;

  /// No description provided for @spiritualFrequentVisitor.
  ///
  /// In es, this message translates to:
  /// **'Visitante frecuente'**
  String get spiritualFrequentVisitor;

  /// No description provided for @membersMapNoLocationSnack.
  ///
  /// In es, this message translates to:
  /// **'Este integrante no tiene ubicación en el mapa'**
  String get membersMapNoLocationSnack;

  /// No description provided for @membersMapNavigationFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la navegación'**
  String get membersMapNavigationFailed;

  /// No description provided for @membersMapRequestsVisit.
  ///
  /// In es, this message translates to:
  /// **'Solicita visita'**
  String get membersMapRequestsVisit;

  /// No description provided for @membersMapDistanceFromLeader.
  ///
  /// In es, this message translates to:
  /// **'{km} km del líder'**
  String membersMapDistanceFromLeader(String km);

  /// No description provided for @membersMapGetDirections.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get membersMapGetDirections;

  /// No description provided for @membersMapViewDetail.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle'**
  String get membersMapViewDetail;

  /// No description provided for @membersMapLeaderLabel.
  ///
  /// In es, this message translates to:
  /// **'Líder'**
  String get membersMapLeaderLabel;

  /// No description provided for @membersMapEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicaciones en el mapa'**
  String get membersMapEmptyTitle;

  /// No description provided for @membersMapEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los integrantes necesitan dirección con coordenadas para aparecer en el mapa.'**
  String get membersMapEmptySubtitle;

  /// No description provided for @membersMapMissingLocationCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 integrante sin ubicación en el mapa} other{{count} integrantes sin ubicación en el mapa}}'**
  String membersMapMissingLocationCount(int count);

  /// No description provided for @membersMapLeaderMarker.
  ///
  /// In es, this message translates to:
  /// **'Marcador morado: {name} (líder)'**
  String membersMapLeaderMarker(String name);

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get commonSaving;

  /// No description provided for @commonNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get commonNew;

  /// No description provided for @commonRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get commonRefresh;

  /// No description provided for @commonUnblock.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get commonUnblock;

  /// No description provided for @commonBlock.
  ///
  /// In es, this message translates to:
  /// **'Bloquear'**
  String get commonBlock;

  /// No description provided for @commonBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get commonBlocked;

  /// No description provided for @commonBlockedFem.
  ///
  /// In es, this message translates to:
  /// **'Bloqueada'**
  String get commonBlockedFem;

  /// No description provided for @commonUnblocked.
  ///
  /// In es, this message translates to:
  /// **'Desbloqueado'**
  String get commonUnblocked;

  /// No description provided for @commonUnblockedFem.
  ///
  /// In es, this message translates to:
  /// **'Desbloqueada'**
  String get commonUnblockedFem;

  /// No description provided for @commonNoMatches.
  ///
  /// In es, this message translates to:
  /// **'No hay coincidencias'**
  String get commonNoMatches;

  /// No description provided for @commonNoName.
  ///
  /// In es, this message translates to:
  /// **'(Sin nombre)'**
  String get commonNoName;

  /// No description provided for @commonLoadListError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la lista.'**
  String get commonLoadListError;

  /// No description provided for @commonExportError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo exportar el listado. Intenta de nuevo.'**
  String get commonExportError;

  /// No description provided for @commonDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar a {name}? Esta acción no se puede deshacer.'**
  String commonDeleteConfirm(String name);

  /// No description provided for @accessDeniedTitle.
  ///
  /// In es, this message translates to:
  /// **'Acceso restringido'**
  String get accessDeniedTitle;

  /// No description provided for @accessDeniedDefault.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para ver esta sección.'**
  String get accessDeniedDefault;

  /// No description provided for @blockedAccountUserTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta bloqueada'**
  String get blockedAccountUserTitle;

  /// No description provided for @blockedAccountChurchTitle.
  ///
  /// In es, this message translates to:
  /// **'Iglesia bloqueada'**
  String get blockedAccountChurchTitle;

  /// No description provided for @blockedAccountUserMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu usuario fue suspendido. Contacta al super administrador para reactivar tu acceso.'**
  String get blockedAccountUserMessage;

  /// No description provided for @blockedAccountChurchMessage.
  ///
  /// In es, this message translates to:
  /// **'La iglesia asignada a tu cuenta está bloqueada. No puedes usar el sistema hasta que el super administrador la reactive.'**
  String get blockedAccountChurchMessage;

  /// No description provided for @membersListTitle.
  ///
  /// In es, this message translates to:
  /// **'Creyentes'**
  String get membersListTitle;

  /// No description provided for @membersListExportExcel.
  ///
  /// In es, this message translates to:
  /// **'Descargar Excel'**
  String get membersListExportExcel;

  /// No description provided for @membersListDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar creyente'**
  String get membersListDeleteTitle;

  /// No description provided for @membersListDeleted.
  ///
  /// In es, this message translates to:
  /// **'Creyente eliminado'**
  String get membersListDeleted;

  /// No description provided for @membersListLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la lista.\nVerifica Firestore en Firebase Console.'**
  String get membersListLoadError;

  /// No description provided for @membersListEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay creyentes registrados'**
  String get membersListEmptyTitle;

  /// No description provided for @membersListEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pulsa \"Nuevo\" para registrar al primero.'**
  String get membersListEmptySubtitle;

  /// No description provided for @membersListSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, teléfono, líder o localidad…'**
  String get membersListSearchHint;

  /// No description provided for @membersListLeaderPrefix.
  ///
  /// In es, this message translates to:
  /// **'Líder: {name}'**
  String membersListLeaderPrefix(String name);

  /// No description provided for @membersListDatePrefix.
  ///
  /// In es, this message translates to:
  /// **'Fecha: {date}'**
  String membersListDatePrefix(String date);

  /// No description provided for @membersByLeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'Integrantes por líder'**
  String get membersByLeaderTitle;

  /// No description provided for @membersByLeaderEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay integrantes registrados'**
  String get membersByLeaderEmpty;

  /// No description provided for @membersByLeaderAssignedCount.
  ///
  /// In es, this message translates to:
  /// **'{assigned} de {total} integrantes con líder asignado'**
  String membersByLeaderAssignedCount(int assigned, int total);

  /// No description provided for @membersByLeaderMemberCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 integrante} other{{count} integrantes}}'**
  String membersByLeaderMemberCount(int count);

  /// No description provided for @membersByLeaderRegistrationDate.
  ///
  /// In es, this message translates to:
  /// **'Registro: {date}'**
  String membersByLeaderRegistrationDate(String date);

  /// No description provided for @leaderAssignedTitle.
  ///
  /// In es, this message translates to:
  /// **'Integrantes asignados'**
  String get leaderAssignedTitle;

  /// No description provided for @leaderAssignedTabList.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get leaderAssignedTabList;

  /// No description provided for @leaderAssignedTabMap.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get leaderAssignedTabMap;

  /// No description provided for @leaderAssignedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 integrante asignado} other{{count} integrantes asignados}}'**
  String leaderAssignedCount(int count);

  /// No description provided for @leaderAssignedCellSuffix.
  ///
  /// In es, this message translates to:
  /// **'· Célula {code}'**
  String leaderAssignedCellSuffix(String code);

  /// No description provided for @leaderAssignedEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin integrantes asignados'**
  String get leaderAssignedEmptyTitle;

  /// No description provided for @leaderAssignedEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los integrantes con visita activada y dirección aparecerán aquí al registrarse.'**
  String get leaderAssignedEmptySubtitle;

  /// No description provided for @leaderAssignedNoMapLocation.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicación en mapa'**
  String get leaderAssignedNoMapLocation;

  /// No description provided for @leaderAssignedRegisterVisit.
  ///
  /// In es, this message translates to:
  /// **'Registrar visita'**
  String get leaderAssignedRegisterVisit;

  /// No description provided for @leaderAssignedLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar los integrantes.'**
  String get leaderAssignedLoadError;

  /// No description provided for @leadersListTitle.
  ///
  /// In es, this message translates to:
  /// **'Líderes'**
  String get leadersListTitle;

  /// No description provided for @leadersListDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar líder'**
  String get leadersListDeleteTitle;

  /// No description provided for @leadersListDeleted.
  ///
  /// In es, this message translates to:
  /// **'Líder eliminado'**
  String get leadersListDeleted;

  /// No description provided for @leadersListLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la lista. Verifica Firestore y las reglas de la colección \"leaders\".'**
  String get leadersListLoadError;

  /// No description provided for @leadersListEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay líderes registrados'**
  String get leadersListEmpty;

  /// No description provided for @leadersListSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, teléfono, correo o célula…'**
  String get leadersListSearchHint;

  /// No description provided for @leadersListCellPrefix.
  ///
  /// In es, this message translates to:
  /// **'Célula {code}'**
  String leadersListCellPrefix(String code);

  /// No description provided for @leadersListViewMembers.
  ///
  /// In es, this message translates to:
  /// **'Ver integrantes asignados'**
  String get leadersListViewMembers;

  /// No description provided for @leadersListViewLeader.
  ///
  /// In es, this message translates to:
  /// **'Ver líder'**
  String get leadersListViewLeader;

  /// No description provided for @leaderDetailEditLeader.
  ///
  /// In es, this message translates to:
  /// **'Editar líder'**
  String get leaderDetailEditLeader;

  /// No description provided for @leaderDetailDeleteLeader.
  ///
  /// In es, this message translates to:
  /// **'Eliminar líder'**
  String get leaderDetailDeleteLeader;

  /// No description provided for @leaderDetailViewMembers.
  ///
  /// In es, this message translates to:
  /// **'Ver integrantes asignados'**
  String get leaderDetailViewMembers;

  /// No description provided for @leaderDetailSectionLeadership.
  ///
  /// In es, this message translates to:
  /// **'Datos del liderazgo'**
  String get leaderDetailSectionLeadership;

  /// No description provided for @leaderDetailSectionCellContact.
  ///
  /// In es, this message translates to:
  /// **'Célula y contacto'**
  String get leaderDetailSectionCellContact;

  /// No description provided for @leaderDetailSectionRoles.
  ///
  /// In es, this message translates to:
  /// **'Roles en la app'**
  String get leaderDetailSectionRoles;

  /// No description provided for @leaderDetailLastName.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get leaderDetailLastName;

  /// No description provided for @leaderDetailFirstNames.
  ///
  /// In es, this message translates to:
  /// **'Nombres'**
  String get leaderDetailFirstNames;

  /// No description provided for @leaderDetailChurchOffice.
  ///
  /// In es, this message translates to:
  /// **'Cargo en la iglesia'**
  String get leaderDetailChurchOffice;

  /// No description provided for @leaderDetailMobile.
  ///
  /// In es, this message translates to:
  /// **'Celular / Móvil'**
  String get leaderDetailMobile;

  /// No description provided for @leaderDetailPermissions.
  ///
  /// In es, this message translates to:
  /// **'Permisos'**
  String get leaderDetailPermissions;

  /// No description provided for @leaderDetailDeleted.
  ///
  /// In es, this message translates to:
  /// **'Líder eliminado'**
  String get leaderDetailDeleted;

  /// No description provided for @leadersMapNoLocationSnack.
  ///
  /// In es, this message translates to:
  /// **'Este líder no tiene ubicación en el mapa'**
  String get leadersMapNoLocationSnack;

  /// No description provided for @leadersMapEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicaciones en el mapa'**
  String get leadersMapEmptyTitle;

  /// No description provided for @leadersMapEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los líderes necesitan dirección con coordenadas para aparecer en el mapa.'**
  String get leadersMapEmptySubtitle;

  /// No description provided for @leadersMapMissingLocationCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 líder sin ubicación en el mapa} other{{count} líderes sin ubicación en el mapa}}'**
  String leadersMapMissingLocationCount(int count);

  /// No description provided for @leadersMapViewLeader.
  ///
  /// In es, this message translates to:
  /// **'Ver líder'**
  String get leadersMapViewLeader;

  /// No description provided for @supervisorMyLeadersTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis líderes asignados'**
  String get supervisorMyLeadersTitle;

  /// No description provided for @supervisorMyLeadersDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para ver tus líderes asignados.'**
  String get supervisorMyLeadersDenied;

  /// No description provided for @supervisorMyLeadersCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 líder bajo tu supervisión} other{{count} líderes bajo tu supervisión}}'**
  String supervisorMyLeadersCount(int count);

  /// No description provided for @supervisorMyLeadersSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar líder'**
  String get supervisorMyLeadersSearchHint;

  /// No description provided for @supervisorMyLeadersEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin líderes asignados'**
  String get supervisorMyLeadersEmptyTitle;

  /// No description provided for @supervisorMyLeadersEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'El administrador te asignará líderes cuando corresponda.'**
  String get supervisorMyLeadersEmptySubtitle;

  /// No description provided for @supervisorMyLeadersNoSearchResults.
  ///
  /// In es, this message translates to:
  /// **'Ningún líder coincide con la búsqueda.'**
  String get supervisorMyLeadersNoSearchResults;

  /// No description provided for @supervisorMyLeadersViewMembers.
  ///
  /// In es, this message translates to:
  /// **'Creyentes'**
  String get supervisorMyLeadersViewMembers;

  /// No description provided for @supervisorAssignmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Líderes por supervisor'**
  String get supervisorAssignmentsTitle;

  /// No description provided for @supervisorAssignmentsDeniedSupervisor.
  ///
  /// In es, this message translates to:
  /// **'Los supervisores no pueden acceder a esta pantalla. Usa «Mis líderes asignados» para ver tu cartera.'**
  String get supervisorAssignmentsDeniedSupervisor;

  /// No description provided for @supervisorAssignmentsDeniedAdmin.
  ///
  /// In es, this message translates to:
  /// **'Solo el administrador puede asignar líderes a supervisores.'**
  String get supervisorAssignmentsDeniedAdmin;

  /// No description provided for @supervisorAssignmentsNoSupervisors.
  ///
  /// In es, this message translates to:
  /// **'No hay supervisores en tu iglesia'**
  String get supervisorAssignmentsNoSupervisors;

  /// No description provided for @supervisorAssignmentsNoSupervisorsHint.
  ///
  /// In es, this message translates to:
  /// **'Al registrar un líder, asigna el rol Supervisor en la app.'**
  String get supervisorAssignmentsNoSupervisorsHint;

  /// No description provided for @supervisorAssignmentsSelectSupervisor.
  ///
  /// In es, this message translates to:
  /// **'Selecciona supervisor *'**
  String get supervisorAssignmentsSelectSupervisor;

  /// No description provided for @supervisorAssignmentsAssignedLeaders.
  ///
  /// In es, this message translates to:
  /// **'Líderes asignados ({count})'**
  String supervisorAssignmentsAssignedLeaders(int count);

  /// No description provided for @supervisorAssignmentsSearchLeader.
  ///
  /// In es, this message translates to:
  /// **'Buscar líder'**
  String get supervisorAssignmentsSearchLeader;

  /// No description provided for @supervisorAssignmentsNoLeaders.
  ///
  /// In es, this message translates to:
  /// **'No hay líderes registrados en tu iglesia.'**
  String get supervisorAssignmentsNoLeaders;

  /// No description provided for @supervisorAssignmentsNoLeaderMatches.
  ///
  /// In es, this message translates to:
  /// **'Ningún líder coincide con la búsqueda.'**
  String get supervisorAssignmentsNoLeaderMatches;

  /// No description provided for @supervisorAssignmentsNoLeadersAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay líderes disponibles para asignar.'**
  String get supervisorAssignmentsNoLeadersAvailable;

  /// No description provided for @supervisorAssignmentsSelectSupervisorError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un supervisor'**
  String get supervisorAssignmentsSelectSupervisorError;

  /// No description provided for @supervisorAssignmentsConflict.
  ///
  /// In es, this message translates to:
  /// **'No se puede guardar: un líder ya pertenece a {name}'**
  String supervisorAssignmentsConflict(String name);

  /// No description provided for @supervisorAssignmentsSaved.
  ///
  /// In es, this message translates to:
  /// **'Líderes asignados correctamente'**
  String get supervisorAssignmentsSaved;

  /// No description provided for @dashboardVisitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Dashboard de visitas'**
  String get dashboardVisitsTitle;

  /// No description provided for @dashboardPastoralTitle.
  ///
  /// In es, this message translates to:
  /// **'Dashboard pastoral'**
  String get dashboardPastoralTitle;

  /// No description provided for @dashboardVisitsDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para ver el dashboard de visitas.'**
  String get dashboardVisitsDenied;

  /// No description provided for @dashboardPastoralDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para ver el dashboard pastoral.'**
  String get dashboardPastoralDenied;

  /// No description provided for @dashboardScopeAllChurches.
  ///
  /// In es, this message translates to:
  /// **'Todas las iglesias'**
  String get dashboardScopeAllChurches;

  /// No description provided for @dashboardScopeYourChurch.
  ///
  /// In es, this message translates to:
  /// **'Tu iglesia'**
  String get dashboardScopeYourChurch;

  /// No description provided for @dashboardScopeYourLeaders.
  ///
  /// In es, this message translates to:
  /// **'Tus líderes asignados'**
  String get dashboardScopeYourLeaders;

  /// No description provided for @dashboardChurchLabel.
  ///
  /// In es, this message translates to:
  /// **'Iglesia'**
  String get dashboardChurchLabel;

  /// No description provided for @dashboardNoAssignedLeadersTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin líderes asignados'**
  String get dashboardNoAssignedLeadersTitle;

  /// No description provided for @dashboardNoAssignedLeadersVisits.
  ///
  /// In es, this message translates to:
  /// **'Cuando el administrador te asigne líderes, verás aquí las estadísticas de sus visitas.'**
  String get dashboardNoAssignedLeadersVisits;

  /// No description provided for @dashboardNoAssignedLeadersPastoral.
  ///
  /// In es, this message translates to:
  /// **'Cuando el administrador te asigne líderes, verás aquí el seguimiento pastoral.'**
  String get dashboardNoAssignedLeadersPastoral;

  /// No description provided for @dashboardTotalPeriod.
  ///
  /// In es, this message translates to:
  /// **'Total en el período'**
  String get dashboardTotalPeriod;

  /// No description provided for @dashboardLeadersWithVisits.
  ///
  /// In es, this message translates to:
  /// **'Líderes con visitas'**
  String get dashboardLeadersWithVisits;

  /// No description provided for @dashboardVisitCount.
  ///
  /// In es, this message translates to:
  /// **'Número de visitas'**
  String get dashboardVisitCount;

  /// No description provided for @dashboardTopVisitPlaces.
  ///
  /// In es, this message translates to:
  /// **'Lugares de visita más frecuentes'**
  String get dashboardTopVisitPlaces;

  /// No description provided for @dashboardByVisitPlace.
  ///
  /// In es, this message translates to:
  /// **'Por lugar de la visita'**
  String get dashboardByVisitPlace;

  /// No description provided for @dashboardTopPrayerRequests.
  ///
  /// In es, this message translates to:
  /// **'Peticiones de oración más comunes'**
  String get dashboardTopPrayerRequests;

  /// No description provided for @dashboardPrayerRequestsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Textos repetidos en el período'**
  String get dashboardPrayerRequestsSubtitle;

  /// No description provided for @dashboardNoPrayerRequests.
  ///
  /// In es, this message translates to:
  /// **'No hay peticiones de oración registradas en este período.'**
  String get dashboardNoPrayerRequests;

  /// No description provided for @dashboardVisitsByLeader.
  ///
  /// In es, this message translates to:
  /// **'Visitas por líder'**
  String get dashboardVisitsByLeader;

  /// No description provided for @dashboardPeriodLast14Days.
  ///
  /// In es, this message translates to:
  /// **'Últimos 14 días'**
  String get dashboardPeriodLast14Days;

  /// No description provided for @dashboardPeriodLast12Months.
  ///
  /// In es, this message translates to:
  /// **'Últimos 12 meses'**
  String get dashboardPeriodLast12Months;

  /// No description provided for @dashboardPeriodLast5Years.
  ///
  /// In es, this message translates to:
  /// **'Últimos 5 años'**
  String get dashboardPeriodLast5Years;

  /// No description provided for @dashboardFollowUpTitle.
  ///
  /// In es, this message translates to:
  /// **'Personas que requieren seguimiento'**
  String get dashboardFollowUpTitle;

  /// No description provided for @dashboardFollowUpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Marcadas en visitas del período'**
  String get dashboardFollowUpSubtitle;

  /// No description provided for @dashboardFollowUpEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay personas con seguimiento pendiente en este período.'**
  String get dashboardFollowUpEmpty;

  /// No description provided for @dashboardVisitOnDate.
  ///
  /// In es, this message translates to:
  /// **'Visita: {date}'**
  String dashboardVisitOnDate(String date);

  /// No description provided for @dashboardLeaderPrefix.
  ///
  /// In es, this message translates to:
  /// **'Líder: {name}'**
  String dashboardLeaderPrefix(String name);

  /// No description provided for @dashboardMemberNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el integrante.'**
  String get dashboardMemberNotFound;

  /// No description provided for @dashboardNewMembersTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevos creyentes'**
  String get dashboardNewMembersTitle;

  /// No description provided for @dashboardNewMembersCount.
  ///
  /// In es, this message translates to:
  /// **'{count} registrados en el período'**
  String dashboardNewMembersCount(int count);

  /// No description provided for @dashboardPrayerVisitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Visitas con oración'**
  String get dashboardPrayerVisitsTitle;

  /// No description provided for @dashboardPrayerVisitsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin visitas en el período seleccionado.'**
  String get dashboardPrayerVisitsEmpty;

  /// No description provided for @dashboardPrayerVisitsSummary.
  ///
  /// In es, this message translates to:
  /// **'{withPrayer} de {total} visitas incluyeron oración.'**
  String dashboardPrayerVisitsSummary(int withPrayer, int total);

  /// No description provided for @dashboardNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos para mostrar'**
  String get dashboardNoData;

  /// No description provided for @chartPeriodDay.
  ///
  /// In es, this message translates to:
  /// **'Por día'**
  String get chartPeriodDay;

  /// No description provided for @chartPeriodMonth.
  ///
  /// In es, this message translates to:
  /// **'Por mes'**
  String get chartPeriodMonth;

  /// No description provided for @chartPeriodYear.
  ///
  /// In es, this message translates to:
  /// **'Por año'**
  String get chartPeriodYear;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @notificationsLeaderNotLinked.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no está vinculada a un líder. Contacta al administrador.'**
  String get notificationsLeaderNotLinked;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar leídas'**
  String get notificationsMarkRead;

  /// No description provided for @notificationsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las notificaciones. Revisa las reglas de Firestore.'**
  String get notificationsLoadError;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuando te asignen un integrante nuevo, aparecerá aquí.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsMemberUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El integrante ya no está disponible.'**
  String get notificationsMemberUnavailable;

  /// No description provided for @notificationsToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy {time}'**
  String notificationsToday(String time);

  /// No description provided for @notificationsYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer {time}'**
  String notificationsYesterday(String time);

  /// No description provided for @notificationNewMemberTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo creyente asignado'**
  String get notificationNewMemberTitle;

  /// No description provided for @notificationNewMemberBody.
  ///
  /// In es, this message translates to:
  /// **'Se te asignó a {name}. Toca para ver el detalle.'**
  String notificationNewMemberBody(String name);

  /// No description provided for @notificationMemberFallback.
  ///
  /// In es, this message translates to:
  /// **'Integrante'**
  String get notificationMemberFallback;

  /// No description provided for @visitRegDenied.
  ///
  /// In es, this message translates to:
  /// **'Solo el líder puede registrar visitas a sus integrantes.'**
  String get visitRegDenied;

  /// No description provided for @visitRegTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar visita'**
  String get visitRegTitle;

  /// No description provided for @visitRegPrayerFollowUpRequired.
  ///
  /// In es, this message translates to:
  /// **'Indica si se realizó oración y si necesita seguimiento.'**
  String get visitRegPrayerFollowUpRequired;

  /// No description provided for @visitRegInvalidMember.
  ///
  /// In es, this message translates to:
  /// **'El integrante no tiene identificador válido.'**
  String get visitRegInvalidMember;

  /// No description provided for @visitRegSaved.
  ///
  /// In es, this message translates to:
  /// **'Visita registrada'**
  String get visitRegSaved;

  /// No description provided for @visitRegSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar la visita.'**
  String get visitRegSaveFailed;

  /// No description provided for @visitRegSelectOption.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una opción'**
  String get visitRegSelectOption;

  /// No description provided for @visitRegDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de la visita *'**
  String get visitRegDate;

  /// No description provided for @visitRegPlace.
  ///
  /// In es, this message translates to:
  /// **'Lugar de la visita *'**
  String get visitRegPlace;

  /// No description provided for @visitRegSelectPlace.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el lugar'**
  String get visitRegSelectPlace;

  /// No description provided for @visitRegDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración aproximada de la visita'**
  String get visitRegDuration;

  /// No description provided for @visitRegDurationHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 30 min, 1 hora'**
  String get visitRegDurationHint;

  /// No description provided for @visitRegPrayerTitle.
  ///
  /// In es, this message translates to:
  /// **'Se realizó oración *'**
  String get visitRegPrayerTitle;

  /// No description provided for @visitRegPrayerRequests.
  ///
  /// In es, this message translates to:
  /// **'Peticiones de oración'**
  String get visitRegPrayerRequests;

  /// No description provided for @visitRegPrayerRequestsHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional: motivos o peticiones compartidas'**
  String get visitRegPrayerRequestsHint;

  /// No description provided for @visitRegFollowUpTitle.
  ///
  /// In es, this message translates to:
  /// **'Necesita seguimiento *'**
  String get visitRegFollowUpTitle;

  /// No description provided for @visitRegSpiritualState.
  ///
  /// In es, this message translates to:
  /// **'Estado espiritual (opcional)'**
  String get visitRegSpiritualState;

  /// No description provided for @visitRegSpiritualUnspecified.
  ///
  /// In es, this message translates to:
  /// **'Sin especificar'**
  String get visitRegSpiritualUnspecified;

  /// No description provided for @visitRegComment.
  ///
  /// In es, this message translates to:
  /// **'Comentario *'**
  String get visitRegComment;

  /// No description provided for @visitRegCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Resumen de la visita, temas tratados...'**
  String get visitRegCommentHint;

  /// No description provided for @visitRegCommentRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un comentario'**
  String get visitRegCommentRequired;

  /// No description provided for @visitRegSaveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar visita'**
  String get visitRegSaveButton;

  /// No description provided for @addressAutocompleteApiKey.
  ///
  /// In es, this message translates to:
  /// **'Configura la API key de Google Maps en maps_api_key.dart'**
  String get addressAutocompleteApiKey;

  /// No description provided for @addressAutocompleteLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar sugerencias de Google Maps.'**
  String get addressAutocompleteLoadError;

  /// No description provided for @leaderNoLeaderAssigned.
  ///
  /// In es, this message translates to:
  /// **'Sin líder asignado'**
  String get leaderNoLeaderAssigned;

  /// No description provided for @leaderFallbackName.
  ///
  /// In es, this message translates to:
  /// **'Líder'**
  String get leaderFallbackName;

  /// No description provided for @serviceGenericError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado. Intenta de nuevo.'**
  String get serviceGenericError;

  /// No description provided for @serviceUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Servicio no disponible. Revisa tu conexión.'**
  String get serviceUnavailable;

  /// No description provided for @servicePermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para esta operación.'**
  String get servicePermissionDenied;

  /// No description provided for @visitServicePermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para registrar visitas.'**
  String get visitServicePermissionDenied;

  /// No description provided for @visitServiceSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar la visita. Intenta de nuevo.'**
  String get visitServiceSaveError;

  /// No description provided for @visitDashboardPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para ver el dashboard de visitas.'**
  String get visitDashboardPermissionDenied;

  /// No description provided for @visitDashboardIndexBuilding.
  ///
  /// In es, this message translates to:
  /// **'El índice de visitas se está creando en Firebase. Espera unos minutos e intenta de nuevo.'**
  String get visitDashboardIndexBuilding;

  /// No description provided for @visitDashboardIndexMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta un índice en Firestore para visitas. Ejecuta: firebase deploy --only firestore:indexes'**
  String get visitDashboardIndexMissing;

  /// No description provided for @visitDashboardDateFormatError.
  ///
  /// In es, this message translates to:
  /// **'Error al formatear fechas en el gráfico. Reinicia la app e intenta de nuevo.'**
  String get visitDashboardDateFormatError;

  /// No description provided for @visitDashboardLoadUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado al cargar visitas ({code}).'**
  String visitDashboardLoadUnexpected(String code);

  /// No description provided for @visitDashboardLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar visitas: {message}'**
  String visitDashboardLoadError(String message);

  /// No description provided for @churchOfficePastor.
  ///
  /// In es, this message translates to:
  /// **'Pastor'**
  String get churchOfficePastor;

  /// No description provided for @churchOfficeLeader.
  ///
  /// In es, this message translates to:
  /// **'Líderes'**
  String get churchOfficeLeader;

  /// No description provided for @churchOfficeJuniorElder.
  ///
  /// In es, this message translates to:
  /// **'Anciano menor'**
  String get churchOfficeJuniorElder;

  /// No description provided for @churchOfficeElder.
  ///
  /// In es, this message translates to:
  /// **'Anciano'**
  String get churchOfficeElder;

  /// No description provided for @churchOfficeSeniorElder.
  ///
  /// In es, this message translates to:
  /// **'Anciano mayor'**
  String get churchOfficeSeniorElder;

  /// No description provided for @churchOfficeVolunteer.
  ///
  /// In es, this message translates to:
  /// **'Voluntario'**
  String get churchOfficeVolunteer;

  /// No description provided for @assignableRolesRegistrarExclusive.
  ///
  /// In es, this message translates to:
  /// **'El rol Registrador es exclusivo: no se puede combinar con otros.'**
  String get assignableRolesRegistrarExclusive;

  /// No description provided for @assignableRolesHint.
  ///
  /// In es, this message translates to:
  /// **'Marca los permisos de acceso en la aplicación. Puedes combinar Líder y Supervisor en la misma cuenta. El rol Registrador debe ir solo.'**
  String get assignableRolesHint;

  /// No description provided for @adminsDenied.
  ///
  /// In es, this message translates to:
  /// **'Solo el super administrador puede gestionar administradores.'**
  String get adminsDenied;

  /// No description provided for @adminsTitle.
  ///
  /// In es, this message translates to:
  /// **'Administradores'**
  String get adminsTitle;

  /// No description provided for @adminsNoChurch.
  ///
  /// In es, this message translates to:
  /// **'Sin iglesia asignada'**
  String get adminsNoChurch;

  /// No description provided for @adminsChurchLabel.
  ///
  /// In es, this message translates to:
  /// **'Iglesia ({id})'**
  String adminsChurchLabel(String id);

  /// No description provided for @adminsBlockTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloquear administrador'**
  String get adminsBlockTitle;

  /// No description provided for @adminsUnblockTitle.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear administrador'**
  String get adminsUnblockTitle;

  /// No description provided for @adminsBlockConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Bloquear a \"{name}\"? No podrá iniciar sesión hasta que lo desbloquees.'**
  String adminsBlockConfirm(String name);

  /// No description provided for @adminsUnblockConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Desbloquear a \"{name}\" y permitir el acceso de nuevo?'**
  String adminsUnblockConfirm(String name);

  /// No description provided for @adminsBlocked.
  ///
  /// In es, this message translates to:
  /// **'Administrador bloqueado'**
  String get adminsBlocked;

  /// No description provided for @adminsUnblocked.
  ///
  /// In es, this message translates to:
  /// **'Administrador desbloqueado'**
  String get adminsUnblocked;

  /// No description provided for @adminsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar los administradores. Verifica Firestore y el índice de la colección \"users\".'**
  String get adminsLoadError;

  /// No description provided for @adminsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay administradores registrados'**
  String get adminsEmpty;

  /// No description provided for @adminsRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar administrador'**
  String get adminsRegister;

  /// No description provided for @adminsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, correo o iglesia…'**
  String get adminsSearchHint;

  /// No description provided for @adminsShowBlocked.
  ///
  /// In es, this message translates to:
  /// **'Mostrar bloqueados ({count})'**
  String adminsShowBlocked(int count);

  /// No description provided for @adminsHideBlocked.
  ///
  /// In es, this message translates to:
  /// **'Ocultar bloqueados ({count})'**
  String adminsHideBlocked(int count);

  /// No description provided for @adminsAllBlocked.
  ///
  /// In es, this message translates to:
  /// **'Todos los administradores están bloqueados'**
  String get adminsAllBlocked;

  /// No description provided for @churchesDenied.
  ///
  /// In es, this message translates to:
  /// **'Solo el super administrador puede gestionar iglesias.'**
  String get churchesDenied;

  /// No description provided for @churchesTitle.
  ///
  /// In es, this message translates to:
  /// **'Iglesias'**
  String get churchesTitle;

  /// No description provided for @churchesBlockTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloquear iglesia'**
  String get churchesBlockTitle;

  /// No description provided for @churchesUnblockTitle.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear iglesia'**
  String get churchesUnblockTitle;

  /// No description provided for @churchesBlockConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Bloquear \"{name}\"? No se podrá asignar a nuevos administradores hasta que la desbloquees.'**
  String churchesBlockConfirm(String name);

  /// No description provided for @churchesUnblockConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Desbloquear \"{name}\" y volver a permitir su uso?'**
  String churchesUnblockConfirm(String name);

  /// No description provided for @churchesBlocked.
  ///
  /// In es, this message translates to:
  /// **'Iglesia bloqueada'**
  String get churchesBlocked;

  /// No description provided for @churchesUnblocked.
  ///
  /// In es, this message translates to:
  /// **'Iglesia desbloqueada'**
  String get churchesUnblocked;

  /// No description provided for @churchesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar las iglesias. Verifica Firestore y las reglas de la colección \"churches\".'**
  String get churchesLoadError;

  /// No description provided for @churchesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay iglesias registradas'**
  String get churchesEmpty;

  /// No description provided for @churchesRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar iglesia'**
  String get churchesRegister;

  /// No description provided for @churchesSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o dirección…'**
  String get churchesSearchHint;

  /// No description provided for @churchesShowBlocked.
  ///
  /// In es, this message translates to:
  /// **'Mostrar bloqueadas ({count})'**
  String churchesShowBlocked(int count);

  /// No description provided for @churchesHideBlocked.
  ///
  /// In es, this message translates to:
  /// **'Ocultar bloqueadas ({count})'**
  String churchesHideBlocked(int count);

  /// No description provided for @churchesAllBlocked.
  ///
  /// In es, this message translates to:
  /// **'Todas las iglesias están bloqueadas'**
  String get churchesAllBlocked;

  /// No description provided for @churchRegLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar los datos de la iglesia.'**
  String get churchRegLoadError;

  /// No description provided for @churchRegPickAddress.
  ///
  /// In es, this message translates to:
  /// **'Elige una dirección de la lista para ubicarla en el mapa'**
  String get churchRegPickAddress;

  /// No description provided for @churchRegImageError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo seleccionar la imagen: {error}'**
  String churchRegImageError(String error);

  /// No description provided for @churchRegSaved.
  ///
  /// In es, this message translates to:
  /// **'Iglesia registrada'**
  String get churchRegSaved;

  /// No description provided for @churchRegUpdated.
  ///
  /// In es, this message translates to:
  /// **'Datos de la iglesia guardados'**
  String get churchRegUpdated;

  /// No description provided for @churchRegNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva iglesia'**
  String get churchRegNewTitle;

  /// No description provided for @churchRegViewTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de la iglesia'**
  String get churchRegViewTitle;

  /// No description provided for @churchRegEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar iglesia'**
  String get churchRegEditTitle;

  /// No description provided for @churchRegCreateDenied.
  ///
  /// In es, this message translates to:
  /// **'Solo el super administrador puede crear iglesias.'**
  String get churchRegCreateDenied;

  /// No description provided for @churchRegViewDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para ver los datos de esta iglesia.'**
  String get churchRegViewDenied;

  /// No description provided for @churchRegEditDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para editar los datos de esta iglesia.'**
  String get churchRegEditDenied;

  /// No description provided for @churchRegBlocked.
  ///
  /// In es, this message translates to:
  /// **'Esta iglesia está bloqueada. Contacta al super administrador para reactivarla.'**
  String get churchRegBlocked;

  /// No description provided for @churchRegLogo.
  ///
  /// In es, this message translates to:
  /// **'LOGO'**
  String get churchRegLogo;

  /// No description provided for @churchRegLogoOptional.
  ///
  /// In es, this message translates to:
  /// **'LOGO (opcional)'**
  String get churchRegLogoOptional;

  /// No description provided for @churchRegLogoHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes guardar sin logo; se usará el predeterminado.'**
  String get churchRegLogoHint;

  /// No description provided for @churchRegUploadLogo.
  ///
  /// In es, this message translates to:
  /// **'Subir logo'**
  String get churchRegUploadLogo;

  /// No description provided for @churchRegRemoveLogo.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get churchRegRemoveLogo;

  /// No description provided for @churchRegSectionInfo.
  ///
  /// In es, this message translates to:
  /// **'INFORMACIÓN'**
  String get churchRegSectionInfo;

  /// No description provided for @churchRegName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la iglesia'**
  String get churchRegName;

  /// No description provided for @churchRegNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la iglesia *'**
  String get churchRegNameRequired;

  /// No description provided for @churchRegNameValidation.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el nombre'**
  String get churchRegNameValidation;

  /// No description provided for @churchRegAddressSection.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get churchRegAddressSection;

  /// No description provided for @churchSearchLabel.
  ///
  /// In es, this message translates to:
  /// **'Iglesia *'**
  String get churchSearchLabel;

  /// No description provided for @churchSearchClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar selección'**
  String get churchSearchClear;

  /// No description provided for @churchSearchTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar iglesia'**
  String get churchSearchTitle;

  /// No description provided for @churchSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o dirección…'**
  String get churchSearchHint;

  /// No description provided for @churchSearchEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay iglesias disponibles'**
  String get churchSearchEmpty;

  /// No description provided for @churchSearchNoMatches.
  ///
  /// In es, this message translates to:
  /// **'No hay coincidencias para \"{query}\"'**
  String churchSearchNoMatches(String query);

  /// No description provided for @changePasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrent.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual *'**
  String get changePasswordCurrent;

  /// No description provided for @changePasswordNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña *'**
  String get changePasswordNew;

  /// No description provided for @changePasswordConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña *'**
  String get changePasswordConfirm;

  /// No description provided for @changePasswordCurrentRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña actual'**
  String get changePasswordCurrentRequired;

  /// No description provided for @changePasswordNewRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la nueva contraseña'**
  String get changePasswordNewRequired;

  /// No description provided for @changePasswordConfirmRequired.
  ///
  /// In es, this message translates to:
  /// **'Confirma la nueva contraseña'**
  String get changePasswordConfirmRequired;

  /// No description provided for @changePasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get changePasswordMismatch;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In es, this message translates to:
  /// **'Actualizar contraseña'**
  String get changePasswordSubmit;

  /// No description provided for @editPersonalDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get editPersonalDataTitle;

  /// No description provided for @editPersonalDataSaved.
  ///
  /// In es, this message translates to:
  /// **'Datos guardados'**
  String get editPersonalDataSaved;

  /// No description provided for @editPersonalDataRoles.
  ///
  /// In es, this message translates to:
  /// **'Roles en el sistema'**
  String get editPersonalDataRoles;

  /// No description provided for @pushChannelName.
  ///
  /// In es, this message translates to:
  /// **'Asignación de integrantes'**
  String get pushChannelName;

  /// No description provided for @pushChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Avisos cuando te asignan un integrante'**
  String get pushChannelDescription;

  /// No description provided for @authCreateUserFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear el usuario'**
  String get authCreateUserFailed;

  /// No description provided for @firestoreLeaderNotFound.
  ///
  /// In es, this message translates to:
  /// **'El líder ya no existe.'**
  String get firestoreLeaderNotFound;

  /// No description provided for @leaderRegNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo líder'**
  String get leaderRegNewTitle;

  /// No description provided for @leaderRegEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar líder'**
  String get leaderRegEditTitle;

  /// No description provided for @leaderRegSelectChurchOffice.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el cargo en la iglesia'**
  String get leaderRegSelectChurchOffice;

  /// No description provided for @leaderRegSelectAtLeastOneRole.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un rol en la app'**
  String get leaderRegSelectAtLeastOneRole;

  /// No description provided for @leaderRegSuccessWithLogin.
  ///
  /// In es, this message translates to:
  /// **'Líder registrado. Puede ingresar con su correo y contraseña.'**
  String get leaderRegSuccessWithLogin;

  /// No description provided for @leaderRegUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Líder actualizado correctamente'**
  String get leaderRegUpdatedSuccess;

  /// No description provided for @leaderRegEditDenied.
  ///
  /// In es, this message translates to:
  /// **'Solo el administrador puede editar líderes.'**
  String get leaderRegEditDenied;

  /// No description provided for @leaderRegRegisterDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para registrar líderes.'**
  String get leaderRegRegisterDenied;

  /// No description provided for @leaderRegSectionChurchOffice.
  ///
  /// In es, this message translates to:
  /// **'CARGO EN LA IGLESIA'**
  String get leaderRegSectionChurchOffice;

  /// No description provided for @leaderRegChurchOffice.
  ///
  /// In es, this message translates to:
  /// **'Cargo *'**
  String get leaderRegChurchOffice;

  /// No description provided for @leaderRegSelectChurchOfficeField.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el cargo'**
  String get leaderRegSelectChurchOfficeField;

  /// No description provided for @leaderRegNoAccessAccountHint.
  ///
  /// In es, this message translates to:
  /// **'Sin cuenta de acceso: los roles se aplicarán cuando se cree el usuario.'**
  String get leaderRegNoAccessAccountHint;

  /// No description provided for @leaderRegCell.
  ///
  /// In es, this message translates to:
  /// **'Célula'**
  String get leaderRegCell;

  /// No description provided for @leaderRegCellHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Ñ10, E4, L4'**
  String get leaderRegCellHint;

  /// No description provided for @leaderRegMobileRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el celular'**
  String get leaderRegMobileRequired;

  /// No description provided for @leaderRegSectionAppAccess.
  ///
  /// In es, this message translates to:
  /// **'ACCESO A LA APP'**
  String get leaderRegSectionAppAccess;

  /// No description provided for @leaderRegEmailLoginHint.
  ///
  /// In es, this message translates to:
  /// **'El líder ingresará con su correo como usuario.'**
  String get leaderRegEmailLoginHint;

  /// No description provided for @leaderRegEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo (usuario de acceso)'**
  String get leaderRegEmailLabel;

  /// No description provided for @leaderRegEmailLabelRequired.
  ///
  /// In es, this message translates to:
  /// **'Correo (usuario de acceso) *'**
  String get leaderRegEmailLabelRequired;

  /// No description provided for @leaderRegEmailLockedHelper.
  ///
  /// In es, this message translates to:
  /// **'La cuenta ya fue creada; el correo no se puede cambiar aquí'**
  String get leaderRegEmailLockedHelper;

  /// No description provided for @leaderRegEmailLoginHelper.
  ///
  /// In es, this message translates to:
  /// **'Será el usuario para iniciar sesión'**
  String get leaderRegEmailLoginHelper;

  /// No description provided for @leaderRegEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el correo del líder'**
  String get leaderRegEmailRequired;

  /// No description provided for @leaderRegPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una contraseña'**
  String get leaderRegPasswordRequired;

  /// No description provided for @leaderRegSubmitButton.
  ///
  /// In es, this message translates to:
  /// **'Registrar líder'**
  String get leaderRegSubmitButton;

  /// No description provided for @leaderRegLastName.
  ///
  /// In es, this message translates to:
  /// **'Apellido *'**
  String get leaderRegLastName;

  /// No description provided for @leaderRegLastNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el apellido'**
  String get leaderRegLastNameRequired;

  /// No description provided for @leaderRegFirstNames.
  ///
  /// In es, this message translates to:
  /// **'Nombres *'**
  String get leaderRegFirstNames;

  /// No description provided for @leaderRegFirstNamesRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los nombres'**
  String get leaderRegFirstNamesRequired;

  /// No description provided for @leaderRegBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get leaderRegBirthDate;

  /// No description provided for @leaderRegAge.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get leaderRegAge;

  /// No description provided for @adminRegNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo administrador'**
  String get adminRegNewTitle;

  /// No description provided for @adminRegEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar administrador'**
  String get adminRegEditTitle;

  /// No description provided for @adminRegNoChurches.
  ///
  /// In es, this message translates to:
  /// **'No hay iglesias activas. Crea una o desbloquea una existente.'**
  String get adminRegNoChurches;

  /// No description provided for @adminRegCreateChurch.
  ///
  /// In es, this message translates to:
  /// **'Crear iglesia'**
  String get adminRegCreateChurch;

  /// No description provided for @adminRegSelectChurch.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una iglesia'**
  String get adminRegSelectChurch;

  /// No description provided for @adminRegNewChurch.
  ///
  /// In es, this message translates to:
  /// **'Nueva iglesia'**
  String get adminRegNewChurch;

  /// No description provided for @adminRegChurchCreated.
  ///
  /// In es, this message translates to:
  /// **'Iglesia creada. Selecciónala en la lista.'**
  String get adminRegChurchCreated;

  /// No description provided for @adminRegSelectChurchForAdmin.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la iglesia para este administrador.'**
  String get adminRegSelectChurchForAdmin;

  /// No description provided for @adminRegUpdated.
  ///
  /// In es, this message translates to:
  /// **'Administrador actualizado'**
  String get adminRegUpdated;

  /// No description provided for @adminRegSuccess.
  ///
  /// In es, this message translates to:
  /// **'Administrador registrado correctamente'**
  String get adminRegSuccess;

  /// No description provided for @adminRegSaveProfileError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar el perfil.'**
  String get adminRegSaveProfileError;

  /// No description provided for @adminRegRegisterError.
  ///
  /// In es, this message translates to:
  /// **'Error al registrar: {error}'**
  String adminRegRegisterError(String error);

  /// No description provided for @adminRegEditDenied.
  ///
  /// In es, this message translates to:
  /// **'Solo el super administrador puede editar administradores.'**
  String get adminRegEditDenied;

  /// No description provided for @adminRegRegisterDenied.
  ///
  /// In es, this message translates to:
  /// **'Solo el super administrador puede registrar administradores de iglesia.'**
  String get adminRegRegisterDenied;

  /// No description provided for @adminRegSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'CUENTA'**
  String get adminRegSectionAccount;

  /// No description provided for @adminRegEmailLockedHelper.
  ///
  /// In es, this message translates to:
  /// **'El correo de inicio de sesión no se puede cambiar desde aquí.'**
  String get adminRegEmailLockedHelper;

  /// No description provided for @adminRegSectionChurch.
  ///
  /// In es, this message translates to:
  /// **'IGLESIA ASIGNADA'**
  String get adminRegSectionChurch;

  /// No description provided for @adminRegChurchHint.
  ///
  /// In es, this message translates to:
  /// **'Este administrador solo gestionará la iglesia seleccionada.'**
  String get adminRegChurchHint;

  /// No description provided for @adminRegPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la contraseña'**
  String get adminRegPasswordRequired;

  /// No description provided for @adminRegRegisterButton.
  ///
  /// In es, this message translates to:
  /// **'Registrar administrador'**
  String get adminRegRegisterButton;

  /// No description provided for @editPersonalDataSectionName.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE'**
  String get editPersonalDataSectionName;

  /// No description provided for @editPersonalDataSectionContact.
  ///
  /// In es, this message translates to:
  /// **'CONTACTO'**
  String get editPersonalDataSectionContact;

  /// No description provided for @churchServiceStorageNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'Firebase Storage no está activo en el proyecto. En Firebase Console → Storage, pulsa \"Comenzar\", elige ubicación y vuelve a subir el logo.'**
  String get churchServiceStorageNotConfigured;

  /// No description provided for @churchServicePermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar iglesias.'**
  String get churchServicePermissionDenied;

  /// No description provided for @churchServiceNotFound.
  ///
  /// In es, this message translates to:
  /// **'La iglesia ya no existe.'**
  String get churchServiceNotFound;

  /// No description provided for @churchServiceUploadUnauthorized.
  ///
  /// In es, this message translates to:
  /// **'No autorizado para subir el logo. Revisa las reglas de Storage.'**
  String get churchServiceUploadUnauthorized;

  /// No description provided for @churchServiceAppCheckError.
  ///
  /// In es, this message translates to:
  /// **'App Check no configurado. En desarrollo: busca en logcat \"App Check debug token\", regístralo en Firebase Console → App Check → Android, cierra la app y vuelve a abrirla.'**
  String get churchServiceAppCheckError;

  /// No description provided for @churchServiceAppCheckThrottled.
  ///
  /// In es, this message translates to:
  /// **'App Check bloqueado por demasiados intentos. Espera 15 minutos, registra el token de depuración en Firebase Console, o desactiva temporalmente App Check en Storage.'**
  String get churchServiceAppCheckThrottled;

  /// No description provided for @churchServiceSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {message}'**
  String churchServiceSaveError(String message);

  /// No description provided for @userProfileAdminPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar administradores.'**
  String get userProfileAdminPermissionDenied;

  /// No description provided for @userProfileError.
  ///
  /// In es, this message translates to:
  /// **'Error: {message}'**
  String userProfileError(String message);

  /// No description provided for @supervisorServicePermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para asignar líderes a supervisores.'**
  String get supervisorServicePermissionDenied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
