import 'package:utopia_database/utopia_database.dart';
import 'package:test/test.dart';

void main() {
  group('test Database', () async {
    final mariadb = MariaDB();
    await mariadb.init(
        host: 'mariadb', port: '3306', user: 'user', password: 'password');
    final database = Database(mariadb);
    database.setNamespace('utopia_dart');
    database.setDefaultDatabase('applications');

    setUp(() {
      // Additional setup goes here.
    });

    test('test create', () async {
      final created = await database.create();
      expect(created, true);
      final exists = await database.exists(database.getNamespace());
      expect(exists = true);
    });
  });
}
