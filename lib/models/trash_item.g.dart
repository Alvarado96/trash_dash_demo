// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrashItemAdapter extends TypeAdapter<TrashItem> {
  @override
  final int typeId = 3;

  @override
  TrashItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrashItem._(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as ItemCategory,
      description: fields[3] as String?,
      imageUrl: fields[4] as String,
      latitude: fields[5] as double,
      longitude: fields[6] as double,
      postedBy: fields[7] as String,
      postedAt: fields[8] as DateTime,
      status: fields[9] as ItemStatus,
      claimedBy: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrashItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude)
      ..writeByte(7)
      ..write(obj.postedBy)
      ..writeByte(8)
      ..write(obj.postedAt)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.claimedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrashItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemStatusAdapter extends TypeAdapter<ItemStatus> {
  @override
  final int typeId = 1;

  @override
  ItemStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemStatus.available;
      case 1:
        return ItemStatus.claimed;
      case 2:
        return ItemStatus.pickedUp;
      default:
        return ItemStatus.available;
    }
  }

  @override
  void write(BinaryWriter writer, ItemStatus obj) {
    switch (obj) {
      case ItemStatus.available:
        writer.writeByte(0);
        break;
      case ItemStatus.claimed:
        writer.writeByte(1);
        break;
      case ItemStatus.pickedUp:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemCategoryAdapter extends TypeAdapter<ItemCategory> {
  @override
  final int typeId = 2;

  @override
  ItemCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemCategory.furniture;
      case 1:
        return ItemCategory.electronics;
      case 2:
        return ItemCategory.clothing;
      case 3:
        return ItemCategory.books;
      case 4:
        return ItemCategory.toys;
      case 5:
        return ItemCategory.appliances;
      case 6:
        return ItemCategory.decorations;
      case 7:
        return ItemCategory.other;
      case 8:
        return ItemCategory.tools;
      case 9:
        return ItemCategory.bookshelf;
      case 10:
        return ItemCategory.table;
      case 11:
        return ItemCategory.chair;
      case 12:
        return ItemCategory.generalTrash;
      default:
        return ItemCategory.furniture;
    }
  }

  @override
  void write(BinaryWriter writer, ItemCategory obj) {
    switch (obj) {
      case ItemCategory.furniture:
        writer.writeByte(0);
        break;
      case ItemCategory.electronics:
        writer.writeByte(1);
        break;
      case ItemCategory.clothing:
        writer.writeByte(2);
        break;
      case ItemCategory.books:
        writer.writeByte(3);
        break;
      case ItemCategory.toys:
        writer.writeByte(4);
        break;
      case ItemCategory.appliances:
        writer.writeByte(5);
        break;
      case ItemCategory.decorations:
        writer.writeByte(6);
        break;
      case ItemCategory.other:
        writer.writeByte(7);
        break;
      case ItemCategory.tools:
        writer.writeByte(8);
        break;
      case ItemCategory.bookshelf:
        writer.writeByte(9);
        break;
      case ItemCategory.table:
        writer.writeByte(10);
        break;
      case ItemCategory.chair:
        writer.writeByte(11);
        break;
      case ItemCategory.generalTrash:
        writer.writeByte(12);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
