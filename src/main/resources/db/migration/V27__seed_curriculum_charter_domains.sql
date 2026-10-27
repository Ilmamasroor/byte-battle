-- Curriculum per the product Charter: six new domains plus the flagship Multithreading concepts.
-- Idempotent: every INSERT is ON CONFLICT DO NOTHING on fixed ids / unique slugs.

INSERT INTO curriculum_domains (id, name, description, slug, display_order, active) VALUES
    ('00000000-0000-0000-0000-000000000002', 'Data Structures & Algorithms', 'Core data structures and algorithmic problem solving for interviews and real-world engineering.', 'data-structures-algorithms', 2, true),
    ('00000000-0000-0000-0000-000000000003', 'DBMS & SQL', 'Relational databases: querying with SQL, schema design, transactions and indexing.', 'dbms-sql', 3, true),
    ('00000000-0000-0000-0000-000000000004', 'Operating Systems', 'Processes, scheduling, memory management and OS-level concurrency.', 'operating-systems', 4, true),
    ('00000000-0000-0000-0000-000000000005', 'Computer Networks', 'How data moves across networks: layers, addressing, transport protocols and the web.', 'computer-networks', 5, true),
    ('00000000-0000-0000-0000-000000000006', 'System Design', 'Designing scalable, reliable systems: caching, load balancing, data partitioning and messaging.', 'system-design', 6, true),
    ('00000000-0000-0000-0000-000000000007', 'Technical Interview Prep', 'Interview strategy, communication, behavioural rounds and reusable problem-solving patterns.', 'technical-interview-prep', 7, true)
ON CONFLICT DO NOTHING;

INSERT INTO topics (id, domain_id, name, description, slug, display_order, active) VALUES
    ('00000000-0000-0000-0000-000000000111', '00000000-0000-0000-0000-000000000002', 'Stacks & Queues', 'LIFO and FIFO structures, their operations and typical uses.', 'stacks_queues', 1, true),
    ('00000000-0000-0000-0000-000000000112', '00000000-0000-0000-0000-000000000002', 'Hashing', 'Hash functions, hash maps and sets, and how collisions are handled.', 'hashing', 2, true),
    ('00000000-0000-0000-0000-000000000113', '00000000-0000-0000-0000-000000000002', 'Graphs', 'Graph representations and traversal algorithms.', 'graphs', 3, true),
    ('00000000-0000-0000-0000-000000000114', '00000000-0000-0000-0000-000000000002', 'Dynamic Programming', 'Breaking problems into overlapping subproblems.', 'dynamic_programming', 4, true),
    ('00000000-0000-0000-0000-000000000115', '00000000-0000-0000-0000-000000000003', 'SQL Fundamentals', 'Querying relational data with SQL.', 'sql_fundamentals', 1, true),
    ('00000000-0000-0000-0000-000000000116', '00000000-0000-0000-0000-000000000003', 'Normalization and Design', 'Designing relational schemas without redundancy.', 'normalization', 2, true),
    ('00000000-0000-0000-0000-000000000117', '00000000-0000-0000-0000-000000000003', 'Transactions and Indexing', 'Correctness and performance of database operations.', 'transactions_indexing', 3, true),
    ('00000000-0000-0000-0000-000000000118', '00000000-0000-0000-0000-000000000004', 'Processes and Scheduling', 'How the operating system runs programs.', 'processes_scheduling', 1, true),
    ('00000000-0000-0000-0000-000000000119', '00000000-0000-0000-0000-000000000004', 'Memory Management', 'How the operating system manages RAM.', 'memory_management', 2, true),
    ('00000000-0000-0000-0000-000000000120', '00000000-0000-0000-0000-000000000004', 'OS Concurrency Primitives', 'Synchronization primitives provided by the operating system.', 'os_concurrency', 3, true),
    ('00000000-0000-0000-0000-000000000121', '00000000-0000-0000-0000-000000000005', 'Network Models', 'Layered models of network communication.', 'network_models', 1, true),
    ('00000000-0000-0000-0000-000000000122', '00000000-0000-0000-0000-000000000005', 'Transport and Application Protocols', 'Protocols that applications use every day.', 'transport_application', 2, true),
    ('00000000-0000-0000-0000-000000000123', '00000000-0000-0000-0000-000000000006', 'Scalability', 'Growing a system to serve more users.', 'scalability', 1, true),
    ('00000000-0000-0000-0000-000000000124', '00000000-0000-0000-0000-000000000006', 'Data and Reliability', 'Keeping data correct and available at scale.', 'data_reliability', 2, true),
    ('00000000-0000-0000-0000-000000000125', '00000000-0000-0000-0000-000000000007', 'Interview Strategy', 'How to approach and communicate in a technical interview.', 'interview_strategy', 1, true),
    ('00000000-0000-0000-0000-000000000126', '00000000-0000-0000-0000-000000000007', 'Behavioural and Design Rounds', 'Non-coding interview rounds.', 'behavioral_rounds', 2, true),
    ('00000000-0000-0000-0000-000000000127', '00000000-0000-0000-0000-000000000007', 'Problem-Solving Patterns', 'Reusable patterns that unlock many interview problems.', 'problem_patterns', 3, true)
