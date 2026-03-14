import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iqamty/src/models/types.dart';

void main() {
  test('Meal.fromJson should correctly parse Firestore data', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);
    final json = {
      'id': 'test_id',
      'menu': 'Eggs, bread, milk',
      'type': 'Breakfast',
      'date': timestamp,
    };

    final meal = Meal.fromJson(json);

    expect(meal.id, 'test_id');
    expect(meal.menu, 'Eggs, bread, milk');
    expect(meal.type, 'Breakfast');
    expect(meal.date.year, now.year);
    expect(meal.date.month, now.month);
    expect(meal.date.day, now.day);
  });

  test('Meal.toJson should correctly format data for Firestore', () {
    final now = DateTime.now();
    final meal = Meal(
      id: 'test_id',
      menu: 'Couscous',
      type: 'Lunch',
      date: now,
    );

    final json = meal.toJson();

    expect(json['menu'], 'Couscous');
    expect(json['type'], 'Lunch');
    expect(json['date'], isA<Timestamp>());
    expect((json['date'] as Timestamp).toDate().day, now.day);
  });
}
