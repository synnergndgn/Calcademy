enum SavedCalculationsIssue {
  storageRead,
  storageWrite,
  invalidSchema,
  invalidPayload,
  itemLimit,
  titleTooLong,
  summaryTooLong,
  payloadTooLarge,
  searchQueryTooLong,
  unknownModule,
}

class SavedCalculationsException implements Exception {
  const SavedCalculationsException(this.issue, [this.cause]);

  final SavedCalculationsIssue issue;
  final Object? cause;
}
