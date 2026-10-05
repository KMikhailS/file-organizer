// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SourcesTable extends Sources with TableInfo<$SourcesTable, SourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _canMoveMeta = const VerificationMeta(
    'canMove',
  );
  @override
  late final GeneratedColumn<bool> canMove = GeneratedColumn<bool>(
    'can_move',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_move" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canMkdirMeta = const VerificationMeta(
    'canMkdir',
  );
  @override
  late final GeneratedColumn<bool> canMkdir = GeneratedColumn<bool>(
    'can_mkdir',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_mkdir" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canQuarantineMeta = const VerificationMeta(
    'canQuarantine',
  );
  @override
  late final GeneratedColumn<bool> canQuarantine = GeneratedColumn<bool>(
    'can_quarantine',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_quarantine" IN (0, 1))',
    ),
  );
  static const VerificationMeta _quarantineRestorableMeta =
      const VerificationMeta('quarantineRestorable');
  @override
  late final GeneratedColumn<bool> quarantineRestorable = GeneratedColumn<bool>(
    'quarantine_restorable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quarantine_restorable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canAddToAlbumMeta = const VerificationMeta(
    'canAddToAlbum',
  );
  @override
  late final GeneratedColumn<bool> canAddToAlbum = GeneratedColumn<bool>(
    'can_add_to_album',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_add_to_album" IN (0, 1))',
    ),
  );
  static const VerificationMeta _providesCapturedAtMeta =
      const VerificationMeta('providesCapturedAt');
  @override
  late final GeneratedColumn<bool> providesCapturedAt = GeneratedColumn<bool>(
    'provides_captured_at',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("provides_captured_at" IN (0, 1))',
    ),
  );
  static const VerificationMeta _systemPurgesQuarantineMeta =
      const VerificationMeta('systemPurgesQuarantine');
  @override
  late final GeneratedColumn<bool> systemPurgesQuarantine =
      GeneratedColumn<bool>(
        'system_purges_quarantine',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("system_purges_quarantine" IN (0, 1))',
        ),
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    displayName,
    location,
    canMove,
    canMkdir,
    canQuarantine,
    quarantineRestorable,
    canAddToAlbum,
    providesCapturedAt,
    systemPurgesQuarantine,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('can_move')) {
      context.handle(
        _canMoveMeta,
        canMove.isAcceptableOrUnknown(data['can_move']!, _canMoveMeta),
      );
    } else if (isInserting) {
      context.missing(_canMoveMeta);
    }
    if (data.containsKey('can_mkdir')) {
      context.handle(
        _canMkdirMeta,
        canMkdir.isAcceptableOrUnknown(data['can_mkdir']!, _canMkdirMeta),
      );
    } else if (isInserting) {
      context.missing(_canMkdirMeta);
    }
    if (data.containsKey('can_quarantine')) {
      context.handle(
        _canQuarantineMeta,
        canQuarantine.isAcceptableOrUnknown(
          data['can_quarantine']!,
          _canQuarantineMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canQuarantineMeta);
    }
    if (data.containsKey('quarantine_restorable')) {
      context.handle(
        _quarantineRestorableMeta,
        quarantineRestorable.isAcceptableOrUnknown(
          data['quarantine_restorable']!,
          _quarantineRestorableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quarantineRestorableMeta);
    }
    if (data.containsKey('can_add_to_album')) {
      context.handle(
        _canAddToAlbumMeta,
        canAddToAlbum.isAcceptableOrUnknown(
          data['can_add_to_album']!,
          _canAddToAlbumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canAddToAlbumMeta);
    }
    if (data.containsKey('provides_captured_at')) {
      context.handle(
        _providesCapturedAtMeta,
        providesCapturedAt.isAcceptableOrUnknown(
          data['provides_captured_at']!,
          _providesCapturedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providesCapturedAtMeta);
    }
    if (data.containsKey('system_purges_quarantine')) {
      context.handle(
        _systemPurgesQuarantineMeta,
        systemPurgesQuarantine.isAcceptableOrUnknown(
          data['system_purges_quarantine']!,
          _systemPurgesQuarantineMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_systemPurgesQuarantineMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      canMove: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_move'],
      )!,
      canMkdir: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_mkdir'],
      )!,
      canQuarantine: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_quarantine'],
      )!,
      quarantineRestorable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quarantine_restorable'],
      )!,
      canAddToAlbum: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_add_to_album'],
      )!,
      providesCapturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}provides_captured_at'],
      )!,
      systemPurgesQuarantine: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}system_purges_quarantine'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class SourceRow extends DataClass implements Insertable<SourceRow> {
  final String id;
  final String kind;
  final String displayName;

  /// Added in schema version 2; empty for sources of version 1.
  final String location;
  final bool canMove;
  final bool canMkdir;
  final bool canQuarantine;
  final bool quarantineRestorable;
  final bool canAddToAlbum;
  final bool providesCapturedAt;
  final bool systemPurgesQuarantine;
  final bool enabled;
  const SourceRow({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.location,
    required this.canMove,
    required this.canMkdir,
    required this.canQuarantine,
    required this.quarantineRestorable,
    required this.canAddToAlbum,
    required this.providesCapturedAt,
    required this.systemPurgesQuarantine,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['display_name'] = Variable<String>(displayName);
    map['location'] = Variable<String>(location);
    map['can_move'] = Variable<bool>(canMove);
    map['can_mkdir'] = Variable<bool>(canMkdir);
    map['can_quarantine'] = Variable<bool>(canQuarantine);
    map['quarantine_restorable'] = Variable<bool>(quarantineRestorable);
    map['can_add_to_album'] = Variable<bool>(canAddToAlbum);
    map['provides_captured_at'] = Variable<bool>(providesCapturedAt);
    map['system_purges_quarantine'] = Variable<bool>(systemPurgesQuarantine);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      kind: Value(kind),
      displayName: Value(displayName),
      location: Value(location),
      canMove: Value(canMove),
      canMkdir: Value(canMkdir),
      canQuarantine: Value(canQuarantine),
      quarantineRestorable: Value(quarantineRestorable),
      canAddToAlbum: Value(canAddToAlbum),
      providesCapturedAt: Value(providesCapturedAt),
      systemPurgesQuarantine: Value(systemPurgesQuarantine),
      enabled: Value(enabled),
    );
  }

  factory SourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      displayName: serializer.fromJson<String>(json['displayName']),
      location: serializer.fromJson<String>(json['location']),
      canMove: serializer.fromJson<bool>(json['canMove']),
      canMkdir: serializer.fromJson<bool>(json['canMkdir']),
      canQuarantine: serializer.fromJson<bool>(json['canQuarantine']),
      quarantineRestorable: serializer.fromJson<bool>(
        json['quarantineRestorable'],
      ),
      canAddToAlbum: serializer.fromJson<bool>(json['canAddToAlbum']),
      providesCapturedAt: serializer.fromJson<bool>(json['providesCapturedAt']),
      systemPurgesQuarantine: serializer.fromJson<bool>(
        json['systemPurgesQuarantine'],
      ),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'displayName': serializer.toJson<String>(displayName),
      'location': serializer.toJson<String>(location),
      'canMove': serializer.toJson<bool>(canMove),
      'canMkdir': serializer.toJson<bool>(canMkdir),
      'canQuarantine': serializer.toJson<bool>(canQuarantine),
      'quarantineRestorable': serializer.toJson<bool>(quarantineRestorable),
      'canAddToAlbum': serializer.toJson<bool>(canAddToAlbum),
      'providesCapturedAt': serializer.toJson<bool>(providesCapturedAt),
      'systemPurgesQuarantine': serializer.toJson<bool>(systemPurgesQuarantine),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  SourceRow copyWith({
    String? id,
    String? kind,
    String? displayName,
    String? location,
    bool? canMove,
    bool? canMkdir,
    bool? canQuarantine,
    bool? quarantineRestorable,
    bool? canAddToAlbum,
    bool? providesCapturedAt,
    bool? systemPurgesQuarantine,
    bool? enabled,
  }) => SourceRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    displayName: displayName ?? this.displayName,
    location: location ?? this.location,
    canMove: canMove ?? this.canMove,
    canMkdir: canMkdir ?? this.canMkdir,
    canQuarantine: canQuarantine ?? this.canQuarantine,
    quarantineRestorable: quarantineRestorable ?? this.quarantineRestorable,
    canAddToAlbum: canAddToAlbum ?? this.canAddToAlbum,
    providesCapturedAt: providesCapturedAt ?? this.providesCapturedAt,
    systemPurgesQuarantine:
        systemPurgesQuarantine ?? this.systemPurgesQuarantine,
    enabled: enabled ?? this.enabled,
  );
  SourceRow copyWithCompanion(SourcesCompanion data) {
    return SourceRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      location: data.location.present ? data.location.value : this.location,
      canMove: data.canMove.present ? data.canMove.value : this.canMove,
      canMkdir: data.canMkdir.present ? data.canMkdir.value : this.canMkdir,
      canQuarantine: data.canQuarantine.present
          ? data.canQuarantine.value
          : this.canQuarantine,
      quarantineRestorable: data.quarantineRestorable.present
          ? data.quarantineRestorable.value
          : this.quarantineRestorable,
      canAddToAlbum: data.canAddToAlbum.present
          ? data.canAddToAlbum.value
          : this.canAddToAlbum,
      providesCapturedAt: data.providesCapturedAt.present
          ? data.providesCapturedAt.value
          : this.providesCapturedAt,
      systemPurgesQuarantine: data.systemPurgesQuarantine.present
          ? data.systemPurgesQuarantine.value
          : this.systemPurgesQuarantine,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('location: $location, ')
          ..write('canMove: $canMove, ')
          ..write('canMkdir: $canMkdir, ')
          ..write('canQuarantine: $canQuarantine, ')
          ..write('quarantineRestorable: $quarantineRestorable, ')
          ..write('canAddToAlbum: $canAddToAlbum, ')
          ..write('providesCapturedAt: $providesCapturedAt, ')
          ..write('systemPurgesQuarantine: $systemPurgesQuarantine, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    displayName,
    location,
    canMove,
    canMkdir,
    canQuarantine,
    quarantineRestorable,
    canAddToAlbum,
    providesCapturedAt,
    systemPurgesQuarantine,
    enabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.displayName == this.displayName &&
          other.location == this.location &&
          other.canMove == this.canMove &&
          other.canMkdir == this.canMkdir &&
          other.canQuarantine == this.canQuarantine &&
          other.quarantineRestorable == this.quarantineRestorable &&
          other.canAddToAlbum == this.canAddToAlbum &&
          other.providesCapturedAt == this.providesCapturedAt &&
          other.systemPurgesQuarantine == this.systemPurgesQuarantine &&
          other.enabled == this.enabled);
}

