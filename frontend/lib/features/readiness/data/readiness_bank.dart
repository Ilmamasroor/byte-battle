import 'package:flutter/material.dart';

/// One building block a concept leans on, with a quick proof question and a short refresher.
class Prereq {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String question;
  final List<String> options;
  final int answer;
  final String why;
  final String primer;
  final String example;

  const Prereq({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.question,
    required this.options,
    required this.answer,
    required this.why,
    required this.primer,
    required this.example,
  });
}

/// The prerequisites for a concept, chosen by what the concept is about. Content is static and curated: these are
/// the basics a learner must have for the concept's lessons, battles and coding tasks to make sense.
class ReadinessBank {
  ReadinessBank._();

  static const _variables = Prereq(
    id: 'variables',
    title: 'Variables & data types',
    subtitle: 'int, double, boolean, String',
    icon: Icons.data_object_rounded,
    question: 'Which line correctly declares a whole-number variable in Java?',
    options: ['int count = 5;', 'string count = 5;', 'number count = 5;', 'count := 5;'],
    answer: 0,
    why: 'Java is typed: `int` holds whole numbers. `String` is capitalised and text only, and `number` / `:=` are not Java.',
    primer: 'A variable is a named box that holds one value. Its type decides what fits: int for whole numbers, double for decimals, boolean for true/false, String for text.',
    example: 'int count = 5;\nString name = "Ilma";\nboolean done = false;',
  );

  static const _control = Prereq(
    id: 'control',
    title: 'Conditions & loops',
    subtitle: 'if / else, for, while',
    icon: Icons.loop_rounded,
    question: 'How many times does the body of  for (int i = 0; i < 3; i++)  run?',
    options: ['2 times', '3 times', '4 times', 'Forever'],
    answer: 1,
    why: 'i takes the values 0, 1 and 2. When i reaches 3 the condition i < 3 is false, so the loop stops: 3 runs.',
    primer: 'if/else picks a path. Loops repeat code: for when you know how many times, while when you repeat until something changes.',
    example: 'for (int i = 0; i < 3; i++) {\n  System.out.println(i);\n}   // prints 0 1 2',
  );

  static const _methods = Prereq(
    id: 'methods',
    title: 'Methods',
    subtitle: 'parameters and return values',
    icon: Icons.functions_rounded,
    question: 'What does a method declared with return type  void  do?',
    options: ['Does its work and returns nothing', 'Returns the number 0', 'Cannot take any parameters', 'Returns null'],
    answer: 0,
    why: '`void` means "no return value". The method can still take parameters and have side effects, such as printing or changing a field.',
    primer: 'A method is a named, reusable block of code. It can take inputs (parameters) and hand back one result (return value), or return nothing (void).',
    example: 'static int add(int a, int b) {\n  return a + b;\n}\nint total = add(2, 3); // 5',
  );

  static const _classes = Prereq(
    id: 'classes',
    title: 'Classes & objects',
    subtitle: 'fields, constructors, new',
    icon: Icons.category_rounded,
    question: 'What does  new Counter()  do?',
    options: ['Creates a new object (instance) of the class Counter', 'Declares the class Counter', 'Deletes a Counter', 'Calls a static method named Counter'],
    answer: 0,
    why: 'A class is the blueprint; `new` builds a real object from it, with its own copy of the fields.',
    primer: 'A class is a blueprint (fields = data, methods = behaviour). `new` makes an object from it. Each object has its own copy of the fields unless they are static.',
    example: 'class Counter {\n  int value = 0;\n  void inc() { value++; }\n}\nCounter c = new Counter();',
  );

  static const _thread = Prereq(
    id: 'thread',
    title: 'What a thread is',
    subtitle: 'doing several things at once',
    icon: Icons.account_tree_rounded,
    question: 'Which call actually starts running code on a new thread?',
    options: ['t.run()', 't.start()', 't.begin()', 'new Thread(task)'],
    answer: 1,
    why: '`start()` creates the new thread and then runs the task on it. `run()` just calls the method on your current thread, like any normal method call.',
    primer: 'A thread is an independent path of execution inside your program. Several threads can run at the same time, each following its own instructions.',
    example: 'Thread t = new Thread(() -> System.out.println("hi"));\nt.start();   // runs on a NEW thread',
  );

