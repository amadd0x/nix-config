# Time zone and language. mkDefault so a host can override.
# (LC_* categories fall back to the default locale, so they aren't set separately.)
{lib, ...}: {
  time.timeZone = lib.mkDefault "America/Chicago";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
}
