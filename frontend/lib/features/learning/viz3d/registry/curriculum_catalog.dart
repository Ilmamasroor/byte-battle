// GENERATED from the curriculum seed migrations (V22, V27) and kept in sync by test/viz3d/catalog_test.dart.
// Do not rename ids: they are the concept ids the backend serves.
import '../contract/viz_contract.dart';

/// One concept of the shipped curriculum, with the visualization family it maps to.
class ConceptInfo {
  final String id;
  final String topicId;
  final String name;
  final String domain;
  final VizCategory category;
  const ConceptInfo(this.id, this.topicId, this.name, this.domain, this.category);
}

/// The shipped curriculum, in order. Used to label lessons and to build the coverage matrix.
const List<ConceptInfo> kCurriculumCatalog = [
  ConceptInfo('00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000000101', 'Java Fundamentals', 'Java Programming', VizCategory.codeExecution),
  ConceptInfo('00000000-0000-0000-0000-000000001002', '00000000-0000-0000-0000-000000000102', 'Polymorphism', 'Java Programming', VizCategory.codeExecution),
  ConceptInfo('00000000-0000-0000-0000-000000001003', '00000000-0000-0000-0000-000000000103', 'Race Conditions', 'Java Programming', VizCategory.concurrency),
  ConceptInfo('00000000-0000-0000-0000-000000001004', '00000000-0000-0000-0000-000000000104', 'Java Collections', 'Java Programming', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001005', '00000000-0000-0000-0000-000000000105', 'Exception Handling', 'Java Programming', VizCategory.codeExecution),
  ConceptInfo('00000000-0000-0000-0000-000000001006', '00000000-0000-0000-0000-000000000106', 'Array Traversal', 'Java Programming', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001007', '00000000-0000-0000-0000-000000000107', 'Linked List Operations', 'Java Programming', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001008', '00000000-0000-0000-0000-000000000108', 'Binary Search', 'Java Programming', VizCategory.algorithms),
  ConceptInfo('00000000-0000-0000-0000-000000001009', '00000000-0000-0000-0000-000000000109', 'Sorting Algorithms', 'Java Programming', VizCategory.algorithms),
  ConceptInfo('00000000-0000-0000-0000-000000001010', '00000000-0000-0000-0000-000000000110', 'Tree Traversal', 'Java Programming', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001011', '00000000-0000-0000-0000-000000000103', 'Threads', 'Java Programming', VizCategory.concurrency),
  ConceptInfo('00000000-0000-0000-0000-000000001012', '00000000-0000-0000-0000-000000000103', 'Shared Resources', 'Java Programming', VizCategory.concurrency),
  ConceptInfo('00000000-0000-0000-0000-000000001013', '00000000-0000-0000-0000-000000000103', 'Synchronization', 'Java Programming', VizCategory.concurrency),
  ConceptInfo('00000000-0000-0000-0000-000000001014', '00000000-0000-0000-0000-000000000103', 'Locks', 'Java Programming', VizCategory.concurrency),
  ConceptInfo('00000000-0000-0000-0000-000000001015', '00000000-0000-0000-0000-000000000103', 'Deadlocks', 'Java Programming', VizCategory.concurrency),
  ConceptInfo('00000000-0000-0000-0000-000000001016', '00000000-0000-0000-0000-000000000111', 'Stack Operations', 'Data Structures & Algorithms', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001017', '00000000-0000-0000-0000-000000000111', 'Queue Operations', 'Data Structures & Algorithms', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001018', '00000000-0000-0000-0000-000000000111', 'Monotonic Stack', 'Data Structures & Algorithms', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001019', '00000000-0000-0000-0000-000000000112', 'Hash Maps and Sets', 'Data Structures & Algorithms', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001020', '00000000-0000-0000-0000-000000000112', 'Collision Handling', 'Data Structures & Algorithms', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001021', '00000000-0000-0000-0000-000000000113', 'Graph Representation', 'Data Structures & Algorithms', VizCategory.dataStructures),
  ConceptInfo('00000000-0000-0000-0000-000000001022', '00000000-0000-0000-0000-000000000113', 'BFS and DFS', 'Data Structures & Algorithms', VizCategory.algorithms),
  ConceptInfo('00000000-0000-0000-0000-000000001023', '00000000-0000-0000-0000-000000000113', 'Shortest Paths', 'Data Structures & Algorithms', VizCategory.algorithms),
  ConceptInfo('00000000-0000-0000-0000-000000001024', '00000000-0000-0000-0000-000000000114', 'Memoization', 'Data Structures & Algorithms', VizCategory.algorithms),
  ConceptInfo('00000000-0000-0000-0000-000000001025', '00000000-0000-0000-0000-000000000114', 'Tabulation', 'Data Structures & Algorithms', VizCategory.algorithms),
  ConceptInfo('00000000-0000-0000-0000-000000001026', '00000000-0000-0000-0000-000000000115', 'SELECT and Filtering', 'DBMS & SQL', VizCategory.database),
  ConceptInfo('00000000-0000-0000-0000-000000001027', '00000000-0000-0000-0000-000000000115', 'Joins', 'DBMS & SQL', VizCategory.database),
  ConceptInfo('00000000-0000-0000-0000-000000001028', '00000000-0000-0000-0000-000000000115', 'Aggregation and GROUP BY', 'DBMS & SQL', VizCategory.database),
  ConceptInfo('00000000-0000-0000-0000-000000001029', '00000000-0000-0000-0000-000000000116', 'Normal Forms', 'DBMS & SQL', VizCategory.database),
  ConceptInfo('00000000-0000-0000-0000-000000001030', '00000000-0000-0000-0000-000000000116', 'Keys and Constraints', 'DBMS & SQL', VizCategory.database),
  ConceptInfo('00000000-0000-0000-0000-000000001031', '00000000-0000-0000-0000-000000000117', 'ACID Properties', 'DBMS & SQL', VizCategory.database),
  ConceptInfo('00000000-0000-0000-0000-000000001032', '00000000-0000-0000-0000-000000000117', 'Indexes and Query Plans', 'DBMS & SQL', VizCategory.database),
  ConceptInfo('00000000-0000-0000-0000-000000001033', '00000000-0000-0000-0000-000000000117', 'Isolation Levels', 'DBMS & SQL', VizCategory.database),
  ConceptInfo('00000000-0000-0000-0000-000000001034', '00000000-0000-0000-0000-000000000118', 'Processes vs Threads', 'Operating Systems', VizCategory.operatingSystems),
  ConceptInfo('00000000-0000-0000-0000-000000001035', '00000000-0000-0000-0000-000000000118', 'CPU Scheduling', 'Operating Systems', VizCategory.operatingSystems),
  ConceptInfo('00000000-0000-0000-0000-000000001036', '00000000-0000-0000-0000-000000000119', 'Paging and Virtual Memory', 'Operating Systems', VizCategory.operatingSystems),
  ConceptInfo('00000000-0000-0000-0000-000000001037', '00000000-0000-0000-0000-000000000119', 'Page Replacement', 'Operating Systems', VizCategory.operatingSystems),
  ConceptInfo('00000000-0000-0000-0000-000000001038', '00000000-0000-0000-0000-000000000120', 'Mutexes and Semaphores', 'Operating Systems', VizCategory.concurrency),
  ConceptInfo('00000000-0000-0000-0000-000000001039', '00000000-0000-0000-0000-000000000120', 'Classic Synchronization Problems', 'Operating Systems', VizCategory.concurrency),
  ConceptInfo('00000000-0000-0000-0000-000000001040', '00000000-0000-0000-0000-000000000121', 'OSI and TCP/IP Layers', 'Computer Networks', VizCategory.networks),
  ConceptInfo('00000000-0000-0000-0000-000000001041', '00000000-0000-0000-0000-000000000121', 'IP Addressing and Subnets', 'Computer Networks', VizCategory.networks),
  ConceptInfo('00000000-0000-0000-0000-000000001042', '00000000-0000-0000-0000-000000000122', 'TCP vs UDP', 'Computer Networks', VizCategory.networks),
  ConceptInfo('00000000-0000-0000-0000-000000001043', '00000000-0000-0000-0000-000000000122', 'HTTP and HTTPS', 'Computer Networks', VizCategory.networks),
  ConceptInfo('00000000-0000-0000-0000-000000001044', '00000000-0000-0000-0000-000000000122', 'DNS Resolution', 'Computer Networks', VizCategory.networks),
  ConceptInfo('00000000-0000-0000-0000-000000001045', '00000000-0000-0000-0000-000000000123', 'Load Balancing', 'System Design', VizCategory.systemDesign),
  ConceptInfo('00000000-0000-0000-0000-000000001046', '00000000-0000-0000-0000-000000000123', 'Caching', 'System Design', VizCategory.systemDesign),
  ConceptInfo('00000000-0000-0000-0000-000000001047', '00000000-0000-0000-0000-000000000123', 'Horizontal vs Vertical Scaling', 'System Design', VizCategory.systemDesign),
  ConceptInfo('00000000-0000-0000-0000-000000001048', '00000000-0000-0000-0000-000000000124', 'Sharding and Replication', 'System Design', VizCategory.systemDesign),
  ConceptInfo('00000000-0000-0000-0000-000000001049', '00000000-0000-0000-0000-000000000124', 'Consistency and CAP', 'System Design', VizCategory.systemDesign),
  ConceptInfo('00000000-0000-0000-0000-000000001050', '00000000-0000-0000-0000-000000000124', 'Message Queues', 'System Design', VizCategory.systemDesign),
  ConceptInfo('00000000-0000-0000-0000-000000001051', '00000000-0000-0000-0000-000000000125', 'Clarifying the Problem', 'Technical Interview Prep', VizCategory.interview),
  ConceptInfo('00000000-0000-0000-0000-000000001052', '00000000-0000-0000-0000-000000000125', 'Complexity Analysis', 'Technical Interview Prep', VizCategory.interview),
  ConceptInfo('00000000-0000-0000-0000-000000001053', '00000000-0000-0000-0000-000000000125', 'Communicating Trade-offs', 'Technical Interview Prep', VizCategory.interview),
  ConceptInfo('00000000-0000-0000-0000-000000001054', '00000000-0000-0000-0000-000000000126', 'STAR Method', 'Technical Interview Prep', VizCategory.interview),
  ConceptInfo('00000000-0000-0000-0000-000000001055', '00000000-0000-0000-0000-000000000126', 'Design Round Walkthrough', 'Technical Interview Prep', VizCategory.interview),
  ConceptInfo('00000000-0000-0000-0000-000000001056', '00000000-0000-0000-0000-000000000127', 'Two Pointers', 'Technical Interview Prep', VizCategory.interview),
  ConceptInfo('00000000-0000-0000-0000-000000001057', '00000000-0000-0000-0000-000000000127', 'Sliding Window', 'Technical Interview Prep', VizCategory.interview),
  ConceptInfo('00000000-0000-0000-0000-000000001058', '00000000-0000-0000-0000-000000000127', 'Recursion and Backtracking', 'Technical Interview Prep', VizCategory.interview),
];

final Map<String, ConceptInfo> _byId = {for (final c in kCurriculumCatalog) c.id: c};

ConceptInfo? conceptInfo(String conceptId) => _byId[conceptId];