  static const _shared = Prereq(
    id: 'shared',
    title: 'Shared state',
    subtitle: 'data more than one part can touch',
    icon: Icons.share_rounded,
    question: 'A  static int total;  field is visible to which parts of the program?',
    options: ['Only the method that created it', 'Every object and every thread in the program', 'Only one thread at a time, automatically', 'Nothing, it is private to Java'],
    answer: 1,
    why: 'A static field lives once for the whole class, so every thread can read and write the same variable. Nothing protects it by default, which is exactly why shared state needs care.',
    primer: 'Shared state is data that more than one part of the program can read or change, such as a static field or an object passed to several threads. Local variables are private to one call; shared state is not.',
    example: 'static int total = 0;   // one copy, everyone sees it\nint local = 0;          // private to this method call',
  );

  static const _inherit = Prereq(
    id: 'inherit',
    title: 'Inheritance',
    subtitle: 'extends and super',
    icon: Icons.family_restroom_rounded,
    question: 'Which keyword makes one class inherit from another?',
    options: ['implements', 'extends', 'inherits', 'super'],
    answer: 1,
    why: '`extends` creates a subclass that inherits the parent\'s fields and methods. `implements` is for interfaces.',
    primer: 'Inheritance lets a class (child) reuse and specialise another class (parent). The child gets the parent\'s non-private members and can add or replace behaviour.',
    example: 'class Animal { void speak() {} }\nclass Dog extends Animal {\n  void speak() { System.out.println("Woof"); }\n}',
  );

  static const _override = Prereq(
    id: 'override',
    title: 'Overriding & interfaces',
    subtitle: 'same method, different behaviour',
    icon: Icons.swap_horiz_rounded,
    question: 'What does it mean to override a method?',
    options: ['A subclass provides its own version of a parent method', 'Two methods share a name but take different parameters', 'You make the method private', 'You delete the parent method'],
    answer: 0,
    why: 'Overriding = same signature, new behaviour in the subclass. (Same name with different parameters is overloading.)',
    primer: 'Overriding replaces a parent method\'s behaviour in a subclass. Interfaces list methods a class promises to provide; different classes can answer the same call differently. That is polymorphism.',
    example: 'interface Shape { double area(); }\nclass Circle implements Shape {\n  public double area() { return 3.14 * r * r; }\n}',
  );

  // ── DSA / interview ───────────────────────────────────────────────
  static const _arrays = Prereq(
    id: 'arrays',
    title: 'Arrays & indexing',
    subtitle: 'zero-based positions',
    icon: Icons.view_array_rounded,
    question: 'In Java, what is the index of the LAST element of an array that holds 5 elements?',
    options: ['4', '5', '0', '6'],
    answer: 0,
    why: 'Arrays are zero-based: the indexes are 0, 1, 2, 3, 4. Index 5 would be out of bounds.',
    primer: 'An array is a fixed-size row of values of one type, numbered from 0. a[0] is the first, a[a.length - 1] is the last.',
    example: 'int[] a = {10, 20, 30};\nint first = a[0];          // 10\nint last  = a[a.length-1]; // 30',
  );

  static const _bigO = Prereq(
    id: 'bigo',
    title: 'Big-O basics',
    subtitle: 'how work grows with input',
    icon: Icons.show_chart_rounded,
    question: 'A single loop that visits each of n items once has which time complexity?',
    options: ['O(1)', 'O(n)', 'O(n^2)', 'O(log n)'],
    answer: 1,
    why: 'Work grows in direct proportion to n: double the items, double the steps. That is O(n).',
    primer: 'Big-O describes how the number of steps grows as the input grows, ignoring constants. O(1) constant, O(log n) halving, O(n) one pass, O(n^2) nested loops.',
    example: 'for (int x : items) { ... }        // O(n)\nfor (i..n) for (j..n) { ... }     // O(n^2)',
  );

