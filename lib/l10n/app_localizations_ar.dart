// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'الموزّع';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'سجّل دخولك للمتابعة';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الموبايل';

  @override
  String get emailRequired => 'الرجاء إدخال البريد الإلكتروني';

  @override
  String get passwordRequired => 'الرجاء إدخال كلمة المرور';

  @override
  String get nameRequired => 'الرجاء إدخال الاسم';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get checkEmailForReset =>
      'تحقق من بريدك الإلكتروني لروابط إعادة التعيين';

  @override
  String get loginError => 'البريد الإلكتروني أو كلمة المرور خاطئة';

  @override
  String get verificationRequired => 'التحقق من البريد الإلكتروني مطلوب';

  @override
  String get verificationSent => 'تم إرسال رمز التحقق إلى بريدك الإلكتروني';

  @override
  String get verifyEmail => 'تحقق من البريد الإلكتروني';

  @override
  String get enterVerificationCode => 'أدخل الرمز المكون من 6 أرقام';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get codeExpired => 'انتهت صلاحية الرمز، يرجى طلب رمز جديد';

  @override
  String get invalidCode => 'رمز التحقق غير صحيح';

  @override
  String get emailVerified => 'تم التحقق من البريد الإلكتروني بنجاح!';

  @override
  String get home => 'الرئيسية';

  @override
  String get search => 'بحث';

  @override
  String get messages => 'رسائل';

  @override
  String get profile => 'حسابي';

  @override
  String get all => 'الكل';

  @override
  String get add => 'إضافة';

  @override
  String get noListings => 'مفيش إعلانات دلوقتي';

  @override
  String get noSearchResults => 'لا توجد نتائج';

  @override
  String listingsCount(int count) {
    return '$count إعلان';
  }

  @override
  String get myListings => 'إعلاناتي';

  @override
  String get favorites => 'المحفوظات';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get help => 'المساعدة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get views => 'مشاهدة';

  @override
  String get messagesCount => 'رسائل';

  @override
  String get loginToViewProfile => 'سجّل دخولك لعرض حسابك';

  @override
  String get loginToViewProfileDesc =>
      'محتاج تسجيل دخول عشان تشوف بروفايلك وإعلاناتك';

  @override
  String get activateEmail => 'فعّل بريدك الإلكتروني للمتابعة';

  @override
  String get activateEmailDesc =>
      'أرسلنا كود مكوّن من 6 أرقام إلى بريدك. فعّله لفتح الحساب.';

  @override
  String get activateNow => 'تفعيل الآن';

  @override
  String get title => 'العنوان';

  @override
  String get description => 'الوصف';

  @override
  String get category => 'التصنيف';

  @override
  String get type => 'النوع';

  @override
  String get price => 'السعر';

  @override
  String get location => 'الموقع';

  @override
  String get serviceType => 'نوع الخدمة';

  @override
  String get productType => 'نوع المنتج';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get publish => 'نشر';

  @override
  String get publishSuccess => 'تم النشر بنجاح!';

  @override
  String get publishFailed => 'فشل النشر، حاول تاني';

  @override
  String get delete => 'حذف';

  @override
  String get deleteConfirm => 'هل أنت متأكد من الحذف؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get edit => 'تعديل';

  @override
  String get searchHint => 'ابحث عن الخدمات...';

  @override
  String get professionalServices => 'خدمات مهنية';

  @override
  String get manufacturing => 'صناعة وتصنيع';

  @override
  String get contracting => 'مقاولات';

  @override
  String get logistics => 'نقل ولوجستيات';
}
