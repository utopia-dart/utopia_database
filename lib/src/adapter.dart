abstract class Adapter {
  String namespace = '';
  String defaultDatabase = '';
  Map<String, dynamic> debug = {};

  Adapter setDebug(String key, dynamic value) {
    debug[key] = value;
    return this;
  }

  Map<String, dynamic> getDebug() {
    return debug;
  }

  Adapter resetDebug() {
    debug = {};
    return this;
  }

  bool setNamespace(String namespace) {
    if (namespace.isEmpty) {
      throw Exception('Missing namespace');
    }
    this.namespace = filter(namespace);
    return true;
  }

  String getNamespace() {
    if (namespace.isEmpty) {
      throw Exception('Missing namespace');
    }
    return namespace;
  }

  bool setDefaultDatabase(String name, {bool reset = false}) {
    if (name.isEmpty && !reset) {
      throw Exception('Missing database');
    }
    defaultDatabase = reset ? '' : filter(name);
    return true;
  }

  String getDefaultDatabase() {
    if (defaultDatabase.isEmpty) {
      throw Exception('Missing default database');
    }
    return defaultDatabase;
  }

  String filter(String value) {
    value = value.replaceAll(RegExp(r'[^A-Za-z0-9\_\-]'), '');
    if (value.isEmpty) {
      throw Exception('Failed to filter key');
    }
    return value;
  }

  bool ping();
  Future<bool> create(String name);
  Future<bool> exists(String database, {String? collection});
  Future<List> list();
  Future<bool> delete(String name);

  Future<bool> createCollection(String name, List attributes, List indexes);
  Future<bool> deleteCollection(String name);
}

/*

    abstract public function createAttribute(string $collection, string $id, string $type, int $size, bool $signed = true, bool $array = false): bool;

    abstract public function updateAttribute(string $collection, string $id, string $type, int $size, bool $signed = true, bool $array = false): bool;

    abstract public function deleteAttribute(string $collection, string $id): bool;

    abstract public function renameAttribute(string $collection, string $old, string $new): bool;

    abstract public function createRelationship(string $collection, string $relatedCollection, string $type, bool $twoWay = false, string $id = '', string $twoWayKey = ''): bool;

    abstract public function updateRelationship(string $collection, string $relatedCollection, string $type, bool $twoWay, string $key, string $twoWayKey, ?string $newKey = null, ?string $newTwoWayKey = null): bool;

    abstract public function deleteRelationship(string $collection, string $relatedCollection, string $type, bool $twoWay, string $key, string $twoWayKey, string $side): bool;

    abstract public function renameIndex(string $collection, string $old, string $new): bool;

    abstract public function createIndex(string $collection, string $id, string $type, array $attributes, array $lengths, array $orders): bool;

    abstract public function deleteIndex(string $collection, string $id): bool;

    abstract public function getDocument(string $collection, string $id, array $queries = []): Document;

    abstract public function createDocument(string $collection, Document $document): Document;

    abstract public function updateDocument(string $collection, Document $document): Document;

    abstract public function deleteDocument(string $collection, string $id): bool;

    abstract public function find(string $collection, array $queries = [], ?int $limit = 25, ?int $offset = null, array $orderAttributes = [], array $orderTypes = [], array $cursor = [], string $cursorDirection = Database::CURSOR_AFTER, ?int $timeout = null): array;

    abstract public function sum(string $collection, string $attribute, array $queries = [], ?int $max = null): float|int;

    abstract public function count(string $collection, array $queries = [], ?int $max = null): int;

    abstract public function getLimitForString(): int;

    abstract public function getLimitForInt(): int;

    abstract public function getLimitForAttributes(): int;
    abstract public function getLimitForIndexes(): int;
    abstract public function getSupportForSchemas(): bool;
    abstract public function getSupportForIndex(): bool;
    abstract public function getSupportForUniqueIndex(): bool;
    abstract public function getSupportForFulltextIndex(): bool;
    abstract public function getSupportForFulltextWildcardIndex(): bool;
    abstract public function getSupportForCasting(): bool;
    abstract public function getSupportForQueryContains(): bool;
    abstract public function getSupportForTimeouts(): bool;
    abstract public function getSupportForRelationships(): bool;
    abstract public function getCountOfAttributes(Document $collection): int;
    abstract public function getCountOfIndexes(Document $collection): int;
    abstract public static function getCountOfDefaultAttributes(): int;
    abstract public static function getCountOfDefaultIndexes(): int;
    abstract public static function getDocumentSizeLimit(): int;
    abstract public function getAttributeWidth(Document $collection): int;
    abstract public function getKeywords(): array;
    abstract protected function getAttributeProjection(array $selections, string $prefix = ''): mixed;

    protected function getAttributeSelections(array $queries): array
    {
        $selections = [];

        foreach ($queries as $query) {
            switch ($query->getMethod()) {
                case Query::TYPE_SELECT:
                    foreach ($query->getValues() as $value) {
                        $selections[] = $value;
                    }
                    break;
            }
        }

        return $selections;
    }

    public function escapeWildcards(string $value): string
    {
        $wildcards = [
            '%',
            '_',
            '[',
            ']',
            '^',
            '-',
            '.',
            '*',
            '+',
            '?',
            '(',
            ')',
            '{',
            '}',
            '|'
        ];

        foreach ($wildcards as $wildcard) {
            $value = \str_replace($wildcard, "\\$wildcard", $value);
        }

        return $value;
    }
    abstract public function increaseDocumentAttribute(string $collection, string $id, string $attribute, int|float $value, int|float|null $min = null, int|float|null $max = null): bool;
}
*/

