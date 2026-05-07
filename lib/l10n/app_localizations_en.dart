// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'El Moza3';

  @override
  String get login => 'Log In';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get register => 'Sign Up';

  @override
  String get logout => 'Log Out';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get emailRequired => 'Please enter your email.';

  @override
  String get passwordRequired => 'Please enter your password.';

  @override
  String get nameRequired => 'Please enter your name.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get checkEmailForReset => 'Check your email for password reset link';

  @override
  String get loginError => 'Invalid email or password';

  @override
  String get verificationRequired => 'Email verification required';

  @override
  String get verificationSent => 'Verification code sent to your email';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get enterVerificationCode => 'Enter the 6-digit code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get codeExpired => 'Code expired, please request a new one';

  @override
  String get invalidCode => 'Invalid verification code';

  @override
  String get emailVerified => 'Email verified successfully!';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get all => 'All';

  @override
  String get add => 'Add';

  @override
  String get noListings => 'No listings available';

  @override
  String get noSearchResults => 'No results found';

  @override
  String listingsCount(int count) {
    return '$count listings';
  }

  @override
  String get myListings => 'My Listings';

  @override
  String get favorites => 'Favorites';

  @override
  String get notifications => 'Notifications';

  @override
  String get help => 'Help';

  @override
  String get settings => 'Settings';

  @override
  String get views => 'Views';

  @override
  String get messagesCount => 'Messages';

  @override
  String get loginToViewProfile => 'Sign in to view your profile';

  @override
  String get loginToViewProfileDesc =>
      'Please login to see your listings and messages';

  @override
  String get activateEmail => 'Activate your email to continue';

  @override
  String get activateEmailDesc =>
      'We\'ve sent a 6-digit code to your email. Activate it to access your account.';

  @override
  String get activateNow => 'Activate Now';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get type => 'Type';

  @override
  String get price => 'Price';

  @override
  String get location => 'Location';

  @override
  String get serviceType => 'Service Type';

  @override
  String get productType => 'Product Type';

  @override
  String get requiredField => 'This field is required';

  @override
  String get publish => 'Publish';

  @override
  String get publishSuccess => 'Published successfully!';

  @override
  String get publishFailed => 'Failed to publish, please try again';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirm => 'Are you sure you want to delete?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get searchHint => 'Search for services...';

  @override
  String get professionalServices => 'Professional Services';

  @override
  String get manufacturing => 'Manufacturing';

  @override
  String get contracting => 'Contracting';

  @override
  String get logistics => 'Logistics';
}
