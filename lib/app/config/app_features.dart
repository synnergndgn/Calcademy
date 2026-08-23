/// Build-time switches for modules that are finished in the tree but held back
/// from a release.
abstract final class AppFeatures {
  /// The Quiz/Testler practice module, held out of the 1.10.1 production
  /// release. The feature, its routes and its tests all stay in the tree; only
  /// the home surfaces that lead to it are withdrawn, so putting the section
  /// back is this one flag.
  static const practiceEnabled = false;
}