  static const _recursion = Prereq(
    id: 'recursion',
    title: 'Recursion',
    subtitle: 'a method calling itself',
    icon: Icons.all_inclusive_rounded,
    question: 'What does every recursive method need so that it eventually stops?',
    options: ['A base case that returns without calling itself', 'A loop inside it', 'A static variable', 'A try/catch block'],
    answer: 0,
    why: 'Without a base case the calls never end and you get a StackOverflowError. Each call must also move closer to the base case.',
    primer: 'Recursion solves a problem by solving a smaller copy of it. A base case ends the chain; the recursive case shrinks the problem.',
    example: 'int fact(int n) {\n  if (n <= 1) return 1;     // base case\n  return n * fact(n - 1);   // smaller problem\n}',
  );

  // ── SQL ───────────────────────────────────────────────────────────
  static const _tables = Prereq(
    id: 'tables',
    title: 'Tables, rows & columns',
    subtitle: 'how relational data is laid out',
    icon: Icons.table_chart_rounded,
    question: 'In a relational table, what does ONE row represent?',
    options: ['One record, such as a single user or order', 'One kind of data, such as "name"', 'The whole database', 'One query'],
    answer: 0,
    why: 'Columns describe the kinds of data (name, age); each row is one record holding a value for every column.',
    primer: 'A table is a grid. Columns are the attributes, rows are the records. A database holds many tables that can be linked together.',
    example: 'users\nid | name | age\n1  | Ann  | 17\n2  | Ben  | 25',
  );

  static const _selectBasics = Prereq(
    id: 'select',
    title: 'SELECT, FROM, WHERE',
    subtitle: 'asking a table a question',
    icon: Icons.manage_search_rounded,
    question: 'Which query returns the names of users older than 18?',
    options: ['SELECT name FROM users WHERE age > 18;', 'GET name FROM users IF age > 18;', 'SELECT users WHERE name > 18;', 'FROM users SELECT name WHEN age > 18;'],
    answer: 0,
    why: 'SQL order is SELECT (what) FROM (where) WHERE (which rows). The other forms are not valid SQL.',
    primer: 'SELECT picks columns, FROM names the table, WHERE keeps only rows that satisfy a condition.',
    example: 'SELECT name\nFROM users\nWHERE age > 18;',
  );

  static const _keys = Prereq(
    id: 'keys',
    title: 'Primary keys',
    subtitle: 'telling rows apart',
    icon: Icons.vpn_key_rounded,
    question: 'What does a primary key guarantee?',
    options: ['Every row can be identified uniquely', 'The column is sorted', 'The column can hold any text', 'The table is encrypted'],
    answer: 0,
    why: 'A primary key is unique and never NULL, so one value always points at exactly one row.',
    primer: 'A primary key (often id) uniquely identifies each row. Other tables refer to it with a foreign key to link records.',
    example: 'CREATE TABLE users (\n  id INT PRIMARY KEY,\n  name TEXT\n);',
  );

  // ── OS / networks / system design ────────────────────────────────
  static const _process = Prereq(
    id: 'process',
    title: 'Programs vs processes',
    subtitle: 'a file vs a running thing',
    icon: Icons.settings_applications_rounded,
    question: 'What is a process?',
    options: ['A running instance of a program', 'A file stored on disk', 'A CPU core', 'A kind of memory'],
    answer: 0,
    why: 'A program is code sitting on disk. When the OS runs it, that live instance with its own memory is a process.',
    primer: 'A program is a passive file. Run it and the operating system creates a process: the program plus its memory and state. You can run the same program twice and get two processes.',
    example: 'chrome.exe  (a file on disk)  ->  2 windows = 2 processes',
  );

  static const _memory = Prereq(
    id: 'memory',
    title: 'RAM vs disk',
    subtitle: 'fast and temporary vs slow and permanent',
    icon: Icons.sd_card_rounded,
    question: 'Which storage is fast but loses its contents when the power goes off?',
    options: ['Hard disk', 'SSD', 'RAM', 'USB stick'],
    answer: 2,
    why: 'RAM is the computer\'s fast working memory and is volatile. Disks and SSDs keep data without power but are slower.',
    primer: 'The CPU works on data in RAM because it is fast. Disk is where things are saved permanently. The OS moves data between them.',
    example: 'open file: disk -> RAM -> CPU works on it\nsave file: RAM -> disk',
  );

