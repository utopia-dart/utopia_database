import 'package:utopia_database/utopia_database.dart';
import 'package:test/test.dart';

void main() {
  group('test Database', () {
    final mariadb = MariaDB();
    final database = Database(mariadb);
    database.setNamespace('utopia_dart');
    database.setDefaultDatabase('mypersonaldatabase');

    setUp(() async {
      await mariadb.init(
          host: 'mariadb', port: 3306, user: 'root', password: 'root');
      // Additional setup goes here.
    });

    test('test create', () async {
      final created = await database.create();
      expect(created, true);
    });

    test('test exists', () async {
      final exists = await database.exists(database.getDefaultDatabase());
      expect(exists, true);
    });

    test('test create collection', () async {
      final collection = await database.createCollection('users', [
        Attribute(
            id: 'username',
            type: Database.varString,
            size: 255,
            required: true),
      ], []);
      expect(collection!.id, 'users');
    });

    test('test create document', () async {
      final document = await database.createDocument(
          'users',
          Document(
              {"\$id": 'myspecialdocument', 'username': 'myspecialusername'}));
      expect(document.id, 'myspecialdocument');
    });

    test('delete document', () async {
      final deleted =
          await database.deleteDocument('users', 'myspecialdocument');
      expect(deleted, true);
    });

    test('test Delete Collection', () async {
      final deleted = await database.deleteCollection('users');
      expect(deleted, true);
    });
    test('test Delete', () async {
      final deleted = await database.delete(database.getDefaultDatabase());
      expect(deleted, true);
    });
  });
}