class SourcesCompanion extends UpdateCompanion<SourceRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> displayName;
  final Value<String> location;
  final Value<bool> canMove;
  final Value<bool> canMkdir;
  final Value<bool> canQuarantine;
  final Value<bool> quarantineRestorable;
  final Value<bool> canAddToAlbum;
  final Value<bool> providesCapturedAt;
  final Value<bool> systemPurgesQuarantine;
  final Value<bool> enabled;
  final Value<int> rowid;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.displayName = const Value.absent(),
    this.location = const Value.absent(),
    this.canMove = const Value.absent(),
    this.canMkdir = const Value.absent(),
    this.canQuarantine = const Value.absent(),
    this.quarantineRestorable = const Value.absent(),
    this.canAddToAlbum = const Value.absent(),
    this.providesCapturedAt = const Value.absent(),
    this.systemPurgesQuarantine = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcesCompanion.insert({
    required String id,
    required String kind,
    required String displayName,
    this.location = const Value.absent(),
    required bool canMove,
    required bool canMkdir,
    required bool canQuarantine,
    required bool quarantineRestorable,
    required bool canAddToAlbum,
    required bool providesCapturedAt,
    required bool systemPurgesQuarantine,
    required bool enabled,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       displayName = Value(displayName),
       canMove = Value(canMove),
       canMkdir = Value(canMkdir),
       canQuarantine = Value(canQuarantine),
       quarantineRestorable = Value(quarantineRestorable),
       canAddToAlbum = Value(canAddToAlbum),
       providesCapturedAt = Value(providesCapturedAt),
       systemPurgesQuarantine = Value(systemPurgesQuarantine),
       enabled = Value(enabled);
  static Insertable<SourceRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? displayName,
    Expression<String>? location,
    Expression<bool>? canMove,
    Expression<bool>? canMkdir,
    Expression<bool>? canQuarantine,
    Expression<bool>? quarantineRestorable,
    Expression<bool>? canAddToAlbum,
    Expression<bool>? providesCapturedAt,
    Expression<bool>? systemPurgesQuarantine,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (displayName != null) 'display_name': displayName,
      if (location != null) 'location': location,
      if (canMove != null) 'can_move': canMove,
      if (canMkdir != null) 'can_mkdir': canMkdir,
      if (canQuarantine != null) 'can_quarantine': canQuarantine,
      if (quarantineRestorable != null)
        'quarantine_restorable': quarantineRestorable,
      if (canAddToAlbum != null) 'can_add_to_album': canAddToAlbum,
      if (providesCapturedAt != null)
        'provides_captured_at': providesCapturedAt,
      if (systemPurgesQuarantine != null)
        'system_purges_quarantine': systemPurgesQuarantine,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? displayName,
    Value<String>? location,
    Value<bool>? canMove,
    Value<bool>? canMkdir,
    Value<bool>? canQuarantine,
    Value<bool>? quarantineRestorable,
    Value<bool>? canAddToAlbum,
    Value<bool>? providesCapturedAt,
    Value<bool>? systemPurgesQuarantine,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      displayName: displayName ?? this.displayName,
      location: location ?? this.location,
      canMove: canMove ?? this.canMove,
      canMkdir: canMkdir ?? this.canMkdir,
      canQuarantine: canQuarantine ?? this.canQuarantine,
      quarantineRestorable: quarantineRestorable ?? this.quarantineRestorable,
      canAddToAlbum: canAddToAlbum ?? this.canAddToAlbum,
      providesCapturedAt: providesCapturedAt ?? this.providesCapturedAt,
      systemPurgesQuarantine:
          systemPurgesQuarantine ?? this.systemPurgesQuarantine,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (canMove.present) {
      map['can_move'] = Variable<bool>(canMove.value);
    }
    if (canMkdir.present) {
      map['can_mkdir'] = Variable<bool>(canMkdir.value);
    }
    if (canQuarantine.present) {
      map['can_quarantine'] = Variable<bool>(canQuarantine.value);
    }
    if (quarantineRestorable.present) {
      map['quarantine_restorable'] = Variable<bool>(quarantineRestorable.value);
    }
    if (canAddToAlbum.present) {
      map['can_add_to_album'] = Variable<bool>(canAddToAlbum.value);
    }
    if (providesCapturedAt.present) {
      map['provides_captured_at'] = Variable<bool>(providesCapturedAt.value);
    }
    if (systemPurgesQuarantine.present) {
      map['system_purges_quarantine'] = Variable<bool>(
        systemPurgesQuarantine.value,
      );
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('location: $location, ')
          ..write('canMove: $canMove, ')
          ..write('canMkdir: $canMkdir, ')
          ..write('canQuarantine: $canQuarantine, ')
          ..write('quarantineRestorable: $quarantineRestorable, ')
          ..write('canAddToAlbum: $canAddToAlbum, ')
          ..write('providesCapturedAt: $providesCapturedAt, ')
          ..write('systemPurgesQuarantine: $systemPurgesQuarantine, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FileIndexTable extends FileIndex
    with TableInfo<$FileIndexTable, FileIndexRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<int> capturedAt = GeneratedColumn<int>(
    'captured_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partialHashMeta = const VerificationMeta(
    'partialHash',
  );
  @override
  late final GeneratedColumn<String> partialHash = GeneratedColumn<String>(
    'partial_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullHashMeta = const VerificationMeta(
    'fullHash',
  );
  @override
  late final GeneratedColumn<String> fullHash = GeneratedColumn<String>(
    'full_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenScanIdMeta = const VerificationMeta(
    'lastSeenScanId',
  );
  @override
  late final GeneratedColumn<String> lastSeenScanId = GeneratedColumn<String>(
    'last_seen_scan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    path,
    size,
    modifiedAt,
    capturedAt,
    mimeType,
    partialHash,
    fullHash,
    lastSeenScanId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileIndexRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('partial_hash')) {
      context.handle(
        _partialHashMeta,
        partialHash.isAcceptableOrUnknown(
          data['partial_hash']!,
          _partialHashMeta,
        ),
      );
    }
    if (data.containsKey('full_hash')) {
      context.handle(
        _fullHashMeta,
        fullHash.isAcceptableOrUnknown(data['full_hash']!, _fullHashMeta),
      );
    }
    if (data.containsKey('last_seen_scan_id')) {
      context.handle(
        _lastSeenScanIdMeta,
        lastSeenScanId.isAcceptableOrUnknown(
          data['last_seen_scan_id']!,
          _lastSeenScanIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, path};
  @override
  FileIndexRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileIndexRow(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captured_at'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      partialHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partial_hash'],
      ),
      fullHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_hash'],
      ),
      lastSeenScanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_seen_scan_id'],
      ),
    );
  }

  @override
  $FileIndexTable createAlias(String alias) {
    return $FileIndexTable(attachedDatabase, alias);
  }
}

class FileIndexRow extends DataClass implements Insertable<FileIndexRow> {
  final String sourceId;
  final String path;
  final int size;
  final int modifiedAt;
  final int? capturedAt;
  final String? mimeType;
  final String? partialHash;
  final String? fullHash;
  final String? lastSeenScanId;
  const FileIndexRow({
    required this.sourceId,
    required this.path,
    required this.size,
    required this.modifiedAt,
    this.capturedAt,
    this.mimeType,
    this.partialHash,
    this.fullHash,
    this.lastSeenScanId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['path'] = Variable<String>(path);
    map['size'] = Variable<int>(size);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || capturedAt != null) {
      map['captured_at'] = Variable<int>(capturedAt);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || partialHash != null) {
      map['partial_hash'] = Variable<String>(partialHash);
    }
    if (!nullToAbsent || fullHash != null) {
      map['full_hash'] = Variable<String>(fullHash);
    }
    if (!nullToAbsent || lastSeenScanId != null) {
      map['last_seen_scan_id'] = Variable<String>(lastSeenScanId);
    }
    return map;
  }