  static const _binary = Prereq(
    id: 'binary',
    title: 'Binary numbers',
    subtitle: 'bits, bytes and powers of two',
    icon: Icons.filter_1_rounded,
    question: 'What is the binary number 1010 in decimal?',
    options: ['8', '10', '12', '5'],
    answer: 1,
    why: '1010 = 8 + 0 + 2 + 0 = 10. Each position is a power of two: 8, 4, 2, 1.',
    primer: 'Computers store everything as bits (0 or 1). In binary each place is worth double the one to its right: 8, 4, 2, 1. Eight bits make a byte.',
    example: '1010 = 1x8 + 0x4 + 1x2 + 0x1 = 10',
  );

  static const _clientServer = Prereq(
    id: 'clientserver',
    title: 'Clients and servers',
    subtitle: 'who asks, who answers',
    icon: Icons.dns_rounded,
    question: 'When you open a website, which side starts the conversation?',
    options: ['The client (your browser) sends a request', 'The server pushes the page unasked', 'The router decides', 'The DNS server'],
    answer: 0,
    why: 'The client asks and the server answers. A server only responds to requests it receives.',
    primer: 'A client (browser, app) sends requests; a server (a program on another machine) listens and responds. The web, email and games all work this way.',
    example: 'Browser --GET /home--> Server\nBrowser <--200 OK + page-- Server',
  );

  static const _database = Prereq(
    id: 'database',
    title: 'Why databases exist',
    subtitle: 'keeping data safe and shared',
    icon: Icons.storage_rounded,
    question: 'Why does an app store users in a database instead of in program variables?',
    options: ['Data survives restarts and can be shared by many servers', 'Variables cannot hold text', 'Databases make the code shorter', 'It is required by Java'],
    answer: 0,
    why: 'Variables vanish when the program stops and live inside one process. A database persists data and can be reached by many servers.',
    primer: 'A database is a separate program that stores data durably and answers queries. Apps are stateless helpers around it.',
    example: 'app restarts -> variables gone, database rows still there',
  );

  static List<Prereq> forConcept(String? name) {
    final n = (name ?? '').toLowerCase();
    bool has(String pattern) => RegExp(pattern).hasMatch(n);

    // Order matters: the most specific domains are checked first.
    if (has(r'process|cpu scheduling|paging|page replacement|mutex|semaphore|classic synchronization')) {
      return const [_process, _memory, _binary];
    }
    if (has(r'osi|ip addressing|subnet|tcp|udp|http|dns')) return const [_clientServer, _binary, _process];
    if (has(r'load balanc|caching|scaling|sharding|replication|consistency|cap\b|message queue')) {
      return const [_clientServer, _database, _bigO];
    }
    if (has(r'select|join|aggregat|group by|normal form|keys and constraints|acid|index|isolation|sql|transaction')) {
      return const [_tables, _selectBasics, _keys];
    }
    if (has(r'clarifying|trade-off|star method|design round|complexity')) return const [_arrays, _bigO, _control];
    if (has(r'recursion|backtrack|graph|bfs|dfs|memoiz|tabulat|tree|shortest')) return const [_arrays, _control, _recursion, _bigO];
    if (has(r'stack|queue|monoton|hash|collision|array|linked list|binary search|sort|two pointers|sliding window')) {
      return const [_arrays, _control, _methods, _bigO];
    }
    final concurrency = has(r'thread|race|sync|lock|deadlock|concurren|shared|executor|volatile|atomic|parallel');
    final oop = has(r'polymorph|inherit|class|object|interface|encapsul|abstract|overrid');
    if (concurrency) return const [_variables, _methods, _classes, _thread, _shared];
    if (oop) return const [_variables, _methods, _classes, _inherit, _override];
    return const [_variables, _control, _methods, _classes];
  }
}