ON CONFLICT DO NOTHING;

INSERT INTO concepts (id, topic_id, name, description, slug, difficulty, display_order, active) VALUES
    ('00000000-0000-0000-0000-000000001016', '00000000-0000-0000-0000-000000000111', 'Stack Operations', 'Push, pop, peek and applications such as balanced parentheses and undo stacks.', 'stack-operations', 'EASY', 1, true),
    ('00000000-0000-0000-0000-000000001017', '00000000-0000-0000-0000-000000000111', 'Queue Operations', 'Enqueue, dequeue, circular queues and breadth-first processing.', 'queue-operations', 'EASY', 2, true),
    ('00000000-0000-0000-0000-000000001018', '00000000-0000-0000-0000-000000000111', 'Monotonic Stack', 'Next-greater-element style problems solved with a monotonic stack.', 'monotonic-stack', 'MEDIUM', 3, true),
    ('00000000-0000-0000-0000-000000001019', '00000000-0000-0000-0000-000000000112', 'Hash Maps and Sets', 'Constant-time lookup, counting with maps and de-duplication with sets.', 'hash-maps-and-sets', 'EASY', 1, true),
    ('00000000-0000-0000-0000-000000001020', '00000000-0000-0000-0000-000000000112', 'Collision Handling', 'Chaining versus open addressing, load factor and resizing.', 'collision-handling', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001021', '00000000-0000-0000-0000-000000000113', 'Graph Representation', 'Adjacency lists and matrices, directed versus undirected graphs.', 'graph-representation', 'MEDIUM', 1, true),
    ('00000000-0000-0000-0000-000000001022', '00000000-0000-0000-0000-000000000113', 'BFS and DFS', 'Breadth-first and depth-first traversal, visited sets and connected components.', 'bfs-and-dfs', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001023', '00000000-0000-0000-0000-000000000113', 'Shortest Paths', 'Dijkstra and BFS shortest paths on weighted and unweighted graphs.', 'shortest-paths', 'HARD', 3, true),
    ('00000000-0000-0000-0000-000000001024', '00000000-0000-0000-0000-000000000114', 'Memoization', 'Top-down recursion with caching to remove repeated work.', 'memoization', 'MEDIUM', 1, true),
    ('00000000-0000-0000-0000-000000001025', '00000000-0000-0000-0000-000000000114', 'Tabulation', 'Bottom-up dynamic programming tables, state definition and transitions.', 'tabulation', 'HARD', 2, true),
    ('00000000-0000-0000-0000-000000001026', '00000000-0000-0000-0000-000000000115', 'SELECT and Filtering', 'SELECT, WHERE, ORDER BY, LIMIT and NULL handling.', 'select-and-filtering', 'EASY', 1, true),
    ('00000000-0000-0000-0000-000000001027', '00000000-0000-0000-0000-000000000115', 'Joins', 'INNER, LEFT, RIGHT and FULL joins and choosing the right one.', 'sql-joins', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001028', '00000000-0000-0000-0000-000000000115', 'Aggregation and GROUP BY', 'COUNT, SUM, AVG, GROUP BY and HAVING.', 'aggregation-group-by', 'MEDIUM', 3, true),
    ('00000000-0000-0000-0000-000000001029', '00000000-0000-0000-0000-000000000116', 'Normal Forms', 'First, second and third normal form and Boyce-Codd normal form.', 'normal-forms', 'MEDIUM', 1, true),
    ('00000000-0000-0000-0000-000000001030', '00000000-0000-0000-0000-000000000116', 'Keys and Constraints', 'Primary, foreign and unique keys, NOT NULL and CHECK constraints.', 'keys-and-constraints', 'EASY', 2, true),
    ('00000000-0000-0000-0000-000000001031', '00000000-0000-0000-0000-000000000117', 'ACID Properties', 'Atomicity, consistency, isolation and durability explained with examples.', 'acid-properties', 'MEDIUM', 1, true),
    ('00000000-0000-0000-0000-000000001032', '00000000-0000-0000-0000-000000000117', 'Indexes and Query Plans', 'B-tree indexes, covering indexes and reading EXPLAIN output.', 'indexes-and-query-plans', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001033', '00000000-0000-0000-0000-000000000117', 'Isolation Levels', 'Dirty, non-repeatable and phantom reads and the isolation levels that prevent them.', 'isolation-levels', 'HARD', 3, true),
    ('00000000-0000-0000-0000-000000001034', '00000000-0000-0000-0000-000000000118', 'Processes vs Threads', 'Address spaces, context switches and the cost of processes versus threads.', 'processes-vs-threads', 'EASY', 1, true),
    ('00000000-0000-0000-0000-000000001035', '00000000-0000-0000-0000-000000000118', 'CPU Scheduling', 'FCFS, SJF, round robin and priority scheduling with their trade-offs.', 'cpu-scheduling', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001036', '00000000-0000-0000-0000-000000000119', 'Paging and Virtual Memory', 'Page tables, TLBs and demand paging.', 'paging-and-virtual-memory', 'MEDIUM', 1, true),
    ('00000000-0000-0000-0000-000000001037', '00000000-0000-0000-0000-000000000119', 'Page Replacement', 'FIFO, LRU and optimal replacement and thrashing.', 'page-replacement', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001038', '00000000-0000-0000-0000-000000000120', 'Mutexes and Semaphores', 'Binary and counting semaphores, mutexes and critical sections.', 'mutexes-and-semaphores', 'MEDIUM', 1, true),
    ('00000000-0000-0000-0000-000000001039', '00000000-0000-0000-0000-000000000120', 'Classic Synchronization Problems', 'Producer-consumer, readers-writers and dining philosophers.', 'classic-synchronization-problems', 'HARD', 2, true),
    ('00000000-0000-0000-0000-000000001040', '00000000-0000-0000-0000-000000000121', 'OSI and TCP/IP Layers', 'Responsibilities of each layer and encapsulation.', 'osi-and-tcp-ip-layers', 'EASY', 1, true),
    ('00000000-0000-0000-0000-000000001041', '00000000-0000-0000-0000-000000000121', 'IP Addressing and Subnets', 'IPv4, CIDR notation and subnet calculations.', 'ip-addressing-and-subnets', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001042', '00000000-0000-0000-0000-000000000122', 'TCP vs UDP', 'Reliability, ordering, handshakes and when to choose each protocol.', 'tcp-vs-udp', 'MEDIUM', 1, true),
    ('00000000-0000-0000-0000-000000001043', '00000000-0000-0000-0000-000000000122', 'HTTP and HTTPS', 'Methods, status codes, headers and TLS basics.', 'http-and-https', 'EASY', 2, true),
    ('00000000-0000-0000-0000-000000001044', '00000000-0000-0000-0000-000000000122', 'DNS Resolution', 'Recursive and iterative resolution, caching and record types.', 'dns-resolution', 'MEDIUM', 3, true),
    ('00000000-0000-0000-0000-000000001045', '00000000-0000-0000-0000-000000000123', 'Load Balancing', 'Round robin, least connections and health checks.', 'load-balancing', 'MEDIUM', 1, true),
    ('00000000-0000-0000-0000-000000001046', '00000000-0000-0000-0000-000000000123', 'Caching', 'Cache-aside, write-through, eviction policies and invalidation.', 'caching', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001047', '00000000-0000-0000-0000-000000000123', 'Horizontal vs Vertical Scaling', 'Trade-offs of scaling out versus scaling up.', 'horizontal-vs-vertical-scaling', 'EASY', 3, true),
    ('00000000-0000-0000-0000-000000001048', '00000000-0000-0000-0000-000000000124', 'Sharding and Replication', 'Partitioning data, leader-follower replication and failover.', 'sharding-and-replication', 'HARD', 1, true),
    ('00000000-0000-0000-0000-000000001049', '00000000-0000-0000-0000-000000000124', 'Consistency and CAP', 'The CAP theorem and eventual versus strong consistency.', 'consistency-and-cap', 'HARD', 2, true),
    ('00000000-0000-0000-0000-000000001050', '00000000-0000-0000-0000-000000000124', 'Message Queues', 'Asynchronous processing, delivery guarantees and back-pressure.', 'message-queues', 'MEDIUM', 3, true),
    ('00000000-0000-0000-0000-000000001051', '00000000-0000-0000-0000-000000000125', 'Clarifying the Problem', 'Asking questions, restating requirements and agreeing on examples.', 'clarifying-the-problem', 'EASY', 1, true),
    ('00000000-0000-0000-0000-000000001052', '00000000-0000-0000-0000-000000000125', 'Complexity Analysis', 'Stating time and space complexity and comparing alternatives.', 'complexity-analysis', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001053', '00000000-0000-0000-0000-000000000125', 'Communicating Trade-offs', 'Explaining why you chose one approach over another.', 'communicating-trade-offs', 'MEDIUM', 3, true),
    ('00000000-0000-0000-0000-000000001054', '00000000-0000-0000-0000-000000000126', 'STAR Method', 'Structuring behavioural answers: situation, task, action, result.', 'star-method', 'EASY', 1, true),
    ('00000000-0000-0000-0000-000000001055', '00000000-0000-0000-0000-000000000126', 'Design Round Walkthrough', 'A repeatable structure for system-design interviews.', 'design-round-walkthrough', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001056', '00000000-0000-0000-0000-000000000127', 'Two Pointers', 'Converging and fast/slow pointer techniques.', 'two-pointers', 'MEDIUM', 1, true),
    ('00000000-0000-0000-0000-000000001057', '00000000-0000-0000-0000-000000000127', 'Sliding Window', 'Fixed and variable windows over arrays and strings.', 'sliding-window', 'MEDIUM', 2, true),
    ('00000000-0000-0000-0000-000000001058', '00000000-0000-0000-0000-000000000127', 'Recursion and Backtracking', 'Exploring decision trees, pruning and restoring state.', 'recursion-and-backtracking', 'HARD', 3, true)
ON CONFLICT DO NOTHING;

-- Flagship topic: Multithreading & Concurrency. Race Conditions already exists (V22); it is looked up by
-- slug and only re-ordered. Order: Threads, Shared Resources, Race Conditions, Synchronization, Locks, Deadlocks.
INSERT INTO concepts (id, topic_id, name, description, slug, difficulty, display_order, active)
SELECT '00000000-0000-0000-0000-000000001011', t.id, 'Threads', 'Creating, starting and joining threads, thread lifecycle and the difference between start() and run().', 'threads', 'EASY', 1, true FROM topics t WHERE t.slug = 'multithreading'
ON CONFLICT DO NOTHING;

INSERT INTO concepts (id, topic_id, name, description, slug, difficulty, display_order, active)
SELECT '00000000-0000-0000-0000-000000001012', t.id, 'Shared Resources', 'Shared mutable state, thread-safe collections, atomics and immutability.', 'shared-resources', 'MEDIUM', 2, true FROM topics t WHERE t.slug = 'multithreading'
ON CONFLICT DO NOTHING;

INSERT INTO concepts (id, topic_id, name, description, slug, difficulty, display_order, active)
SELECT '00000000-0000-0000-0000-000000001013', t.id, 'Synchronization', 'Monitors, the synchronized keyword, wait/notify and happens-before.', 'synchronization', 'MEDIUM', 4, true FROM topics t WHERE t.slug = 'multithreading'
ON CONFLICT DO NOTHING;

INSERT INTO concepts (id, topic_id, name, description, slug, difficulty, display_order, active)
SELECT '00000000-0000-0000-0000-000000001014', t.id, 'Locks', 'ReentrantLock, tryLock, read-write locks and lock discipline.', 'locks', 'MEDIUM', 5, true FROM topics t WHERE t.slug = 'multithreading'
ON CONFLICT DO NOTHING;

INSERT INTO concepts (id, topic_id, name, description, slug, difficulty, display_order, active)
SELECT '00000000-0000-0000-0000-000000001015', t.id, 'Deadlocks', 'Circular wait, the four Coffman conditions, lock ordering and detection.', 'deadlocks', 'HARD', 6, true FROM topics t WHERE t.slug = 'multithreading'
ON CONFLICT DO NOTHING;

UPDATE concepts SET display_order = 3, updated_at = now()
WHERE slug = 'race-conditions' AND display_order <> 3
  AND topic_id IN (SELECT id FROM topics WHERE slug = 'multithreading');
