/// A single Boss Battle round question: the prompt shown to the learner,
/// its difficulty, and up to 3 progressive hints revealed one at a time
/// (via the "Get Hint" button, with a short simulated-thinking delay).
class BattleQuestionData {
  final String id;
  final String difficulty; // EASY / MEDIUM / HARD
  final String topicLabel;
  final String question;
  final List<String> hints;

  const BattleQuestionData({
    required this.id,
    required this.difficulty,
    required this.topicLabel,
    required this.question,
    required this.hints,
  });
}

/// Fallback question bank used to populate Boss Battle rounds.
///
/// There is currently no backend endpoint that serves a fixed list of
/// battle questions (`aiBattleHint` / `aiBossBattle` only *generate* a
/// hint or a boss briefing for a question the app already knows about —
/// see [BattleAiRemoteDatasource]). Until such an endpoint exists,
/// [BattleRepository.getQuestions] always returns this hardcoded set.
/// The moment a real "list battle questions" endpoint is added, only
/// [BattleRepository.getQuestions] needs to change — every screen reads
/// through that method, never this list directly.
const List<BattleQuestionData> kBattleQuestionBank = [
  BattleQuestionData(
    id: 'concurrency-lockfree-queue',
    difficulty: 'EASY',
    topicLabel: 'Java • Multithreading',
    question:
        'Implement a thread-safe queue using AtomicReference (lock-free, '
        'compare-and-swap based) instead of synchronized blocks or explicit '
        'locks.',
    hints: [
      'Queue ke liye Node structure use karo.',
      'Head aur tail ko AtomicReference se manage karo.',
      'Add aur get operations mein compareAndSet ka use karke thread safety '
          'maintain karo.',
    ],
  ),
  BattleQuestionData(
    id: 'concurrency-sequential-generator',
    difficulty: 'EASY',
    topicLabel: 'Java • Multithreading',
    question:
        'Implement a generator that hands out sequential numbers to '
        'multiple concurrent threads with no duplicates or gaps, using an '
        'atomic variable instead of a lock.',
    hints: [
      'Shared counter ke liye AtomicLong use karo.',
      'Counter ko atomically increment karo.',
      'compareAndSet ya incrementAndGet se ensure karo ki duplicate numbers '
          'na aaye.',
    ],
  ),
  BattleQuestionData(
    id: 'concurrency-lockfree-stack',
    difficulty: 'EASY',
    topicLabel: 'Java • Multithreading',
    question:
        'Implement a thread-safe stack using AtomicReference (lock-free, '
        'compare-and-swap based).',
    hints: [
      'Stack ko linked Nodes se implement karo.',
      'Top/head ko AtomicReference mein rakho.',
      'Push aur pop ke time compareAndSet use karo.',
    ],
  ),
  BattleQuestionData(
    id: 'concurrency-dining-philosophers',
    difficulty: 'MEDIUM',
    topicLabel: 'Java • Multithreading',
    question:
        'Implement a solution to the Dining Philosophers problem: N '
        'philosophers share N chopsticks and each needs both neighboring '
        'chopsticks to eat, without deadlock or starvation, and without two '
        'neighbors eating at the same time.',
    hints: [
      'Har chopstick ko Semaphore se represent karo.',
      'Philosopher ko dono chopsticks acquire karne honge before eating.',
      'Deadlock avoid karne ke liye ek philosopher ka fork-acquisition order '
          'reverse karo.',
    ],
  ),
  BattleQuestionData(
    id: 'concurrency-readers-writers',
    difficulty: 'MEDIUM',
    topicLabel: 'Java • Multithreading',
    question:
        "Implement the Readers-Writers problem with reader priority: any "
        'number of readers may read concurrently, but a writer requires '
        "exclusive access once it's ready to write.",
    hints: [
      'Active readers ka count maintain karo.',
      'First reader writer lock acquire kare aur last reader release kare.',
      'Semaphore/mutex se shared reader count ko safely update karo.',
    ],
  ),
  BattleQuestionData(
    id: 'concurrency-readers-writers-fair',
    difficulty: 'MEDIUM',
    topicLabel: 'Java • Multithreading',
    question:
        'Implement a starvation-free variant of the Readers-Writers '
        'problem, ensuring neither readers nor writers can be blocked '
        'indefinitely by the other group.',
    hints: [
      'Readers aur writers ko fair order mein access dene ka mechanism use '
          'karo.',
      'Entry control ke liye semaphore/turnstile use kar sakte ho.',
      'Ensure karo ki continuously aane wale readers writers ko indefinitely '
          'block na karein, aur vice versa.',
    ],
  ),
];
