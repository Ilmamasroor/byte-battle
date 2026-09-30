-- Seed the Java curriculum used by the AI personalization service.

INSERT INTO curriculum_domains
    (id, name, description, slug, display_order, active)
VALUES
    (
        '00000000-0000-0000-0000-000000000001',
        'Java Programming',
        'Java programming fundamentals, object-oriented programming, data structures, algorithms, and concurrency.',
        'java-programming',
        1,
        true
    );

INSERT INTO topics
    (id, domain_id, name, description, slug, display_order, active)
VALUES
    (
        '00000000-0000-0000-0000-000000000101',
        '00000000-0000-0000-0000-000000000001',
        'Core Java',
        'Java language fundamentals and core programming concepts.',
        'core_java',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000000102',
        '00000000-0000-0000-0000-000000000001',
        'Object-Oriented Programming',
        'Classes, objects, inheritance, encapsulation, polymorphism, and abstraction.',
        'oop',
        2,
        true
    ),
    (
        '00000000-0000-0000-0000-000000000103',
        '00000000-0000-0000-0000-000000000001',
        'Multithreading & Concurrency',
        'Threads, shared resources, synchronization, race conditions, and deadlocks.',
        'multithreading',
        3,
        true
    ),
    (
        '00000000-0000-0000-0000-000000000104',
        '00000000-0000-0000-0000-000000000001',
        'Collections',
        'Java collections, iterators, generics, and safe collection usage.',
        'collections',
        4,
        true
    ),
    (
        '00000000-0000-0000-0000-000000000105',
        '00000000-0000-0000-0000-000000000001',
        'Exception Handling',
        'Checked and unchecked exceptions, resource handling, and custom exceptions.',
        'exception_handling',
        5,
        true
    ),
    (
        '00000000-0000-0000-0000-000000000106',
        '00000000-0000-0000-0000-000000000001',
        'Arrays',
        'Array traversal, indexing, bounds, and multidimensional arrays.',
        'arrays',
        6,
        true
    ),
    (
        '00000000-0000-0000-0000-000000000107',
        '00000000-0000-0000-0000-000000000001',
        'Linked Lists',
        'Linked-list traversal, insertion, deletion, references, and cycle detection.',
        'linked_lists',
        7,
        true
    ),
    (
        '00000000-0000-0000-0000-000000000108',
        '00000000-0000-0000-0000-000000000001',
        'Searching',
        'Linear search, binary search, search conditions, and complexity.',
        'searching',
        8,
        true
    ),
    (
        '00000000-0000-0000-0000-000000000109',
        '00000000-0000-0000-0000-000000000001',
        'Sorting',
        'Sorting algorithms, comparators, stability, complexity, and edge cases.',
        'sorting',
        9,
        true
    ),
    (
        '00000000-0000-0000-0000-000000000110',
        '00000000-0000-0000-0000-000000000001',
        'Trees',
        'Tree traversal, recursion, balance, depth, height, and node references.',
        'trees',
        10,
        true
    );

INSERT INTO concepts
    (id, topic_id, name, description, slug, difficulty, display_order, active)
VALUES
    (
        '00000000-0000-0000-0000-000000001001',
        '00000000-0000-0000-0000-000000000101',
        'Java Fundamentals',
        'Variables, data types, control flow, methods, and arrays.',
        'java-fundamentals',
        'EASY',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000001002',
        '00000000-0000-0000-0000-000000000102',
        'Polymorphism',
        'Understanding method overriding, dynamic dispatch, and polymorphic behavior.',
        'polymorphism',
        'MEDIUM',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000001003',
        '00000000-0000-0000-0000-000000000103',
        'Race Conditions',
        'Understanding shared resources, data races, synchronization, and execution order.',
        'race-conditions',
        'HARD',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000001004',
        '00000000-0000-0000-0000-000000000104',
        'Java Collections',
        'Choosing and using collections, iterators, and generics safely.',
        'java-collections',
        'MEDIUM',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000001005',
        '00000000-0000-0000-0000-000000000105',
        'Exception Handling',
        'Exception catching, resource management, and checked versus unchecked exceptions.',
        'exception-handling',
        'MEDIUM',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000001006',
        '00000000-0000-0000-0000-000000000106',
        'Array Traversal',
        'Array indexing, traversal logic, bounds, and off-by-one errors.',
        'array-traversal',
        'EASY',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000001007',
        '00000000-0000-0000-0000-000000000107',
        'Linked List Operations',
        'Node references, traversal, insertion, deletion, and head/tail tracking.',
        'linked-list-operations',
        'MEDIUM',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000001008',
        '00000000-0000-0000-0000-000000000108',
        'Binary Search',
        'Search boundaries, conditions, sorted data assumptions, and complexity.',
        'binary-search',
        'MEDIUM',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000001009',
        '00000000-0000-0000-0000-000000000109',
        'Sorting Algorithms',
        'Comparator logic, stability, algorithm selection, and sorting edge cases.',
        'sorting-algorithms',
        'MEDIUM',
        1,
        true
    ),
    (
        '00000000-0000-0000-0000-000000001010',
        '00000000-0000-0000-0000-000000000110',
        'Tree Traversal',
        'Tree traversal order, recursion, node references, depth, and height.',
        'tree-traversal',
        'MEDIUM',
        1,
        true
    );
