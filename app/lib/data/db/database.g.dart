// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta('pinnedAt');
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCollapsedMeta = const VerificationMeta('isCollapsed');
  @override
  late final GeneratedColumn<bool> isCollapsed = GeneratedColumn<bool>(
    'is_collapsed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_collapsed" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, name, pinnedAt, isCollapsed, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(Insertable<Folder> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('pinned_at')) {
      context.handle(_pinnedAtMeta, pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta));
    }
    if (data.containsKey('is_collapsed')) {
      context.handle(_isCollapsedMeta, isCollapsed.isAcceptableOrUnknown(data['is_collapsed']!, _isCollapsedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      pinnedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}pinned_at']),
      isCollapsed: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_collapsed'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String name;
  final DateTime? pinnedAt;
  final bool isCollapsed;
  final int sortOrder;
  const Folder({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    this.pinnedAt,
    required this.isCollapsed,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    map['is_collapsed'] = Variable<bool>(isCollapsed);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      name: Value(name),
      pinnedAt: pinnedAt == null && nullToAbsent ? const Value.absent() : Value(pinnedAt),
      isCollapsed: Value(isCollapsed),
      sortOrder: Value(sortOrder),
    );
  }

  factory Folder.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      isCollapsed: serializer.fromJson<bool>(json['isCollapsed']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'isCollapsed': serializer.toJson<bool>(isCollapsed),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Folder copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    Value<DateTime?> pinnedAt = const Value.absent(),
    bool? isCollapsed,
    int? sortOrder,
  }) => Folder(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    isCollapsed: isCollapsed ?? this.isCollapsed,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      isCollapsed: data.isCollapsed.present ? data.isCollapsed.value : this.isCollapsed,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('isCollapsed: $isCollapsed, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, name, pinnedAt, isCollapsed, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.pinnedAt == this.pinnedAt &&
          other.isCollapsed == this.isCollapsed &&
          other.sortOrder == this.sortOrder);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<DateTime?> pinnedAt;
  final Value<bool> isCollapsed;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.isCollapsed = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    this.pinnedAt = const Value.absent(),
    this.isCollapsed = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<Folder> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<DateTime>? pinnedAt,
    Expression<bool>? isCollapsed,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (isCollapsed != null) 'is_collapsed': isCollapsed,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<DateTime?>? pinnedAt,
    Value<bool>? isCollapsed,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (isCollapsed.present) {
      map['is_collapsed'] = Variable<bool>(isCollapsed.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('isCollapsed: $isCollapsed, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListsTable extends Lists with TableInfo<$ListsTable, TaskList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES folders (id)'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ListKind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(ListKind.tasks.code),
  ).withConverter<ListKind>($ListsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<ViewMode, String> viewMode = GeneratedColumn<String>(
    'view_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(ViewMode.list.code),
  ).withConverter<ViewMode>($ListsTable.$converterviewMode);
  static const VerificationMeta _showInSmartListsMeta = const VerificationMeta('showInSmartLists');
  @override
  late final GeneratedColumn<bool> showInSmartLists = GeneratedColumn<bool>(
    'show_in_smart_lists',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("show_in_smart_lists" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta('pinnedAt');
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Grouping, String> groupBy = GeneratedColumn<String>(
    'group_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(Grouping.custom.code),
  ).withConverter<Grouping>($ListsTable.$convertergroupBy);
  @override
  late final GeneratedColumnWithTypeConverter<Sorting, String> sortBy = GeneratedColumn<String>(
    'sort_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(Sorting.custom.code),
  ).withConverter<Sorting>($ListsTable.$convertersortBy);
  static const VerificationMeta _showCompletedMeta = const VerificationMeta('showCompleted');
  @override
  late final GeneratedColumn<bool> showCompleted = GeneratedColumn<bool>(
    'show_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("show_completed" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showDetailsMeta = const VerificationMeta('showDetails');
  @override
  late final GeneratedColumn<bool> showDetails = GeneratedColumn<bool>(
    'show_details',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("show_details" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dateAsCountdownMeta = const VerificationMeta('dateAsCountdown');
  @override
  late final GeneratedColumn<bool> dateAsCountdown = GeneratedColumn<bool>(
    'date_as_countdown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("date_as_countdown" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    emoji,
    color,
    folderId,
    kind,
    viewMode,
    showInSmartLists,
    pinnedAt,
    archivedAt,
    sortOrder,
    groupBy,
    sortBy,
    showCompleted,
    showDetails,
    dateAsCountdown,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lists';
  @override
  VerificationContext validateIntegrity(Insertable<TaskList> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(_emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta, folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    if (data.containsKey('show_in_smart_lists')) {
      context.handle(_showInSmartListsMeta, showInSmartLists.isAcceptableOrUnknown(data['show_in_smart_lists']!, _showInSmartListsMeta));
    }
    if (data.containsKey('pinned_at')) {
      context.handle(_pinnedAtMeta, pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(_archivedAtMeta, archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('show_completed')) {
      context.handle(_showCompletedMeta, showCompleted.isAcceptableOrUnknown(data['show_completed']!, _showCompletedMeta));
    }
    if (data.containsKey('show_details')) {
      context.handle(_showDetailsMeta, showDetails.isAcceptableOrUnknown(data['show_details']!, _showDetailsMeta));
    }
    if (data.containsKey('date_as_countdown')) {
      context.handle(_dateAsCountdownMeta, dateAsCountdown.isAcceptableOrUnknown(data['date_as_countdown']!, _dateAsCountdownMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskList(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      emoji: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}emoji']),
      color: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}color']),
      folderId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
      kind: $ListsTable.$converterkind.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      viewMode: $ListsTable.$converterviewMode.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}view_mode'])!),
      showInSmartLists: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}show_in_smart_lists'])!,
      pinnedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}pinned_at']),
      archivedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      groupBy: $ListsTable.$convertergroupBy.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}group_by'])!),
      sortBy: $ListsTable.$convertersortBy.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}sort_by'])!),
      showCompleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}show_completed'])!,
      showDetails: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}show_details'])!,
      dateAsCountdown: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}date_as_countdown'])!,
    );
  }

  @override
  $ListsTable createAlias(String alias) {
    return $ListsTable(attachedDatabase, alias);
  }

  static TypeConverter<ListKind, String> $converterkind = const TextCodeConverter<ListKind>(ListKind.fromCode);
  static TypeConverter<ViewMode, String> $converterviewMode = const TextCodeConverter<ViewMode>(ViewMode.fromCode);
  static TypeConverter<Grouping, String> $convertergroupBy = const TextCodeConverter<Grouping>(Grouping.fromCode);
  static TypeConverter<Sorting, String> $convertersortBy = const TextCodeConverter<Sorting>(Sorting.fromCode);
}

class TaskList extends DataClass implements Insertable<TaskList> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String name;
  final String? emoji;

  /// Hex color (`#RRGGBB`) or null ("none").
  final String? color;
  final String? folderId;
  final ListKind kind;
  final ViewMode viewMode;

  /// "Show in Smart List": whether the list's tasks appear in All/Today/Next 7 days.
  final bool showInSmartLists;
  final DateTime? pinnedAt;
  final DateTime? archivedAt;
  final int sortOrder;
  final Grouping groupBy;
  final Sorting sortBy;
  final bool showCompleted;
  final bool showDetails;
  final bool dateAsCountdown;
  const TaskList({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    this.emoji,
    this.color,
    this.folderId,
    required this.kind,
    required this.viewMode,
    required this.showInSmartLists,
    this.pinnedAt,
    this.archivedAt,
    required this.sortOrder,
    required this.groupBy,
    required this.sortBy,
    required this.showCompleted,
    required this.showDetails,
    required this.dateAsCountdown,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    {
      map['kind'] = Variable<String>($ListsTable.$converterkind.toSql(kind));
    }
    {
      map['view_mode'] = Variable<String>($ListsTable.$converterviewMode.toSql(viewMode));
    }
    map['show_in_smart_lists'] = Variable<bool>(showInSmartLists);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    {
      map['group_by'] = Variable<String>($ListsTable.$convertergroupBy.toSql(groupBy));
    }
    {
      map['sort_by'] = Variable<String>($ListsTable.$convertersortBy.toSql(sortBy));
    }
    map['show_completed'] = Variable<bool>(showCompleted);
    map['show_details'] = Variable<bool>(showDetails);
    map['date_as_countdown'] = Variable<bool>(dateAsCountdown);
    return map;
  }

  ListsCompanion toCompanion(bool nullToAbsent) {
    return ListsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      name: Value(name),
      emoji: emoji == null && nullToAbsent ? const Value.absent() : Value(emoji),
      color: color == null && nullToAbsent ? const Value.absent() : Value(color),
      folderId: folderId == null && nullToAbsent ? const Value.absent() : Value(folderId),
      kind: Value(kind),
      viewMode: Value(viewMode),
      showInSmartLists: Value(showInSmartLists),
      pinnedAt: pinnedAt == null && nullToAbsent ? const Value.absent() : Value(pinnedAt),
      archivedAt: archivedAt == null && nullToAbsent ? const Value.absent() : Value(archivedAt),
      sortOrder: Value(sortOrder),
      groupBy: Value(groupBy),
      sortBy: Value(sortBy),
      showCompleted: Value(showCompleted),
      showDetails: Value(showDetails),
      dateAsCountdown: Value(dateAsCountdown),
    );
  }

  factory TaskList.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskList(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      color: serializer.fromJson<String?>(json['color']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      kind: serializer.fromJson<ListKind>(json['kind']),
      viewMode: serializer.fromJson<ViewMode>(json['viewMode']),
      showInSmartLists: serializer.fromJson<bool>(json['showInSmartLists']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      groupBy: serializer.fromJson<Grouping>(json['groupBy']),
      sortBy: serializer.fromJson<Sorting>(json['sortBy']),
      showCompleted: serializer.fromJson<bool>(json['showCompleted']),
      showDetails: serializer.fromJson<bool>(json['showDetails']),
      dateAsCountdown: serializer.fromJson<bool>(json['dateAsCountdown']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String?>(emoji),
      'color': serializer.toJson<String?>(color),
      'folderId': serializer.toJson<String?>(folderId),
      'kind': serializer.toJson<ListKind>(kind),
      'viewMode': serializer.toJson<ViewMode>(viewMode),
      'showInSmartLists': serializer.toJson<bool>(showInSmartLists),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'groupBy': serializer.toJson<Grouping>(groupBy),
      'sortBy': serializer.toJson<Sorting>(sortBy),
      'showCompleted': serializer.toJson<bool>(showCompleted),
      'showDetails': serializer.toJson<bool>(showDetails),
      'dateAsCountdown': serializer.toJson<bool>(dateAsCountdown),
    };
  }

  TaskList copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    Value<String?> emoji = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> folderId = const Value.absent(),
    ListKind? kind,
    ViewMode? viewMode,
    bool? showInSmartLists,
    Value<DateTime?> pinnedAt = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    int? sortOrder,
    Grouping? groupBy,
    Sorting? sortBy,
    bool? showCompleted,
    bool? showDetails,
    bool? dateAsCountdown,
  }) => TaskList(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    emoji: emoji.present ? emoji.value : this.emoji,
    color: color.present ? color.value : this.color,
    folderId: folderId.present ? folderId.value : this.folderId,
    kind: kind ?? this.kind,
    viewMode: viewMode ?? this.viewMode,
    showInSmartLists: showInSmartLists ?? this.showInSmartLists,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    sortOrder: sortOrder ?? this.sortOrder,
    groupBy: groupBy ?? this.groupBy,
    sortBy: sortBy ?? this.sortBy,
    showCompleted: showCompleted ?? this.showCompleted,
    showDetails: showDetails ?? this.showDetails,
    dateAsCountdown: dateAsCountdown ?? this.dateAsCountdown,
  );
  TaskList copyWithCompanion(ListsCompanion data) {
    return TaskList(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      color: data.color.present ? data.color.value : this.color,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      kind: data.kind.present ? data.kind.value : this.kind,
      viewMode: data.viewMode.present ? data.viewMode.value : this.viewMode,
      showInSmartLists: data.showInSmartLists.present ? data.showInSmartLists.value : this.showInSmartLists,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      archivedAt: data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      groupBy: data.groupBy.present ? data.groupBy.value : this.groupBy,
      sortBy: data.sortBy.present ? data.sortBy.value : this.sortBy,
      showCompleted: data.showCompleted.present ? data.showCompleted.value : this.showCompleted,
      showDetails: data.showDetails.present ? data.showDetails.value : this.showDetails,
      dateAsCountdown: data.dateAsCountdown.present ? data.dateAsCountdown.value : this.dateAsCountdown,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskList(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('color: $color, ')
          ..write('folderId: $folderId, ')
          ..write('kind: $kind, ')
          ..write('viewMode: $viewMode, ')
          ..write('showInSmartLists: $showInSmartLists, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('groupBy: $groupBy, ')
          ..write('sortBy: $sortBy, ')
          ..write('showCompleted: $showCompleted, ')
          ..write('showDetails: $showDetails, ')
          ..write('dateAsCountdown: $dateAsCountdown')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    emoji,
    color,
    folderId,
    kind,
    viewMode,
    showInSmartLists,
    pinnedAt,
    archivedAt,
    sortOrder,
    groupBy,
    sortBy,
    showCompleted,
    showDetails,
    dateAsCountdown,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskList &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.color == this.color &&
          other.folderId == this.folderId &&
          other.kind == this.kind &&
          other.viewMode == this.viewMode &&
          other.showInSmartLists == this.showInSmartLists &&
          other.pinnedAt == this.pinnedAt &&
          other.archivedAt == this.archivedAt &&
          other.sortOrder == this.sortOrder &&
          other.groupBy == this.groupBy &&
          other.sortBy == this.sortBy &&
          other.showCompleted == this.showCompleted &&
          other.showDetails == this.showDetails &&
          other.dateAsCountdown == this.dateAsCountdown);
}

class ListsCompanion extends UpdateCompanion<TaskList> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String?> emoji;
  final Value<String?> color;
  final Value<String?> folderId;
  final Value<ListKind> kind;
  final Value<ViewMode> viewMode;
  final Value<bool> showInSmartLists;
  final Value<DateTime?> pinnedAt;
  final Value<DateTime?> archivedAt;
  final Value<int> sortOrder;
  final Value<Grouping> groupBy;
  final Value<Sorting> sortBy;
  final Value<bool> showCompleted;
  final Value<bool> showDetails;
  final Value<bool> dateAsCountdown;
  final Value<int> rowid;
  const ListsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.color = const Value.absent(),
    this.folderId = const Value.absent(),
    this.kind = const Value.absent(),
    this.viewMode = const Value.absent(),
    this.showInSmartLists = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.groupBy = const Value.absent(),
    this.sortBy = const Value.absent(),
    this.showCompleted = const Value.absent(),
    this.showDetails = const Value.absent(),
    this.dateAsCountdown = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    this.emoji = const Value.absent(),
    this.color = const Value.absent(),
    this.folderId = const Value.absent(),
    this.kind = const Value.absent(),
    this.viewMode = const Value.absent(),
    this.showInSmartLists = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    required int sortOrder,
    this.groupBy = const Value.absent(),
    this.sortBy = const Value.absent(),
    this.showCompleted = const Value.absent(),
    this.showDetails = const Value.absent(),
    this.dateAsCountdown = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<TaskList> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<String>? color,
    Expression<String>? folderId,
    Expression<String>? kind,
    Expression<String>? viewMode,
    Expression<bool>? showInSmartLists,
    Expression<DateTime>? pinnedAt,
    Expression<DateTime>? archivedAt,
    Expression<int>? sortOrder,
    Expression<String>? groupBy,
    Expression<String>? sortBy,
    Expression<bool>? showCompleted,
    Expression<bool>? showDetails,
    Expression<bool>? dateAsCountdown,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (color != null) 'color': color,
      if (folderId != null) 'folder_id': folderId,
      if (kind != null) 'kind': kind,
      if (viewMode != null) 'view_mode': viewMode,
      if (showInSmartLists != null) 'show_in_smart_lists': showInSmartLists,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (groupBy != null) 'group_by': groupBy,
      if (sortBy != null) 'sort_by': sortBy,
      if (showCompleted != null) 'show_completed': showCompleted,
      if (showDetails != null) 'show_details': showDetails,
      if (dateAsCountdown != null) 'date_as_countdown': dateAsCountdown,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String?>? emoji,
    Value<String?>? color,
    Value<String?>? folderId,
    Value<ListKind>? kind,
    Value<ViewMode>? viewMode,
    Value<bool>? showInSmartLists,
    Value<DateTime?>? pinnedAt,
    Value<DateTime?>? archivedAt,
    Value<int>? sortOrder,
    Value<Grouping>? groupBy,
    Value<Sorting>? sortBy,
    Value<bool>? showCompleted,
    Value<bool>? showDetails,
    Value<bool>? dateAsCountdown,
    Value<int>? rowid,
  }) {
    return ListsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      folderId: folderId ?? this.folderId,
      kind: kind ?? this.kind,
      viewMode: viewMode ?? this.viewMode,
      showInSmartLists: showInSmartLists ?? this.showInSmartLists,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      groupBy: groupBy ?? this.groupBy,
      sortBy: sortBy ?? this.sortBy,
      showCompleted: showCompleted ?? this.showCompleted,
      showDetails: showDetails ?? this.showDetails,
      dateAsCountdown: dateAsCountdown ?? this.dateAsCountdown,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($ListsTable.$converterkind.toSql(kind.value));
    }
    if (viewMode.present) {
      map['view_mode'] = Variable<String>($ListsTable.$converterviewMode.toSql(viewMode.value));
    }
    if (showInSmartLists.present) {
      map['show_in_smart_lists'] = Variable<bool>(showInSmartLists.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (groupBy.present) {
      map['group_by'] = Variable<String>($ListsTable.$convertergroupBy.toSql(groupBy.value));
    }
    if (sortBy.present) {
      map['sort_by'] = Variable<String>($ListsTable.$convertersortBy.toSql(sortBy.value));
    }
    if (showCompleted.present) {
      map['show_completed'] = Variable<bool>(showCompleted.value);
    }
    if (showDetails.present) {
      map['show_details'] = Variable<bool>(showDetails.value);
    }
    if (dateAsCountdown.present) {
      map['date_as_countdown'] = Variable<bool>(dateAsCountdown.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('color: $color, ')
          ..write('folderId: $folderId, ')
          ..write('kind: $kind, ')
          ..write('viewMode: $viewMode, ')
          ..write('showInSmartLists: $showInSmartLists, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('groupBy: $groupBy, ')
          ..write('sortBy: $sortBy, ')
          ..write('showCompleted: $showCompleted, ')
          ..write('showDetails: $showDetails, ')
          ..write('dateAsCountdown: $dateAsCountdown, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionsTable extends Sections with TableInfo<$SectionsTable, Section> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES lists (id)'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, listId, name, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sections';
  @override
  VerificationContext validateIntegrity(Insertable<Section> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta, listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Section map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Section(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      listId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}list_id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $SectionsTable createAlias(String alias) {
    return $SectionsTable(attachedDatabase, alias);
  }
}

class Section extends DataClass implements Insertable<Section> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String listId;
  final String name;
  final int sortOrder;
  const Section({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.listId,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['list_id'] = Variable<String>(listId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  SectionsCompanion toCompanion(bool nullToAbsent) {
    return SectionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      listId: Value(listId),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory Section.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Section(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      listId: serializer.fromJson<String>(json['listId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'listId': serializer.toJson<String>(listId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Section copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? listId,
    String? name,
    int? sortOrder,
  }) => Section(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    listId: listId ?? this.listId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Section copyWithCompanion(SectionsCompanion data) {
    return Section(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      listId: data.listId.present ? data.listId.value : this.listId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Section(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, listId, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Section &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.listId == this.listId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class SectionsCompanion extends UpdateCompanion<Section> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> listId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const SectionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.listId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String listId,
    required String name,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       listId = Value(listId),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<Section> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? listId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (listId != null) 'list_id': listId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? listId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return SectionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES lists (id)'),
  );
  static const VerificationMeta _sectionIdMeta = const VerificationMeta('sectionId');
  @override
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
    'section_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES sections (id)'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tasks (id)'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskKind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(TaskKind.text.code),
  ).withConverter<TaskKind>($TasksTable.$converterkind);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Priority, int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(Priority.none.code),
  ).withConverter<Priority>($TasksTable.$converterpriority);
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(TaskStatus.open.code),
  ).withConverter<TaskStatus>($TasksTable.$converterstatus);
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAllDayMeta = const VerificationMeta('isAllDay');
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_all_day" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta('timeZone');
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFloatingMeta = const VerificationMeta('isFloating');
  @override
  late final GeneratedColumn<bool> isFloating = GeneratedColumn<bool>(
    'is_floating',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_floating" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta('pinnedAt');
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta('repeatRule');
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatFromMeta = const VerificationMeta('repeatFrom');
  @override
  late final GeneratedColumn<String> repeatFrom = GeneratedColumn<String>(
    'repeat_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozeUntilMeta = const VerificationMeta('snoozeUntil');
  @override
  late final GeneratedColumn<DateTime> snoozeUntil = GeneratedColumn<DateTime>(
    'snooze_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedPomosMeta = const VerificationMeta('estimatedPomos');
  @override
  late final GeneratedColumn<int> estimatedPomos = GeneratedColumn<int>(
    'estimated_pomos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedMinutesMeta = const VerificationMeta('estimatedMinutes');
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
    'estimated_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    listId,
    sectionId,
    parentId,
    kind,
    title,
    content,
    priority,
    status,
    completedAt,
    startDate,
    dueDate,
    isAllDay,
    timeZone,
    isFloating,
    pinnedAt,
    progress,
    sortOrder,
    repeatRule,
    repeatFrom,
    snoozeUntil,
    estimatedPomos,
    estimatedMinutes,
    color,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta, listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta, sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta, parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta, content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(_completedAtMeta, completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta, startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta, dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('is_all_day')) {
      context.handle(_isAllDayMeta, isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta));
    }
    if (data.containsKey('time_zone')) {
      context.handle(_timeZoneMeta, timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta));
    }
    if (data.containsKey('is_floating')) {
      context.handle(_isFloatingMeta, isFloating.isAcceptableOrUnknown(data['is_floating']!, _isFloatingMeta));
    }
    if (data.containsKey('pinned_at')) {
      context.handle(_pinnedAtMeta, pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta, progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(_repeatRuleMeta, repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta));
    }
    if (data.containsKey('repeat_from')) {
      context.handle(_repeatFromMeta, repeatFrom.isAcceptableOrUnknown(data['repeat_from']!, _repeatFromMeta));
    }
    if (data.containsKey('snooze_until')) {
      context.handle(_snoozeUntilMeta, snoozeUntil.isAcceptableOrUnknown(data['snooze_until']!, _snoozeUntilMeta));
    }
    if (data.containsKey('estimated_pomos')) {
      context.handle(_estimatedPomosMeta, estimatedPomos.isAcceptableOrUnknown(data['estimated_pomos']!, _estimatedPomosMeta));
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(_estimatedMinutesMeta, estimatedMinutes.isAcceptableOrUnknown(data['estimated_minutes']!, _estimatedMinutesMeta));
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      listId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}list_id'])!,
      sectionId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}section_id']),
      parentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      kind: $TasksTable.$converterkind.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      priority: $TasksTable.$converterpriority.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}priority'])!),
      status: $TasksTable.$converterstatus.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      completedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      startDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}start_date']),
      dueDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      isAllDay: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_all_day'])!,
      timeZone: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}time_zone']),
      isFloating: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_floating'])!,
      pinnedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}pinned_at']),
      progress: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      repeatRule: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}repeat_rule']),
      repeatFrom: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}repeat_from']),
      snoozeUntil: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}snooze_until']),
      estimatedPomos: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}estimated_pomos']),
      estimatedMinutes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}estimated_minutes']),
      color: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}color']),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static TypeConverter<TaskKind, String> $converterkind = const TextCodeConverter<TaskKind>(TaskKind.fromCode);
  static TypeConverter<Priority, int> $converterpriority = const IntCodeConverter<Priority>(Priority.fromCode);
  static TypeConverter<TaskStatus, int> $converterstatus = const IntCodeConverter<TaskStatus>(TaskStatus.fromCode);
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String listId;
  final String? sectionId;

  /// Parent task when this is a subtask (up to 5 levels).
  final String? parentId;
  final TaskKind kind;
  final String title;

  /// Markdown content.
  final String content;
  final Priority priority;
  final TaskStatus status;
  final DateTime? completedAt;

  /// Start and due dates in UTC; for all-day tasks, local midnight of [timeZone] converted to UTC.
  final DateTime? startDate;
  final DateTime? dueDate;
  final bool isAllDay;
  final String? timeZone;

  /// Floating time ignores the time zone (a 9 AM task is at 9 AM in any zone).
  final bool isFloating;
  final DateTime? pinnedAt;

  /// Checklist progress, 0 to 100.
  final int progress;
  final int sortOrder;

  /// Repetition as an RRULE body (`FREQ=WEEKLY;BYDAY=TH`); `COUNT` = occurrences left (schema v2).
  final String? repeatRule;

  /// `dueDate` or `completion` (see `RepeatFrom`) (schema v2).
  final String? repeatFrom;

  /// A snoozed reminder fires again at this UTC time; the due date does not change (schema v3).
  final DateTime? snoozeUntil;

  /// "Estimativa": Pomos or minutes of focus the task should take; at most one is set
  /// (schema v13).
  final int? estimatedPomos;
  final int? estimatedMinutes;

  /// Its own color in the calendar (`#RRGGBB`, Google Calendar's event color), over the list's; null =
  /// the default (schema v17).
  final String? color;
  const Task({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.listId,
    this.sectionId,
    this.parentId,
    required this.kind,
    required this.title,
    required this.content,
    required this.priority,
    required this.status,
    this.completedAt,
    this.startDate,
    this.dueDate,
    required this.isAllDay,
    this.timeZone,
    required this.isFloating,
    this.pinnedAt,
    required this.progress,
    required this.sortOrder,
    this.repeatRule,
    this.repeatFrom,
    this.snoozeUntil,
    this.estimatedPomos,
    this.estimatedMinutes,
    this.color,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['list_id'] = Variable<String>(listId);
    if (!nullToAbsent || sectionId != null) {
      map['section_id'] = Variable<String>(sectionId);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    {
      map['kind'] = Variable<String>($TasksTable.$converterkind.toSql(kind));
    }
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    {
      map['priority'] = Variable<int>($TasksTable.$converterpriority.toSql(priority));
    }
    {
      map['status'] = Variable<int>($TasksTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    if (!nullToAbsent || timeZone != null) {
      map['time_zone'] = Variable<String>(timeZone);
    }
    map['is_floating'] = Variable<bool>(isFloating);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    map['progress'] = Variable<int>(progress);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    if (!nullToAbsent || repeatFrom != null) {
      map['repeat_from'] = Variable<String>(repeatFrom);
    }
    if (!nullToAbsent || snoozeUntil != null) {
      map['snooze_until'] = Variable<DateTime>(snoozeUntil);
    }
    if (!nullToAbsent || estimatedPomos != null) {
      map['estimated_pomos'] = Variable<int>(estimatedPomos);
    }
    if (!nullToAbsent || estimatedMinutes != null) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      listId: Value(listId),
      sectionId: sectionId == null && nullToAbsent ? const Value.absent() : Value(sectionId),
      parentId: parentId == null && nullToAbsent ? const Value.absent() : Value(parentId),
      kind: Value(kind),
      title: Value(title),
      content: Value(content),
      priority: Value(priority),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
      startDate: startDate == null && nullToAbsent ? const Value.absent() : Value(startDate),
      dueDate: dueDate == null && nullToAbsent ? const Value.absent() : Value(dueDate),
      isAllDay: Value(isAllDay),
      timeZone: timeZone == null && nullToAbsent ? const Value.absent() : Value(timeZone),
      isFloating: Value(isFloating),
      pinnedAt: pinnedAt == null && nullToAbsent ? const Value.absent() : Value(pinnedAt),
      progress: Value(progress),
      sortOrder: Value(sortOrder),
      repeatRule: repeatRule == null && nullToAbsent ? const Value.absent() : Value(repeatRule),
      repeatFrom: repeatFrom == null && nullToAbsent ? const Value.absent() : Value(repeatFrom),
      snoozeUntil: snoozeUntil == null && nullToAbsent ? const Value.absent() : Value(snoozeUntil),
      estimatedPomos: estimatedPomos == null && nullToAbsent ? const Value.absent() : Value(estimatedPomos),
      estimatedMinutes: estimatedMinutes == null && nullToAbsent ? const Value.absent() : Value(estimatedMinutes),
      color: color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      listId: serializer.fromJson<String>(json['listId']),
      sectionId: serializer.fromJson<String?>(json['sectionId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      kind: serializer.fromJson<TaskKind>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      priority: serializer.fromJson<Priority>(json['priority']),
      status: serializer.fromJson<TaskStatus>(json['status']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      timeZone: serializer.fromJson<String?>(json['timeZone']),
      isFloating: serializer.fromJson<bool>(json['isFloating']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      progress: serializer.fromJson<int>(json['progress']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      repeatFrom: serializer.fromJson<String?>(json['repeatFrom']),
      snoozeUntil: serializer.fromJson<DateTime?>(json['snoozeUntil']),
      estimatedPomos: serializer.fromJson<int?>(json['estimatedPomos']),
      estimatedMinutes: serializer.fromJson<int?>(json['estimatedMinutes']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'listId': serializer.toJson<String>(listId),
      'sectionId': serializer.toJson<String?>(sectionId),
      'parentId': serializer.toJson<String?>(parentId),
      'kind': serializer.toJson<TaskKind>(kind),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'priority': serializer.toJson<Priority>(priority),
      'status': serializer.toJson<TaskStatus>(status),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'timeZone': serializer.toJson<String?>(timeZone),
      'isFloating': serializer.toJson<bool>(isFloating),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'progress': serializer.toJson<int>(progress),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'repeatFrom': serializer.toJson<String?>(repeatFrom),
      'snoozeUntil': serializer.toJson<DateTime?>(snoozeUntil),
      'estimatedPomos': serializer.toJson<int?>(estimatedPomos),
      'estimatedMinutes': serializer.toJson<int?>(estimatedMinutes),
      'color': serializer.toJson<String?>(color),
    };
  }

  Task copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? listId,
    Value<String?> sectionId = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    TaskKind? kind,
    String? title,
    String? content,
    Priority? priority,
    TaskStatus? status,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    bool? isAllDay,
    Value<String?> timeZone = const Value.absent(),
    bool? isFloating,
    Value<DateTime?> pinnedAt = const Value.absent(),
    int? progress,
    int? sortOrder,
    Value<String?> repeatRule = const Value.absent(),
    Value<String?> repeatFrom = const Value.absent(),
    Value<DateTime?> snoozeUntil = const Value.absent(),
    Value<int?> estimatedPomos = const Value.absent(),
    Value<int?> estimatedMinutes = const Value.absent(),
    Value<String?> color = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    listId: listId ?? this.listId,
    sectionId: sectionId.present ? sectionId.value : this.sectionId,
    parentId: parentId.present ? parentId.value : this.parentId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    content: content ?? this.content,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    startDate: startDate.present ? startDate.value : this.startDate,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isAllDay: isAllDay ?? this.isAllDay,
    timeZone: timeZone.present ? timeZone.value : this.timeZone,
    isFloating: isFloating ?? this.isFloating,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    progress: progress ?? this.progress,
    sortOrder: sortOrder ?? this.sortOrder,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    repeatFrom: repeatFrom.present ? repeatFrom.value : this.repeatFrom,
    snoozeUntil: snoozeUntil.present ? snoozeUntil.value : this.snoozeUntil,
    estimatedPomos: estimatedPomos.present ? estimatedPomos.value : this.estimatedPomos,
    estimatedMinutes: estimatedMinutes.present ? estimatedMinutes.value : this.estimatedMinutes,
    color: color.present ? color.value : this.color,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      listId: data.listId.present ? data.listId.value : this.listId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      isFloating: data.isFloating.present ? data.isFloating.value : this.isFloating,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      progress: data.progress.present ? data.progress.value : this.progress,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      repeatRule: data.repeatRule.present ? data.repeatRule.value : this.repeatRule,
      repeatFrom: data.repeatFrom.present ? data.repeatFrom.value : this.repeatFrom,
      snoozeUntil: data.snoozeUntil.present ? data.snoozeUntil.value : this.snoozeUntil,
      estimatedPomos: data.estimatedPomos.present ? data.estimatedPomos.value : this.estimatedPomos,
      estimatedMinutes: data.estimatedMinutes.present ? data.estimatedMinutes.value : this.estimatedMinutes,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('listId: $listId, ')
          ..write('sectionId: $sectionId, ')
          ..write('parentId: $parentId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('startDate: $startDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('timeZone: $timeZone, ')
          ..write('isFloating: $isFloating, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('progress: $progress, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('repeatFrom: $repeatFrom, ')
          ..write('snoozeUntil: $snoozeUntil, ')
          ..write('estimatedPomos: $estimatedPomos, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    listId,
    sectionId,
    parentId,
    kind,
    title,
    content,
    priority,
    status,
    completedAt,
    startDate,
    dueDate,
    isAllDay,
    timeZone,
    isFloating,
    pinnedAt,
    progress,
    sortOrder,
    repeatRule,
    repeatFrom,
    snoozeUntil,
    estimatedPomos,
    estimatedMinutes,
    color,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.listId == this.listId &&
          other.sectionId == this.sectionId &&
          other.parentId == this.parentId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.content == this.content &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.startDate == this.startDate &&
          other.dueDate == this.dueDate &&
          other.isAllDay == this.isAllDay &&
          other.timeZone == this.timeZone &&
          other.isFloating == this.isFloating &&
          other.pinnedAt == this.pinnedAt &&
          other.progress == this.progress &&
          other.sortOrder == this.sortOrder &&
          other.repeatRule == this.repeatRule &&
          other.repeatFrom == this.repeatFrom &&
          other.snoozeUntil == this.snoozeUntil &&
          other.estimatedPomos == this.estimatedPomos &&
          other.estimatedMinutes == this.estimatedMinutes &&
          other.color == this.color);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> listId;
  final Value<String?> sectionId;
  final Value<String?> parentId;
  final Value<TaskKind> kind;
  final Value<String> title;
  final Value<String> content;
  final Value<Priority> priority;
  final Value<TaskStatus> status;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> startDate;
  final Value<DateTime?> dueDate;
  final Value<bool> isAllDay;
  final Value<String?> timeZone;
  final Value<bool> isFloating;
  final Value<DateTime?> pinnedAt;
  final Value<int> progress;
  final Value<int> sortOrder;
  final Value<String?> repeatRule;
  final Value<String?> repeatFrom;
  final Value<DateTime?> snoozeUntil;
  final Value<int?> estimatedPomos;
  final Value<int?> estimatedMinutes;
  final Value<String?> color;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.listId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.startDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.isFloating = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.progress = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.repeatFrom = const Value.absent(),
    this.snoozeUntil = const Value.absent(),
    this.estimatedPomos = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String listId,
    this.sectionId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.startDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.isFloating = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.progress = const Value.absent(),
    required int sortOrder,
    this.repeatRule = const Value.absent(),
    this.repeatFrom = const Value.absent(),
    this.snoozeUntil = const Value.absent(),
    this.estimatedPomos = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       listId = Value(listId),
       sortOrder = Value(sortOrder);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? listId,
    Expression<String>? sectionId,
    Expression<String>? parentId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? priority,
    Expression<int>? status,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? startDate,
    Expression<DateTime>? dueDate,
    Expression<bool>? isAllDay,
    Expression<String>? timeZone,
    Expression<bool>? isFloating,
    Expression<DateTime>? pinnedAt,
    Expression<int>? progress,
    Expression<int>? sortOrder,
    Expression<String>? repeatRule,
    Expression<String>? repeatFrom,
    Expression<DateTime>? snoozeUntil,
    Expression<int>? estimatedPomos,
    Expression<int>? estimatedMinutes,
    Expression<String>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (listId != null) 'list_id': listId,
      if (sectionId != null) 'section_id': sectionId,
      if (parentId != null) 'parent_id': parentId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (startDate != null) 'start_date': startDate,
      if (dueDate != null) 'due_date': dueDate,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (timeZone != null) 'time_zone': timeZone,
      if (isFloating != null) 'is_floating': isFloating,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (progress != null) 'progress': progress,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (repeatFrom != null) 'repeat_from': repeatFrom,
      if (snoozeUntil != null) 'snooze_until': snoozeUntil,
      if (estimatedPomos != null) 'estimated_pomos': estimatedPomos,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? listId,
    Value<String?>? sectionId,
    Value<String?>? parentId,
    Value<TaskKind>? kind,
    Value<String>? title,
    Value<String>? content,
    Value<Priority>? priority,
    Value<TaskStatus>? status,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? startDate,
    Value<DateTime?>? dueDate,
    Value<bool>? isAllDay,
    Value<String?>? timeZone,
    Value<bool>? isFloating,
    Value<DateTime?>? pinnedAt,
    Value<int>? progress,
    Value<int>? sortOrder,
    Value<String?>? repeatRule,
    Value<String?>? repeatFrom,
    Value<DateTime?>? snoozeUntil,
    Value<int?>? estimatedPomos,
    Value<int?>? estimatedMinutes,
    Value<String?>? color,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      listId: listId ?? this.listId,
      sectionId: sectionId ?? this.sectionId,
      parentId: parentId ?? this.parentId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      isAllDay: isAllDay ?? this.isAllDay,
      timeZone: timeZone ?? this.timeZone,
      isFloating: isFloating ?? this.isFloating,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      progress: progress ?? this.progress,
      sortOrder: sortOrder ?? this.sortOrder,
      repeatRule: repeatRule ?? this.repeatRule,
      repeatFrom: repeatFrom ?? this.repeatFrom,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      estimatedPomos: estimatedPomos ?? this.estimatedPomos,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($TasksTable.$converterkind.toSql(kind.value));
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>($TasksTable.$converterpriority.toSql(priority.value));
    }
    if (status.present) {
      map['status'] = Variable<int>($TasksTable.$converterstatus.toSql(status.value));
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (isFloating.present) {
      map['is_floating'] = Variable<bool>(isFloating.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (repeatFrom.present) {
      map['repeat_from'] = Variable<String>(repeatFrom.value);
    }
    if (snoozeUntil.present) {
      map['snooze_until'] = Variable<DateTime>(snoozeUntil.value);
    }
    if (estimatedPomos.present) {
      map['estimated_pomos'] = Variable<int>(estimatedPomos.value);
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('listId: $listId, ')
          ..write('sectionId: $sectionId, ')
          ..write('parentId: $parentId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('startDate: $startDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('timeZone: $timeZone, ')
          ..write('isFloating: $isFloating, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('progress: $progress, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('repeatFrom: $repeatFrom, ')
          ..write('snoozeUntil: $snoozeUntil, ')
          ..write('estimatedPomos: $estimatedPomos, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistItemsTable extends ChecklistItems with TableInfo<$ChecklistItemsTable, ChecklistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tasks (id)'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_completed" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAllDayMeta = const VerificationMeta('isAllDay');
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_all_day" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, taskId, title, isCompleted, completedAt, sortOrder, dueDate, isAllDay];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_items';
  @override
  VerificationContext validateIntegrity(Insertable<ChecklistItem> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(_isCompletedMeta, isCompleted.isAcceptableOrUnknown(data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(_completedAtMeta, completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta, dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('is_all_day')) {
      context.handle(_isAllDayMeta, isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItem(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      taskId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      isCompleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      completedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      dueDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      isAllDay: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_all_day'])!,
    );
  }

  @override
  $ChecklistItemsTable createAlias(String alias) {
    return $ChecklistItemsTable(attachedDatabase, alias);
  }
}

class ChecklistItem extends DataClass implements Insertable<ChecklistItem> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String taskId;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;
  final int sortOrder;

  /// Reminder of the item ("Lembrete em item de checklist"), UTC; all-day items remind
  /// at 09:00 (schema v4).
  final DateTime? dueDate;
  final bool isAllDay;
  const ChecklistItem({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    this.completedAt,
    required this.sortOrder,
    this.dueDate,
    required this.isAllDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['task_id'] = Variable<String>(taskId);
    map['title'] = Variable<String>(title);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    return map;
  }

  ChecklistItemsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistItemsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      taskId: Value(taskId),
      title: Value(title),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
      sortOrder: Value(sortOrder),
      dueDate: dueDate == null && nullToAbsent ? const Value.absent() : Value(dueDate),
      isAllDay: Value(isAllDay),
    );
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItem(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      taskId: serializer.fromJson<String>(json['taskId']),
      title: serializer.fromJson<String>(json['title']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'taskId': serializer.toJson<String>(taskId),
      'title': serializer.toJson<String>(title),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'isAllDay': serializer.toJson<bool>(isAllDay),
    };
  }

  ChecklistItem copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? taskId,
    String? title,
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    int? sortOrder,
    Value<DateTime?> dueDate = const Value.absent(),
    bool? isAllDay,
  }) => ChecklistItem(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    sortOrder: sortOrder ?? this.sortOrder,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isAllDay: isAllDay ?? this.isAllDay,
  );
  ChecklistItem copyWithCompanion(ChecklistItemsCompanion data) {
    return ChecklistItem(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      title: data.title.present ? data.title.value : this.title,
      isCompleted: data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItem(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('dueDate: $dueDate, ')
          ..write('isAllDay: $isAllDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, taskId, title, isCompleted, completedAt, sortOrder, dueDate, isAllDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItem &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.taskId == this.taskId &&
          other.title == this.title &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.sortOrder == this.sortOrder &&
          other.dueDate == this.dueDate &&
          other.isAllDay == this.isAllDay);
}

class ChecklistItemsCompanion extends UpdateCompanion<ChecklistItem> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> taskId;
  final Value<String> title;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<int> sortOrder;
  final Value<DateTime?> dueDate;
  final Value<bool> isAllDay;
  final Value<int> rowid;
  const ChecklistItemsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.taskId = const Value.absent(),
    this.title = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistItemsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String taskId,
    this.title = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    required int sortOrder,
    this.dueDate = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       taskId = Value(taskId),
       sortOrder = Value(sortOrder);
  static Insertable<ChecklistItem> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? taskId,
    Expression<String>? title,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<int>? sortOrder,
    Expression<DateTime>? dueDate,
    Expression<bool>? isAllDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (taskId != null) 'task_id': taskId,
      if (title != null) 'title': title,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (dueDate != null) 'due_date': dueDate,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistItemsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? taskId,
    Value<String>? title,
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<int>? sortOrder,
    Value<DateTime?>? dueDate,
    Value<bool>? isAllDay,
    Value<int>? rowid,
  }) {
    return ChecklistItemsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      dueDate: dueDate ?? this.dueDate,
      isAllDay: isAllDay ?? this.isAllDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('dueDate: $dueDate, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tags (id)'),
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta('pinnedAt');
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, name, color, parentId, pinnedAt, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta, parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('pinned_at')) {
      context.handle(_pinnedAtMeta, pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}color']),
      parentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      pinnedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}pinned_at']),
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String name;
  final String? color;
  final String? parentId;
  final DateTime? pinnedAt;
  final int sortOrder;
  const Tag({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    this.color,
    this.parentId,
    this.pinnedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      name: Value(name),
      color: color == null && nullToAbsent ? const Value.absent() : Value(color),
      parentId: parentId == null && nullToAbsent ? const Value.absent() : Value(parentId),
      pinnedAt: pinnedAt == null && nullToAbsent ? const Value.absent() : Value(pinnedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'parentId': serializer.toJson<String?>(parentId),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Tag copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    Value<String?> color = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    Value<DateTime?> pinnedAt = const Value.absent(),
    int? sortOrder,
  }) => Tag(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    parentId: parentId.present ? parentId.value : this.parentId,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, name, color, parentId, pinnedAt, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.color == this.color &&
          other.parentId == this.parentId &&
          other.pinnedAt == this.pinnedAt &&
          other.sortOrder == this.sortOrder);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String?> color;
  final Value<String?> parentId;
  final Value<DateTime?> pinnedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.parentId = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.parentId = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? parentId,
    Expression<DateTime>? pinnedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (parentId != null) 'parent_id': parentId,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String?>? color,
    Value<String?>? parentId,
    Value<DateTime?>? pinnedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTagsTable extends TaskTags with TableInfo<$TaskTagsTable, TaskTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tasks (id)'),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tags (id)'),
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_tags';
  @override
  VerificationContext validateIntegrity(Insertable<TaskTag> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(_tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, tagId};
  @override
  TaskTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTag(
      taskId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      tagId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $TaskTagsTable createAlias(String alias) {
    return $TaskTagsTable(attachedDatabase, alias);
  }
}

class TaskTag extends DataClass implements Insertable<TaskTag> {
  final String taskId;
  final String tagId;
  const TaskTag({required this.taskId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  TaskTagsCompanion toCompanion(bool nullToAbsent) {
    return TaskTagsCompanion(taskId: Value(taskId), tagId: Value(tagId));
  }

  factory TaskTag.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTag(taskId: serializer.fromJson<String>(json['taskId']), tagId: serializer.fromJson<String>(json['tagId']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'taskId': serializer.toJson<String>(taskId), 'tagId': serializer.toJson<String>(tagId)};
  }

  TaskTag copyWith({String? taskId, String? tagId}) => TaskTag(taskId: taskId ?? this.taskId, tagId: tagId ?? this.tagId);
  TaskTag copyWithCompanion(TaskTagsCompanion data) {
    return TaskTag(taskId: data.taskId.present ? data.taskId.value : this.taskId, tagId: data.tagId.present ? data.tagId.value : this.tagId);
  }

  @override
  String toString() {
    return (StringBuffer('TaskTag(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, tagId);
  @override
  bool operator ==(Object other) => identical(this, other) || (other is TaskTag && other.taskId == this.taskId && other.tagId == this.tagId);
}

class TaskTagsCompanion extends UpdateCompanion<TaskTag> {
  final Value<String> taskId;
  final Value<String> tagId;
  final Value<int> rowid;
  const TaskTagsCompanion({this.taskId = const Value.absent(), this.tagId = const Value.absent(), this.rowid = const Value.absent()});
  TaskTagsCompanion.insert({required String taskId, required String tagId, this.rowid = const Value.absent()})
    : taskId = Value(taskId),
      tagId = Value(tagId);
  static Insertable<TaskTag> custom({Expression<String>? taskId, Expression<String>? tagId, Expression<int>? rowid}) {
    return RawValuesInsertable({if (taskId != null) 'task_id': taskId, if (tagId != null) 'tag_id': tagId, if (rowid != null) 'rowid': rowid});
  }

  TaskTagsCompanion copyWith({Value<String>? taskId, Value<String>? tagId, Value<int>? rowid}) {
    return TaskTagsCompanion(taskId: taskId ?? this.taskId, tagId: tagId ?? this.tagId, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTagsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(Insertable<Preference> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String name;
  final String value;
  final DateTime updatedAt;
  const Preference({required this.name, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(name: Value(name), value: Value(value), updatedAt: Value(updatedAt));
  }

  factory Preference.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Preference copyWith({String? name, String? value, DateTime? updatedAt}) =>
      Preference(name: name ?? this.name, value: value ?? this.value, updatedAt: updatedAt ?? this.updatedAt);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Preference && other.name == this.name && other.value == this.value && other.updatedAt == this.updatedAt);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> name;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({required String name, required String value, required DateTime updatedAt, this.rowid = const Value.absent()})
    : name = Value(name),
      value = Value(value),
      updatedAt = Value(updatedAt);
  static Insertable<Preference> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({Value<String>? name, Value<String>? value, Value<DateTime>? updatedAt, Value<int>? rowid}) {
    return PreferencesCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRemindersTable extends TaskReminders with TableInfo<$TaskRemindersTable, TaskReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tasks (id)'),
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta('trigger');
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, trigger];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_reminders';
  @override
  VerificationContext validateIntegrity(Insertable<TaskReminder> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('trigger')) {
      context.handle(_triggerMeta, trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta));
    } else if (isInserting) {
      context.missing(_triggerMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, trigger};
  @override
  TaskReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskReminder(
      taskId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      trigger: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}trigger'])!,
    );
  }

  @override
  $TaskRemindersTable createAlias(String alias) {
    return $TaskRemindersTable(attachedDatabase, alias);
  }
}

class TaskReminder extends DataClass implements Insertable<TaskReminder> {
  final String taskId;
  final String trigger;
  const TaskReminder({required this.taskId, required this.trigger});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['trigger'] = Variable<String>(trigger);
    return map;
  }

  TaskRemindersCompanion toCompanion(bool nullToAbsent) {
    return TaskRemindersCompanion(taskId: Value(taskId), trigger: Value(trigger));
  }

  factory TaskReminder.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskReminder(taskId: serializer.fromJson<String>(json['taskId']), trigger: serializer.fromJson<String>(json['trigger']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'taskId': serializer.toJson<String>(taskId), 'trigger': serializer.toJson<String>(trigger)};
  }

  TaskReminder copyWith({String? taskId, String? trigger}) => TaskReminder(taskId: taskId ?? this.taskId, trigger: trigger ?? this.trigger);
  TaskReminder copyWithCompanion(TaskRemindersCompanion data) {
    return TaskReminder(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskReminder(')
          ..write('taskId: $taskId, ')
          ..write('trigger: $trigger')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, trigger);
  @override
  bool operator ==(Object other) => identical(this, other) || (other is TaskReminder && other.taskId == this.taskId && other.trigger == this.trigger);
}

class TaskRemindersCompanion extends UpdateCompanion<TaskReminder> {
  final Value<String> taskId;
  final Value<String> trigger;
  final Value<int> rowid;
  const TaskRemindersCompanion({this.taskId = const Value.absent(), this.trigger = const Value.absent(), this.rowid = const Value.absent()});
  TaskRemindersCompanion.insert({required String taskId, required String trigger, this.rowid = const Value.absent()})
    : taskId = Value(taskId),
      trigger = Value(trigger);
  static Insertable<TaskReminder> custom({Expression<String>? taskId, Expression<String>? trigger, Expression<int>? rowid}) {
    return RawValuesInsertable({if (taskId != null) 'task_id': taskId, if (trigger != null) 'trigger': trigger, if (rowid != null) 'rowid': rowid});
  }

  TaskRemindersCompanion copyWith({Value<String>? taskId, Value<String>? trigger, Value<int>? rowid}) {
    return TaskRemindersCompanion(taskId: taskId ?? this.taskId, trigger: trigger ?? this.trigger, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRemindersCompanion(')
          ..write('taskId: $taskId, ')
          ..write('trigger: $trigger, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates with TableInfo<$TemplatesTable, TaskTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskKind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(TaskKind.text.code),
  ).withConverter<TaskKind>($TemplatesTable.$converterkind);
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumn<String> items = GeneratedColumn<String>(
    'items',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tagIdsMeta = const VerificationMeta('tagIds');
  @override
  late final GeneratedColumn<String> tagIds = GeneratedColumn<String>(
    'tag_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, name, title, content, kind, items, tagIds, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(Insertable<TaskTemplate> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta, content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('items')) {
      context.handle(_itemsMeta, items.isAcceptableOrUnknown(data['items']!, _itemsMeta));
    }
    if (data.containsKey('tag_ids')) {
      context.handle(_tagIdsMeta, tagIds.isAcceptableOrUnknown(data['tag_ids']!, _tagIdsMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTemplate(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      kind: $TemplatesTable.$converterkind.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      items: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}items'])!,
      tagIds: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tag_ids'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }

  static TypeConverter<TaskKind, String> $converterkind = const TextCodeConverter<TaskKind>(TaskKind.fromCode);
}

class TaskTemplate extends DataClass implements Insertable<TaskTemplate> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String name;
  final String title;
  final String content;
  final TaskKind kind;

  /// Checklist items, one per line.
  final String items;

  /// Tag ids, comma separated.
  final String tagIds;
  final int sortOrder;
  const TaskTemplate({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.title,
    required this.content,
    required this.kind,
    required this.items,
    required this.tagIds,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    {
      map['kind'] = Variable<String>($TemplatesTable.$converterkind.toSql(kind));
    }
    map['items'] = Variable<String>(items);
    map['tag_ids'] = Variable<String>(tagIds);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      name: Value(name),
      title: Value(title),
      content: Value(content),
      kind: Value(kind),
      items: Value(items),
      tagIds: Value(tagIds),
      sortOrder: Value(sortOrder),
    );
  }

  factory TaskTemplate.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTemplate(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      kind: serializer.fromJson<TaskKind>(json['kind']),
      items: serializer.fromJson<String>(json['items']),
      tagIds: serializer.fromJson<String>(json['tagIds']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'kind': serializer.toJson<TaskKind>(kind),
      'items': serializer.toJson<String>(items),
      'tagIds': serializer.toJson<String>(tagIds),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TaskTemplate copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    String? title,
    String? content,
    TaskKind? kind,
    String? items,
    String? tagIds,
    int? sortOrder,
  }) => TaskTemplate(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    title: title ?? this.title,
    content: content ?? this.content,
    kind: kind ?? this.kind,
    items: items ?? this.items,
    tagIds: tagIds ?? this.tagIds,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TaskTemplate copyWithCompanion(TemplatesCompanion data) {
    return TaskTemplate(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      kind: data.kind.present ? data.kind.value : this.kind,
      items: data.items.present ? data.items.value : this.items,
      tagIds: data.tagIds.present ? data.tagIds.value : this.tagIds,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplate(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('kind: $kind, ')
          ..write('items: $items, ')
          ..write('tagIds: $tagIds, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, name, title, content, kind, items, tagIds, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTemplate &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.title == this.title &&
          other.content == this.content &&
          other.kind == this.kind &&
          other.items == this.items &&
          other.tagIds == this.tagIds &&
          other.sortOrder == this.sortOrder);
}

class TemplatesCompanion extends UpdateCompanion<TaskTemplate> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String> title;
  final Value<String> content;
  final Value<TaskKind> kind;
  final Value<String> items;
  final Value<String> tagIds;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.kind = const Value.absent(),
    this.items = const Value.absent(),
    this.tagIds = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.kind = const Value.absent(),
    this.items = const Value.absent(),
    this.tagIds = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<TaskTemplate> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? kind,
    Expression<String>? items,
    Expression<String>? tagIds,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (kind != null) 'kind': kind,
      if (items != null) 'items': items,
      if (tagIds != null) 'tag_ids': tagIds,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String>? title,
    Value<String>? content,
    Value<TaskKind>? kind,
    Value<String>? items,
    Value<String>? tagIds,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      title: title ?? this.title,
      content: content ?? this.content,
      kind: kind ?? this.kind,
      items: items ?? this.items,
      tagIds: tagIds ?? this.tagIds,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($TemplatesTable.$converterkind.toSql(kind.value));
    }
    if (items.present) {
      map['items'] = Variable<String>(items.value);
    }
    if (tagIds.present) {
      map['tag_ids'] = Variable<String>(tagIds.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('kind: $kind, ')
          ..write('items: $items, ')
          ..write('tagIds: $tagIds, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommentsTable extends Comments with TableInfo<$CommentsTable, Comment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tasks (id)'),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, taskId, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comments';
  @override
  VerificationContext validateIntegrity(Insertable<Comment> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Comment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Comment(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      taskId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}body'])!,
    );
  }

  @override
  $CommentsTable createAlias(String alias) {
    return $CommentsTable(attachedDatabase, alias);
  }
}

class Comment extends DataClass implements Insertable<Comment> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String taskId;
  final String body;
  const Comment({required this.id, required this.createdAt, required this.updatedAt, this.deletedAt, required this.taskId, required this.body});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['task_id'] = Variable<String>(taskId);
    map['body'] = Variable<String>(body);
    return map;
  }

  CommentsCompanion toCompanion(bool nullToAbsent) {
    return CommentsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      taskId: Value(taskId),
      body: Value(body),
    );
  }

  factory Comment.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Comment(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      taskId: serializer.fromJson<String>(json['taskId']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'taskId': serializer.toJson<String>(taskId),
      'body': serializer.toJson<String>(body),
    };
  }

  Comment copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? taskId,
    String? body,
  }) => Comment(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    taskId: taskId ?? this.taskId,
    body: body ?? this.body,
  );
  Comment copyWithCompanion(CommentsCompanion data) {
    return Comment(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Comment(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, taskId, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Comment &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.taskId == this.taskId &&
          other.body == this.body);
}

class CommentsCompanion extends UpdateCompanion<Comment> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> taskId;
  final Value<String> body;
  final Value<int> rowid;
  const CommentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.taskId = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommentsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String taskId,
    required String body,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       taskId = Value(taskId),
       body = Value(body);
  static Insertable<Comment> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? taskId,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (taskId != null) 'task_id': taskId,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? taskId,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return CommentsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      taskId: taskId ?? this.taskId,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CountdownsTable extends Countdowns with TableInfo<$CountdownsTable, Countdown> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountdownsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CountdownType, String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(CountdownType.countdown.code),
  ).withConverter<CountdownType>($CountdownsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<CountMode, String> countMode = GeneratedColumn<String>(
    'count_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(CountMode.standard.code),
  ).withConverter<CountMode>($CountdownsTable.$convertercountMode);
  static const VerificationMeta _ignoreYearMeta = const VerificationMeta('ignoreYear');
  @override
  late final GeneratedColumn<bool> ignoreYear = GeneratedColumn<bool>(
    'ignore_year',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("ignore_year" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showAgeMeta = const VerificationMeta('showAge');
  @override
  late final GeneratedColumn<bool> showAge = GeneratedColumn<bool>(
    'show_age',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("show_age" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remindersMeta = const VerificationMeta('reminders');
  @override
  late final GeneratedColumn<String> reminders = GeneratedColumn<String>(
    'reminders',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta('repeatRule');
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CountdownVisibility, String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(CountdownVisibility.onTheDay.code),
  ).withConverter<CountdownVisibility>($CountdownsTable.$convertervisibility);
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<int> style = GeneratedColumn<int>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta('pinnedAt');
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconColorMeta = const VerificationMeta('iconColor');
  @override
  late final GeneratedColumn<String> iconColor = GeneratedColumn<String>(
    'icon_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
    'image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countUpMeta = const VerificationMeta('countUp');
  @override
  late final GeneratedColumn<bool> countUp = GeneratedColumn<bool>(
    'count_up',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("count_up" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    date,
    type,
    countMode,
    ignoreYear,
    showAge,
    reminders,
    repeatRule,
    visibility,
    style,
    color,
    note,
    pinnedAt,
    archivedAt,
    sortOrder,
    icon,
    iconColor,
    image,
    countUp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'countdowns';
  @override
  VerificationContext validateIntegrity(Insertable<Countdown> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('ignore_year')) {
      context.handle(_ignoreYearMeta, ignoreYear.isAcceptableOrUnknown(data['ignore_year']!, _ignoreYearMeta));
    }
    if (data.containsKey('show_age')) {
      context.handle(_showAgeMeta, showAge.isAcceptableOrUnknown(data['show_age']!, _showAgeMeta));
    }
    if (data.containsKey('reminders')) {
      context.handle(_remindersMeta, reminders.isAcceptableOrUnknown(data['reminders']!, _remindersMeta));
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(_repeatRuleMeta, repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta));
    }
    if (data.containsKey('style')) {
      context.handle(_styleMeta, style.isAcceptableOrUnknown(data['style']!, _styleMeta));
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('pinned_at')) {
      context.handle(_pinnedAtMeta, pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(_archivedAtMeta, archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('icon_color')) {
      context.handle(_iconColorMeta, iconColor.isAcceptableOrUnknown(data['icon_color']!, _iconColorMeta));
    }
    if (data.containsKey('image')) {
      context.handle(_imageMeta, image.isAcceptableOrUnknown(data['image']!, _imageMeta));
    }
    if (data.containsKey('count_up')) {
      context.handle(_countUpMeta, countUp.isAcceptableOrUnknown(data['count_up']!, _countUpMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Countdown map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Countdown(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      type: $CountdownsTable.$convertertype.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      countMode: $CountdownsTable.$convertercountMode.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}count_mode'])!,
      ),
      ignoreYear: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}ignore_year'])!,
      showAge: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}show_age'])!,
      reminders: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reminders'])!,
      repeatRule: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}repeat_rule']),
      visibility: $CountdownsTable.$convertervisibility.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}visibility'])!,
      ),
      style: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}style'])!,
      color: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}color']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      pinnedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}pinned_at']),
      archivedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon']),
      iconColor: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon_color']),
      image: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}image']),
      countUp: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}count_up'])!,
    );
  }

  @override
  $CountdownsTable createAlias(String alias) {
    return $CountdownsTable(attachedDatabase, alias);
  }

  static TypeConverter<CountdownType, String> $convertertype = const TextCodeConverter<CountdownType>(CountdownType.fromCode);
  static TypeConverter<CountMode, String> $convertercountMode = const TextCodeConverter<CountMode>(CountMode.fromCode);
  static TypeConverter<CountdownVisibility, String> $convertervisibility = const TextCodeConverter<CountdownVisibility>(CountdownVisibility.fromCode);
}

class Countdown extends DataClass implements Insertable<Countdown> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String name;
  final DateTime date;
  final CountdownType type;
  final CountMode countMode;
  final bool ignoreYear;
  final bool showAge;
  final String reminders;
  final String? repeatRule;
  final CountdownVisibility visibility;

  /// Card layout (0-5) and color (hex).
  final int style;
  final String? color;
  final String note;
  final DateTime? pinnedAt;
  final DateTime? archivedAt;
  final int sortOrder;

  /// Emoji or text shown before the name, and the background picture's file name,
  /// schema v12.
  final String? icon;

  /// Background of a "Texto" icon (one letter on a colored circle), `#RRGGBB`.
  final String? iconColor;
  final String? image;

  /// "Modo de Contagem": Cronômetro counts up from the date instead of down to the
  /// next occurrence (schema v14).
  final bool countUp;
  const Countdown({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.date,
    required this.type,
    required this.countMode,
    required this.ignoreYear,
    required this.showAge,
    required this.reminders,
    this.repeatRule,
    required this.visibility,
    required this.style,
    this.color,
    required this.note,
    this.pinnedAt,
    this.archivedAt,
    required this.sortOrder,
    this.icon,
    this.iconColor,
    this.image,
    required this.countUp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['date'] = Variable<DateTime>(date);
    {
      map['type'] = Variable<String>($CountdownsTable.$convertertype.toSql(type));
    }
    {
      map['count_mode'] = Variable<String>($CountdownsTable.$convertercountMode.toSql(countMode));
    }
    map['ignore_year'] = Variable<bool>(ignoreYear);
    map['show_age'] = Variable<bool>(showAge);
    map['reminders'] = Variable<String>(reminders);
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    {
      map['visibility'] = Variable<String>($CountdownsTable.$convertervisibility.toSql(visibility));
    }
    map['style'] = Variable<int>(style);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || iconColor != null) {
      map['icon_color'] = Variable<String>(iconColor);
    }
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    map['count_up'] = Variable<bool>(countUp);
    return map;
  }

  CountdownsCompanion toCompanion(bool nullToAbsent) {
    return CountdownsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      name: Value(name),
      date: Value(date),
      type: Value(type),
      countMode: Value(countMode),
      ignoreYear: Value(ignoreYear),
      showAge: Value(showAge),
      reminders: Value(reminders),
      repeatRule: repeatRule == null && nullToAbsent ? const Value.absent() : Value(repeatRule),
      visibility: Value(visibility),
      style: Value(style),
      color: color == null && nullToAbsent ? const Value.absent() : Value(color),
      note: Value(note),
      pinnedAt: pinnedAt == null && nullToAbsent ? const Value.absent() : Value(pinnedAt),
      archivedAt: archivedAt == null && nullToAbsent ? const Value.absent() : Value(archivedAt),
      sortOrder: Value(sortOrder),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      iconColor: iconColor == null && nullToAbsent ? const Value.absent() : Value(iconColor),
      image: image == null && nullToAbsent ? const Value.absent() : Value(image),
      countUp: Value(countUp),
    );
  }

  factory Countdown.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Countdown(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: serializer.fromJson<CountdownType>(json['type']),
      countMode: serializer.fromJson<CountMode>(json['countMode']),
      ignoreYear: serializer.fromJson<bool>(json['ignoreYear']),
      showAge: serializer.fromJson<bool>(json['showAge']),
      reminders: serializer.fromJson<String>(json['reminders']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      visibility: serializer.fromJson<CountdownVisibility>(json['visibility']),
      style: serializer.fromJson<int>(json['style']),
      color: serializer.fromJson<String?>(json['color']),
      note: serializer.fromJson<String>(json['note']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      icon: serializer.fromJson<String?>(json['icon']),
      iconColor: serializer.fromJson<String?>(json['iconColor']),
      image: serializer.fromJson<String?>(json['image']),
      countUp: serializer.fromJson<bool>(json['countUp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<CountdownType>(type),
      'countMode': serializer.toJson<CountMode>(countMode),
      'ignoreYear': serializer.toJson<bool>(ignoreYear),
      'showAge': serializer.toJson<bool>(showAge),
      'reminders': serializer.toJson<String>(reminders),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'visibility': serializer.toJson<CountdownVisibility>(visibility),
      'style': serializer.toJson<int>(style),
      'color': serializer.toJson<String?>(color),
      'note': serializer.toJson<String>(note),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'icon': serializer.toJson<String?>(icon),
      'iconColor': serializer.toJson<String?>(iconColor),
      'image': serializer.toJson<String?>(image),
      'countUp': serializer.toJson<bool>(countUp),
    };
  }

  Countdown copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    DateTime? date,
    CountdownType? type,
    CountMode? countMode,
    bool? ignoreYear,
    bool? showAge,
    String? reminders,
    Value<String?> repeatRule = const Value.absent(),
    CountdownVisibility? visibility,
    int? style,
    Value<String?> color = const Value.absent(),
    String? note,
    Value<DateTime?> pinnedAt = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    int? sortOrder,
    Value<String?> icon = const Value.absent(),
    Value<String?> iconColor = const Value.absent(),
    Value<String?> image = const Value.absent(),
    bool? countUp,
  }) => Countdown(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    date: date ?? this.date,
    type: type ?? this.type,
    countMode: countMode ?? this.countMode,
    ignoreYear: ignoreYear ?? this.ignoreYear,
    showAge: showAge ?? this.showAge,
    reminders: reminders ?? this.reminders,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    visibility: visibility ?? this.visibility,
    style: style ?? this.style,
    color: color.present ? color.value : this.color,
    note: note ?? this.note,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    sortOrder: sortOrder ?? this.sortOrder,
    icon: icon.present ? icon.value : this.icon,
    iconColor: iconColor.present ? iconColor.value : this.iconColor,
    image: image.present ? image.value : this.image,
    countUp: countUp ?? this.countUp,
  );
  Countdown copyWithCompanion(CountdownsCompanion data) {
    return Countdown(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      countMode: data.countMode.present ? data.countMode.value : this.countMode,
      ignoreYear: data.ignoreYear.present ? data.ignoreYear.value : this.ignoreYear,
      showAge: data.showAge.present ? data.showAge.value : this.showAge,
      reminders: data.reminders.present ? data.reminders.value : this.reminders,
      repeatRule: data.repeatRule.present ? data.repeatRule.value : this.repeatRule,
      visibility: data.visibility.present ? data.visibility.value : this.visibility,
      style: data.style.present ? data.style.value : this.style,
      color: data.color.present ? data.color.value : this.color,
      note: data.note.present ? data.note.value : this.note,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      archivedAt: data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      icon: data.icon.present ? data.icon.value : this.icon,
      iconColor: data.iconColor.present ? data.iconColor.value : this.iconColor,
      image: data.image.present ? data.image.value : this.image,
      countUp: data.countUp.present ? data.countUp.value : this.countUp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Countdown(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('countMode: $countMode, ')
          ..write('ignoreYear: $ignoreYear, ')
          ..write('showAge: $showAge, ')
          ..write('reminders: $reminders, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('visibility: $visibility, ')
          ..write('style: $style, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('icon: $icon, ')
          ..write('iconColor: $iconColor, ')
          ..write('image: $image, ')
          ..write('countUp: $countUp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    date,
    type,
    countMode,
    ignoreYear,
    showAge,
    reminders,
    repeatRule,
    visibility,
    style,
    color,
    note,
    pinnedAt,
    archivedAt,
    sortOrder,
    icon,
    iconColor,
    image,
    countUp,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Countdown &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.date == this.date &&
          other.type == this.type &&
          other.countMode == this.countMode &&
          other.ignoreYear == this.ignoreYear &&
          other.showAge == this.showAge &&
          other.reminders == this.reminders &&
          other.repeatRule == this.repeatRule &&
          other.visibility == this.visibility &&
          other.style == this.style &&
          other.color == this.color &&
          other.note == this.note &&
          other.pinnedAt == this.pinnedAt &&
          other.archivedAt == this.archivedAt &&
          other.sortOrder == this.sortOrder &&
          other.icon == this.icon &&
          other.iconColor == this.iconColor &&
          other.image == this.image &&
          other.countUp == this.countUp);
}

class CountdownsCompanion extends UpdateCompanion<Countdown> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<DateTime> date;
  final Value<CountdownType> type;
  final Value<CountMode> countMode;
  final Value<bool> ignoreYear;
  final Value<bool> showAge;
  final Value<String> reminders;
  final Value<String?> repeatRule;
  final Value<CountdownVisibility> visibility;
  final Value<int> style;
  final Value<String?> color;
  final Value<String> note;
  final Value<DateTime?> pinnedAt;
  final Value<DateTime?> archivedAt;
  final Value<int> sortOrder;
  final Value<String?> icon;
  final Value<String?> iconColor;
  final Value<String?> image;
  final Value<bool> countUp;
  final Value<int> rowid;
  const CountdownsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.countMode = const Value.absent(),
    this.ignoreYear = const Value.absent(),
    this.showAge = const Value.absent(),
    this.reminders = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.visibility = const Value.absent(),
    this.style = const Value.absent(),
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.icon = const Value.absent(),
    this.iconColor = const Value.absent(),
    this.image = const Value.absent(),
    this.countUp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CountdownsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required DateTime date,
    this.type = const Value.absent(),
    this.countMode = const Value.absent(),
    this.ignoreYear = const Value.absent(),
    this.showAge = const Value.absent(),
    this.reminders = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.visibility = const Value.absent(),
    this.style = const Value.absent(),
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    required int sortOrder,
    this.icon = const Value.absent(),
    this.iconColor = const Value.absent(),
    this.image = const Value.absent(),
    this.countUp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       date = Value(date),
       sortOrder = Value(sortOrder);
  static Insertable<Countdown> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<DateTime>? date,
    Expression<String>? type,
    Expression<String>? countMode,
    Expression<bool>? ignoreYear,
    Expression<bool>? showAge,
    Expression<String>? reminders,
    Expression<String>? repeatRule,
    Expression<String>? visibility,
    Expression<int>? style,
    Expression<String>? color,
    Expression<String>? note,
    Expression<DateTime>? pinnedAt,
    Expression<DateTime>? archivedAt,
    Expression<int>? sortOrder,
    Expression<String>? icon,
    Expression<String>? iconColor,
    Expression<String>? image,
    Expression<bool>? countUp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (countMode != null) 'count_mode': countMode,
      if (ignoreYear != null) 'ignore_year': ignoreYear,
      if (showAge != null) 'show_age': showAge,
      if (reminders != null) 'reminders': reminders,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (visibility != null) 'visibility': visibility,
      if (style != null) 'style': style,
      if (color != null) 'color': color,
      if (note != null) 'note': note,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (icon != null) 'icon': icon,
      if (iconColor != null) 'icon_color': iconColor,
      if (image != null) 'image': image,
      if (countUp != null) 'count_up': countUp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CountdownsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<DateTime>? date,
    Value<CountdownType>? type,
    Value<CountMode>? countMode,
    Value<bool>? ignoreYear,
    Value<bool>? showAge,
    Value<String>? reminders,
    Value<String?>? repeatRule,
    Value<CountdownVisibility>? visibility,
    Value<int>? style,
    Value<String?>? color,
    Value<String>? note,
    Value<DateTime?>? pinnedAt,
    Value<DateTime?>? archivedAt,
    Value<int>? sortOrder,
    Value<String?>? icon,
    Value<String?>? iconColor,
    Value<String?>? image,
    Value<bool>? countUp,
    Value<int>? rowid,
  }) {
    return CountdownsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      date: date ?? this.date,
      type: type ?? this.type,
      countMode: countMode ?? this.countMode,
      ignoreYear: ignoreYear ?? this.ignoreYear,
      showAge: showAge ?? this.showAge,
      reminders: reminders ?? this.reminders,
      repeatRule: repeatRule ?? this.repeatRule,
      visibility: visibility ?? this.visibility,
      style: style ?? this.style,
      color: color ?? this.color,
      note: note ?? this.note,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      image: image ?? this.image,
      countUp: countUp ?? this.countUp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>($CountdownsTable.$convertertype.toSql(type.value));
    }
    if (countMode.present) {
      map['count_mode'] = Variable<String>($CountdownsTable.$convertercountMode.toSql(countMode.value));
    }
    if (ignoreYear.present) {
      map['ignore_year'] = Variable<bool>(ignoreYear.value);
    }
    if (showAge.present) {
      map['show_age'] = Variable<bool>(showAge.value);
    }
    if (reminders.present) {
      map['reminders'] = Variable<String>(reminders.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>($CountdownsTable.$convertervisibility.toSql(visibility.value));
    }
    if (style.present) {
      map['style'] = Variable<int>(style.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (iconColor.present) {
      map['icon_color'] = Variable<String>(iconColor.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (countUp.present) {
      map['count_up'] = Variable<bool>(countUp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CountdownsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('countMode: $countMode, ')
          ..write('ignoreYear: $ignoreYear, ')
          ..write('showAge: $showAge, ')
          ..write('reminders: $reminders, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('visibility: $visibility, ')
          ..write('style: $style, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('icon: $icon, ')
          ..write('iconColor: $iconColor, ')
          ..write('image: $image, ')
          ..write('countUp: $countUp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusRecordsTable extends FocusRecords with TableInfo<$FocusRecordsTable, FocusRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta('seconds');
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>('seconds', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<FocusMode, String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(FocusMode.pomo.code),
  ).withConverter<FocusMode>($FocusRecordsTable.$convertermode);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timerIdMeta = const VerificationMeta('timerId');
  @override
  late final GeneratedColumn<String> timerId = GeneratedColumn<String>(
    'timer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, startedAt, endedAt, seconds, mode, taskId, timerId, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_records';
  @override
  VerificationContext validateIntegrity(Insertable<FocusRecord> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta, endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(_secondsMeta, seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta));
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    }
    if (data.containsKey('timer_id')) {
      context.handle(_timerIdMeta, timerId.isAcceptableOrUnknown(data['timer_id']!, _timerIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusRecord(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      startedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at'])!,
      seconds: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}seconds'])!,
      mode: $FocusRecordsTable.$convertermode.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}mode'])!),
      taskId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}task_id']),
      timerId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}timer_id']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $FocusRecordsTable createAlias(String alias) {
    return $FocusRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<FocusMode, String> $convertermode = const TextCodeConverter<FocusMode>(FocusMode.fromCode);
}

class FocusRecord extends DataClass implements Insertable<FocusRecord> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final DateTime startedAt;
  final DateTime endedAt;
  final int seconds;
  final FocusMode mode;

  /// Linked task (or, from the Habits phase, habit), and the saved timer that ran it.
  final String? taskId;
  final String? timerId;
  final String note;
  const FocusRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.startedAt,
    required this.endedAt,
    required this.seconds,
    required this.mode,
    this.taskId,
    this.timerId,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['seconds'] = Variable<int>(seconds);
    {
      map['mode'] = Variable<String>($FocusRecordsTable.$convertermode.toSql(mode));
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || timerId != null) {
      map['timer_id'] = Variable<String>(timerId);
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  FocusRecordsCompanion toCompanion(bool nullToAbsent) {
    return FocusRecordsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      seconds: Value(seconds),
      mode: Value(mode),
      taskId: taskId == null && nullToAbsent ? const Value.absent() : Value(taskId),
      timerId: timerId == null && nullToAbsent ? const Value.absent() : Value(timerId),
      note: Value(note),
    );
  }

  factory FocusRecord.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusRecord(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      seconds: serializer.fromJson<int>(json['seconds']),
      mode: serializer.fromJson<FocusMode>(json['mode']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      timerId: serializer.fromJson<String?>(json['timerId']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'seconds': serializer.toJson<int>(seconds),
      'mode': serializer.toJson<FocusMode>(mode),
      'taskId': serializer.toJson<String?>(taskId),
      'timerId': serializer.toJson<String?>(timerId),
      'note': serializer.toJson<String>(note),
    };
  }

  FocusRecord copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? startedAt,
    DateTime? endedAt,
    int? seconds,
    FocusMode? mode,
    Value<String?> taskId = const Value.absent(),
    Value<String?> timerId = const Value.absent(),
    String? note,
  }) => FocusRecord(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    seconds: seconds ?? this.seconds,
    mode: mode ?? this.mode,
    taskId: taskId.present ? taskId.value : this.taskId,
    timerId: timerId.present ? timerId.value : this.timerId,
    note: note ?? this.note,
  );
  FocusRecord copyWithCompanion(FocusRecordsCompanion data) {
    return FocusRecord(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      mode: data.mode.present ? data.mode.value : this.mode,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      timerId: data.timerId.present ? data.timerId.value : this.timerId,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusRecord(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('seconds: $seconds, ')
          ..write('mode: $mode, ')
          ..write('taskId: $taskId, ')
          ..write('timerId: $timerId, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, startedAt, endedAt, seconds, mode, taskId, timerId, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusRecord &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.seconds == this.seconds &&
          other.mode == this.mode &&
          other.taskId == this.taskId &&
          other.timerId == this.timerId &&
          other.note == this.note);
}

class FocusRecordsCompanion extends UpdateCompanion<FocusRecord> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> seconds;
  final Value<FocusMode> mode;
  final Value<String?> taskId;
  final Value<String?> timerId;
  final Value<String> note;
  final Value<int> rowid;
  const FocusRecordsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.seconds = const Value.absent(),
    this.mode = const Value.absent(),
    this.taskId = const Value.absent(),
    this.timerId = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusRecordsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    required int seconds,
    this.mode = const Value.absent(),
    this.taskId = const Value.absent(),
    this.timerId = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       seconds = Value(seconds);
  static Insertable<FocusRecord> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? seconds,
    Expression<String>? mode,
    Expression<String>? taskId,
    Expression<String>? timerId,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (seconds != null) 'seconds': seconds,
      if (mode != null) 'mode': mode,
      if (taskId != null) 'task_id': taskId,
      if (timerId != null) 'timer_id': timerId,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusRecordsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? seconds,
    Value<FocusMode>? mode,
    Value<String?>? taskId,
    Value<String?>? timerId,
    Value<String>? note,
    Value<int>? rowid,
  }) {
    return FocusRecordsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      seconds: seconds ?? this.seconds,
      mode: mode ?? this.mode,
      taskId: taskId ?? this.taskId,
      timerId: timerId ?? this.timerId,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>($FocusRecordsTable.$convertermode.toSql(mode.value));
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (timerId.present) {
      map['timer_id'] = Variable<String>(timerId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusRecordsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('seconds: $seconds, ')
          ..write('mode: $mode, ')
          ..write('taskId: $taskId, ')
          ..write('timerId: $timerId, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mottoMeta = const VerificationMeta('motto');
  @override
  late final GeneratedColumn<String> motto = GeneratedColumn<String>(
    'motto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitFrequency, String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(HabitFrequency.daily.code),
  ).withConverter<HabitFrequency>($HabitsTable.$converterfrequency);
  static const VerificationMeta _weekdaysMeta = const VerificationMeta('weekdays');
  @override
  late final GeneratedColumn<String> weekdays = GeneratedColumn<String>(
    'weekdays',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _perWeekMeta = const VerificationMeta('perWeek');
  @override
  late final GeneratedColumn<int> perWeek = GeneratedColumn<int>(
    'per_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _everyDaysMeta = const VerificationMeta('everyDays');
  @override
  late final GeneratedColumn<int> everyDays = GeneratedColumn<int>(
    'every_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitGoal, String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(HabitGoal.checkIn.code),
  ).withConverter<HabitGoal>($HabitsTable.$convertergoal);
  static const VerificationMeta _goalAmountMeta = const VerificationMeta('goalAmount');
  @override
  late final GeneratedColumn<double> goalAmount = GeneratedColumn<double>(
    'goal_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitCheckMode, String> checkMode = GeneratedColumn<String>(
    'check_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(HabitCheckMode.auto.code),
  ).withConverter<HabitCheckMode>($HabitsTable.$convertercheckMode);
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<double> step = GeneratedColumn<double>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDaysMeta = const VerificationMeta('targetDays');
  @override
  late final GeneratedColumn<int> targetDays = GeneratedColumn<int>(
    'target_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta('section');
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('others'),
  );
  static const VerificationMeta _remindersMeta = const VerificationMeta('reminders');
  @override
  late final GeneratedColumn<String> reminders = GeneratedColumn<String>(
    'reminders',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _autoShowLogMeta = const VerificationMeta('autoShowLog');
  @override
  late final GeneratedColumn<bool> autoShowLog = GeneratedColumn<bool>(
    'auto_show_log',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("auto_show_log" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    motto,
    icon,
    color,
    frequency,
    weekdays,
    perWeek,
    everyDays,
    goal,
    goalAmount,
    unit,
    checkMode,
    step,
    startDate,
    targetDays,
    section,
    reminders,
    autoShowLog,
    archivedAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(Insertable<Habit> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('motto')) {
      context.handle(_mottoMeta, motto.isAcceptableOrUnknown(data['motto']!, _mottoMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('weekdays')) {
      context.handle(_weekdaysMeta, weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta));
    }
    if (data.containsKey('per_week')) {
      context.handle(_perWeekMeta, perWeek.isAcceptableOrUnknown(data['per_week']!, _perWeekMeta));
    }
    if (data.containsKey('every_days')) {
      context.handle(_everyDaysMeta, everyDays.isAcceptableOrUnknown(data['every_days']!, _everyDaysMeta));
    }
    if (data.containsKey('goal_amount')) {
      context.handle(_goalAmountMeta, goalAmount.isAcceptableOrUnknown(data['goal_amount']!, _goalAmountMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(_unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('step')) {
      context.handle(_stepMeta, step.isAcceptableOrUnknown(data['step']!, _stepMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta, startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('target_days')) {
      context.handle(_targetDaysMeta, targetDays.isAcceptableOrUnknown(data['target_days']!, _targetDaysMeta));
    }
    if (data.containsKey('section')) {
      context.handle(_sectionMeta, section.isAcceptableOrUnknown(data['section']!, _sectionMeta));
    }
    if (data.containsKey('reminders')) {
      context.handle(_remindersMeta, reminders.isAcceptableOrUnknown(data['reminders']!, _remindersMeta));
    }
    if (data.containsKey('auto_show_log')) {
      context.handle(_autoShowLogMeta, autoShowLog.isAcceptableOrUnknown(data['auto_show_log']!, _autoShowLogMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(_archivedAtMeta, archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      motto: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}motto'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      color: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}color']),
      frequency: $HabitsTable.$converterfrequency.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      ),
      weekdays: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}weekdays'])!,
      perWeek: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}per_week'])!,
      everyDays: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}every_days'])!,
      goal: $HabitsTable.$convertergoal.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}goal'])!),
      goalAmount: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}goal_amount'])!,
      unit: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      checkMode: $HabitsTable.$convertercheckMode.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}check_mode'])!,
      ),
      step: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}step'])!,
      startDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      targetDays: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}target_days']),
      section: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}section'])!,
      reminders: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reminders'])!,
      autoShowLog: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}auto_show_log'])!,
      archivedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }

  static TypeConverter<HabitFrequency, String> $converterfrequency = const TextCodeConverter<HabitFrequency>(HabitFrequency.fromCode);
  static TypeConverter<HabitGoal, String> $convertergoal = const TextCodeConverter<HabitGoal>(HabitGoal.fromCode);
  static TypeConverter<HabitCheckMode, String> $convertercheckMode = const TextCodeConverter<HabitCheckMode>(HabitCheckMode.fromCode);
}

class Habit extends DataClass implements Insertable<Habit> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String name;

  /// "Frase motivacional", shown under the name (schema v15).
  final String motto;

  /// Emoji or one letter, on [color].
  final String icon;
  final String? color;
  final HabitFrequency frequency;

  /// Daily: the weekdays (1 = Monday … 7 = Sunday), comma separated; empty = every day.
  final String weekdays;

  /// Weekly: times per week. Interval: every N days.
  final int perWeek;
  final int everyDays;
  final HabitGoal goal;
  final double goalAmount;
  final String unit;
  final HabitCheckMode checkMode;

  /// Amount added by each "Automático" check-in.
  final double step;
  final DateTime startDate;

  /// "Dias de meta"; null = "Para sempre".
  final int? targetDays;
  final String section;

  /// Reminder times "HH:mm", comma separated.
  final String reminders;
  final bool autoShowLog;
  final DateTime? archivedAt;
  final int sortOrder;
  const Habit({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.motto,
    required this.icon,
    this.color,
    required this.frequency,
    required this.weekdays,
    required this.perWeek,
    required this.everyDays,
    required this.goal,
    required this.goalAmount,
    required this.unit,
    required this.checkMode,
    required this.step,
    required this.startDate,
    this.targetDays,
    required this.section,
    required this.reminders,
    required this.autoShowLog,
    this.archivedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['motto'] = Variable<String>(motto);
    map['icon'] = Variable<String>(icon);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    {
      map['frequency'] = Variable<String>($HabitsTable.$converterfrequency.toSql(frequency));
    }
    map['weekdays'] = Variable<String>(weekdays);
    map['per_week'] = Variable<int>(perWeek);
    map['every_days'] = Variable<int>(everyDays);
    {
      map['goal'] = Variable<String>($HabitsTable.$convertergoal.toSql(goal));
    }
    map['goal_amount'] = Variable<double>(goalAmount);
    map['unit'] = Variable<String>(unit);
    {
      map['check_mode'] = Variable<String>($HabitsTable.$convertercheckMode.toSql(checkMode));
    }
    map['step'] = Variable<double>(step);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || targetDays != null) {
      map['target_days'] = Variable<int>(targetDays);
    }
    map['section'] = Variable<String>(section);
    map['reminders'] = Variable<String>(reminders);
    map['auto_show_log'] = Variable<bool>(autoShowLog);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      name: Value(name),
      motto: Value(motto),
      icon: Value(icon),
      color: color == null && nullToAbsent ? const Value.absent() : Value(color),
      frequency: Value(frequency),
      weekdays: Value(weekdays),
      perWeek: Value(perWeek),
      everyDays: Value(everyDays),
      goal: Value(goal),
      goalAmount: Value(goalAmount),
      unit: Value(unit),
      checkMode: Value(checkMode),
      step: Value(step),
      startDate: Value(startDate),
      targetDays: targetDays == null && nullToAbsent ? const Value.absent() : Value(targetDays),
      section: Value(section),
      reminders: Value(reminders),
      autoShowLog: Value(autoShowLog),
      archivedAt: archivedAt == null && nullToAbsent ? const Value.absent() : Value(archivedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      motto: serializer.fromJson<String>(json['motto']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      frequency: serializer.fromJson<HabitFrequency>(json['frequency']),
      weekdays: serializer.fromJson<String>(json['weekdays']),
      perWeek: serializer.fromJson<int>(json['perWeek']),
      everyDays: serializer.fromJson<int>(json['everyDays']),
      goal: serializer.fromJson<HabitGoal>(json['goal']),
      goalAmount: serializer.fromJson<double>(json['goalAmount']),
      unit: serializer.fromJson<String>(json['unit']),
      checkMode: serializer.fromJson<HabitCheckMode>(json['checkMode']),
      step: serializer.fromJson<double>(json['step']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      targetDays: serializer.fromJson<int?>(json['targetDays']),
      section: serializer.fromJson<String>(json['section']),
      reminders: serializer.fromJson<String>(json['reminders']),
      autoShowLog: serializer.fromJson<bool>(json['autoShowLog']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'motto': serializer.toJson<String>(motto),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<String?>(color),
      'frequency': serializer.toJson<HabitFrequency>(frequency),
      'weekdays': serializer.toJson<String>(weekdays),
      'perWeek': serializer.toJson<int>(perWeek),
      'everyDays': serializer.toJson<int>(everyDays),
      'goal': serializer.toJson<HabitGoal>(goal),
      'goalAmount': serializer.toJson<double>(goalAmount),
      'unit': serializer.toJson<String>(unit),
      'checkMode': serializer.toJson<HabitCheckMode>(checkMode),
      'step': serializer.toJson<double>(step),
      'startDate': serializer.toJson<DateTime>(startDate),
      'targetDays': serializer.toJson<int?>(targetDays),
      'section': serializer.toJson<String>(section),
      'reminders': serializer.toJson<String>(reminders),
      'autoShowLog': serializer.toJson<bool>(autoShowLog),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Habit copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    String? motto,
    String? icon,
    Value<String?> color = const Value.absent(),
    HabitFrequency? frequency,
    String? weekdays,
    int? perWeek,
    int? everyDays,
    HabitGoal? goal,
    double? goalAmount,
    String? unit,
    HabitCheckMode? checkMode,
    double? step,
    DateTime? startDate,
    Value<int?> targetDays = const Value.absent(),
    String? section,
    String? reminders,
    bool? autoShowLog,
    Value<DateTime?> archivedAt = const Value.absent(),
    int? sortOrder,
  }) => Habit(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    motto: motto ?? this.motto,
    icon: icon ?? this.icon,
    color: color.present ? color.value : this.color,
    frequency: frequency ?? this.frequency,
    weekdays: weekdays ?? this.weekdays,
    perWeek: perWeek ?? this.perWeek,
    everyDays: everyDays ?? this.everyDays,
    goal: goal ?? this.goal,
    goalAmount: goalAmount ?? this.goalAmount,
    unit: unit ?? this.unit,
    checkMode: checkMode ?? this.checkMode,
    step: step ?? this.step,
    startDate: startDate ?? this.startDate,
    targetDays: targetDays.present ? targetDays.value : this.targetDays,
    section: section ?? this.section,
    reminders: reminders ?? this.reminders,
    autoShowLog: autoShowLog ?? this.autoShowLog,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      motto: data.motto.present ? data.motto.value : this.motto,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
      perWeek: data.perWeek.present ? data.perWeek.value : this.perWeek,
      everyDays: data.everyDays.present ? data.everyDays.value : this.everyDays,
      goal: data.goal.present ? data.goal.value : this.goal,
      goalAmount: data.goalAmount.present ? data.goalAmount.value : this.goalAmount,
      unit: data.unit.present ? data.unit.value : this.unit,
      checkMode: data.checkMode.present ? data.checkMode.value : this.checkMode,
      step: data.step.present ? data.step.value : this.step,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      targetDays: data.targetDays.present ? data.targetDays.value : this.targetDays,
      section: data.section.present ? data.section.value : this.section,
      reminders: data.reminders.present ? data.reminders.value : this.reminders,
      autoShowLog: data.autoShowLog.present ? data.autoShowLog.value : this.autoShowLog,
      archivedAt: data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('motto: $motto, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('frequency: $frequency, ')
          ..write('weekdays: $weekdays, ')
          ..write('perWeek: $perWeek, ')
          ..write('everyDays: $everyDays, ')
          ..write('goal: $goal, ')
          ..write('goalAmount: $goalAmount, ')
          ..write('unit: $unit, ')
          ..write('checkMode: $checkMode, ')
          ..write('step: $step, ')
          ..write('startDate: $startDate, ')
          ..write('targetDays: $targetDays, ')
          ..write('section: $section, ')
          ..write('reminders: $reminders, ')
          ..write('autoShowLog: $autoShowLog, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    motto,
    icon,
    color,
    frequency,
    weekdays,
    perWeek,
    everyDays,
    goal,
    goalAmount,
    unit,
    checkMode,
    step,
    startDate,
    targetDays,
    section,
    reminders,
    autoShowLog,
    archivedAt,
    sortOrder,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.motto == this.motto &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.frequency == this.frequency &&
          other.weekdays == this.weekdays &&
          other.perWeek == this.perWeek &&
          other.everyDays == this.everyDays &&
          other.goal == this.goal &&
          other.goalAmount == this.goalAmount &&
          other.unit == this.unit &&
          other.checkMode == this.checkMode &&
          other.step == this.step &&
          other.startDate == this.startDate &&
          other.targetDays == this.targetDays &&
          other.section == this.section &&
          other.reminders == this.reminders &&
          other.autoShowLog == this.autoShowLog &&
          other.archivedAt == this.archivedAt &&
          other.sortOrder == this.sortOrder);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String> motto;
  final Value<String> icon;
  final Value<String?> color;
  final Value<HabitFrequency> frequency;
  final Value<String> weekdays;
  final Value<int> perWeek;
  final Value<int> everyDays;
  final Value<HabitGoal> goal;
  final Value<double> goalAmount;
  final Value<String> unit;
  final Value<HabitCheckMode> checkMode;
  final Value<double> step;
  final Value<DateTime> startDate;
  final Value<int?> targetDays;
  final Value<String> section;
  final Value<String> reminders;
  final Value<bool> autoShowLog;
  final Value<DateTime?> archivedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.motto = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.frequency = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.perWeek = const Value.absent(),
    this.everyDays = const Value.absent(),
    this.goal = const Value.absent(),
    this.goalAmount = const Value.absent(),
    this.unit = const Value.absent(),
    this.checkMode = const Value.absent(),
    this.step = const Value.absent(),
    this.startDate = const Value.absent(),
    this.targetDays = const Value.absent(),
    this.section = const Value.absent(),
    this.reminders = const Value.absent(),
    this.autoShowLog = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    this.motto = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.frequency = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.perWeek = const Value.absent(),
    this.everyDays = const Value.absent(),
    this.goal = const Value.absent(),
    this.goalAmount = const Value.absent(),
    this.unit = const Value.absent(),
    this.checkMode = const Value.absent(),
    this.step = const Value.absent(),
    required DateTime startDate,
    this.targetDays = const Value.absent(),
    this.section = const Value.absent(),
    this.reminders = const Value.absent(),
    this.autoShowLog = const Value.absent(),
    this.archivedAt = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       startDate = Value(startDate),
       sortOrder = Value(sortOrder);
  static Insertable<Habit> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? motto,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<String>? frequency,
    Expression<String>? weekdays,
    Expression<int>? perWeek,
    Expression<int>? everyDays,
    Expression<String>? goal,
    Expression<double>? goalAmount,
    Expression<String>? unit,
    Expression<String>? checkMode,
    Expression<double>? step,
    Expression<DateTime>? startDate,
    Expression<int>? targetDays,
    Expression<String>? section,
    Expression<String>? reminders,
    Expression<bool>? autoShowLog,
    Expression<DateTime>? archivedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (motto != null) 'motto': motto,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (frequency != null) 'frequency': frequency,
      if (weekdays != null) 'weekdays': weekdays,
      if (perWeek != null) 'per_week': perWeek,
      if (everyDays != null) 'every_days': everyDays,
      if (goal != null) 'goal': goal,
      if (goalAmount != null) 'goal_amount': goalAmount,
      if (unit != null) 'unit': unit,
      if (checkMode != null) 'check_mode': checkMode,
      if (step != null) 'step': step,
      if (startDate != null) 'start_date': startDate,
      if (targetDays != null) 'target_days': targetDays,
      if (section != null) 'section': section,
      if (reminders != null) 'reminders': reminders,
      if (autoShowLog != null) 'auto_show_log': autoShowLog,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String>? motto,
    Value<String>? icon,
    Value<String?>? color,
    Value<HabitFrequency>? frequency,
    Value<String>? weekdays,
    Value<int>? perWeek,
    Value<int>? everyDays,
    Value<HabitGoal>? goal,
    Value<double>? goalAmount,
    Value<String>? unit,
    Value<HabitCheckMode>? checkMode,
    Value<double>? step,
    Value<DateTime>? startDate,
    Value<int?>? targetDays,
    Value<String>? section,
    Value<String>? reminders,
    Value<bool>? autoShowLog,
    Value<DateTime?>? archivedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      motto: motto ?? this.motto,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      perWeek: perWeek ?? this.perWeek,
      everyDays: everyDays ?? this.everyDays,
      goal: goal ?? this.goal,
      goalAmount: goalAmount ?? this.goalAmount,
      unit: unit ?? this.unit,
      checkMode: checkMode ?? this.checkMode,
      step: step ?? this.step,
      startDate: startDate ?? this.startDate,
      targetDays: targetDays ?? this.targetDays,
      section: section ?? this.section,
      reminders: reminders ?? this.reminders,
      autoShowLog: autoShowLog ?? this.autoShowLog,
      archivedAt: archivedAt ?? this.archivedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (motto.present) {
      map['motto'] = Variable<String>(motto.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>($HabitsTable.$converterfrequency.toSql(frequency.value));
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<String>(weekdays.value);
    }
    if (perWeek.present) {
      map['per_week'] = Variable<int>(perWeek.value);
    }
    if (everyDays.present) {
      map['every_days'] = Variable<int>(everyDays.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>($HabitsTable.$convertergoal.toSql(goal.value));
    }
    if (goalAmount.present) {
      map['goal_amount'] = Variable<double>(goalAmount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (checkMode.present) {
      map['check_mode'] = Variable<String>($HabitsTable.$convertercheckMode.toSql(checkMode.value));
    }
    if (step.present) {
      map['step'] = Variable<double>(step.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (targetDays.present) {
      map['target_days'] = Variable<int>(targetDays.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (reminders.present) {
      map['reminders'] = Variable<String>(reminders.value);
    }
    if (autoShowLog.present) {
      map['auto_show_log'] = Variable<bool>(autoShowLog.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('motto: $motto, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('frequency: $frequency, ')
          ..write('weekdays: $weekdays, ')
          ..write('perWeek: $perWeek, ')
          ..write('everyDays: $everyDays, ')
          ..write('goal: $goal, ')
          ..write('goalAmount: $goalAmount, ')
          ..write('unit: $unit, ')
          ..write('checkMode: $checkMode, ')
          ..write('step: $step, ')
          ..write('startDate: $startDate, ')
          ..write('targetDays: $targetDays, ')
          ..write('section: $section, ')
          ..write('reminders: $reminders, ')
          ..write('autoShowLog: $autoShowLog, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitCheckinsTable extends HabitCheckins with TableInfo<$HabitCheckinsTable, HabitCheckin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitCheckinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES habits (id)'),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitMark, String> mark = GeneratedColumn<String>(
    'mark',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(HabitMark.none.code),
  ).withConverter<HabitMark>($HabitCheckinsTable.$convertermark);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>('mood', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, habitId, day, value, mark, mood, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_checkins';
  @override
  VerificationContext validateIntegrity(Insertable<HabitCheckin> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta, habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('mood')) {
      context.handle(_moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitCheckin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitCheckin(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      habitId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}habit_id'])!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}day'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      mark: $HabitCheckinsTable.$convertermark.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}mark'])!),
      mood: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}mood']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $HabitCheckinsTable createAlias(String alias) {
    return $HabitCheckinsTable(attachedDatabase, alias);
  }

  static TypeConverter<HabitMark, String> $convertermark = const TextCodeConverter<HabitMark>(HabitMark.fromCode);
}

class HabitCheckin extends DataClass implements Insertable<HabitCheckin> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String habitId;
  final DateTime day;
  final double value;
  final HabitMark mark;
  final int? mood;
  final String note;
  const HabitCheckin({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.habitId,
    required this.day,
    required this.value,
    required this.mark,
    this.mood,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['habit_id'] = Variable<String>(habitId);
    map['day'] = Variable<DateTime>(day);
    map['value'] = Variable<double>(value);
    {
      map['mark'] = Variable<String>($HabitCheckinsTable.$convertermark.toSql(mark));
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  HabitCheckinsCompanion toCompanion(bool nullToAbsent) {
    return HabitCheckinsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      habitId: Value(habitId),
      day: Value(day),
      value: Value(value),
      mark: Value(mark),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      note: Value(note),
    );
  }

  factory HabitCheckin.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitCheckin(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      habitId: serializer.fromJson<String>(json['habitId']),
      day: serializer.fromJson<DateTime>(json['day']),
      value: serializer.fromJson<double>(json['value']),
      mark: serializer.fromJson<HabitMark>(json['mark']),
      mood: serializer.fromJson<int?>(json['mood']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'habitId': serializer.toJson<String>(habitId),
      'day': serializer.toJson<DateTime>(day),
      'value': serializer.toJson<double>(value),
      'mark': serializer.toJson<HabitMark>(mark),
      'mood': serializer.toJson<int?>(mood),
      'note': serializer.toJson<String>(note),
    };
  }

  HabitCheckin copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? habitId,
    DateTime? day,
    double? value,
    HabitMark? mark,
    Value<int?> mood = const Value.absent(),
    String? note,
  }) => HabitCheckin(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    habitId: habitId ?? this.habitId,
    day: day ?? this.day,
    value: value ?? this.value,
    mark: mark ?? this.mark,
    mood: mood.present ? mood.value : this.mood,
    note: note ?? this.note,
  );
  HabitCheckin copyWithCompanion(HabitCheckinsCompanion data) {
    return HabitCheckin(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      day: data.day.present ? data.day.value : this.day,
      value: data.value.present ? data.value.value : this.value,
      mark: data.mark.present ? data.mark.value : this.mark,
      mood: data.mood.present ? data.mood.value : this.mood,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitCheckin(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('value: $value, ')
          ..write('mark: $mark, ')
          ..write('mood: $mood, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, habitId, day, value, mark, mood, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitCheckin &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.habitId == this.habitId &&
          other.day == this.day &&
          other.value == this.value &&
          other.mark == this.mark &&
          other.mood == this.mood &&
          other.note == this.note);
}

class HabitCheckinsCompanion extends UpdateCompanion<HabitCheckin> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> habitId;
  final Value<DateTime> day;
  final Value<double> value;
  final Value<HabitMark> mark;
  final Value<int?> mood;
  final Value<String> note;
  final Value<int> rowid;
  const HabitCheckinsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.habitId = const Value.absent(),
    this.day = const Value.absent(),
    this.value = const Value.absent(),
    this.mark = const Value.absent(),
    this.mood = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitCheckinsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String habitId,
    required DateTime day,
    this.value = const Value.absent(),
    this.mark = const Value.absent(),
    this.mood = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       habitId = Value(habitId),
       day = Value(day);
  static Insertable<HabitCheckin> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? habitId,
    Expression<DateTime>? day,
    Expression<double>? value,
    Expression<String>? mark,
    Expression<int>? mood,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (habitId != null) 'habit_id': habitId,
      if (day != null) 'day': day,
      if (value != null) 'value': value,
      if (mark != null) 'mark': mark,
      if (mood != null) 'mood': mood,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitCheckinsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? habitId,
    Value<DateTime>? day,
    Value<double>? value,
    Value<HabitMark>? mark,
    Value<int?>? mood,
    Value<String>? note,
    Value<int>? rowid,
  }) {
    return HabitCheckinsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      habitId: habitId ?? this.habitId,
      day: day ?? this.day,
      value: value ?? this.value,
      mark: mark ?? this.mark,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (mark.present) {
      map['mark'] = Variable<String>($HabitCheckinsTable.$convertermark.toSql(mark.value));
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('value: $value, ')
          ..write('mark: $mark, ')
          ..write('mood: $mood, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FiltersTable extends Filters with TableInfo<$FiltersTable, TaskFilter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiltersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleMeta = const VerificationMeta('rule');
  @override
  late final GeneratedColumn<String> rule = GeneratedColumn<String>(
    'rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta('pinnedAt');
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, name, rule, pinnedAt, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'filters';
  @override
  VerificationContext validateIntegrity(Insertable<TaskFilter> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rule')) {
      context.handle(_ruleMeta, rule.isAcceptableOrUnknown(data['rule']!, _ruleMeta));
    } else if (isInserting) {
      context.missing(_ruleMeta);
    }
    if (data.containsKey('pinned_at')) {
      context.handle(_pinnedAtMeta, pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskFilter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskFilter(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      rule: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}rule'])!,
      pinnedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}pinned_at']),
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $FiltersTable createAlias(String alias) {
    return $FiltersTable(attachedDatabase, alias);
  }
}

class TaskFilter extends DataClass implements Insertable<TaskFilter> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String name;
  final String rule;
  final DateTime? pinnedAt;
  final int sortOrder;
  const TaskFilter({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.rule,
    this.pinnedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['rule'] = Variable<String>(rule);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FiltersCompanion toCompanion(bool nullToAbsent) {
    return FiltersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      name: Value(name),
      rule: Value(rule),
      pinnedAt: pinnedAt == null && nullToAbsent ? const Value.absent() : Value(pinnedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory TaskFilter.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskFilter(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      rule: serializer.fromJson<String>(json['rule']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'rule': serializer.toJson<String>(rule),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TaskFilter copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    String? rule,
    Value<DateTime?> pinnedAt = const Value.absent(),
    int? sortOrder,
  }) => TaskFilter(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    rule: rule ?? this.rule,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TaskFilter copyWithCompanion(FiltersCompanion data) {
    return TaskFilter(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      rule: data.rule.present ? data.rule.value : this.rule,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskFilter(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('rule: $rule, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, name, rule, pinnedAt, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskFilter &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.rule == this.rule &&
          other.pinnedAt == this.pinnedAt &&
          other.sortOrder == this.sortOrder);
}

class FiltersCompanion extends UpdateCompanion<TaskFilter> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String> rule;
  final Value<DateTime?> pinnedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const FiltersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.rule = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FiltersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required String rule,
    this.pinnedAt = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       rule = Value(rule),
       sortOrder = Value(sortOrder);
  static Insertable<TaskFilter> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? rule,
    Expression<DateTime>? pinnedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (rule != null) 'rule': rule,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FiltersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String>? rule,
    Value<DateTime?>? pinnedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return FiltersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      rule: rule ?? this.rule,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rule.present) {
      map['rule'] = Variable<String>(rule.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiltersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('rule: $rule, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivitiesTable extends Activities with TableInfo<$ActivitiesTable, Activity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityAction, String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ActivityAction>($ActivitiesTable.$converteraction);
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, deletedAt, taskId, listId, action, detail];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(Insertable<Activity> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta, listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    }
    if (data.containsKey('detail')) {
      context.handle(_detailMeta, detail.isAcceptableOrUnknown(data['detail']!, _detailMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Activity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Activity(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      taskId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}task_id']),
      listId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}list_id']),
      action: $ActivitiesTable.$converteraction.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}action'])!),
      detail: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}detail'])!,
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }

  static TypeConverter<ActivityAction, String> $converteraction = const TextCodeConverter<ActivityAction>(ActivityAction.fromCode);
}

class Activity extends DataClass implements Insertable<Activity> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  final DateTime? deletedAt;
  final String? taskId;
  final String? listId;
  final ActivityAction action;
  final String detail;
  const Activity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.taskId,
    this.listId,
    required this.action,
    required this.detail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || listId != null) {
      map['list_id'] = Variable<String>(listId);
    }
    {
      map['action'] = Variable<String>($ActivitiesTable.$converteraction.toSql(action));
    }
    map['detail'] = Variable<String>(detail);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      taskId: taskId == null && nullToAbsent ? const Value.absent() : Value(taskId),
      listId: listId == null && nullToAbsent ? const Value.absent() : Value(listId),
      action: Value(action),
      detail: Value(detail),
    );
  }

  factory Activity.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Activity(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      listId: serializer.fromJson<String?>(json['listId']),
      action: serializer.fromJson<ActivityAction>(json['action']),
      detail: serializer.fromJson<String>(json['detail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'taskId': serializer.toJson<String?>(taskId),
      'listId': serializer.toJson<String?>(listId),
      'action': serializer.toJson<ActivityAction>(action),
      'detail': serializer.toJson<String>(detail),
    };
  }

  Activity copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    Value<String?> listId = const Value.absent(),
    ActivityAction? action,
    String? detail,
  }) => Activity(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    taskId: taskId.present ? taskId.value : this.taskId,
    listId: listId.present ? listId.value : this.listId,
    action: action ?? this.action,
    detail: detail ?? this.detail,
  );
  Activity copyWithCompanion(ActivitiesCompanion data) {
    return Activity(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      listId: data.listId.present ? data.listId.value : this.listId,
      action: data.action.present ? data.action.value : this.action,
      detail: data.detail.present ? data.detail.value : this.detail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Activity(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('listId: $listId, ')
          ..write('action: $action, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, taskId, listId, action, detail);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Activity &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.taskId == this.taskId &&
          other.listId == this.listId &&
          other.action == this.action &&
          other.detail == this.detail);
}

class ActivitiesCompanion extends UpdateCompanion<Activity> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> taskId;
  final Value<String?> listId;
  final Value<ActivityAction> action;
  final Value<String> detail;
  final Value<int> rowid;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.taskId = const Value.absent(),
    this.listId = const Value.absent(),
    this.action = const Value.absent(),
    this.detail = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.taskId = const Value.absent(),
    this.listId = const Value.absent(),
    required ActivityAction action,
    this.detail = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       action = Value(action);
  static Insertable<Activity> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? taskId,
    Expression<String>? listId,
    Expression<String>? action,
    Expression<String>? detail,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (taskId != null) 'task_id': taskId,
      if (listId != null) 'list_id': listId,
      if (action != null) 'action': action,
      if (detail != null) 'detail': detail,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitiesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? taskId,
    Value<String?>? listId,
    Value<ActivityAction>? action,
    Value<String>? detail,
    Value<int>? rowid,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      taskId: taskId ?? this.taskId,
      listId: listId ?? this.listId,
      action: action ?? this.action,
      detail: detail ?? this.detail,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>($ActivitiesTable.$converteraction.toSql(action.value));
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('listId: $listId, ')
          ..write('action: $action, ')
          ..write('detail: $detail, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $ListsTable lists = $ListsTable(this);
  late final $SectionsTable sections = $SectionsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $ChecklistItemsTable checklistItems = $ChecklistItemsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TaskTagsTable taskTags = $TaskTagsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $TaskRemindersTable taskReminders = $TaskRemindersTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $CommentsTable comments = $CommentsTable(this);
  late final $CountdownsTable countdowns = $CountdownsTable(this);
  late final $FocusRecordsTable focusRecords = $FocusRecordsTable(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitCheckinsTable habitCheckins = $HabitCheckinsTable(this);
  late final $FiltersTable filters = $FiltersTable(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    folders,
    lists,
    sections,
    tasks,
    checklistItems,
    tags,
    taskTags,
    preferences,
    taskReminders,
    templates,
    comments,
    countdowns,
    focusRecords,
    habits,
    habitCheckins,
    filters,
    activities,
  ];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  Value<DateTime?> pinnedAt,
  Value<bool> isCollapsed,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<DateTime?> pinnedAt,
  Value<bool> isCollapsed,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$FoldersTableReferences extends BaseReferences<_$AppDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ListsTable, List<TaskList>> _listsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lists, aliasName: 'folders__id__lists__folder_id');

  $$ListsTableProcessedTableManager get listsRefs {
    final manager = $$ListsTableTableManager($_db, $_db.lists).filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_listsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FoldersTableFilterComposer extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCollapsed => $composableBuilder(column: $table.isCollapsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> listsRefs(Expression<bool> Function($$ListsTableFilterComposer f) f) {
    final $$ListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.folderId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ListsTableFilterComposer(
        $db: $db,
        $table: $db.lists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCollapsed => $composableBuilder(column: $table.isCollapsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$FoldersTableAnnotationComposer extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<bool> get isCollapsed => $composableBuilder(column: $table.isCollapsed, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> listsRefs<T extends Object>(Expression<T> Function($$ListsTableAnnotationComposer a) f) {
    final $$ListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.folderId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ListsTableAnnotationComposer(
        $db: $db,
        $table: $db.lists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({bool listsRefs})
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<bool> isCollapsed = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                pinnedAt: pinnedAt,
                isCollapsed: isCollapsed,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<bool> isCollapsed = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                pinnedAt: pinnedAt,
                isCollapsed: isCollapsed,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable<$FoldersTable, Folder>(table), $$FoldersTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({listsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (listsRefs) db.lists],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (listsRefs)
                    await $_getPrefetchedData<Folder, $FoldersTable, TaskList>(
                      currentTable: table,
                      referencedTable: $$FoldersTableReferences._listsRefsTable(db),
                      managerFromTypedResult: (p0) => $$FoldersTableReferences(db, table, p0).listsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({bool listsRefs})
    >;
typedef $$ListsTableCreateCompanionBuilder = ListsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  Value<String?> emoji,
  Value<String?> color,
  Value<String?> folderId,
  Value<ListKind> kind,
  Value<ViewMode> viewMode,
  Value<bool> showInSmartLists,
  Value<DateTime?> pinnedAt,
  Value<DateTime?> archivedAt,
  required int sortOrder,
  Value<Grouping> groupBy,
  Value<Sorting> sortBy,
  Value<bool> showCompleted,
  Value<bool> showDetails,
  Value<bool> dateAsCountdown,
  Value<int> rowid,
});
typedef $$ListsTableUpdateCompanionBuilder = ListsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<String?> emoji,
  Value<String?> color,
  Value<String?> folderId,
  Value<ListKind> kind,
  Value<ViewMode> viewMode,
  Value<bool> showInSmartLists,
  Value<DateTime?> pinnedAt,
  Value<DateTime?> archivedAt,
  Value<int> sortOrder,
  Value<Grouping> groupBy,
  Value<Sorting> sortBy,
  Value<bool> showCompleted,
  Value<bool> showDetails,
  Value<bool> dateAsCountdown,
  Value<int> rowid,
});

final class $$ListsTableReferences extends BaseReferences<_$AppDatabase, $ListsTable, TaskList> {
  $$ListsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _folderIdTable(_$AppDatabase db) => db.folders.createAlias('lists__folder_id__folders__id');

  $$FoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager($_db, $_db.folders).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SectionsTable, List<Section>> _sectionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sections, aliasName: 'lists__id__sections__list_id');

  $$SectionsTableProcessedTableManager get sectionsRefs {
    final manager = $$SectionsTableTableManager($_db, $_db.sections).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sectionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.tasks, aliasName: 'lists__id__tasks__list_id');

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ListsTableFilterComposer extends Composer<_$AppDatabase, $ListsTable> {
  $$ListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emoji => $composableBuilder(column: $table.emoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ListKind, ListKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ViewMode, ViewMode, String> get viewMode =>
      $composableBuilder(column: $table.viewMode, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get showInSmartLists => $composableBuilder(column: $table.showInSmartLists, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Grouping, Grouping, String> get groupBy =>
      $composableBuilder(column: $table.groupBy, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Sorting, Sorting, String> get sortBy =>
      $composableBuilder(column: $table.sortBy, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get showCompleted => $composableBuilder(column: $table.showCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showDetails => $composableBuilder(column: $table.showDetails, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dateAsCountdown => $composableBuilder(column: $table.dateAsCountdown, builder: (column) => ColumnFilters(column));

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FoldersTableFilterComposer(
        $db: $db,
        $table: $db.folders,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<bool> sectionsRefs(Expression<bool> Function($$SectionsTableFilterComposer f) f) {
    final $$SectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sections,
      getReferencedColumn: (t) => t.listId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$SectionsTableFilterComposer(
        $db: $db,
        $table: $db.sections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(Expression<bool> Function($$TasksTableFilterComposer f) f) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.listId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableFilterComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$ListsTableOrderingComposer extends Composer<_$AppDatabase, $ListsTable> {
  $$ListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emoji => $composableBuilder(column: $table.emoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get viewMode => $composableBuilder(column: $table.viewMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showInSmartLists => $composableBuilder(column: $table.showInSmartLists, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupBy => $composableBuilder(column: $table.groupBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sortBy => $composableBuilder(column: $table.sortBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showCompleted => $composableBuilder(column: $table.showCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showDetails => $composableBuilder(column: $table.showDetails, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dateAsCountdown => $composableBuilder(column: $table.dateAsCountdown, builder: (column) => ColumnOrderings(column));

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FoldersTableOrderingComposer(
        $db: $db,
        $table: $db.folders,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$ListsTableAnnotationComposer extends Composer<_$AppDatabase, $ListsTable> {
  $$ListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji => $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ListKind, String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ViewMode, String> get viewMode => $composableBuilder(column: $table.viewMode, builder: (column) => column);

  GeneratedColumn<bool> get showInSmartLists => $composableBuilder(column: $table.showInSmartLists, builder: (column) => column);

  GeneratedColumn<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Grouping, String> get groupBy => $composableBuilder(column: $table.groupBy, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Sorting, String> get sortBy => $composableBuilder(column: $table.sortBy, builder: (column) => column);

  GeneratedColumn<bool> get showCompleted => $composableBuilder(column: $table.showCompleted, builder: (column) => column);

  GeneratedColumn<bool> get showDetails => $composableBuilder(column: $table.showDetails, builder: (column) => column);

  GeneratedColumn<bool> get dateAsCountdown => $composableBuilder(column: $table.dateAsCountdown, builder: (column) => column);

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FoldersTableAnnotationComposer(
        $db: $db,
        $table: $db.folders,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<T> sectionsRefs<T extends Object>(Expression<T> Function($$SectionsTableAnnotationComposer a) f) {
    final $$SectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sections,
      getReferencedColumn: (t) => t.listId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$SectionsTableAnnotationComposer(
        $db: $db,
        $table: $db.sections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(Expression<T> Function($$TasksTableAnnotationComposer a) f) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.listId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableAnnotationComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$ListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListsTable,
          TaskList,
          $$ListsTableFilterComposer,
          $$ListsTableOrderingComposer,
          $$ListsTableAnnotationComposer,
          $$ListsTableCreateCompanionBuilder,
          $$ListsTableUpdateCompanionBuilder,
          (TaskList, $$ListsTableReferences),
          TaskList,
          PrefetchHooks Function({bool folderId, bool sectionsRefs, bool tasksRefs})
        > {
  $$ListsTableTableManager(_$AppDatabase db, $ListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<ListKind> kind = const Value.absent(),
                Value<ViewMode> viewMode = const Value.absent(),
                Value<bool> showInSmartLists = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<Grouping> groupBy = const Value.absent(),
                Value<Sorting> sortBy = const Value.absent(),
                Value<bool> showCompleted = const Value.absent(),
                Value<bool> showDetails = const Value.absent(),
                Value<bool> dateAsCountdown = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                emoji: emoji,
                color: color,
                folderId: folderId,
                kind: kind,
                viewMode: viewMode,
                showInSmartLists: showInSmartLists,
                pinnedAt: pinnedAt,
                archivedAt: archivedAt,
                sortOrder: sortOrder,
                groupBy: groupBy,
                sortBy: sortBy,
                showCompleted: showCompleted,
                showDetails: showDetails,
                dateAsCountdown: dateAsCountdown,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<String?> emoji = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<ListKind> kind = const Value.absent(),
                Value<ViewMode> viewMode = const Value.absent(),
                Value<bool> showInSmartLists = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                required int sortOrder,
                Value<Grouping> groupBy = const Value.absent(),
                Value<Sorting> sortBy = const Value.absent(),
                Value<bool> showCompleted = const Value.absent(),
                Value<bool> showDetails = const Value.absent(),
                Value<bool> dateAsCountdown = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                emoji: emoji,
                color: color,
                folderId: folderId,
                kind: kind,
                viewMode: viewMode,
                showInSmartLists: showInSmartLists,
                pinnedAt: pinnedAt,
                archivedAt: archivedAt,
                sortOrder: sortOrder,
                groupBy: groupBy,
                sortBy: sortBy,
                showCompleted: showCompleted,
                showDetails: showDetails,
                dateAsCountdown: dateAsCountdown,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable<$ListsTable, TaskList>(table), $$ListsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({folderId = false, sectionsRefs = false, tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sectionsRefs) db.sections, if (tasksRefs) db.tasks],
              addJoins:
                  <T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic>>(
                    state,
                  ) {
                    if (folderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.folderId,
                        referencedTable: $$ListsTableReferences._folderIdTable(db),
                        referencedColumn: $$ListsTableReferences._folderIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sectionsRefs)
                    await $_getPrefetchedData<TaskList, $ListsTable, Section>(
                      currentTable: table,
                      referencedTable: $$ListsTableReferences._sectionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ListsTableReferences(db, table, p0).sectionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.listId == item.id),
                      typedResults: items,
                    ),
                  if (tasksRefs)
                    await $_getPrefetchedData<TaskList, $ListsTable, Task>(
                      currentTable: table,
                      referencedTable: $$ListsTableReferences._tasksRefsTable(db),
                      managerFromTypedResult: (p0) => $$ListsTableReferences(db, table, p0).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.listId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListsTable,
      TaskList,
      $$ListsTableFilterComposer,
      $$ListsTableOrderingComposer,
      $$ListsTableAnnotationComposer,
      $$ListsTableCreateCompanionBuilder,
      $$ListsTableUpdateCompanionBuilder,
      (TaskList, $$ListsTableReferences),
      TaskList,
      PrefetchHooks Function({bool folderId, bool sectionsRefs, bool tasksRefs})
    >;
typedef $$SectionsTableCreateCompanionBuilder = SectionsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String listId,
  required String name,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$SectionsTableUpdateCompanionBuilder = SectionsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> listId,
  Value<String> name,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$SectionsTableReferences extends BaseReferences<_$AppDatabase, $SectionsTable, Section> {
  $$SectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ListsTable _listIdTable(_$AppDatabase db) => db.lists.createAlias('sections__list_id__lists__id');

  $$ListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$ListsTableTableManager($_db, $_db.lists).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.tasks, aliasName: 'sections__id__tasks__section_id');

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.sectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SectionsTableFilterComposer extends Composer<_$AppDatabase, $SectionsTable> {
  $$SectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$ListsTableFilterComposer get listId {
    final $$ListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ListsTableFilterComposer(
        $db: $db,
        $table: $db.lists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<bool> tasksRefs(Expression<bool> Function($$TasksTableFilterComposer f) f) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.sectionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableFilterComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$SectionsTableOrderingComposer extends Composer<_$AppDatabase, $SectionsTable> {
  $$SectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$ListsTableOrderingComposer get listId {
    final $$ListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ListsTableOrderingComposer(
        $db: $db,
        $table: $db.lists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$SectionsTableAnnotationComposer extends Composer<_$AppDatabase, $SectionsTable> {
  $$SectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ListsTableAnnotationComposer get listId {
    final $$ListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ListsTableAnnotationComposer(
        $db: $db,
        $table: $db.lists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<T> tasksRefs<T extends Object>(Expression<T> Function($$TasksTableAnnotationComposer a) f) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.sectionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableAnnotationComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$SectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SectionsTable,
          Section,
          $$SectionsTableFilterComposer,
          $$SectionsTableOrderingComposer,
          $$SectionsTableAnnotationComposer,
          $$SectionsTableCreateCompanionBuilder,
          $$SectionsTableUpdateCompanionBuilder,
          (Section, $$SectionsTableReferences),
          Section,
          PrefetchHooks Function({bool listId, bool tasksRefs})
        > {
  $$SectionsTableTableManager(_$AppDatabase db, $SectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SectionsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                listId: listId,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String listId,
                required String name,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => SectionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                listId: listId,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable<$SectionsTable, Section>(table), $$SectionsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({listId = false, tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins:
                  <T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic>>(
                    state,
                  ) {
                    if (listId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.listId,
                        referencedTable: $$SectionsTableReferences._listIdTable(db),
                        referencedColumn: $$SectionsTableReferences._listIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<Section, $SectionsTable, Task>(
                      currentTable: table,
                      referencedTable: $$SectionsTableReferences._tasksRefsTable(db),
                      managerFromTypedResult: (p0) => $$SectionsTableReferences(db, table, p0).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.sectionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SectionsTable,
      Section,
      $$SectionsTableFilterComposer,
      $$SectionsTableOrderingComposer,
      $$SectionsTableAnnotationComposer,
      $$SectionsTableCreateCompanionBuilder,
      $$SectionsTableUpdateCompanionBuilder,
      (Section, $$SectionsTableReferences),
      Section,
      PrefetchHooks Function({bool listId, bool tasksRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String listId,
  Value<String?> sectionId,
  Value<String?> parentId,
  Value<TaskKind> kind,
  Value<String> title,
  Value<String> content,
  Value<Priority> priority,
  Value<TaskStatus> status,
  Value<DateTime?> completedAt,
  Value<DateTime?> startDate,
  Value<DateTime?> dueDate,
  Value<bool> isAllDay,
  Value<String?> timeZone,
  Value<bool> isFloating,
  Value<DateTime?> pinnedAt,
  Value<int> progress,
  required int sortOrder,
  Value<String?> repeatRule,
  Value<String?> repeatFrom,
  Value<DateTime?> snoozeUntil,
  Value<int?> estimatedPomos,
  Value<int?> estimatedMinutes,
  Value<String?> color,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> listId,
  Value<String?> sectionId,
  Value<String?> parentId,
  Value<TaskKind> kind,
  Value<String> title,
  Value<String> content,
  Value<Priority> priority,
  Value<TaskStatus> status,
  Value<DateTime?> completedAt,
  Value<DateTime?> startDate,
  Value<DateTime?> dueDate,
  Value<bool> isAllDay,
  Value<String?> timeZone,
  Value<bool> isFloating,
  Value<DateTime?> pinnedAt,
  Value<int> progress,
  Value<int> sortOrder,
  Value<String?> repeatRule,
  Value<String?> repeatFrom,
  Value<DateTime?> snoozeUntil,
  Value<int?> estimatedPomos,
  Value<int?> estimatedMinutes,
  Value<String?> color,
  Value<int> rowid,
});

final class $$TasksTableReferences extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ListsTable _listIdTable(_$AppDatabase db) => db.lists.createAlias('tasks__list_id__lists__id');

  $$ListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$ListsTableTableManager($_db, $_db.lists).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SectionsTable _sectionIdTable(_$AppDatabase db) => db.sections.createAlias('tasks__section_id__sections__id');

  $$SectionsTableProcessedTableManager? get sectionId {
    final $_column = $_itemColumn<String>('section_id');
    if ($_column == null) return null;
    final manager = $$SectionsTableTableManager($_db, $_db.sections).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TasksTable _parentIdTable(_$AppDatabase db) => db.tasks.createAlias('tasks__parent_id__tasks__id');

  $$TasksTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ChecklistItemsTable, List<ChecklistItem>> _checklistItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.checklistItems, aliasName: 'tasks__id__checklist_items__task_id');

  $$ChecklistItemsTableProcessedTableManager get checklistItemsRefs {
    final manager = $$ChecklistItemsTableTableManager($_db, $_db.checklistItems).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_checklistItemsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TaskTagsTable, List<TaskTag>> _taskTagsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.taskTags, aliasName: 'tasks__id__task_tags__task_id');

  $$TaskTagsTableProcessedTableManager get taskTagsRefs {
    final manager = $$TaskTagsTableTableManager($_db, $_db.taskTags).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TaskRemindersTable, List<TaskReminder>> _taskRemindersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.taskReminders, aliasName: 'tasks__id__task_reminders__task_id');

  $$TaskRemindersTableProcessedTableManager get taskRemindersRefs {
    final manager = $$TaskRemindersTableTableManager($_db, $_db.taskReminders).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskRemindersRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CommentsTable, List<Comment>> _commentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.comments, aliasName: 'tasks__id__comments__task_id');

  $$CommentsTableProcessedTableManager get commentsRefs {
    final manager = $$CommentsTableTableManager($_db, $_db.comments).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_commentsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TaskKind, TaskKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Priority, Priority, int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAllDay => $composableBuilder(column: $table.isAllDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeZone => $composableBuilder(column: $table.timeZone, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFloating => $composableBuilder(column: $table.isFloating, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progress => $composableBuilder(column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeatRule => $composableBuilder(column: $table.repeatRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeatFrom => $composableBuilder(column: $table.repeatFrom, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get snoozeUntil => $composableBuilder(column: $table.snoozeUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedPomos => $composableBuilder(column: $table.estimatedPomos, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(column: $table.estimatedMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  $$ListsTableFilterComposer get listId {
    final $$ListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ListsTableFilterComposer(
        $db: $db,
        $table: $db.lists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$SectionsTableFilterComposer get sectionId {
    final $$SectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sectionId,
      referencedTable: $db.sections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$SectionsTableFilterComposer(
        $db: $db,
        $table: $db.sections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get parentId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableFilterComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<bool> checklistItemsRefs(Expression<bool> Function($$ChecklistItemsTableFilterComposer f) f) {
    final $$ChecklistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checklistItems,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ChecklistItemsTableFilterComposer(
        $db: $db,
        $table: $db.checklistItems,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> taskTagsRefs(Expression<bool> Function($$TaskTagsTableFilterComposer f) f) {
    final $$TaskTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TaskTagsTableFilterComposer(
        $db: $db,
        $table: $db.taskTags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> taskRemindersRefs(Expression<bool> Function($$TaskRemindersTableFilterComposer f) f) {
    final $$TaskRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TaskRemindersTableFilterComposer(
        $db: $db,
        $table: $db.taskReminders,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> commentsRefs(Expression<bool> Function($$CommentsTableFilterComposer f) f) {
    final $$CommentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comments,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$CommentsTableFilterComposer(
        $db: $db,
        $table: $db.comments,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAllDay => $composableBuilder(column: $table.isAllDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeZone => $composableBuilder(column: $table.timeZone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFloating => $composableBuilder(column: $table.isFloating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progress => $composableBuilder(column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatRule => $composableBuilder(column: $table.repeatRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatFrom => $composableBuilder(column: $table.repeatFrom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get snoozeUntil => $composableBuilder(column: $table.snoozeUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedPomos => $composableBuilder(column: $table.estimatedPomos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(column: $table.estimatedMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  $$ListsTableOrderingComposer get listId {
    final $$ListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ListsTableOrderingComposer(
        $db: $db,
        $table: $db.lists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$SectionsTableOrderingComposer get sectionId {
    final $$SectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sectionId,
      referencedTable: $db.sections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$SectionsTableOrderingComposer(
        $db: $db,
        $table: $db.sections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get parentId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableOrderingComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskKind, String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content => $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Priority, int> get priority => $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, int> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate => $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate => $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay => $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<String> get timeZone => $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<bool> get isFloating => $composableBuilder(column: $table.isFloating, builder: (column) => column);

  GeneratedColumn<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<int> get progress => $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(column: $table.repeatRule, builder: (column) => column);

  GeneratedColumn<String> get repeatFrom => $composableBuilder(column: $table.repeatFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozeUntil => $composableBuilder(column: $table.snoozeUntil, builder: (column) => column);

  GeneratedColumn<int> get estimatedPomos => $composableBuilder(column: $table.estimatedPomos, builder: (column) => column);

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(column: $table.estimatedMinutes, builder: (column) => column);

  GeneratedColumn<String> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  $$ListsTableAnnotationComposer get listId {
    final $$ListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ListsTableAnnotationComposer(
        $db: $db,
        $table: $db.lists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$SectionsTableAnnotationComposer get sectionId {
    final $$SectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sectionId,
      referencedTable: $db.sections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$SectionsTableAnnotationComposer(
        $db: $db,
        $table: $db.sections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get parentId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableAnnotationComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<T> checklistItemsRefs<T extends Object>(Expression<T> Function($$ChecklistItemsTableAnnotationComposer a) f) {
    final $$ChecklistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checklistItems,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ChecklistItemsTableAnnotationComposer(
        $db: $db,
        $table: $db.checklistItems,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<T> taskTagsRefs<T extends Object>(Expression<T> Function($$TaskTagsTableAnnotationComposer a) f) {
    final $$TaskTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TaskTagsTableAnnotationComposer(
        $db: $db,
        $table: $db.taskTags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<T> taskRemindersRefs<T extends Object>(Expression<T> Function($$TaskRemindersTableAnnotationComposer a) f) {
    final $$TaskRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TaskRemindersTableAnnotationComposer(
        $db: $db,
        $table: $db.taskReminders,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<T> commentsRefs<T extends Object>(Expression<T> Function($$CommentsTableAnnotationComposer a) f) {
    final $$CommentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comments,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$CommentsTableAnnotationComposer(
        $db: $db,
        $table: $db.comments,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool listId,
            bool sectionId,
            bool parentId,
            bool checklistItemsRefs,
            bool taskTagsRefs,
            bool taskRemindersRefs,
            bool commentsRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String?> sectionId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<TaskKind> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<Priority> priority = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<bool> isFloating = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<String?> repeatFrom = const Value.absent(),
                Value<DateTime?> snoozeUntil = const Value.absent(),
                Value<int?> estimatedPomos = const Value.absent(),
                Value<int?> estimatedMinutes = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                listId: listId,
                sectionId: sectionId,
                parentId: parentId,
                kind: kind,
                title: title,
                content: content,
                priority: priority,
                status: status,
                completedAt: completedAt,
                startDate: startDate,
                dueDate: dueDate,
                isAllDay: isAllDay,
                timeZone: timeZone,
                isFloating: isFloating,
                pinnedAt: pinnedAt,
                progress: progress,
                sortOrder: sortOrder,
                repeatRule: repeatRule,
                repeatFrom: repeatFrom,
                snoozeUntil: snoozeUntil,
                estimatedPomos: estimatedPomos,
                estimatedMinutes: estimatedMinutes,
                color: color,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String listId,
                Value<String?> sectionId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<TaskKind> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<Priority> priority = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<bool> isFloating = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<int> progress = const Value.absent(),
                required int sortOrder,
                Value<String?> repeatRule = const Value.absent(),
                Value<String?> repeatFrom = const Value.absent(),
                Value<DateTime?> snoozeUntil = const Value.absent(),
                Value<int?> estimatedPomos = const Value.absent(),
                Value<int?> estimatedMinutes = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                listId: listId,
                sectionId: sectionId,
                parentId: parentId,
                kind: kind,
                title: title,
                content: content,
                priority: priority,
                status: status,
                completedAt: completedAt,
                startDate: startDate,
                dueDate: dueDate,
                isAllDay: isAllDay,
                timeZone: timeZone,
                isFloating: isFloating,
                pinnedAt: pinnedAt,
                progress: progress,
                sortOrder: sortOrder,
                repeatRule: repeatRule,
                repeatFrom: repeatFrom,
                snoozeUntil: snoozeUntil,
                estimatedPomos: estimatedPomos,
                estimatedMinutes: estimatedMinutes,
                color: color,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable<$TasksTable, Task>(table), $$TasksTableReferences(db, table, e))).toList(),
          prefetchHooksCallback:
              ({
                listId = false,
                sectionId = false,
                parentId = false,
                checklistItemsRefs = false,
                taskTagsRefs = false,
                taskRemindersRefs = false,
                commentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (checklistItemsRefs) db.checklistItems,
                    if (taskTagsRefs) db.taskTags,
                    if (taskRemindersRefs) db.taskReminders,
                    if (commentsRefs) db.comments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic>
                      >(state) {
                        if (listId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.listId,
                            referencedTable: $$TasksTableReferences._listIdTable(db),
                            referencedColumn: $$TasksTableReferences._listIdTable(db).id,
                          ) as T;
                        }
                        if (sectionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sectionId,
                            referencedTable: $$TasksTableReferences._sectionIdTable(db),
                            referencedColumn: $$TasksTableReferences._sectionIdTable(db).id,
                          ) as T;
                        }
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $$TasksTableReferences._parentIdTable(db),
                            referencedColumn: $$TasksTableReferences._parentIdTable(db).id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (checklistItemsRefs)
                        await $_getPrefetchedData<Task, $TasksTable, ChecklistItem>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences._checklistItemsRefsTable(db),
                          managerFromTypedResult: (p0) => $$TasksTableReferences(db, table, p0).checklistItemsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.taskId == item.id),
                          typedResults: items,
                        ),
                      if (taskTagsRefs)
                        await $_getPrefetchedData<Task, $TasksTable, TaskTag>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences._taskTagsRefsTable(db),
                          managerFromTypedResult: (p0) => $$TasksTableReferences(db, table, p0).taskTagsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.taskId == item.id),
                          typedResults: items,
                        ),
                      if (taskRemindersRefs)
                        await $_getPrefetchedData<Task, $TasksTable, TaskReminder>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences._taskRemindersRefsTable(db),
                          managerFromTypedResult: (p0) => $$TasksTableReferences(db, table, p0).taskRemindersRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.taskId == item.id),
                          typedResults: items,
                        ),
                      if (commentsRefs)
                        await $_getPrefetchedData<Task, $TasksTable, Comment>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences._commentsRefsTable(db),
                          managerFromTypedResult: (p0) => $$TasksTableReferences(db, table, p0).commentsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.taskId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool listId,
        bool sectionId,
        bool parentId,
        bool checklistItemsRefs,
        bool taskTagsRefs,
        bool taskRemindersRefs,
        bool commentsRefs,
      })
    >;
typedef $$ChecklistItemsTableCreateCompanionBuilder = ChecklistItemsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String taskId,
  Value<String> title,
  Value<bool> isCompleted,
  Value<DateTime?> completedAt,
  required int sortOrder,
  Value<DateTime?> dueDate,
  Value<bool> isAllDay,
  Value<int> rowid,
});
typedef $$ChecklistItemsTableUpdateCompanionBuilder = ChecklistItemsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> taskId,
  Value<String> title,
  Value<bool> isCompleted,
  Value<DateTime?> completedAt,
  Value<int> sortOrder,
  Value<DateTime?> dueDate,
  Value<bool> isAllDay,
  Value<int> rowid,
});

final class $$ChecklistItemsTableReferences extends BaseReferences<_$AppDatabase, $ChecklistItemsTable, ChecklistItem> {
  $$ChecklistItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias('checklist_items__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChecklistItemsTableFilterComposer extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAllDay => $composableBuilder(column: $table.isAllDay, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableFilterComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$ChecklistItemsTableOrderingComposer extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAllDay => $composableBuilder(column: $table.isAllDay, builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableOrderingComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$ChecklistItemsTableAnnotationComposer extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate => $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay => $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableAnnotationComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$ChecklistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistItemsTable,
          ChecklistItem,
          $$ChecklistItemsTableFilterComposer,
          $$ChecklistItemsTableOrderingComposer,
          $$ChecklistItemsTableAnnotationComposer,
          $$ChecklistItemsTableCreateCompanionBuilder,
          $$ChecklistItemsTableUpdateCompanionBuilder,
          (ChecklistItem, $$ChecklistItemsTableReferences),
          ChecklistItem,
          PrefetchHooks Function({bool taskId})
        > {
  $$ChecklistItemsTableTableManager(_$AppDatabase db, $ChecklistItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ChecklistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ChecklistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ChecklistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistItemsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                title: title,
                isCompleted: isCompleted,
                completedAt: completedAt,
                sortOrder: sortOrder,
                dueDate: dueDate,
                isAllDay: isAllDay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String taskId,
                Value<String> title = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                required int sortOrder,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistItemsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                title: title,
                isCompleted: isCompleted,
                completedAt: completedAt,
                sortOrder: sortOrder,
                dueDate: dueDate,
                isAllDay: isAllDay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$ChecklistItemsTable, ChecklistItem>(table), $$ChecklistItemsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic>>(
                    state,
                  ) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$ChecklistItemsTableReferences._taskIdTable(db),
                        referencedColumn: $$ChecklistItemsTableReferences._taskIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChecklistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistItemsTable,
      ChecklistItem,
      $$ChecklistItemsTableFilterComposer,
      $$ChecklistItemsTableOrderingComposer,
      $$ChecklistItemsTableAnnotationComposer,
      $$ChecklistItemsTableCreateCompanionBuilder,
      $$ChecklistItemsTableUpdateCompanionBuilder,
      (ChecklistItem, $$ChecklistItemsTableReferences),
      ChecklistItem,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  Value<String?> color,
  Value<String?> parentId,
  Value<DateTime?> pinnedAt,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<String?> color,
  Value<String?> parentId,
  Value<DateTime?> pinnedAt,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$TagsTableReferences extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TagsTable _parentIdTable(_$AppDatabase db) => db.tags.createAlias('tags__parent_id__tags__id');

  $$TagsTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$TagsTableTableManager($_db, $_db.tags).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TaskTagsTable, List<TaskTag>> _taskTagsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.taskTags, aliasName: 'tags__id__task_tags__tag_id');

  $$TaskTagsTableProcessedTableManager get taskTagsRefs {
    final manager = $$TaskTagsTableTableManager($_db, $_db.taskTags).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$TagsTableFilterComposer get parentId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TagsTableFilterComposer(
        $db: $db,
        $table: $db.tags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<bool> taskTagsRefs(Expression<bool> Function($$TaskTagsTableFilterComposer f) f) {
    final $$TaskTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TaskTagsTableFilterComposer(
        $db: $db,
        $table: $db.taskTags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$TagsTableOrderingComposer get parentId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TagsTableOrderingComposer(
        $db: $db,
        $table: $db.tags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TagsTableAnnotationComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$TagsTableAnnotationComposer get parentId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TagsTableAnnotationComposer(
        $db: $db,
        $table: $db.tags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<T> taskTagsRefs<T extends Object>(Expression<T> Function($$TaskTagsTableAnnotationComposer a) f) {
    final $$TaskTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TaskTagsTableAnnotationComposer(
        $db: $db,
        $table: $db.taskTags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool parentId, bool taskTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                color: color,
                parentId: parentId,
                pinnedAt: pinnedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<String?> color = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                color: color,
                parentId: parentId,
                pinnedAt: pinnedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable<$TagsTable, Tag>(table), $$TagsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({parentId = false, taskTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (taskTagsRefs) db.taskTags],
              addJoins:
                  <T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic>>(
                    state,
                  ) {
                    if (parentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.parentId,
                        referencedTable: $$TagsTableReferences._parentIdTable(db),
                        referencedColumn: $$TagsTableReferences._parentIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (taskTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, TaskTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences._taskTagsRefsTable(db),
                      managerFromTypedResult: (p0) => $$TagsTableReferences(db, table, p0).taskTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool parentId, bool taskTagsRefs})
    >;
typedef $$TaskTagsTableCreateCompanionBuilder = TaskTagsCompanion Function({required String taskId, required String tagId, Value<int> rowid});
typedef $$TaskTagsTableUpdateCompanionBuilder = TaskTagsCompanion Function({Value<String> taskId, Value<String> tagId, Value<int> rowid});

final class $$TaskTagsTableReferences extends BaseReferences<_$AppDatabase, $TaskTagsTable, TaskTag> {
  $$TaskTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias('task_tags__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) => db.tags.createAlias('task_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager($_db, $_db.tags).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TaskTagsTableFilterComposer extends Composer<_$AppDatabase, $TaskTagsTable> {
  $$TaskTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableFilterComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TagsTableFilterComposer(
        $db: $db,
        $table: $db.tags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TaskTagsTableOrderingComposer extends Composer<_$AppDatabase, $TaskTagsTable> {
  $$TaskTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableOrderingComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TagsTableOrderingComposer(
        $db: $db,
        $table: $db.tags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TaskTagsTableAnnotationComposer extends Composer<_$AppDatabase, $TaskTagsTable> {
  $$TaskTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableAnnotationComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TagsTableAnnotationComposer(
        $db: $db,
        $table: $db.tags,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TaskTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTagsTable,
          TaskTag,
          $$TaskTagsTableFilterComposer,
          $$TaskTagsTableOrderingComposer,
          $$TaskTagsTableAnnotationComposer,
          $$TaskTagsTableCreateCompanionBuilder,
          $$TaskTagsTableUpdateCompanionBuilder,
          (TaskTag, $$TaskTagsTableReferences),
          TaskTag,
          PrefetchHooks Function({bool taskId, bool tagId})
        > {
  $$TaskTagsTableTableManager(_$AppDatabase db, $TaskTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TaskTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TaskTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TaskTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> taskId = const Value.absent(),
            Value<String> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => TaskTagsCompanion(taskId: taskId, tagId: tagId, rowid: rowid),
          createCompanionCallback: ({required String taskId, required String tagId, Value<int> rowid = const Value.absent()}) =>
              TaskTagsCompanion.insert(taskId: taskId, tagId: tagId, rowid: rowid),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable<$TaskTagsTable, TaskTag>(table), $$TaskTagsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({taskId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic>>(
                    state,
                  ) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$TaskTagsTableReferences._taskIdTable(db),
                        referencedColumn: $$TaskTagsTableReferences._taskIdTable(db).id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$TaskTagsTableReferences._tagIdTable(db),
                        referencedColumn: $$TaskTagsTableReferences._tagIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTagsTable,
      TaskTag,
      $$TaskTagsTableFilterComposer,
      $$TaskTagsTableOrderingComposer,
      $$TaskTagsTableAnnotationComposer,
      $$TaskTagsTableCreateCompanionBuilder,
      $$TaskTagsTableUpdateCompanionBuilder,
      (TaskTag, $$TaskTagsTableReferences),
      TaskTag,
      PrefetchHooks Function({bool taskId, bool tagId})
    >;
typedef $$PreferencesTableCreateCompanionBuilder = PreferencesCompanion Function({
  required String name,
  required String value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PreferencesTableUpdateCompanionBuilder = PreferencesCompanion Function({
  Value<String> name,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PreferencesTableFilterComposer extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PreferencesTableOrderingComposer extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PreferencesTableAnnotationComposer extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (Preference, BaseReferences<_$AppDatabase, $PreferencesTable, Preference>),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PreferencesCompanion(name: name, value: value, updatedAt: updatedAt, rowid: rowid),
          createCompanionCallback: ({
            required String name,
            required String value,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) => PreferencesCompanion.insert(name: name, value: value, updatedAt: updatedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$PreferencesTable, Preference>(table), BaseReferences<_$AppDatabase, $PreferencesTable, Preference>(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (Preference, BaseReferences<_$AppDatabase, $PreferencesTable, Preference>),
      Preference,
      PrefetchHooks Function()
    >;
typedef $$TaskRemindersTableCreateCompanionBuilder = TaskRemindersCompanion Function({
  required String taskId,
  required String trigger,
  Value<int> rowid,
});
typedef $$TaskRemindersTableUpdateCompanionBuilder = TaskRemindersCompanion Function({Value<String> taskId, Value<String> trigger, Value<int> rowid});

final class $$TaskRemindersTableReferences extends BaseReferences<_$AppDatabase, $TaskRemindersTable, TaskReminder> {
  $$TaskRemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias('task_reminders__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TaskRemindersTableFilterComposer extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trigger => $composableBuilder(column: $table.trigger, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableFilterComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TaskRemindersTableOrderingComposer extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trigger => $composableBuilder(column: $table.trigger, builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableOrderingComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TaskRemindersTableAnnotationComposer extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trigger => $composableBuilder(column: $table.trigger, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableAnnotationComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TaskRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRemindersTable,
          TaskReminder,
          $$TaskRemindersTableFilterComposer,
          $$TaskRemindersTableOrderingComposer,
          $$TaskRemindersTableAnnotationComposer,
          $$TaskRemindersTableCreateCompanionBuilder,
          $$TaskRemindersTableUpdateCompanionBuilder,
          (TaskReminder, $$TaskRemindersTableReferences),
          TaskReminder,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskRemindersTableTableManager(_$AppDatabase db, $TaskRemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TaskRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TaskRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TaskRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> taskId = const Value.absent(),
            Value<String> trigger = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => TaskRemindersCompanion(taskId: taskId, trigger: trigger, rowid: rowid),
          createCompanionCallback: ({required String taskId, required String trigger, Value<int> rowid = const Value.absent()}) =>
              TaskRemindersCompanion.insert(taskId: taskId, trigger: trigger, rowid: rowid),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$TaskRemindersTable, TaskReminder>(table), $$TaskRemindersTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic>>(
                    state,
                  ) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$TaskRemindersTableReferences._taskIdTable(db),
                        referencedColumn: $$TaskRemindersTableReferences._taskIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRemindersTable,
      TaskReminder,
      $$TaskRemindersTableFilterComposer,
      $$TaskRemindersTableOrderingComposer,
      $$TaskRemindersTableAnnotationComposer,
      $$TaskRemindersTableCreateCompanionBuilder,
      $$TaskRemindersTableUpdateCompanionBuilder,
      (TaskReminder, $$TaskRemindersTableReferences),
      TaskReminder,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  Value<String> title,
  Value<String> content,
  Value<TaskKind> kind,
  Value<String> items,
  Value<String> tagIds,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<String> title,
  Value<String> content,
  Value<TaskKind> kind,
  Value<String> items,
  Value<String> tagIds,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$TemplatesTableFilterComposer extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TaskKind, TaskKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get items => $composableBuilder(column: $table.items, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagIds => $composableBuilder(column: $table.tagIds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$TemplatesTableOrderingComposer extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get items => $composableBuilder(column: $table.items, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagIds => $composableBuilder(column: $table.tagIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$TemplatesTableAnnotationComposer extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content => $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskKind, String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get items => $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<String> get tagIds => $composableBuilder(column: $table.tagIds, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          TaskTemplate,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (TaskTemplate, BaseReferences<_$AppDatabase, $TemplatesTable, TaskTemplate>),
          TaskTemplate,
          PrefetchHooks Function()
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<TaskKind> kind = const Value.absent(),
                Value<String> items = const Value.absent(),
                Value<String> tagIds = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                title: title,
                content: content,
                kind: kind,
                items: items,
                tagIds: tagIds,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<TaskKind> kind = const Value.absent(),
                Value<String> items = const Value.absent(),
                Value<String> tagIds = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                title: title,
                content: content,
                kind: kind,
                items: items,
                tagIds: tagIds,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$TemplatesTable, TaskTemplate>(table), BaseReferences<_$AppDatabase, $TemplatesTable, TaskTemplate>(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      TaskTemplate,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (TaskTemplate, BaseReferences<_$AppDatabase, $TemplatesTable, TaskTemplate>),
      TaskTemplate,
      PrefetchHooks Function()
    >;
typedef $$CommentsTableCreateCompanionBuilder = CommentsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String taskId,
  required String body,
  Value<int> rowid,
});
typedef $$CommentsTableUpdateCompanionBuilder = CommentsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> taskId,
  Value<String> body,
  Value<int> rowid,
});

final class $$CommentsTableReferences extends BaseReferences<_$AppDatabase, $CommentsTable, Comment> {
  $$CommentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias('comments__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CommentsTableFilterComposer extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableFilterComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$CommentsTableOrderingComposer extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableOrderingComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$CommentsTableAnnotationComposer extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get body => $composableBuilder(column: $table.body, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TasksTableAnnotationComposer(
        $db: $db,
        $table: $db.tasks,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$CommentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommentsTable,
          Comment,
          $$CommentsTableFilterComposer,
          $$CommentsTableOrderingComposer,
          $$CommentsTableAnnotationComposer,
          $$CommentsTableCreateCompanionBuilder,
          $$CommentsTableUpdateCompanionBuilder,
          (Comment, $$CommentsTableReferences),
          Comment,
          PrefetchHooks Function({bool taskId})
        > {
  $$CommentsTableTableManager(_$AppDatabase db, $CommentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CommentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CommentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CommentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> taskId = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => CommentsCompanion(id: id, createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt, taskId: taskId, body: body, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String taskId,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => CommentsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable<$CommentsTable, Comment>(table), $$CommentsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic>>(
                    state,
                  ) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$CommentsTableReferences._taskIdTable(db),
                        referencedColumn: $$CommentsTableReferences._taskIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CommentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommentsTable,
      Comment,
      $$CommentsTableFilterComposer,
      $$CommentsTableOrderingComposer,
      $$CommentsTableAnnotationComposer,
      $$CommentsTableCreateCompanionBuilder,
      $$CommentsTableUpdateCompanionBuilder,
      (Comment, $$CommentsTableReferences),
      Comment,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$CountdownsTableCreateCompanionBuilder = CountdownsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  required DateTime date,
  Value<CountdownType> type,
  Value<CountMode> countMode,
  Value<bool> ignoreYear,
  Value<bool> showAge,
  Value<String> reminders,
  Value<String?> repeatRule,
  Value<CountdownVisibility> visibility,
  Value<int> style,
  Value<String?> color,
  Value<String> note,
  Value<DateTime?> pinnedAt,
  Value<DateTime?> archivedAt,
  required int sortOrder,
  Value<String?> icon,
  Value<String?> iconColor,
  Value<String?> image,
  Value<bool> countUp,
  Value<int> rowid,
});
typedef $$CountdownsTableUpdateCompanionBuilder = CountdownsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<DateTime> date,
  Value<CountdownType> type,
  Value<CountMode> countMode,
  Value<bool> ignoreYear,
  Value<bool> showAge,
  Value<String> reminders,
  Value<String?> repeatRule,
  Value<CountdownVisibility> visibility,
  Value<int> style,
  Value<String?> color,
  Value<String> note,
  Value<DateTime?> pinnedAt,
  Value<DateTime?> archivedAt,
  Value<int> sortOrder,
  Value<String?> icon,
  Value<String?> iconColor,
  Value<String?> image,
  Value<bool> countUp,
  Value<int> rowid,
});

class $$CountdownsTableFilterComposer extends Composer<_$AppDatabase, $CountdownsTable> {
  $$CountdownsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CountdownType, CountdownType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<CountMode, CountMode, String> get countMode =>
      $composableBuilder(column: $table.countMode, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get ignoreYear => $composableBuilder(column: $table.ignoreYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showAge => $composableBuilder(column: $table.showAge, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reminders => $composableBuilder(column: $table.reminders, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeatRule => $composableBuilder(column: $table.repeatRule, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CountdownVisibility, CountdownVisibility, String> get visibility =>
      $composableBuilder(column: $table.visibility, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get style => $composableBuilder(column: $table.style, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconColor => $composableBuilder(column: $table.iconColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get image => $composableBuilder(column: $table.image, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get countUp => $composableBuilder(column: $table.countUp, builder: (column) => ColumnFilters(column));
}

class $$CountdownsTableOrderingComposer extends Composer<_$AppDatabase, $CountdownsTable> {
  $$CountdownsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get countMode => $composableBuilder(column: $table.countMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ignoreYear => $composableBuilder(column: $table.ignoreYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showAge => $composableBuilder(column: $table.showAge, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reminders => $composableBuilder(column: $table.reminders, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatRule => $composableBuilder(column: $table.repeatRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visibility => $composableBuilder(column: $table.visibility, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get style => $composableBuilder(column: $table.style, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconColor => $composableBuilder(column: $table.iconColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get image => $composableBuilder(column: $table.image, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get countUp => $composableBuilder(column: $table.countUp, builder: (column) => ColumnOrderings(column));
}

class $$CountdownsTableAnnotationComposer extends Composer<_$AppDatabase, $CountdownsTable> {
  $$CountdownsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CountdownType, String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CountMode, String> get countMode => $composableBuilder(column: $table.countMode, builder: (column) => column);

  GeneratedColumn<bool> get ignoreYear => $composableBuilder(column: $table.ignoreYear, builder: (column) => column);

  GeneratedColumn<bool> get showAge => $composableBuilder(column: $table.showAge, builder: (column) => column);

  GeneratedColumn<String> get reminders => $composableBuilder(column: $table.reminders, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(column: $table.repeatRule, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CountdownVisibility, String> get visibility =>
      $composableBuilder(column: $table.visibility, builder: (column) => column);

  GeneratedColumn<int> get style => $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get iconColor => $composableBuilder(column: $table.iconColor, builder: (column) => column);

  GeneratedColumn<String> get image => $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<bool> get countUp => $composableBuilder(column: $table.countUp, builder: (column) => column);
}

class $$CountdownsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CountdownsTable,
          Countdown,
          $$CountdownsTableFilterComposer,
          $$CountdownsTableOrderingComposer,
          $$CountdownsTableAnnotationComposer,
          $$CountdownsTableCreateCompanionBuilder,
          $$CountdownsTableUpdateCompanionBuilder,
          (Countdown, BaseReferences<_$AppDatabase, $CountdownsTable, Countdown>),
          Countdown,
          PrefetchHooks Function()
        > {
  $$CountdownsTableTableManager(_$AppDatabase db, $CountdownsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CountdownsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CountdownsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CountdownsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<CountdownType> type = const Value.absent(),
                Value<CountMode> countMode = const Value.absent(),
                Value<bool> ignoreYear = const Value.absent(),
                Value<bool> showAge = const Value.absent(),
                Value<String> reminders = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<CountdownVisibility> visibility = const Value.absent(),
                Value<int> style = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> iconColor = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<bool> countUp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CountdownsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                date: date,
                type: type,
                countMode: countMode,
                ignoreYear: ignoreYear,
                showAge: showAge,
                reminders: reminders,
                repeatRule: repeatRule,
                visibility: visibility,
                style: style,
                color: color,
                note: note,
                pinnedAt: pinnedAt,
                archivedAt: archivedAt,
                sortOrder: sortOrder,
                icon: icon,
                iconColor: iconColor,
                image: image,
                countUp: countUp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required DateTime date,
                Value<CountdownType> type = const Value.absent(),
                Value<CountMode> countMode = const Value.absent(),
                Value<bool> ignoreYear = const Value.absent(),
                Value<bool> showAge = const Value.absent(),
                Value<String> reminders = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<CountdownVisibility> visibility = const Value.absent(),
                Value<int> style = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                required int sortOrder,
                Value<String?> icon = const Value.absent(),
                Value<String?> iconColor = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<bool> countUp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CountdownsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                date: date,
                type: type,
                countMode: countMode,
                ignoreYear: ignoreYear,
                showAge: showAge,
                reminders: reminders,
                repeatRule: repeatRule,
                visibility: visibility,
                style: style,
                color: color,
                note: note,
                pinnedAt: pinnedAt,
                archivedAt: archivedAt,
                sortOrder: sortOrder,
                icon: icon,
                iconColor: iconColor,
                image: image,
                countUp: countUp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$CountdownsTable, Countdown>(table), BaseReferences<_$AppDatabase, $CountdownsTable, Countdown>(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CountdownsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CountdownsTable,
      Countdown,
      $$CountdownsTableFilterComposer,
      $$CountdownsTableOrderingComposer,
      $$CountdownsTableAnnotationComposer,
      $$CountdownsTableCreateCompanionBuilder,
      $$CountdownsTableUpdateCompanionBuilder,
      (Countdown, BaseReferences<_$AppDatabase, $CountdownsTable, Countdown>),
      Countdown,
      PrefetchHooks Function()
    >;
typedef $$FocusRecordsTableCreateCompanionBuilder = FocusRecordsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required DateTime startedAt,
  required DateTime endedAt,
  required int seconds,
  Value<FocusMode> mode,
  Value<String?> taskId,
  Value<String?> timerId,
  Value<String> note,
  Value<int> rowid,
});
typedef $$FocusRecordsTableUpdateCompanionBuilder = FocusRecordsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> startedAt,
  Value<DateTime> endedAt,
  Value<int> seconds,
  Value<FocusMode> mode,
  Value<String?> taskId,
  Value<String?> timerId,
  Value<String> note,
  Value<int> rowid,
});

class $$FocusRecordsTableFilterComposer extends Composer<_$AppDatabase, $FocusRecordsTable> {
  $$FocusRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seconds => $composableBuilder(column: $table.seconds, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<FocusMode, FocusMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get taskId => $composableBuilder(column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timerId => $composableBuilder(column: $table.timerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$FocusRecordsTableOrderingComposer extends Composer<_$AppDatabase, $FocusRecordsTable> {
  $$FocusRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seconds => $composableBuilder(column: $table.seconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskId => $composableBuilder(column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timerId => $composableBuilder(column: $table.timerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$FocusRecordsTableAnnotationComposer extends Composer<_$AppDatabase, $FocusRecordsTable> {
  $$FocusRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt => $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt => $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get seconds => $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FocusMode, String> get mode => $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get taskId => $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get timerId => $composableBuilder(column: $table.timerId, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$FocusRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusRecordsTable,
          FocusRecord,
          $$FocusRecordsTableFilterComposer,
          $$FocusRecordsTableOrderingComposer,
          $$FocusRecordsTableAnnotationComposer,
          $$FocusRecordsTableCreateCompanionBuilder,
          $$FocusRecordsTableUpdateCompanionBuilder,
          (FocusRecord, BaseReferences<_$AppDatabase, $FocusRecordsTable, FocusRecord>),
          FocusRecord,
          PrefetchHooks Function()
        > {
  $$FocusRecordsTableTableManager(_$AppDatabase db, $FocusRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$FocusRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$FocusRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$FocusRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<FocusMode> mode = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> timerId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusRecordsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                startedAt: startedAt,
                endedAt: endedAt,
                seconds: seconds,
                mode: mode,
                taskId: taskId,
                timerId: timerId,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime startedAt,
                required DateTime endedAt,
                required int seconds,
                Value<FocusMode> mode = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> timerId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusRecordsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                startedAt: startedAt,
                endedAt: endedAt,
                seconds: seconds,
                mode: mode,
                taskId: taskId,
                timerId: timerId,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FocusRecordsTable, FocusRecord>(table),
                  BaseReferences<_$AppDatabase, $FocusRecordsTable, FocusRecord>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusRecordsTable,
      FocusRecord,
      $$FocusRecordsTableFilterComposer,
      $$FocusRecordsTableOrderingComposer,
      $$FocusRecordsTableAnnotationComposer,
      $$FocusRecordsTableCreateCompanionBuilder,
      $$FocusRecordsTableUpdateCompanionBuilder,
      (FocusRecord, BaseReferences<_$AppDatabase, $FocusRecordsTable, FocusRecord>),
      FocusRecord,
      PrefetchHooks Function()
    >;
typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  Value<String> motto,
  Value<String> icon,
  Value<String?> color,
  Value<HabitFrequency> frequency,
  Value<String> weekdays,
  Value<int> perWeek,
  Value<int> everyDays,
  Value<HabitGoal> goal,
  Value<double> goalAmount,
  Value<String> unit,
  Value<HabitCheckMode> checkMode,
  Value<double> step,
  required DateTime startDate,
  Value<int?> targetDays,
  Value<String> section,
  Value<String> reminders,
  Value<bool> autoShowLog,
  Value<DateTime?> archivedAt,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<String> motto,
  Value<String> icon,
  Value<String?> color,
  Value<HabitFrequency> frequency,
  Value<String> weekdays,
  Value<int> perWeek,
  Value<int> everyDays,
  Value<HabitGoal> goal,
  Value<double> goalAmount,
  Value<String> unit,
  Value<HabitCheckMode> checkMode,
  Value<double> step,
  Value<DateTime> startDate,
  Value<int?> targetDays,
  Value<String> section,
  Value<String> reminders,
  Value<bool> autoShowLog,
  Value<DateTime?> archivedAt,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$HabitsTableReferences extends BaseReferences<_$AppDatabase, $HabitsTable, Habit> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HabitCheckinsTable, List<HabitCheckin>> _habitCheckinsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.habitCheckins, aliasName: 'habits__id__habit_checkins__habit_id');

  $$HabitCheckinsTableProcessedTableManager get habitCheckinsRefs {
    final manager = $$HabitCheckinsTableTableManager($_db, $_db.habitCheckins).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitCheckinsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$HabitsTableFilterComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motto => $composableBuilder(column: $table.motto, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<HabitFrequency, HabitFrequency, String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get weekdays => $composableBuilder(column: $table.weekdays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get perWeek => $composableBuilder(column: $table.perWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get everyDays => $composableBuilder(column: $table.everyDays, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<HabitGoal, HabitGoal, String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get goalAmount => $composableBuilder(column: $table.goalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<HabitCheckMode, HabitCheckMode, String> get checkMode =>
      $composableBuilder(column: $table.checkMode, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get step => $composableBuilder(column: $table.step, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetDays => $composableBuilder(column: $table.targetDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get section => $composableBuilder(column: $table.section, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reminders => $composableBuilder(column: $table.reminders, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoShowLog => $composableBuilder(column: $table.autoShowLog, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> habitCheckinsRefs(Expression<bool> Function($$HabitCheckinsTableFilterComposer f) f) {
    final $$HabitCheckinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitCheckins,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitCheckinsTableFilterComposer(
        $db: $db,
        $table: $db.habitCheckins,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motto => $composableBuilder(column: $table.motto, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekdays => $composableBuilder(column: $table.weekdays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get perWeek => $composableBuilder(column: $table.perWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get everyDays => $composableBuilder(column: $table.everyDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get goal => $composableBuilder(column: $table.goal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get goalAmount => $composableBuilder(column: $table.goalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkMode => $composableBuilder(column: $table.checkMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get step => $composableBuilder(column: $table.step, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetDays => $composableBuilder(column: $table.targetDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get section => $composableBuilder(column: $table.section, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reminders => $composableBuilder(column: $table.reminders, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoShowLog => $composableBuilder(column: $table.autoShowLog, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$HabitsTableAnnotationComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get motto => $composableBuilder(column: $table.motto, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HabitFrequency, String> get frequency => $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get weekdays => $composableBuilder(column: $table.weekdays, builder: (column) => column);

  GeneratedColumn<int> get perWeek => $composableBuilder(column: $table.perWeek, builder: (column) => column);

  GeneratedColumn<int> get everyDays => $composableBuilder(column: $table.everyDays, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HabitGoal, String> get goal => $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<double> get goalAmount => $composableBuilder(column: $table.goalAmount, builder: (column) => column);

  GeneratedColumn<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HabitCheckMode, String> get checkMode => $composableBuilder(column: $table.checkMode, builder: (column) => column);

  GeneratedColumn<double> get step => $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate => $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get targetDays => $composableBuilder(column: $table.targetDays, builder: (column) => column);

  GeneratedColumn<String> get section => $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get reminders => $composableBuilder(column: $table.reminders, builder: (column) => column);

  GeneratedColumn<bool> get autoShowLog => $composableBuilder(column: $table.autoShowLog, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> habitCheckinsRefs<T extends Object>(Expression<T> Function($$HabitCheckinsTableAnnotationComposer a) f) {
    final $$HabitCheckinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitCheckins,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitCheckinsTableAnnotationComposer(
        $db: $db,
        $table: $db.habitCheckins,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, $$HabitsTableReferences),
          Habit,
          PrefetchHooks Function({bool habitCheckinsRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> motto = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<HabitFrequency> frequency = const Value.absent(),
                Value<String> weekdays = const Value.absent(),
                Value<int> perWeek = const Value.absent(),
                Value<int> everyDays = const Value.absent(),
                Value<HabitGoal> goal = const Value.absent(),
                Value<double> goalAmount = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<HabitCheckMode> checkMode = const Value.absent(),
                Value<double> step = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int?> targetDays = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<String> reminders = const Value.absent(),
                Value<bool> autoShowLog = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                motto: motto,
                icon: icon,
                color: color,
                frequency: frequency,
                weekdays: weekdays,
                perWeek: perWeek,
                everyDays: everyDays,
                goal: goal,
                goalAmount: goalAmount,
                unit: unit,
                checkMode: checkMode,
                step: step,
                startDate: startDate,
                targetDays: targetDays,
                section: section,
                reminders: reminders,
                autoShowLog: autoShowLog,
                archivedAt: archivedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<String> motto = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<HabitFrequency> frequency = const Value.absent(),
                Value<String> weekdays = const Value.absent(),
                Value<int> perWeek = const Value.absent(),
                Value<int> everyDays = const Value.absent(),
                Value<HabitGoal> goal = const Value.absent(),
                Value<double> goalAmount = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<HabitCheckMode> checkMode = const Value.absent(),
                Value<double> step = const Value.absent(),
                required DateTime startDate,
                Value<int?> targetDays = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<String> reminders = const Value.absent(),
                Value<bool> autoShowLog = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                motto: motto,
                icon: icon,
                color: color,
                frequency: frequency,
                weekdays: weekdays,
                perWeek: perWeek,
                everyDays: everyDays,
                goal: goal,
                goalAmount: goalAmount,
                unit: unit,
                checkMode: checkMode,
                step: step,
                startDate: startDate,
                targetDays: targetDays,
                section: section,
                reminders: reminders,
                autoShowLog: autoShowLog,
                archivedAt: archivedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable<$HabitsTable, Habit>(table), $$HabitsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({habitCheckinsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (habitCheckinsRefs) db.habitCheckins],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (habitCheckinsRefs)
                    await $_getPrefetchedData<Habit, $HabitsTable, HabitCheckin>(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences._habitCheckinsRefsTable(db),
                      managerFromTypedResult: (p0) => $$HabitsTableReferences(db, table, p0).habitCheckinsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.habitId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, $$HabitsTableReferences),
      Habit,
      PrefetchHooks Function({bool habitCheckinsRefs})
    >;
typedef $$HabitCheckinsTableCreateCompanionBuilder = HabitCheckinsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String habitId,
  required DateTime day,
  Value<double> value,
  Value<HabitMark> mark,
  Value<int?> mood,
  Value<String> note,
  Value<int> rowid,
});
typedef $$HabitCheckinsTableUpdateCompanionBuilder = HabitCheckinsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> habitId,
  Value<DateTime> day,
  Value<double> value,
  Value<HabitMark> mark,
  Value<int?> mood,
  Value<String> note,
  Value<int> rowid,
});

final class $$HabitCheckinsTableReferences extends BaseReferences<_$AppDatabase, $HabitCheckinsTable, HabitCheckin> {
  $$HabitCheckinsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias('habit_checkins__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager($_db, $_db.habits).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HabitCheckinsTableFilterComposer extends Composer<_$AppDatabase, $HabitCheckinsTable> {
  $$HabitCheckinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<HabitMark, HabitMark, String> get mark =>
      $composableBuilder(column: $table.mark, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get mood => $composableBuilder(column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitsTableFilterComposer(
        $db: $db,
        $table: $db.habits,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$HabitCheckinsTableOrderingComposer extends Composer<_$AppDatabase, $HabitCheckinsTable> {
  $$HabitCheckinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mark => $composableBuilder(column: $table.mark, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mood => $composableBuilder(column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitsTableOrderingComposer(
        $db: $db,
        $table: $db.habits,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$HabitCheckinsTableAnnotationComposer extends Composer<_$AppDatabase, $HabitCheckinsTable> {
  $$HabitCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get value => $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HabitMark, String> get mark => $composableBuilder(column: $table.mark, builder: (column) => column);

  GeneratedColumn<int> get mood => $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitsTableAnnotationComposer(
        $db: $db,
        $table: $db.habits,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$HabitCheckinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitCheckinsTable,
          HabitCheckin,
          $$HabitCheckinsTableFilterComposer,
          $$HabitCheckinsTableOrderingComposer,
          $$HabitCheckinsTableAnnotationComposer,
          $$HabitCheckinsTableCreateCompanionBuilder,
          $$HabitCheckinsTableUpdateCompanionBuilder,
          (HabitCheckin, $$HabitCheckinsTableReferences),
          HabitCheckin,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitCheckinsTableTableManager(_$AppDatabase db, $HabitCheckinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HabitCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HabitCheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HabitCheckinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<HabitMark> mark = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCheckinsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                habitId: habitId,
                day: day,
                value: value,
                mark: mark,
                mood: mood,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String habitId,
                required DateTime day,
                Value<double> value = const Value.absent(),
                Value<HabitMark> mark = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCheckinsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                habitId: habitId,
                day: day,
                value: value,
                mark: mark,
                mood: mood,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$HabitCheckinsTable, HabitCheckin>(table), $$HabitCheckinsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic>>(
                    state,
                  ) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitCheckinsTableReferences._habitIdTable(db),
                        referencedColumn: $$HabitCheckinsTableReferences._habitIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitCheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitCheckinsTable,
      HabitCheckin,
      $$HabitCheckinsTableFilterComposer,
      $$HabitCheckinsTableOrderingComposer,
      $$HabitCheckinsTableAnnotationComposer,
      $$HabitCheckinsTableCreateCompanionBuilder,
      $$HabitCheckinsTableUpdateCompanionBuilder,
      (HabitCheckin, $$HabitCheckinsTableReferences),
      HabitCheckin,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$FiltersTableCreateCompanionBuilder = FiltersCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  required String rule,
  Value<DateTime?> pinnedAt,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$FiltersTableUpdateCompanionBuilder = FiltersCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<String> rule,
  Value<DateTime?> pinnedAt,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$FiltersTableFilterComposer extends Composer<_$AppDatabase, $FiltersTable> {
  $$FiltersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rule => $composableBuilder(column: $table.rule, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$FiltersTableOrderingComposer extends Composer<_$AppDatabase, $FiltersTable> {
  $$FiltersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rule => $composableBuilder(column: $table.rule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$FiltersTableAnnotationComposer extends Composer<_$AppDatabase, $FiltersTable> {
  $$FiltersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get rule => $composableBuilder(column: $table.rule, builder: (column) => column);

  GeneratedColumn<DateTime> get pinnedAt => $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$FiltersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FiltersTable,
          TaskFilter,
          $$FiltersTableFilterComposer,
          $$FiltersTableOrderingComposer,
          $$FiltersTableAnnotationComposer,
          $$FiltersTableCreateCompanionBuilder,
          $$FiltersTableUpdateCompanionBuilder,
          (TaskFilter, BaseReferences<_$AppDatabase, $FiltersTable, TaskFilter>),
          TaskFilter,
          PrefetchHooks Function()
        > {
  $$FiltersTableTableManager(_$AppDatabase db, $FiltersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$FiltersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$FiltersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$FiltersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> rule = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FiltersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                rule: rule,
                pinnedAt: pinnedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required String rule,
                Value<DateTime?> pinnedAt = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => FiltersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                rule: rule,
                pinnedAt: pinnedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$FiltersTable, TaskFilter>(table), BaseReferences<_$AppDatabase, $FiltersTable, TaskFilter>(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FiltersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FiltersTable,
      TaskFilter,
      $$FiltersTableFilterComposer,
      $$FiltersTableOrderingComposer,
      $$FiltersTableAnnotationComposer,
      $$FiltersTableCreateCompanionBuilder,
      $$FiltersTableUpdateCompanionBuilder,
      (TaskFilter, BaseReferences<_$AppDatabase, $FiltersTable, TaskFilter>),
      TaskFilter,
      PrefetchHooks Function()
    >;
typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> taskId,
  Value<String?> listId,
  required ActivityAction action,
  Value<String> detail,
  Value<int> rowid,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> taskId,
  Value<String?> listId,
  Value<ActivityAction> action,
  Value<String> detail,
  Value<int> rowid,
});

class $$ActivitiesTableFilterComposer extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskId => $composableBuilder(column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get listId => $composableBuilder(column: $table.listId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ActivityAction, ActivityAction, String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get detail => $composableBuilder(column: $table.detail, builder: (column) => ColumnFilters(column));
}

class $$ActivitiesTableOrderingComposer extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskId => $composableBuilder(column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get listId => $composableBuilder(column: $table.listId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detail => $composableBuilder(column: $table.detail, builder: (column) => ColumnOrderings(column));
}

class $$ActivitiesTableAnnotationComposer extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get taskId => $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get listId => $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActivityAction, String> get action => $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get detail => $composableBuilder(column: $table.detail, builder: (column) => column);
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitiesTable,
          Activity,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
          Activity,
          PrefetchHooks Function()
        > {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<ActivityAction> action = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                listId: listId,
                action: action,
                detail: detail,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                required ActivityAction action,
                Value<String> detail = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                listId: listId,
                action: action,
                detail: detail,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$ActivitiesTable, Activity>(table), BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitiesTable,
      Activity,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
      Activity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoldersTableTableManager get folders => $$FoldersTableTableManager(_db, _db.folders);
  $$ListsTableTableManager get lists => $$ListsTableTableManager(_db, _db.lists);
  $$SectionsTableTableManager get sections => $$SectionsTableTableManager(_db, _db.sections);
  $$TasksTableTableManager get tasks => $$TasksTableTableManager(_db, _db.tasks);
  $$ChecklistItemsTableTableManager get checklistItems => $$ChecklistItemsTableTableManager(_db, _db.checklistItems);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TaskTagsTableTableManager get taskTags => $$TaskTagsTableTableManager(_db, _db.taskTags);
  $$PreferencesTableTableManager get preferences => $$PreferencesTableTableManager(_db, _db.preferences);
  $$TaskRemindersTableTableManager get taskReminders => $$TaskRemindersTableTableManager(_db, _db.taskReminders);
  $$TemplatesTableTableManager get templates => $$TemplatesTableTableManager(_db, _db.templates);
  $$CommentsTableTableManager get comments => $$CommentsTableTableManager(_db, _db.comments);
  $$CountdownsTableTableManager get countdowns => $$CountdownsTableTableManager(_db, _db.countdowns);
  $$FocusRecordsTableTableManager get focusRecords => $$FocusRecordsTableTableManager(_db, _db.focusRecords);
  $$HabitsTableTableManager get habits => $$HabitsTableTableManager(_db, _db.habits);
  $$HabitCheckinsTableTableManager get habitCheckins => $$HabitCheckinsTableTableManager(_db, _db.habitCheckins);
  $$FiltersTableTableManager get filters => $$FiltersTableTableManager(_db, _db.filters);
  $$ActivitiesTableTableManager get activities => $$ActivitiesTableTableManager(_db, _db.activities);
}
