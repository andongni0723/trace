import 'package:drift/drift.dart';

import '../../../features/media_library/data/models/media_asset_kind.dart';

class MediaAssets extends Table {
  TextColumn get id => text()();

  TextColumn get displayName => text().withLength(min: 1, max: 160)();

  TextColumn get originalFileName => text().withLength(min: 1, max: 255)();

  TextColumn get kind => textEnum<MediaAssetKind>()();

  TextColumn get mimeType => text().nullable()();

  IntColumn get sizeBytes => integer()();

  TextColumn get filePath => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