  FileIndexCompanion toCompanion(bool nullToAbsent) {
    return FileIndexCompanion(
      sourceId: Value(sourceId),
      path: Value(path),
      size: Value(size),
      modifiedAt: Value(modifiedAt),
      capturedAt: capturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(capturedAt),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      partialHash: partialHash == null && nullToAbsent
          ? const Value.absent()
          : Value(partialHash),
      fullHash: fullHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fullHash),
      lastSeenScanId: lastSeenScanId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenScanId),
    );
  }

  factory FileIndexRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileIndexRow(
      sourceId: serializer.fromJson<String>(json['sourceId']),
      path: serializer.fromJson<String>(json['path']),
      size: serializer.fromJson<int>(json['size']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      capturedAt: serializer.fromJson<int?>(json['capturedAt']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      partialHash: serializer.fromJson<String?>(json['partialHash']),
      fullHash: serializer.fromJson<String?>(json['fullHash']),
      lastSeenScanId: serializer.fromJson<String?>(json['lastSeenScanId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<String>(sourceId),
      'path': serializer.toJson<String>(path),
      'size': serializer.toJson<int>(size),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'capturedAt': serializer.toJson<int?>(capturedAt),
      'mimeType': serializer.toJson<String?>(mimeType),
      'partialHash': serializer.toJson<String?>(partialHash),
      'fullHash': serializer.toJson<String?>(fullHash),
      'lastSeenScanId': serializer.toJson<String?>(lastSeenScanId),
    };
  }

  FileIndexRow copyWith({
    String? sourceId,
    String? path,
    int? size,
    int? modifiedAt,
    Value<int?> capturedAt = const Value.absent(),
    Value<String?> mimeType = const Value.absent(),
    Value<String?> partialHash = const Value.absent(),
    Value<String?> fullHash = const Value.absent(),
    Value<String?> lastSeenScanId = const Value.absent(),
  }) => FileIndexRow(
    sourceId: sourceId ?? this.sourceId,
    path: path ?? this.path,
    size: size ?? this.size,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    capturedAt: capturedAt.present ? capturedAt.value : this.capturedAt,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    partialHash: partialHash.present ? partialHash.value : this.partialHash,
    fullHash: fullHash.present ? fullHash.value : this.fullHash,
    lastSeenScanId: lastSeenScanId.present
        ? lastSeenScanId.value
        : this.lastSeenScanId,
  );
  FileIndexRow copyWithCompanion(FileIndexCompanion data) {
    return FileIndexRow(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      path: data.path.present ? data.path.value : this.path,
      size: data.size.present ? data.size.value : this.size,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      partialHash: data.partialHash.present
          ? data.partialHash.value
          : this.partialHash,
      fullHash: data.fullHash.present ? data.fullHash.value : this.fullHash,
      lastSeenScanId: data.lastSeenScanId.present
          ? data.lastSeenScanId.value
          : this.lastSeenScanId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileIndexRow(')
          ..write('sourceId: $sourceId, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('mimeType: $mimeType, ')
          ..write('partialHash: $partialHash, ')
          ..write('fullHash: $fullHash, ')
          ..write('lastSeenScanId: $lastSeenScanId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    path,
    size,
    modifiedAt,
    capturedAt,
    mimeType,
    partialHash,
    fullHash,
    lastSeenScanId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileIndexRow &&
          other.sourceId == this.sourceId &&
          other.path == this.path &&
          other.size == this.size &&
          other.modifiedAt == this.modifiedAt &&
          other.capturedAt == this.capturedAt &&
          other.mimeType == this.mimeType &&
          other.partialHash == this.partialHash &&
          other.fullHash == this.fullHash &&
          other.lastSeenScanId == this.lastSeenScanId);
}

class FileIndexCompanion extends UpdateCompanion<FileIndexRow> {
  final Value<String> sourceId;
  final Value<String> path;
  final Value<int> size;
  final Value<int> modifiedAt;
  final Value<int?> capturedAt;
  final Value<String?> mimeType;
  final Value<String?> partialHash;
  final Value<String?> fullHash;
  final Value<String?> lastSeenScanId;
  final Value<int> rowid;
  const FileIndexCompanion({
    this.sourceId = const Value.absent(),
    this.path = const Value.absent(),
    this.size = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.partialHash = const Value.absent(),
    this.fullHash = const Value.absent(),
    this.lastSeenScanId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FileIndexCompanion.insert({
    required String sourceId,
    required String path,
    required int size,
    required int modifiedAt,
    this.capturedAt = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.partialHash = const Value.absent(),
    this.fullHash = const Value.absent(),
    this.lastSeenScanId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       path = Value(path),
       size = Value(size),
       modifiedAt = Value(modifiedAt);
  static Insertable<FileIndexRow> custom({
    Expression<String>? sourceId,
    Expression<String>? path,
    Expression<int>? size,
    Expression<int>? modifiedAt,
    Expression<int>? capturedAt,
    Expression<String>? mimeType,
    Expression<String>? partialHash,
    Expression<String>? fullHash,
    Expression<String>? lastSeenScanId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (path != null) 'path': path,
      if (size != null) 'size': size,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (mimeType != null) 'mime_type': mimeType,
      if (partialHash != null) 'partial_hash': partialHash,
      if (fullHash != null) 'full_hash': fullHash,
      if (lastSeenScanId != null) 'last_seen_scan_id': lastSeenScanId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FileIndexCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? path,
    Value<int>? size,
    Value<int>? modifiedAt,
    Value<int?>? capturedAt,
    Value<String?>? mimeType,
    Value<String?>? partialHash,
    Value<String?>? fullHash,
    Value<String?>? lastSeenScanId,
    Value<int>? rowid,
  }) {
    return FileIndexCompanion(
      sourceId: sourceId ?? this.sourceId,
      path: path ?? this.path,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      capturedAt: capturedAt ?? this.capturedAt,
      mimeType: mimeType ?? this.mimeType,
      partialHash: partialHash ?? this.partialHash,
      fullHash: fullHash ?? this.fullHash,
      lastSeenScanId: lastSeenScanId ?? this.lastSeenScanId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(capturedAt.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (partialHash.present) {
      map['partial_hash'] = Variable<String>(partialHash.value);
    }
    if (fullHash.present) {
      map['full_hash'] = Variable<String>(fullHash.value);
    }
    if (lastSeenScanId.present) {
      map['last_seen_scan_id'] = Variable<String>(lastSeenScanId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileIndexCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('mimeType: $mimeType, ')
          ..write('partialHash: $partialHash, ')
          ..write('fullHash: $fullHash, ')
          ..write('lastSeenScanId: $lastSeenScanId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScanCheckpointsTable extends ScanCheckpoints
    with TableInfo<$ScanCheckpointsTable, ScanCheckpointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, scanId, stage, cursor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanCheckpointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId};
  @override
  ScanCheckpointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanCheckpointRow(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
    );
  }

  @override
  $ScanCheckpointsTable createAlias(String alias) {
    return $ScanCheckpointsTable(attachedDatabase, alias);
  }
}

class ScanCheckpointRow extends DataClass
    implements Insertable<ScanCheckpointRow> {
  final String sourceId;
  final String scanId;
  final String stage;
  final String? cursor;
  const ScanCheckpointRow({
    required this.sourceId,
    required this.scanId,
    required this.stage,
    this.cursor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['scan_id'] = Variable<String>(scanId);
    map['stage'] = Variable<String>(stage);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    return map;
  }

  ScanCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return ScanCheckpointsCompanion(
      sourceId: Value(sourceId),
      scanId: Value(scanId),
      stage: Value(stage),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
    );
  }

  factory ScanCheckpointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanCheckpointRow(
      sourceId: serializer.fromJson<String>(json['sourceId']),
      scanId: serializer.fromJson<String>(json['scanId']),
      stage: serializer.fromJson<String>(json['stage']),
      cursor: serializer.fromJson<String?>(json['cursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<String>(sourceId),
      'scanId': serializer.toJson<String>(scanId),
      'stage': serializer.toJson<String>(stage),
      'cursor': serializer.toJson<String?>(cursor),
    };
  }

  ScanCheckpointRow copyWith({
    String? sourceId,
    String? scanId,
    String? stage,
    Value<String?> cursor = const Value.absent(),
  }) => ScanCheckpointRow(
    sourceId: sourceId ?? this.sourceId,
    scanId: scanId ?? this.scanId,
    stage: stage ?? this.stage,
    cursor: cursor.present ? cursor.value : this.cursor,
  );
  ScanCheckpointRow copyWithCompanion(ScanCheckpointsCompanion data) {
    return ScanCheckpointRow(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      stage: data.stage.present ? data.stage.value : this.stage,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanCheckpointRow(')
          ..write('sourceId: $sourceId, ')
          ..write('scanId: $scanId, ')
          ..write('stage: $stage, ')
          ..write('cursor: $cursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, scanId, stage, cursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanCheckpointRow &&
          other.sourceId == this.sourceId &&
          other.scanId == this.scanId &&
          other.stage == this.stage &&
          other.cursor == this.cursor);
}

class ScanCheckpointsCompanion extends UpdateCompanion<ScanCheckpointRow> {
  final Value<String> sourceId;
  final Value<String> scanId;
  final Value<String> stage;
  final Value<String?> cursor;
  final Value<int> rowid;
  const ScanCheckpointsCompanion({
    this.sourceId = const Value.absent(),
    this.scanId = const Value.absent(),
    this.stage = const Value.absent(),
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanCheckpointsCompanion.insert({
    required String sourceId,
    required String scanId,
    required String stage,
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       scanId = Value(scanId),
       stage = Value(stage);
  static Insertable<ScanCheckpointRow> custom({
    Expression<String>? sourceId,
    Expression<String>? scanId,
    Expression<String>? stage,
    Expression<String>? cursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (scanId != null) 'scan_id': scanId,
      if (stage != null) 'stage': stage,
      if (cursor != null) 'cursor': cursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanCheckpointsCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? scanId,
    Value<String>? stage,
    Value<String?>? cursor,
    Value<int>? rowid,
  }) {
    return ScanCheckpointsCompanion(
      sourceId: sourceId ?? this.sourceId,
      scanId: scanId ?? this.scanId,
      stage: stage ?? this.stage,
      cursor: cursor ?? this.cursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanCheckpointsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('scanId: $scanId, ')
          ..write('stage: $stage, ')
          ..write('cursor: $cursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statTotalMeta = const VerificationMeta(
    'statTotal',
  );
  @override
  late final GeneratedColumn<int> statTotal = GeneratedColumn<int>(
    'stat_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statDoneMeta = const VerificationMeta(
    'statDone',
  );
  @override
  late final GeneratedColumn<int> statDone = GeneratedColumn<int>(
    'stat_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statFailedMeta = const VerificationMeta(
    'statFailed',
  );
  @override
  late final GeneratedColumn<int> statFailed = GeneratedColumn<int>(
    'stat_failed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statSkippedMeta = const VerificationMeta(
    'statSkipped',
  );
  @override
  late final GeneratedColumn<int> statSkipped = GeneratedColumn<int>(
    'stat_skipped',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statRevertedMeta = const VerificationMeta(
    'statReverted',
  );
  @override
  late final GeneratedColumn<int> statReverted = GeneratedColumn<int>(
    'stat_reverted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statRevertSkippedMeta = const VerificationMeta(
    'statRevertSkipped',
  );
  @override
  late final GeneratedColumn<int> statRevertSkipped = GeneratedColumn<int>(
    'stat_revert_skipped',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statRemovedBytesMeta = const VerificationMeta(
    'statRemovedBytes',
  );
  @override
  late final GeneratedColumn<int> statRemovedBytes = GeneratedColumn<int>(
    'stat_removed_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    finishedAt,
    status,
    statTotal,
    statDone,
    statFailed,
    statSkipped,
    statReverted,
    statRevertSkipped,
    statRemovedBytes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('stat_total')) {
      context.handle(
        _statTotalMeta,
        statTotal.isAcceptableOrUnknown(data['stat_total']!, _statTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_statTotalMeta);
    }
    if (data.containsKey('stat_done')) {
      context.handle(
        _statDoneMeta,
        statDone.isAcceptableOrUnknown(data['stat_done']!, _statDoneMeta),
      );
    } else if (isInserting) {
      context.missing(_statDoneMeta);
    }
    if (data.containsKey('stat_failed')) {
      context.handle(
        _statFailedMeta,
        statFailed.isAcceptableOrUnknown(data['stat_failed']!, _statFailedMeta),
      );
    } else if (isInserting) {
      context.missing(_statFailedMeta);
    }
    if (data.containsKey('stat_skipped')) {
      context.handle(
        _statSkippedMeta,
        statSkipped.isAcceptableOrUnknown(
          data['stat_skipped']!,
          _statSkippedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statSkippedMeta);
    }
    if (data.containsKey('stat_reverted')) {
      context.handle(
        _statRevertedMeta,
        statReverted.isAcceptableOrUnknown(
          data['stat_reverted']!,
          _statRevertedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statRevertedMeta);
    }
    if (data.containsKey('stat_revert_skipped')) {
      context.handle(
        _statRevertSkippedMeta,
        statRevertSkipped.isAcceptableOrUnknown(
          data['stat_revert_skipped']!,
          _statRevertSkippedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statRevertSkippedMeta);
    }
    if (data.containsKey('stat_removed_bytes')) {
      context.handle(
        _statRemovedBytesMeta,
        statRemovedBytes.isAcceptableOrUnknown(
          data['stat_removed_bytes']!,
          _statRemovedBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statRemovedBytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      statTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stat_total'],
      )!,
      statDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stat_done'],
      )!,
      statFailed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stat_failed'],
      )!,
      statSkipped: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stat_skipped'],
      )!,
      statReverted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stat_reverted'],
      )!,
      statRevertSkipped: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stat_revert_skipped'],
      )!,
      statRemovedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stat_removed_bytes'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final String id;
  final int startedAt;
  final int? finishedAt;
  final String status;
  final int statTotal;
  final int statDone;
  final int statFailed;
  final int statSkipped;
  final int statReverted;
  final int statRevertSkipped;
  final int statRemovedBytes;
  const SessionRow({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    required this.status,
    required this.statTotal,
    required this.statDone,
    required this.statFailed,
    required this.statSkipped,
    required this.statReverted,
    required this.statRevertSkipped,
    required this.statRemovedBytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    map['status'] = Variable<String>(status);
    map['stat_total'] = Variable<int>(statTotal);
    map['stat_done'] = Variable<int>(statDone);
    map['stat_failed'] = Variable<int>(statFailed);
    map['stat_skipped'] = Variable<int>(statSkipped);
    map['stat_reverted'] = Variable<int>(statReverted);
    map['stat_revert_skipped'] = Variable<int>(statRevertSkipped);
    map['stat_removed_bytes'] = Variable<int>(statRemovedBytes);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      status: Value(status),
      statTotal: Value(statTotal),
      statDone: Value(statDone),
      statFailed: Value(statFailed),
      statSkipped: Value(statSkipped),
      statReverted: Value(statReverted),
      statRevertSkipped: Value(statRevertSkipped),
      statRemovedBytes: Value(statRemovedBytes),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
      status: serializer.fromJson<String>(json['status']),
      statTotal: serializer.fromJson<int>(json['statTotal']),
      statDone: serializer.fromJson<int>(json['statDone']),
      statFailed: serializer.fromJson<int>(json['statFailed']),
      statSkipped: serializer.fromJson<int>(json['statSkipped']),
      statReverted: serializer.fromJson<int>(json['statReverted']),
      statRevertSkipped: serializer.fromJson<int>(json['statRevertSkipped']),
      statRemovedBytes: serializer.fromJson<int>(json['statRemovedBytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<int>(startedAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
      'status': serializer.toJson<String>(status),
      'statTotal': serializer.toJson<int>(statTotal),
      'statDone': serializer.toJson<int>(statDone),
      'statFailed': serializer.toJson<int>(statFailed),
      'statSkipped': serializer.toJson<int>(statSkipped),
      'statReverted': serializer.toJson<int>(statReverted),
      'statRevertSkipped': serializer.toJson<int>(statRevertSkipped),
      'statRemovedBytes': serializer.toJson<int>(statRemovedBytes),
    };
  }

  SessionRow copyWith({
    String? id,
    int? startedAt,
    Value<int?> finishedAt = const Value.absent(),
    String? status,
    int? statTotal,
    int? statDone,
    int? statFailed,
    int? statSkipped,
    int? statReverted,
    int? statRevertSkipped,
    int? statRemovedBytes,
  }) => SessionRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    status: status ?? this.status,
    statTotal: statTotal ?? this.statTotal,
    statDone: statDone ?? this.statDone,
    statFailed: statFailed ?? this.statFailed,
    statSkipped: statSkipped ?? this.statSkipped,
    statReverted: statReverted ?? this.statReverted,
    statRevertSkipped: statRevertSkipped ?? this.statRevertSkipped,
    statRemovedBytes: statRemovedBytes ?? this.statRemovedBytes,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      status: data.status.present ? data.status.value : this.status,
      statTotal: data.statTotal.present ? data.statTotal.value : this.statTotal,
      statDone: data.statDone.present ? data.statDone.value : this.statDone,
      statFailed: data.statFailed.present
          ? data.statFailed.value
          : this.statFailed,
      statSkipped: data.statSkipped.present
          ? data.statSkipped.value
          : this.statSkipped,
      statReverted: data.statReverted.present
          ? data.statReverted.value
          : this.statReverted,
      statRevertSkipped: data.statRevertSkipped.present
          ? data.statRevertSkipped.value
          : this.statRevertSkipped,
      statRemovedBytes: data.statRemovedBytes.present
          ? data.statRemovedBytes.value
          : this.statRemovedBytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('status: $status, ')
          ..write('statTotal: $statTotal, ')
          ..write('statDone: $statDone, ')
          ..write('statFailed: $statFailed, ')
          ..write('statSkipped: $statSkipped, ')
          ..write('statReverted: $statReverted, ')
          ..write('statRevertSkipped: $statRevertSkipped, ')
          ..write('statRemovedBytes: $statRemovedBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    finishedAt,
    status,
    statTotal,
    statDone,
    statFailed,
    statSkipped,
    statReverted,
    statRevertSkipped,
    statRemovedBytes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.status == this.status &&
          other.statTotal == this.statTotal &&
          other.statDone == this.statDone &&
          other.statFailed == this.statFailed &&
          other.statSkipped == this.statSkipped &&
          other.statReverted == this.statReverted &&
          other.statRevertSkipped == this.statRevertSkipped &&
          other.statRemovedBytes == this.statRemovedBytes);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> id;
  final Value<int> startedAt;
  final Value<int?> finishedAt;
  final Value<String> status;
  final Value<int> statTotal;
  final Value<int> statDone;
  final Value<int> statFailed;
  final Value<int> statSkipped;
  final Value<int> statReverted;
  final Value<int> statRevertSkipped;
  final Value<int> statRemovedBytes;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.statTotal = const Value.absent(),
    this.statDone = const Value.absent(),
    this.statFailed = const Value.absent(),
    this.statSkipped = const Value.absent(),
    this.statReverted = const Value.absent(),
    this.statRevertSkipped = const Value.absent(),
    this.statRemovedBytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required int startedAt,
    this.finishedAt = const Value.absent(),
    required String status,
    required int statTotal,
    required int statDone,
    required int statFailed,
    required int statSkipped,
    required int statReverted,
    required int statRevertSkipped,
    required int statRemovedBytes,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       status = Value(status),
       statTotal = Value(statTotal),
       statDone = Value(statDone),
       statFailed = Value(statFailed),
       statSkipped = Value(statSkipped),
       statReverted = Value(statReverted),
       statRevertSkipped = Value(statRevertSkipped),
       statRemovedBytes = Value(statRemovedBytes);
  static Insertable<SessionRow> custom({
    Expression<String>? id,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<String>? status,
    Expression<int>? statTotal,
    Expression<int>? statDone,
    Expression<int>? statFailed,
    Expression<int>? statSkipped,
    Expression<int>? statReverted,
    Expression<int>? statRevertSkipped,
    Expression<int>? statRemovedBytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (status != null) 'status': status,
      if (statTotal != null) 'stat_total': statTotal,
      if (statDone != null) 'stat_done': statDone,
      if (statFailed != null) 'stat_failed': statFailed,
      if (statSkipped != null) 'stat_skipped': statSkipped,
      if (statReverted != null) 'stat_reverted': statReverted,
      if (statRevertSkipped != null) 'stat_revert_skipped': statRevertSkipped,
      if (statRemovedBytes != null) 'stat_removed_bytes': statRemovedBytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<int>? startedAt,
    Value<int?>? finishedAt,
    Value<String>? status,
    Value<int>? statTotal,
    Value<int>? statDone,
    Value<int>? statFailed,
    Value<int>? statSkipped,
    Value<int>? statReverted,
    Value<int>? statRevertSkipped,
    Value<int>? statRemovedBytes,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      status: status ?? this.status,
      statTotal: statTotal ?? this.statTotal,
      statDone: statDone ?? this.statDone,
      statFailed: statFailed ?? this.statFailed,
      statSkipped: statSkipped ?? this.statSkipped,
      statReverted: statReverted ?? this.statReverted,
      statRevertSkipped: statRevertSkipped ?? this.statRevertSkipped,
      statRemovedBytes: statRemovedBytes ?? this.statRemovedBytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (statTotal.present) {
      map['stat_total'] = Variable<int>(statTotal.value);
    }
    if (statDone.present) {
      map['stat_done'] = Variable<int>(statDone.value);
    }
    if (statFailed.present) {
      map['stat_failed'] = Variable<int>(statFailed.value);
    }
    if (statSkipped.present) {
      map['stat_skipped'] = Variable<int>(statSkipped.value);
    }
    if (statReverted.present) {
      map['stat_reverted'] = Variable<int>(statReverted.value);
    }
    if (statRevertSkipped.present) {
      map['stat_revert_skipped'] = Variable<int>(statRevertSkipped.value);
    }
    if (statRemovedBytes.present) {
      map['stat_removed_bytes'] = Variable<int>(statRemovedBytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('status: $status, ')
          ..write('statTotal: $statTotal, ')
          ..write('statDone: $statDone, ')
          ..write('statFailed: $statFailed, ')
          ..write('statSkipped: $statSkipped, ')
          ..write('statReverted: $statReverted, ')
          ..write('statRevertSkipped: $statRevertSkipped, ')
          ..write('statRemovedBytes: $statRemovedBytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperationsTable extends Operations
    with TableInfo<$OperationsTable, OperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromPathMeta = const VerificationMeta(
    'fromPath',
  );
  @override
  late final GeneratedColumn<String> fromPath = GeneratedColumn<String>(
    'from_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toPathMeta = const VerificationMeta('toPath');
  @override
  late final GeneratedColumn<String> toPath = GeneratedColumn<String>(
    'to_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fingerprintSizeMeta = const VerificationMeta(
    'fingerprintSize',
  );
  @override
  late final GeneratedColumn<int> fingerprintSize = GeneratedColumn<int>(
    'fingerprint_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fingerprintModifiedAtMeta =
      const VerificationMeta('fingerprintModifiedAt');
  @override
  late final GeneratedColumn<int> fingerprintModifiedAt = GeneratedColumn<int>(
    'fingerprint_modified_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fingerprintFullHashMeta =
      const VerificationMeta('fingerprintFullHash');
  @override
  late final GeneratedColumn<String> fingerprintFullHash =
      GeneratedColumn<String>(
        'fingerprint_full_hash',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _quarantineRefMeta = const VerificationMeta(
    'quarantineRef',
  );
  @override
  late final GeneratedColumn<String> quarantineRef = GeneratedColumn<String>(
    'quarantine_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupKeyMeta = const VerificationMeta(
    'groupKey',
  );
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
    'group_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _executedAtMeta = const VerificationMeta(
    'executedAt',
  );
  @override
  late final GeneratedColumn<int> executedAt = GeneratedColumn<int>(
    'executed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revertedAtMeta = const VerificationMeta(
    'revertedAt',
  );
  @override
  late final GeneratedColumn<int> revertedAt = GeneratedColumn<int>(
    'reverted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seq,
    type,
    sourceId,
    fromPath,
    toPath,
    fingerprintSize,
    fingerprintModifiedAt,
    fingerprintFullHash,
    quarantineRef,
    reason,
    groupKey,
    status,
    error,
    executedAt,
    revertedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<OperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('from_path')) {
      context.handle(
        _fromPathMeta,
        fromPath.isAcceptableOrUnknown(data['from_path']!, _fromPathMeta),
      );
    }
    if (data.containsKey('to_path')) {
      context.handle(
        _toPathMeta,
        toPath.isAcceptableOrUnknown(data['to_path']!, _toPathMeta),
      );
    }
    if (data.containsKey('fingerprint_size')) {
      context.handle(
        _fingerprintSizeMeta,
        fingerprintSize.isAcceptableOrUnknown(
          data['fingerprint_size']!,
          _fingerprintSizeMeta,
        ),
      );
    }
    if (data.containsKey('fingerprint_modified_at')) {
      context.handle(
        _fingerprintModifiedAtMeta,
        fingerprintModifiedAt.isAcceptableOrUnknown(
          data['fingerprint_modified_at']!,
          _fingerprintModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('fingerprint_full_hash')) {
      context.handle(
        _fingerprintFullHashMeta,
        fingerprintFullHash.isAcceptableOrUnknown(
          data['fingerprint_full_hash']!,
          _fingerprintFullHashMeta,
        ),
      );
    }
    if (data.containsKey('quarantine_ref')) {
      context.handle(
        _quarantineRefMeta,
        quarantineRef.isAcceptableOrUnknown(
          data['quarantine_ref']!,
          _quarantineRefMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('group_key')) {
      context.handle(
        _groupKeyMeta,
        groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_groupKeyMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('executed_at')) {
      context.handle(
        _executedAtMeta,
        executedAt.isAcceptableOrUnknown(data['executed_at']!, _executedAtMeta),
      );
    }
    if (data.containsKey('reverted_at')) {
      context.handle(
        _revertedAtMeta,
        revertedAt.isAcceptableOrUnknown(data['reverted_at']!, _revertedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, seq},
  ];
  @override
  OperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OperationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      fromPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_path'],
      ),
      toPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_path'],
      ),
      fingerprintSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fingerprint_size'],
      ),
      fingerprintModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fingerprint_modified_at'],
      ),
      fingerprintFullHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint_full_hash'],
      ),
      quarantineRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quarantine_ref'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      groupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_key'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      executedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}executed_at'],
      ),
      revertedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reverted_at'],
      ),
    );
  }

  @override
  $OperationsTable createAlias(String alias) {
    return $OperationsTable(attachedDatabase, alias);
  }
}

class OperationRow extends DataClass implements Insertable<OperationRow> {
  final String id;
  final String sessionId;
  final int seq;
  final String type;
  final String sourceId;
  final String? fromPath;
  final String? toPath;
  final int? fingerprintSize;
  final int? fingerprintModifiedAt;
  final String? fingerprintFullHash;
  final String? quarantineRef;
  final String reason;
  final String groupKey;
  final String status;
  final String? error;
  final int? executedAt;
  final int? revertedAt;
  const OperationRow({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.type,
    required this.sourceId,
    this.fromPath,
    this.toPath,
    this.fingerprintSize,
    this.fingerprintModifiedAt,
    this.fingerprintFullHash,
    this.quarantineRef,
    required this.reason,
    required this.groupKey,
    required this.status,
    this.error,
    this.executedAt,
    this.revertedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['seq'] = Variable<int>(seq);
    map['type'] = Variable<String>(type);
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || fromPath != null) {
      map['from_path'] = Variable<String>(fromPath);
    }
    if (!nullToAbsent || toPath != null) {
      map['to_path'] = Variable<String>(toPath);
    }
    if (!nullToAbsent || fingerprintSize != null) {
      map['fingerprint_size'] = Variable<int>(fingerprintSize);
    }
    if (!nullToAbsent || fingerprintModifiedAt != null) {
      map['fingerprint_modified_at'] = Variable<int>(fingerprintModifiedAt);
    }
    if (!nullToAbsent || fingerprintFullHash != null) {
      map['fingerprint_full_hash'] = Variable<String>(fingerprintFullHash);
    }
    if (!nullToAbsent || quarantineRef != null) {
      map['quarantine_ref'] = Variable<String>(quarantineRef);
    }
    map['reason'] = Variable<String>(reason);
    map['group_key'] = Variable<String>(groupKey);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || executedAt != null) {
      map['executed_at'] = Variable<int>(executedAt);
    }
    if (!nullToAbsent || revertedAt != null) {
      map['reverted_at'] = Variable<int>(revertedAt);
    }
    return map;
  }

  OperationsCompanion toCompanion(bool nullToAbsent) {
    return OperationsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seq: Value(seq),
      type: Value(type),
      sourceId: Value(sourceId),
      fromPath: fromPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fromPath),
      toPath: toPath == null && nullToAbsent
          ? const Value.absent()
          : Value(toPath),
      fingerprintSize: fingerprintSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fingerprintSize),
      fingerprintModifiedAt: fingerprintModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fingerprintModifiedAt),
      fingerprintFullHash: fingerprintFullHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fingerprintFullHash),
      quarantineRef: quarantineRef == null && nullToAbsent
          ? const Value.absent()
          : Value(quarantineRef),
      reason: Value(reason),
      groupKey: Value(groupKey),
      status: Value(status),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      executedAt: executedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(executedAt),
      revertedAt: revertedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revertedAt),
    );
  }

  factory OperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OperationRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
      type: serializer.fromJson<String>(json['type']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      fromPath: serializer.fromJson<String?>(json['fromPath']),
      toPath: serializer.fromJson<String?>(json['toPath']),
      fingerprintSize: serializer.fromJson<int?>(json['fingerprintSize']),
      fingerprintModifiedAt: serializer.fromJson<int?>(
        json['fingerprintModifiedAt'],
      ),
      fingerprintFullHash: serializer.fromJson<String?>(
        json['fingerprintFullHash'],
      ),
      quarantineRef: serializer.fromJson<String?>(json['quarantineRef']),
      reason: serializer.fromJson<String>(json['reason']),
      groupKey: serializer.fromJson<String>(json['groupKey']),
      status: serializer.fromJson<String>(json['status']),
      error: serializer.fromJson<String?>(json['error']),
      executedAt: serializer.fromJson<int?>(json['executedAt']),
      revertedAt: serializer.fromJson<int?>(json['revertedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'seq': serializer.toJson<int>(seq),
      'type': serializer.toJson<String>(type),
      'sourceId': serializer.toJson<String>(sourceId),
      'fromPath': serializer.toJson<String?>(fromPath),
      'toPath': serializer.toJson<String?>(toPath),
      'fingerprintSize': serializer.toJson<int?>(fingerprintSize),
      'fingerprintModifiedAt': serializer.toJson<int?>(fingerprintModifiedAt),
      'fingerprintFullHash': serializer.toJson<String?>(fingerprintFullHash),
      'quarantineRef': serializer.toJson<String?>(quarantineRef),
      'reason': serializer.toJson<String>(reason),
      'groupKey': serializer.toJson<String>(groupKey),
      'status': serializer.toJson<String>(status),
      'error': serializer.toJson<String?>(error),
      'executedAt': serializer.toJson<int?>(executedAt),
      'revertedAt': serializer.toJson<int?>(revertedAt),
    };
  }

  OperationRow copyWith({
    String? id,
    String? sessionId,
    int? seq,
    String? type,
    String? sourceId,
    Value<String?> fromPath = const Value.absent(),
    Value<String?> toPath = const Value.absent(),
    Value<int?> fingerprintSize = const Value.absent(),
    Value<int?> fingerprintModifiedAt = const Value.absent(),
    Value<String?> fingerprintFullHash = const Value.absent(),
    Value<String?> quarantineRef = const Value.absent(),
    String? reason,
    String? groupKey,
    String? status,
    Value<String?> error = const Value.absent(),
    Value<int?> executedAt = const Value.absent(),
    Value<int?> revertedAt = const Value.absent(),
  }) => OperationRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seq: seq ?? this.seq,
    type: type ?? this.type,
    sourceId: sourceId ?? this.sourceId,
    fromPath: fromPath.present ? fromPath.value : this.fromPath,
    toPath: toPath.present ? toPath.value : this.toPath,
    fingerprintSize: fingerprintSize.present
        ? fingerprintSize.value
        : this.fingerprintSize,
    fingerprintModifiedAt: fingerprintModifiedAt.present
        ? fingerprintModifiedAt.value
        : this.fingerprintModifiedAt,
    fingerprintFullHash: fingerprintFullHash.present
        ? fingerprintFullHash.value
        : this.fingerprintFullHash,
    quarantineRef: quarantineRef.present
        ? quarantineRef.value
        : this.quarantineRef,
    reason: reason ?? this.reason,
    groupKey: groupKey ?? this.groupKey,
    status: status ?? this.status,
    error: error.present ? error.value : this.error,
    executedAt: executedAt.present ? executedAt.value : this.executedAt,
    revertedAt: revertedAt.present ? revertedAt.value : this.revertedAt,
  );
  OperationRow copyWithCompanion(OperationsCompanion data) {
    return OperationRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      type: data.type.present ? data.type.value : this.type,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      fromPath: data.fromPath.present ? data.fromPath.value : this.fromPath,
      toPath: data.toPath.present ? data.toPath.value : this.toPath,
      fingerprintSize: data.fingerprintSize.present
          ? data.fingerprintSize.value
          : this.fingerprintSize,
      fingerprintModifiedAt: data.fingerprintModifiedAt.present
          ? data.fingerprintModifiedAt.value
          : this.fingerprintModifiedAt,
      fingerprintFullHash: data.fingerprintFullHash.present
          ? data.fingerprintFullHash.value
          : this.fingerprintFullHash,
      quarantineRef: data.quarantineRef.present
          ? data.quarantineRef.value
          : this.quarantineRef,
      reason: data.reason.present ? data.reason.value : this.reason,
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      status: data.status.present ? data.status.value : this.status,
      error: data.error.present ? data.error.value : this.error,
      executedAt: data.executedAt.present
          ? data.executedAt.value
          : this.executedAt,
      revertedAt: data.revertedAt.present
          ? data.revertedAt.value
          : this.revertedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OperationRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('sourceId: $sourceId, ')
          ..write('fromPath: $fromPath, ')
          ..write('toPath: $toPath, ')
          ..write('fingerprintSize: $fingerprintSize, ')
          ..write('fingerprintModifiedAt: $fingerprintModifiedAt, ')
          ..write('fingerprintFullHash: $fingerprintFullHash, ')
          ..write('quarantineRef: $quarantineRef, ')
          ..write('reason: $reason, ')
          ..write('groupKey: $groupKey, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('executedAt: $executedAt, ')
          ..write('revertedAt: $revertedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seq,
    type,
    sourceId,
    fromPath,
    toPath,
    fingerprintSize,
    fingerprintModifiedAt,
    fingerprintFullHash,
    quarantineRef,
    reason,
    groupKey,
    status,
    error,
    executedAt,
    revertedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OperationRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq &&
          other.type == this.type &&
          other.sourceId == this.sourceId &&
          other.fromPath == this.fromPath &&
          other.toPath == this.toPath &&
          other.fingerprintSize == this.fingerprintSize &&
          other.fingerprintModifiedAt == this.fingerprintModifiedAt &&
          other.fingerprintFullHash == this.fingerprintFullHash &&
          other.quarantineRef == this.quarantineRef &&
          other.reason == this.reason &&
          other.groupKey == this.groupKey &&
          other.status == this.status &&
          other.error == this.error &&
          other.executedAt == this.executedAt &&
          other.revertedAt == this.revertedAt);
}

class OperationsCompanion extends UpdateCompanion<OperationRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> seq;
  final Value<String> type;
  final Value<String> sourceId;
  final Value<String?> fromPath;
  final Value<String?> toPath;
  final Value<int?> fingerprintSize;
  final Value<int?> fingerprintModifiedAt;
  final Value<String?> fingerprintFullHash;
  final Value<String?> quarantineRef;
  final Value<String> reason;
  final Value<String> groupKey;
  final Value<String> status;
  final Value<String?> error;
  final Value<int?> executedAt;
  final Value<int?> revertedAt;
  final Value<int> rowid;
  const OperationsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.type = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.fromPath = const Value.absent(),
    this.toPath = const Value.absent(),
    this.fingerprintSize = const Value.absent(),
    this.fingerprintModifiedAt = const Value.absent(),
    this.fingerprintFullHash = const Value.absent(),
    this.quarantineRef = const Value.absent(),
    this.reason = const Value.absent(),
    this.groupKey = const Value.absent(),
    this.status = const Value.absent(),
    this.error = const Value.absent(),
    this.executedAt = const Value.absent(),
    this.revertedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperationsCompanion.insert({
    required String id,
    required String sessionId,
    required int seq,
    required String type,
    required String sourceId,
    this.fromPath = const Value.absent(),
    this.toPath = const Value.absent(),
    this.fingerprintSize = const Value.absent(),
    this.fingerprintModifiedAt = const Value.absent(),
    this.fingerprintFullHash = const Value.absent(),
    this.quarantineRef = const Value.absent(),
    required String reason,
    required String groupKey,
    required String status,
    this.error = const Value.absent(),
    this.executedAt = const Value.absent(),
    this.revertedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       seq = Value(seq),
       type = Value(type),
       sourceId = Value(sourceId),
       reason = Value(reason),
       groupKey = Value(groupKey),
       status = Value(status);
  static Insertable<OperationRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? seq,
    Expression<String>? type,
    Expression<String>? sourceId,
    Expression<String>? fromPath,
    Expression<String>? toPath,
    Expression<int>? fingerprintSize,
    Expression<int>? fingerprintModifiedAt,
    Expression<String>? fingerprintFullHash,
    Expression<String>? quarantineRef,
    Expression<String>? reason,
    Expression<String>? groupKey,
    Expression<String>? status,
    Expression<String>? error,
    Expression<int>? executedAt,
    Expression<int>? revertedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (type != null) 'type': type,
      if (sourceId != null) 'source_id': sourceId,
      if (fromPath != null) 'from_path': fromPath,
      if (toPath != null) 'to_path': toPath,
      if (fingerprintSize != null) 'fingerprint_size': fingerprintSize,
      if (fingerprintModifiedAt != null)
        'fingerprint_modified_at': fingerprintModifiedAt,
      if (fingerprintFullHash != null)
        'fingerprint_full_hash': fingerprintFullHash,
      if (quarantineRef != null) 'quarantine_ref': quarantineRef,
      if (reason != null) 'reason': reason,
      if (groupKey != null) 'group_key': groupKey,
      if (status != null) 'status': status,
      if (error != null) 'error': error,
      if (executedAt != null) 'executed_at': executedAt,
      if (revertedAt != null) 'reverted_at': revertedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? seq,
    Value<String>? type,
    Value<String>? sourceId,
    Value<String?>? fromPath,
    Value<String?>? toPath,
    Value<int?>? fingerprintSize,
    Value<int?>? fingerprintModifiedAt,
    Value<String?>? fingerprintFullHash,
    Value<String?>? quarantineRef,
    Value<String>? reason,
    Value<String>? groupKey,
    Value<String>? status,
    Value<String?>? error,
    Value<int?>? executedAt,
    Value<int?>? revertedAt,
    Value<int>? rowid,
  }) {
    return OperationsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      fromPath: fromPath ?? this.fromPath,
      toPath: toPath ?? this.toPath,
      fingerprintSize: fingerprintSize ?? this.fingerprintSize,
      fingerprintModifiedAt:
          fingerprintModifiedAt ?? this.fingerprintModifiedAt,
      fingerprintFullHash: fingerprintFullHash ?? this.fingerprintFullHash,
      quarantineRef: quarantineRef ?? this.quarantineRef,
      reason: reason ?? this.reason,
      groupKey: groupKey ?? this.groupKey,
      status: status ?? this.status,
      error: error ?? this.error,
      executedAt: executedAt ?? this.executedAt,
      revertedAt: revertedAt ?? this.revertedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (fromPath.present) {
      map['from_path'] = Variable<String>(fromPath.value);
    }
    if (toPath.present) {
      map['to_path'] = Variable<String>(toPath.value);
    }
    if (fingerprintSize.present) {
      map['fingerprint_size'] = Variable<int>(fingerprintSize.value);
    }
    if (fingerprintModifiedAt.present) {
      map['fingerprint_modified_at'] = Variable<int>(
        fingerprintModifiedAt.value,
      );
    }
    if (fingerprintFullHash.present) {
      map['fingerprint_full_hash'] = Variable<String>(
        fingerprintFullHash.value,
      );
    }
    if (quarantineRef.present) {
      map['quarantine_ref'] = Variable<String>(quarantineRef.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (executedAt.present) {
      map['executed_at'] = Variable<int>(executedAt.value);
    }
    if (revertedAt.present) {
      map['reverted_at'] = Variable<int>(revertedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperationsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('sourceId: $sourceId, ')
          ..write('fromPath: $fromPath, ')
          ..write('toPath: $toPath, ')
          ..write('fingerprintSize: $fingerprintSize, ')
          ..write('fingerprintModifiedAt: $fingerprintModifiedAt, ')
          ..write('fingerprintFullHash: $fingerprintFullHash, ')
          ..write('quarantineRef: $quarantineRef, ')
          ..write('reason: $reason, ')
          ..write('groupKey: $groupKey, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('executedAt: $executedAt, ')
          ..write('revertedAt: $revertedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ZoneOverridesTable extends ZoneOverrides
    with TableInfo<$ZoneOverridesTable, ZoneOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ZoneOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoneMeta = const VerificationMeta('zone');
  @override
  late final GeneratedColumn<String> zone = GeneratedColumn<String>(
    'zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, folder, zone];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'zone_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<ZoneOverrideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    } else if (isInserting) {
      context.missing(_folderMeta);
    }
    if (data.containsKey('zone')) {
      context.handle(
        _zoneMeta,
        zone.isAcceptableOrUnknown(data['zone']!, _zoneMeta),
      );
    } else if (isInserting) {
      context.missing(_zoneMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, folder};
  @override
  ZoneOverrideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ZoneOverrideRow(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      )!,
      zone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone'],
      )!,
    );
  }

  @override
  $ZoneOverridesTable createAlias(String alias) {
    return $ZoneOverridesTable(attachedDatabase, alias);
  }
}

class ZoneOverrideRow extends DataClass implements Insertable<ZoneOverrideRow> {
  final String sourceId;
  final String folder;
  final String zone;
  const ZoneOverrideRow({
    required this.sourceId,
    required this.folder,
    required this.zone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['folder'] = Variable<String>(folder);
    map['zone'] = Variable<String>(zone);
    return map;
  }

  ZoneOverridesCompanion toCompanion(bool nullToAbsent) {
    return ZoneOverridesCompanion(
      sourceId: Value(sourceId),
      folder: Value(folder),
      zone: Value(zone),
    );
  }

  factory ZoneOverrideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ZoneOverrideRow(
      sourceId: serializer.fromJson<String>(json['sourceId']),
      folder: serializer.fromJson<String>(json['folder']),
      zone: serializer.fromJson<String>(json['zone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<String>(sourceId),
      'folder': serializer.toJson<String>(folder),
      'zone': serializer.toJson<String>(zone),
    };
  }

  ZoneOverrideRow copyWith({String? sourceId, String? folder, String? zone}) =>
      ZoneOverrideRow(
        sourceId: sourceId ?? this.sourceId,
        folder: folder ?? this.folder,
        zone: zone ?? this.zone,
      );
  ZoneOverrideRow copyWithCompanion(ZoneOverridesCompanion data) {
    return ZoneOverrideRow(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      folder: data.folder.present ? data.folder.value : this.folder,
      zone: data.zone.present ? data.zone.value : this.zone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ZoneOverrideRow(')
          ..write('sourceId: $sourceId, ')
          ..write('folder: $folder, ')
          ..write('zone: $zone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, folder, zone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ZoneOverrideRow &&
          other.sourceId == this.sourceId &&
          other.folder == this.folder &&
          other.zone == this.zone);
}

class ZoneOverridesCompanion extends UpdateCompanion<ZoneOverrideRow> {
  final Value<String> sourceId;
  final Value<String> folder;
  final Value<String> zone;
  final Value<int> rowid;
  const ZoneOverridesCompanion({
    this.sourceId = const Value.absent(),
    this.folder = const Value.absent(),
    this.zone = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ZoneOverridesCompanion.insert({
    required String sourceId,
    required String folder,
    required String zone,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       folder = Value(folder),
       zone = Value(zone);
  static Insertable<ZoneOverrideRow> custom({
    Expression<String>? sourceId,
    Expression<String>? folder,
    Expression<String>? zone,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (folder != null) 'folder': folder,
      if (zone != null) 'zone': zone,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ZoneOverridesCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? folder,
    Value<String>? zone,
    Value<int>? rowid,
  }) {
    return ZoneOverridesCompanion(
      sourceId: sourceId ?? this.sourceId,
      folder: folder ?? this.folder,
      zone: zone ?? this.zone,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (zone.present) {
      map['zone'] = Variable<String>(zone.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ZoneOverridesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('folder: $folder, ')
          ..write('zone: $zone, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassificationRulesTable extends ClassificationRules
    with TableInfo<$ClassificationRulesTable, ClassificationRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassificationRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extensionsMeta = const VerificationMeta(
    'extensions',
  );
  @override
  late final GeneratedColumn<String> extensions = GeneratedColumn<String>(
    'extensions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameContainsMeta = const VerificationMeta(
    'nameContains',
  );
  @override
  late final GeneratedColumn<String> nameContains = GeneratedColumn<String>(
    'name_contains',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    priority,
    extensions,
    nameContains,
    folder,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classification_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassificationRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('extensions')) {
      context.handle(
        _extensionsMeta,
        extensions.isAcceptableOrUnknown(data['extensions']!, _extensionsMeta),
      );
    } else if (isInserting) {
      context.missing(_extensionsMeta);
    }
    if (data.containsKey('name_contains')) {
      context.handle(
        _nameContainsMeta,
        nameContains.isAcceptableOrUnknown(
          data['name_contains']!,
          _nameContainsMeta,
        ),
      );
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassificationRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassificationRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      extensions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extensions'],
      )!,
      nameContains: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_contains'],
      ),
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
    );
  }

  @override
  $ClassificationRulesTable createAlias(String alias) {
    return $ClassificationRulesTable(attachedDatabase, alias);
  }
}

class ClassificationRuleRow extends DataClass
    implements Insertable<ClassificationRuleRow> {
  final String id;
  final String category;
  final int priority;

  /// Extensions joined by `,` (they never contain one), sorted.
  final String extensions;
  final String? nameContains;
  final String? folder;
  final String? sourceId;
  const ClassificationRuleRow({
    required this.id,
    required this.category,
    required this.priority,
    required this.extensions,
    this.nameContains,
    this.folder,
    this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['priority'] = Variable<int>(priority);
    map['extensions'] = Variable<String>(extensions);
    if (!nullToAbsent || nameContains != null) {
      map['name_contains'] = Variable<String>(nameContains);
    }
    if (!nullToAbsent || folder != null) {
      map['folder'] = Variable<String>(folder);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    return map;
  }

  ClassificationRulesCompanion toCompanion(bool nullToAbsent) {
    return ClassificationRulesCompanion(
      id: Value(id),
      category: Value(category),
      priority: Value(priority),
      extensions: Value(extensions),
      nameContains: nameContains == null && nullToAbsent
          ? const Value.absent()
          : Value(nameContains),
      folder: folder == null && nullToAbsent
          ? const Value.absent()
          : Value(folder),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
    );
  }

  factory ClassificationRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassificationRuleRow(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      priority: serializer.fromJson<int>(json['priority']),
      extensions: serializer.fromJson<String>(json['extensions']),
      nameContains: serializer.fromJson<String?>(json['nameContains']),
      folder: serializer.fromJson<String?>(json['folder']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'priority': serializer.toJson<int>(priority),
      'extensions': serializer.toJson<String>(extensions),
      'nameContains': serializer.toJson<String?>(nameContains),
      'folder': serializer.toJson<String?>(folder),
      'sourceId': serializer.toJson<String?>(sourceId),
    };
  }

  ClassificationRuleRow copyWith({
    String? id,
    String? category,
    int? priority,
    String? extensions,
    Value<String?> nameContains = const Value.absent(),
    Value<String?> folder = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
  }) => ClassificationRuleRow(
    id: id ?? this.id,
    category: category ?? this.category,
    priority: priority ?? this.priority,
    extensions: extensions ?? this.extensions,
    nameContains: nameContains.present ? nameContains.value : this.nameContains,
    folder: folder.present ? folder.value : this.folder,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
  );
  ClassificationRuleRow copyWithCompanion(ClassificationRulesCompanion data) {
    return ClassificationRuleRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      priority: data.priority.present ? data.priority.value : this.priority,
      extensions: data.extensions.present
          ? data.extensions.value
          : this.extensions,
      nameContains: data.nameContains.present
          ? data.nameContains.value
          : this.nameContains,
      folder: data.folder.present ? data.folder.value : this.folder,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassificationRuleRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('extensions: $extensions, ')
          ..write('nameContains: $nameContains, ')
          ..write('folder: $folder, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    priority,
    extensions,
    nameContains,
    folder,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassificationRuleRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.priority == this.priority &&
          other.extensions == this.extensions &&
          other.nameContains == this.nameContains &&
          other.folder == this.folder &&
          other.sourceId == this.sourceId);
}

class ClassificationRulesCompanion
    extends UpdateCompanion<ClassificationRuleRow> {
  final Value<String> id;
  final Value<String> category;
  final Value<int> priority;
  final Value<String> extensions;
  final Value<String?> nameContains;
  final Value<String?> folder;
  final Value<String?> sourceId;
  final Value<int> rowid;
  const ClassificationRulesCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.extensions = const Value.absent(),
    this.nameContains = const Value.absent(),
    this.folder = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassificationRulesCompanion.insert({
    required String id,
    required String category,
    required int priority,
    required String extensions,
    this.nameContains = const Value.absent(),
    this.folder = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       priority = Value(priority),
       extensions = Value(extensions);
  static Insertable<ClassificationRuleRow> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<int>? priority,
    Expression<String>? extensions,
    Expression<String>? nameContains,
    Expression<String>? folder,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (extensions != null) 'extensions': extensions,
      if (nameContains != null) 'name_contains': nameContains,
      if (folder != null) 'folder': folder,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassificationRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<int>? priority,
    Value<String>? extensions,
    Value<String?>? nameContains,
    Value<String?>? folder,
    Value<String?>? sourceId,
    Value<int>? rowid,
  }) {
    return ClassificationRulesCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      extensions: extensions ?? this.extensions,
      nameContains: nameContains ?? this.nameContains,
      folder: folder ?? this.folder,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (extensions.present) {
      map['extensions'] = Variable<String>(extensions.value);
    }
    if (nameContains.present) {
      map['name_contains'] = Variable<String>(nameContains.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassificationRulesCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('extensions: $extensions, ')
          ..write('nameContains: $nameContains, ')
          ..write('folder: $folder, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
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
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsTableCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsTableCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $FileIndexTable fileIndex = $FileIndexTable(this);
  late final $ScanCheckpointsTable scanCheckpoints = $ScanCheckpointsTable(
    this,
  );
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $OperationsTable operations = $OperationsTable(this);
  late final $ZoneOverridesTable zoneOverrides = $ZoneOverridesTable(this);
  late final $ClassificationRulesTable classificationRules =
      $ClassificationRulesTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final Index fileIndexBySize = Index(
    'file_index_by_size',
    'CREATE INDEX file_index_by_size ON file_index (source_id, size)',
  );
  late final Index fileIndexByFullHash = Index(
    'file_index_by_full_hash',
    'CREATE INDEX file_index_by_full_hash ON file_index (source_id, full_hash)',
  );
  late final Index operationsByTypeStatus = Index(
    'operations_by_type_status',
    'CREATE INDEX operations_by_type_status ON operations (type, status, executed_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    fileIndex,
    scanCheckpoints,
    sessions,
    operations,
    zoneOverrides,
    classificationRules,
    settingsTable,
    fileIndexBySize,
    fileIndexByFullHash,
    operationsByTypeStatus,
  ];
}

typedef $$SourcesTableCreateCompanionBuilder = SourcesCompanion Function({
  required String id,
  required String kind,
  required String displayName,
  Value<String> location,
  required bool canMove,
  required bool canMkdir,
  required bool canQuarantine,
  required bool quarantineRestorable,
  required bool canAddToAlbum,
  required bool providesCapturedAt,
  required bool systemPurgesQuarantine,
  required bool enabled,
  Value<int> rowid,
});
typedef $$SourcesTableUpdateCompanionBuilder = SourcesCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String> displayName,
  Value<String> location,
  Value<bool> canMove,
  Value<bool> canMkdir,
  Value<bool> canQuarantine,
  Value<bool> quarantineRestorable,
  Value<bool> canAddToAlbum,
  Value<bool> providesCapturedAt,
  Value<bool> systemPurgesQuarantine,
  Value<bool> enabled,
  Value<int> rowid,
});

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canMove => $composableBuilder(
    column: $table.canMove,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canMkdir => $composableBuilder(
    column: $table.canMkdir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canQuarantine => $composableBuilder(
    column: $table.canQuarantine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quarantineRestorable => $composableBuilder(
    column: $table.quarantineRestorable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canAddToAlbum => $composableBuilder(
    column: $table.canAddToAlbum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get providesCapturedAt => $composableBuilder(
    column: $table.providesCapturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get systemPurgesQuarantine => $composableBuilder(
    column: $table.systemPurgesQuarantine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canMove => $composableBuilder(
    column: $table.canMove,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canMkdir => $composableBuilder(
    column: $table.canMkdir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canQuarantine => $composableBuilder(
    column: $table.canQuarantine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quarantineRestorable => $composableBuilder(
    column: $table.quarantineRestorable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canAddToAlbum => $composableBuilder(
    column: $table.canAddToAlbum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get providesCapturedAt => $composableBuilder(
    column: $table.providesCapturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get systemPurgesQuarantine => $composableBuilder(
    column: $table.systemPurgesQuarantine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<bool> get canMove =>
      $composableBuilder(column: $table.canMove, builder: (column) => column);

  GeneratedColumn<bool> get canMkdir =>
      $composableBuilder(column: $table.canMkdir, builder: (column) => column);

  GeneratedColumn<bool> get canQuarantine => $composableBuilder(
    column: $table.canQuarantine,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quarantineRestorable => $composableBuilder(
    column: $table.quarantineRestorable,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canAddToAlbum => $composableBuilder(
    column: $table.canAddToAlbum,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get providesCapturedAt => $composableBuilder(
    column: $table.providesCapturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get systemPurgesQuarantine => $composableBuilder(
    column: $table.systemPurgesQuarantine,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcesTable,
          SourceRow,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (SourceRow, BaseReferences<_$AppDatabase, $SourcesTable, SourceRow>),
          SourceRow,
          PrefetchHooks Function()
        > {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<bool> canMove = const Value.absent(),
                Value<bool> canMkdir = const Value.absent(),
                Value<bool> canQuarantine = const Value.absent(),
                Value<bool> quarantineRestorable = const Value.absent(),
                Value<bool> canAddToAlbum = const Value.absent(),
                Value<bool> providesCapturedAt = const Value.absent(),
                Value<bool> systemPurgesQuarantine = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                kind: kind,
                displayName: displayName,
                location: location,
                canMove: canMove,
                canMkdir: canMkdir,
                canQuarantine: canQuarantine,
                quarantineRestorable: quarantineRestorable,
                canAddToAlbum: canAddToAlbum,
                providesCapturedAt: providesCapturedAt,
                systemPurgesQuarantine: systemPurgesQuarantine,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String displayName,
                Value<String> location = const Value.absent(),
                required bool canMove,
                required bool canMkdir,
                required bool canQuarantine,
                required bool quarantineRestorable,
                required bool canAddToAlbum,
                required bool providesCapturedAt,
                required bool systemPurgesQuarantine,
                required bool enabled,
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                kind: kind,
                displayName: displayName,
                location: location,
                canMove: canMove,
                canMkdir: canMkdir,
                canQuarantine: canQuarantine,
                quarantineRestorable: quarantineRestorable,
                canAddToAlbum: canAddToAlbum,
                providesCapturedAt: providesCapturedAt,
                systemPurgesQuarantine: systemPurgesQuarantine,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourcesTable, SourceRow>(table),
                  BaseReferences<_$AppDatabase, $SourcesTable, SourceRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcesTable,
      SourceRow,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (SourceRow, BaseReferences<_$AppDatabase, $SourcesTable, SourceRow>),
      SourceRow,
      PrefetchHooks Function()
    >;
typedef $$FileIndexTableCreateCompanionBuilder = FileIndexCompanion Function({
  required String sourceId,
  required String path,
  required int size,
  required int modifiedAt,
  Value<int?> capturedAt,
  Value<String?> mimeType,
  Value<String?> partialHash,
  Value<String?> fullHash,
  Value<String?> lastSeenScanId,
  Value<int> rowid,
});
typedef $$FileIndexTableUpdateCompanionBuilder = FileIndexCompanion Function({
  Value<String> sourceId,
  Value<String> path,
  Value<int> size,
  Value<int> modifiedAt,
  Value<int?> capturedAt,
  Value<String?> mimeType,
  Value<String?> partialHash,
  Value<String?> fullHash,
  Value<String?> lastSeenScanId,
  Value<int> rowid,
});

class $$FileIndexTableFilterComposer
    extends Composer<_$AppDatabase, $FileIndexTable> {
  $$FileIndexTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partialHash => $composableBuilder(
    column: $table.partialHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullHash => $composableBuilder(
    column: $table.fullHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSeenScanId => $composableBuilder(
    column: $table.lastSeenScanId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FileIndexTableOrderingComposer
    extends Composer<_$AppDatabase, $FileIndexTable> {
  $$FileIndexTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partialHash => $composableBuilder(
    column: $table.partialHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullHash => $composableBuilder(
    column: $table.fullHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSeenScanId => $composableBuilder(
    column: $table.lastSeenScanId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FileIndexTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileIndexTable> {
  $$FileIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get partialHash => $composableBuilder(
    column: $table.partialHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fullHash =>
      $composableBuilder(column: $table.fullHash, builder: (column) => column);

  GeneratedColumn<String> get lastSeenScanId => $composableBuilder(
    column: $table.lastSeenScanId,
    builder: (column) => column,
  );
}

class $$FileIndexTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FileIndexTable,
          FileIndexRow,
          $$FileIndexTableFilterComposer,
          $$FileIndexTableOrderingComposer,
          $$FileIndexTableAnnotationComposer,
          $$FileIndexTableCreateCompanionBuilder,
          $$FileIndexTableUpdateCompanionBuilder,
          (
            FileIndexRow,
            BaseReferences<_$AppDatabase, $FileIndexTable, FileIndexRow>,
          ),
          FileIndexRow,
          PrefetchHooks Function()
        > {
  $$FileIndexTableTableManager(_$AppDatabase db, $FileIndexTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<int?> capturedAt = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<String?> partialHash = const Value.absent(),
                Value<String?> fullHash = const Value.absent(),
                Value<String?> lastSeenScanId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FileIndexCompanion(
                sourceId: sourceId,
                path: path,
                size: size,
                modifiedAt: modifiedAt,
                capturedAt: capturedAt,
                mimeType: mimeType,
                partialHash: partialHash,
                fullHash: fullHash,
                lastSeenScanId: lastSeenScanId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceId,
                required String path,
                required int size,
                required int modifiedAt,
                Value<int?> capturedAt = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<String?> partialHash = const Value.absent(),
                Value<String?> fullHash = const Value.absent(),
                Value<String?> lastSeenScanId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FileIndexCompanion.insert(
                sourceId: sourceId,
                path: path,
                size: size,
                modifiedAt: modifiedAt,
                capturedAt: capturedAt,
                mimeType: mimeType,
                partialHash: partialHash,
                fullHash: fullHash,
                lastSeenScanId: lastSeenScanId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FileIndexTable, FileIndexRow>(table),
                  BaseReferences<_$AppDatabase, $FileIndexTable, FileIndexRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FileIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FileIndexTable,
      FileIndexRow,
      $$FileIndexTableFilterComposer,
      $$FileIndexTableOrderingComposer,
      $$FileIndexTableAnnotationComposer,
      $$FileIndexTableCreateCompanionBuilder,
      $$FileIndexTableUpdateCompanionBuilder,
      (
        FileIndexRow,
        BaseReferences<_$AppDatabase, $FileIndexTable, FileIndexRow>,
      ),
      FileIndexRow,
      PrefetchHooks Function()
    >;
typedef $$ScanCheckpointsTableCreateCompanionBuilder =
    ScanCheckpointsCompanion Function({
      required String sourceId,
      required String scanId,
      required String stage,
      Value<String?> cursor,
      Value<int> rowid,
    });
typedef $$ScanCheckpointsTableUpdateCompanionBuilder =
    ScanCheckpointsCompanion Function({
      Value<String> sourceId,
      Value<String> scanId,
      Value<String> stage,
      Value<String?> cursor,
      Value<int> rowid,
    });

class $$ScanCheckpointsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanCheckpointsTable> {
  $$ScanCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scanId => $composableBuilder(
    column: $table.scanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScanCheckpointsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanCheckpointsTable> {
  $$ScanCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scanId => $composableBuilder(
    column: $table.scanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScanCheckpointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanCheckpointsTable> {
  $$ScanCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get scanId =>
      $composableBuilder(column: $table.scanId, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);
}

class $$ScanCheckpointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanCheckpointsTable,
          ScanCheckpointRow,
          $$ScanCheckpointsTableFilterComposer,
          $$ScanCheckpointsTableOrderingComposer,
          $$ScanCheckpointsTableAnnotationComposer,
          $$ScanCheckpointsTableCreateCompanionBuilder,
          $$ScanCheckpointsTableUpdateCompanionBuilder,
          (
            ScanCheckpointRow,
            BaseReferences<
              _$AppDatabase,
              $ScanCheckpointsTable,
              ScanCheckpointRow
            >,
          ),
          ScanCheckpointRow,
          PrefetchHooks Function()
        > {
  $$ScanCheckpointsTableTableManager(
    _$AppDatabase db,
    $ScanCheckpointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanCheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceId = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanCheckpointsCompanion(
                sourceId: sourceId,
                scanId: scanId,
                stage: stage,
                cursor: cursor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceId,
                required String scanId,
                required String stage,
                Value<String?> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanCheckpointsCompanion.insert(
                sourceId: sourceId,
                scanId: scanId,
                stage: stage,
                cursor: cursor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScanCheckpointsTable, ScanCheckpointRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ScanCheckpointsTable,
                    ScanCheckpointRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScanCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanCheckpointsTable,
      ScanCheckpointRow,
      $$ScanCheckpointsTableFilterComposer,
      $$ScanCheckpointsTableOrderingComposer,
      $$ScanCheckpointsTableAnnotationComposer,
      $$ScanCheckpointsTableCreateCompanionBuilder,
      $$ScanCheckpointsTableUpdateCompanionBuilder,
      (
        ScanCheckpointRow,
        BaseReferences<_$AppDatabase, $ScanCheckpointsTable, ScanCheckpointRow>,
      ),
      ScanCheckpointRow,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required int startedAt,
  Value<int?> finishedAt,
  required String status,
  required int statTotal,
  required int statDone,
  required int statFailed,
  required int statSkipped,
  required int statReverted,
  required int statRevertSkipped,
  required int statRemovedBytes,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<int> startedAt,
  Value<int?> finishedAt,
  Value<String> status,
  Value<int> statTotal,
  Value<int> statDone,
  Value<int> statFailed,
  Value<int> statSkipped,
  Value<int> statReverted,
  Value<int> statRevertSkipped,
  Value<int> statRemovedBytes,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statTotal => $composableBuilder(
    column: $table.statTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statDone => $composableBuilder(
    column: $table.statDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statFailed => $composableBuilder(
    column: $table.statFailed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statSkipped => $composableBuilder(
    column: $table.statSkipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statReverted => $composableBuilder(
    column: $table.statReverted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statRevertSkipped => $composableBuilder(
    column: $table.statRevertSkipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statRemovedBytes => $composableBuilder(
    column: $table.statRemovedBytes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statTotal => $composableBuilder(
    column: $table.statTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statDone => $composableBuilder(
    column: $table.statDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statFailed => $composableBuilder(
    column: $table.statFailed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statSkipped => $composableBuilder(
    column: $table.statSkipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statReverted => $composableBuilder(
    column: $table.statReverted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statRevertSkipped => $composableBuilder(
    column: $table.statRevertSkipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statRemovedBytes => $composableBuilder(
    column: $table.statRemovedBytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get statTotal =>
      $composableBuilder(column: $table.statTotal, builder: (column) => column);

  GeneratedColumn<int> get statDone =>
      $composableBuilder(column: $table.statDone, builder: (column) => column);

  GeneratedColumn<int> get statFailed => $composableBuilder(
    column: $table.statFailed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statSkipped => $composableBuilder(
    column: $table.statSkipped,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statReverted => $composableBuilder(
    column: $table.statReverted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statRevertSkipped => $composableBuilder(
    column: $table.statRevertSkipped,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statRemovedBytes => $composableBuilder(
    column: $table.statRemovedBytes,
    builder: (column) => column,
  );
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (
            SessionRow,
            BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>,
          ),
          SessionRow,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> statTotal = const Value.absent(),
                Value<int> statDone = const Value.absent(),
                Value<int> statFailed = const Value.absent(),
                Value<int> statSkipped = const Value.absent(),
                Value<int> statReverted = const Value.absent(),
                Value<int> statRevertSkipped = const Value.absent(),
                Value<int> statRemovedBytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                status: status,
                statTotal: statTotal,
                statDone: statDone,
                statFailed: statFailed,
                statSkipped: statSkipped,
                statReverted: statReverted,
                statRevertSkipped: statRevertSkipped,
                statRemovedBytes: statRemovedBytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int startedAt,
                Value<int?> finishedAt = const Value.absent(),
                required String status,
                required int statTotal,
                required int statDone,
                required int statFailed,
                required int statSkipped,
                required int statReverted,
                required int statRevertSkipped,
                required int statRemovedBytes,
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                status: status,
                statTotal: statTotal,
                statDone: statDone,
                statFailed: statFailed,
                statSkipped: statSkipped,
                statReverted: statReverted,
                statRevertSkipped: statRevertSkipped,
                statRemovedBytes: statRemovedBytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>),
      SessionRow,
      PrefetchHooks Function()
    >;
typedef $$OperationsTableCreateCompanionBuilder = OperationsCompanion Function({
  required String id,
  required String sessionId,
  required int seq,
  required String type,
  required String sourceId,
  Value<String?> fromPath,
  Value<String?> toPath,
  Value<int?> fingerprintSize,
  Value<int?> fingerprintModifiedAt,
  Value<String?> fingerprintFullHash,
  Value<String?> quarantineRef,
  required String reason,
  required String groupKey,
  required String status,
  Value<String?> error,
  Value<int?> executedAt,
  Value<int?> revertedAt,
  Value<int> rowid,
});
typedef $$OperationsTableUpdateCompanionBuilder = OperationsCompanion Function({
  Value<String> id,
  Value<String> sessionId,
  Value<int> seq,
  Value<String> type,
  Value<String> sourceId,
  Value<String?> fromPath,
  Value<String?> toPath,
  Value<int?> fingerprintSize,
  Value<int?> fingerprintModifiedAt,
  Value<String?> fingerprintFullHash,
  Value<String?> quarantineRef,
  Value<String> reason,
  Value<String> groupKey,
  Value<String> status,
  Value<String?> error,
  Value<int?> executedAt,
  Value<int?> revertedAt,
  Value<int> rowid,
});

class $$OperationsTableFilterComposer
    extends Composer<_$AppDatabase, $OperationsTable> {
  $$OperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromPath => $composableBuilder(
    column: $table.fromPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toPath => $composableBuilder(
    column: $table.toPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fingerprintSize => $composableBuilder(
    column: $table.fingerprintSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fingerprintModifiedAt => $composableBuilder(
    column: $table.fingerprintModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprintFullHash => $composableBuilder(
    column: $table.fingerprintFullHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quarantineRef => $composableBuilder(
    column: $table.quarantineRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get executedAt => $composableBuilder(
    column: $table.executedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revertedAt => $composableBuilder(
    column: $table.revertedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperationsTable> {
  $$OperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromPath => $composableBuilder(
    column: $table.fromPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toPath => $composableBuilder(
    column: $table.toPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fingerprintSize => $composableBuilder(
    column: $table.fingerprintSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fingerprintModifiedAt => $composableBuilder(
    column: $table.fingerprintModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprintFullHash => $composableBuilder(
    column: $table.fingerprintFullHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quarantineRef => $composableBuilder(
    column: $table.quarantineRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get executedAt => $composableBuilder(
    column: $table.executedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revertedAt => $composableBuilder(
    column: $table.revertedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperationsTable> {
  $$OperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get fromPath =>
      $composableBuilder(column: $table.fromPath, builder: (column) => column);

  GeneratedColumn<String> get toPath =>
      $composableBuilder(column: $table.toPath, builder: (column) => column);

  GeneratedColumn<int> get fingerprintSize => $composableBuilder(
    column: $table.fingerprintSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fingerprintModifiedAt => $composableBuilder(
    column: $table.fingerprintModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fingerprintFullHash => $composableBuilder(
    column: $table.fingerprintFullHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quarantineRef => $composableBuilder(
    column: $table.quarantineRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get executedAt => $composableBuilder(
    column: $table.executedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revertedAt => $composableBuilder(
    column: $table.revertedAt,
    builder: (column) => column,
  );
}

class $$OperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperationsTable,
          OperationRow,
          $$OperationsTableFilterComposer,
          $$OperationsTableOrderingComposer,
          $$OperationsTableAnnotationComposer,
          $$OperationsTableCreateCompanionBuilder,
          $$OperationsTableUpdateCompanionBuilder,
          (
            OperationRow,
            BaseReferences<_$AppDatabase, $OperationsTable, OperationRow>,
          ),
          OperationRow,
          PrefetchHooks Function()
        > {
  $$OperationsTableTableManager(_$AppDatabase db, $OperationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String?> fromPath = const Value.absent(),
                Value<String?> toPath = const Value.absent(),
                Value<int?> fingerprintSize = const Value.absent(),
                Value<int?> fingerprintModifiedAt = const Value.absent(),
                Value<String?> fingerprintFullHash = const Value.absent(),
                Value<String?> quarantineRef = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> groupKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int?> executedAt = const Value.absent(),
                Value<int?> revertedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperationsCompanion(
                id: id,
                sessionId: sessionId,
                seq: seq,
                type: type,
                sourceId: sourceId,
                fromPath: fromPath,
                toPath: toPath,
                fingerprintSize: fingerprintSize,
                fingerprintModifiedAt: fingerprintModifiedAt,
                fingerprintFullHash: fingerprintFullHash,
                quarantineRef: quarantineRef,
                reason: reason,
                groupKey: groupKey,
                status: status,
                error: error,
                executedAt: executedAt,
                revertedAt: revertedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int seq,
                required String type,
                required String sourceId,
                Value<String?> fromPath = const Value.absent(),
                Value<String?> toPath = const Value.absent(),
                Value<int?> fingerprintSize = const Value.absent(),
                Value<int?> fingerprintModifiedAt = const Value.absent(),
                Value<String?> fingerprintFullHash = const Value.absent(),
                Value<String?> quarantineRef = const Value.absent(),
                required String reason,
                required String groupKey,
                required String status,
                Value<String?> error = const Value.absent(),
                Value<int?> executedAt = const Value.absent(),
                Value<int?> revertedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperationsCompanion.insert(
                id: id,
                sessionId: sessionId,
                seq: seq,
                type: type,
                sourceId: sourceId,
                fromPath: fromPath,
                toPath: toPath,
                fingerprintSize: fingerprintSize,
                fingerprintModifiedAt: fingerprintModifiedAt,
                fingerprintFullHash: fingerprintFullHash,
                quarantineRef: quarantineRef,
                reason: reason,
                groupKey: groupKey,
                status: status,
                error: error,
                executedAt: executedAt,
                revertedAt: revertedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OperationsTable, OperationRow>(table),
                  BaseReferences<_$AppDatabase, $OperationsTable, OperationRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperationsTable,
      OperationRow,
      $$OperationsTableFilterComposer,
      $$OperationsTableOrderingComposer,
      $$OperationsTableAnnotationComposer,
      $$OperationsTableCreateCompanionBuilder,
      $$OperationsTableUpdateCompanionBuilder,
      (
        OperationRow,
        BaseReferences<_$AppDatabase, $OperationsTable, OperationRow>,
      ),
      OperationRow,
      PrefetchHooks Function()
    >;
typedef $$ZoneOverridesTableCreateCompanionBuilder =
    ZoneOverridesCompanion Function({
      required String sourceId,
      required String folder,
      required String zone,
      Value<int> rowid,
    });
typedef $$ZoneOverridesTableUpdateCompanionBuilder =
    ZoneOverridesCompanion Function({
      Value<String> sourceId,
      Value<String> folder,
      Value<String> zone,
      Value<int> rowid,
    });

class $$ZoneOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $ZoneOverridesTable> {
  $$ZoneOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ZoneOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $ZoneOverridesTable> {
  $$ZoneOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ZoneOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ZoneOverridesTable> {
  $$ZoneOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get zone =>
      $composableBuilder(column: $table.zone, builder: (column) => column);
}

class $$ZoneOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ZoneOverridesTable,
          ZoneOverrideRow,
          $$ZoneOverridesTableFilterComposer,
          $$ZoneOverridesTableOrderingComposer,
          $$ZoneOverridesTableAnnotationComposer,
          $$ZoneOverridesTableCreateCompanionBuilder,
          $$ZoneOverridesTableUpdateCompanionBuilder,
          (
            ZoneOverrideRow,
            BaseReferences<_$AppDatabase, $ZoneOverridesTable, ZoneOverrideRow>,
          ),
          ZoneOverrideRow,
          PrefetchHooks Function()
        > {
  $$ZoneOverridesTableTableManager(_$AppDatabase db, $ZoneOverridesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ZoneOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ZoneOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ZoneOverridesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceId = const Value.absent(),
                Value<String> folder = const Value.absent(),
                Value<String> zone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ZoneOverridesCompanion(
                sourceId: sourceId,
                folder: folder,
                zone: zone,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceId,
                required String folder,
                required String zone,
                Value<int> rowid = const Value.absent(),
              }) => ZoneOverridesCompanion.insert(
                sourceId: sourceId,
                folder: folder,
                zone: zone,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ZoneOverridesTable, ZoneOverrideRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ZoneOverridesTable,
                    ZoneOverrideRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ZoneOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ZoneOverridesTable,
      ZoneOverrideRow,
      $$ZoneOverridesTableFilterComposer,
      $$ZoneOverridesTableOrderingComposer,
      $$ZoneOverridesTableAnnotationComposer,
      $$ZoneOverridesTableCreateCompanionBuilder,
      $$ZoneOverridesTableUpdateCompanionBuilder,
      (
        ZoneOverrideRow,
        BaseReferences<_$AppDatabase, $ZoneOverridesTable, ZoneOverrideRow>,
      ),
      ZoneOverrideRow,
      PrefetchHooks Function()
    >;
typedef $$ClassificationRulesTableCreateCompanionBuilder =
    ClassificationRulesCompanion Function({
      required String id,
      required String category,
      required int priority,
      required String extensions,
      Value<String?> nameContains,
      Value<String?> folder,
      Value<String?> sourceId,
      Value<int> rowid,
    });
typedef $$ClassificationRulesTableUpdateCompanionBuilder =
    ClassificationRulesCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<int> priority,
      Value<String> extensions,
      Value<String?> nameContains,
      Value<String?> folder,
      Value<String?> sourceId,
      Value<int> rowid,
    });

class $$ClassificationRulesTableFilterComposer
    extends Composer<_$AppDatabase, $ClassificationRulesTable> {
  $$ClassificationRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extensions => $composableBuilder(
    column: $table.extensions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameContains => $composableBuilder(
    column: $table.nameContains,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClassificationRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassificationRulesTable> {
  $$ClassificationRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extensions => $composableBuilder(
    column: $table.extensions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameContains => $composableBuilder(
    column: $table.nameContains,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClassificationRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassificationRulesTable> {
  $$ClassificationRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get extensions => $composableBuilder(
    column: $table.extensions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameContains => $composableBuilder(
    column: $table.nameContains,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);
}

class $$ClassificationRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassificationRulesTable,
          ClassificationRuleRow,
          $$ClassificationRulesTableFilterComposer,
          $$ClassificationRulesTableOrderingComposer,
          $$ClassificationRulesTableAnnotationComposer,
          $$ClassificationRulesTableCreateCompanionBuilder,
          $$ClassificationRulesTableUpdateCompanionBuilder,
          (
            ClassificationRuleRow,
            BaseReferences<
              _$AppDatabase,
              $ClassificationRulesTable,
              ClassificationRuleRow
            >,
          ),
          ClassificationRuleRow,
          PrefetchHooks Function()
        > {
  $$ClassificationRulesTableTableManager(
    _$AppDatabase db,
    $ClassificationRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassificationRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassificationRulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClassificationRulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> extensions = const Value.absent(),
                Value<String?> nameContains = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassificationRulesCompanion(
                id: id,
                category: category,
                priority: priority,
                extensions: extensions,
                nameContains: nameContains,
                folder: folder,
                sourceId: sourceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required int priority,
                required String extensions,
                Value<String?> nameContains = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassificationRulesCompanion.insert(
                id: id,
                category: category,
                priority: priority,
                extensions: extensions,
                nameContains: nameContains,
                folder: folder,
                sourceId: sourceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClassificationRulesTable, ClassificationRuleRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ClassificationRulesTable,
                    ClassificationRuleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClassificationRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassificationRulesTable,
      ClassificationRuleRow,
      $$ClassificationRulesTableFilterComposer,
      $$ClassificationRulesTableOrderingComposer,
      $$ClassificationRulesTableAnnotationComposer,
      $$ClassificationRulesTableCreateCompanionBuilder,
      $$ClassificationRulesTableUpdateCompanionBuilder,
      (
        ClassificationRuleRow,
        BaseReferences<
          _$AppDatabase,
          $ClassificationRulesTable,
          ClassificationRuleRow
        >,
      ),
      ClassificationRuleRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingRow,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTableTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTableTable, SettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingsTableTable,
                    SettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingRow,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$FileIndexTableTableManager get fileIndex =>
      $$FileIndexTableTableManager(_db, _db.fileIndex);
  $$ScanCheckpointsTableTableManager get scanCheckpoints =>
      $$ScanCheckpointsTableTableManager(_db, _db.scanCheckpoints);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$OperationsTableTableManager get operations =>
      $$OperationsTableTableManager(_db, _db.operations);
  $$ZoneOverridesTableTableManager get zoneOverrides =>
      $$ZoneOverridesTableTableManager(_db, _db.zoneOverrides);
  $$ClassificationRulesTableTableManager get classificationRules =>
      $$ClassificationRulesTableTableManager(_db, _db.classificationRules);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
