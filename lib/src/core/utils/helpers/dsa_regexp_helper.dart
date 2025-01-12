class DsaRegexpHelper {
  DsaRegexpHelper._();
  static RegExp simActivationSuccessfullyRegExp =
      RegExp(r'La carte SIM (\d+) est activee, avec le numero (2136\d{8})');
  static RegExp activationInProgressRegExp = RegExp(r'Activation en cours');
  static RegExp simAlreadyActivatedRegExp = RegExp(r'SIM deja active avec MSISDN (\d{12})');
}
