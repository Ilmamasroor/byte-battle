-- Debugging exercises (buggy code + hint ladder) for Race Conditions, Synchronization and Deadlocks.
-- Each buggy version was run locally and fails (wrong output or deadlock/timeout); each solution passes all tests.

INSERT INTO debug_exercises (id, concept_id, title, description, buggy_code, language, test_cases_json, hint_ladder_json, bug_category, difficulty, solution_code, created_at) VALUES
    ('00000000-0000-0000-0000-00000d000001', '00000000-0000-0000-0000-000000001003', 'The Vanishing Increments', $d$Several threads increment a shared counter, but the final count is lower than threads x increments. Find why updates vanish and fix the program. Input: "T N" (threads, increments per thread). Expected output: "Count: <T*N>".$d$,
     $b$import java.util.*;

public class Main {
    private static int count = 0;

    private static void increment() throws InterruptedException {
        int current = count;
        Thread.sleep(1);
        count = current + 1;
    }

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        int threads = in.nextInt();
        int perThread = in.nextInt();

        Thread[] workers = new Thread[threads];
        for (int t = 0; t < threads; t++) {
            workers[t] = new Thread(() -> {
                try {
                    for (int i = 0; i < perThread; i++) increment();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
            workers[t].start();
        }
        for (Thread w : workers) w.join();

        System.out.println("Count: " + count);
    }
}
$b$,
     'JAVA',
     $t$[
  {
    "input": "2 20\n",
    "expectedOutput": "Count: 40\n",
    "hidden": false
  },
  {
    "input": "4 25\n",
    "expectedOutput": "Count: 100\n",
    "hidden": false
  },
  {
    "input": "3 30\n",
    "expectedOutput": "Count: 90\n",
    "hidden": true
  },
  {
    "input": "5 20\n",
    "expectedOutput": "Count: 100\n",
    "hidden": true
  }
]$t$,
     $h$[
  "Run it with one thread, then with several. What changes? Two threads can both read the same old value of count.",
  "increment() is a read-modify-write on shared state: read count, wait, write count + 1. Another thread can slip in between the read and the write.",
  "Only one thread at a time may execute the read-modify-write sequence. Which keyword gives a method mutual exclusion on its object or class?",
  "Declare increment() as synchronized (it is static, so it locks the Main class)."
]$h$,
     'RACE_CONDITION', 'EASY',
     $s$import java.util.*;

public class Main {
    private static int count = 0;

    private static synchronized void increment() throws InterruptedException {
        int current = count;
        Thread.sleep(1);
        count = current + 1;
    }

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        int threads = in.nextInt();
        int perThread = in.nextInt();

        Thread[] workers = new Thread[threads];
        for (int t = 0; t < threads; t++) {
            workers[t] = new Thread(() -> {
                try {
                    for (int i = 0; i < perThread; i++) increment();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
            workers[t].start();
        }
        for (Thread w : workers) w.join();

        System.out.println("Count: " + count);
    }
}
$s$, now()),
    ('00000000-0000-0000-0000-00000d000002', '00000000-0000-0000-0000-000000001003', 'Check-Then-Act Withdrawals', $d$Each thread tries to withdraw a fixed amount if the balance is high enough. The account must never go negative, yet too many withdrawals succeed. Input: "balance amount threads". Expected output: "Successful: <s> Balance: <b>".$d$,
     $b$import java.util.*;

public class Main {
    private static int balance;
    private static int successes = 0;

    private static void withdraw(int amount) throws InterruptedException {
        if (balance >= amount) {
            Thread.sleep(5);
            balance -= amount;
            successes++;
        }
    }

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        balance = in.nextInt();
        int amount = in.nextInt();
        int threads = in.nextInt();

        Thread[] workers = new Thread[threads];
        for (int i = 0; i < threads; i++) {
            workers[i] = new Thread(() -> {
                try {
                    withdraw(amount);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
            workers[i].start();
        }
        for (Thread w : workers) w.join();

        System.out.println("Successful: " + successes + " Balance: " + balance);
    }
}
$b$,
     'JAVA',
     $t$[
  {
    "input": "100 30 6\n",
    "expectedOutput": "Successful: 3 Balance: 10\n",
    "hidden": false
  },
  {
    "input": "50 10 8\n",
    "expectedOutput": "Successful: 5 Balance: 0\n",
    "hidden": false
  },
  {
    "input": "90 40 5\n",
    "expectedOutput": "Successful: 2 Balance: 10\n",
    "hidden": true
  },
  {
    "input": "1000 100 4\n",
    "expectedOutput": "Successful: 4 Balance: 600\n",
    "hidden": true
  }
]$t$,
     $h$[
  "With balance 100, amount 30 and 6 threads, how many withdrawals should succeed? Compare with what the program prints.",
  "The condition balance >= amount is checked, and only later is the balance reduced. Several threads can pass the check before any of them subtracts.",
  "The check and the update must form one indivisible step.",
  "Make withdraw() synchronized so the check-then-act sequence cannot interleave."
]$h$,
     'CHECK_THEN_ACT', 'MEDIUM',
     $s$import java.util.*;

public class Main {
    private static int balance;
    private static int successes = 0;

    private static synchronized void withdraw(int amount) throws InterruptedException {
        if (balance >= amount) {
            Thread.sleep(5);
            balance -= amount;
            successes++;
        }
    }

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        balance = in.nextInt();
        int amount = in.nextInt();
        int threads = in.nextInt();

        Thread[] workers = new Thread[threads];
        for (int i = 0; i < threads; i++) {
            workers[i] = new Thread(() -> {
                try {
                    withdraw(amount);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
            workers[i].start();
        }
        for (Thread w : workers) w.join();

        System.out.println("Successful: " + successes + " Balance: " + balance);
    }
}
$s$, now()),
    ('00000000-0000-0000-0000-00000d000003', '00000000-0000-0000-0000-000000001013', 'Two Locks, One Variable', $d$Adder threads add 1 and subtractor threads subtract 1 on the same value, each using synchronized, yet the result is wrong. Input: "adders subtractors n" (each thread performs n operations). Expected output: "Value: <(adders - subtractors) * n>".$d$,
     $b$import java.util.*;

public class Main {
    private static int value = 0;
    private static final Object addLock = new Object();
    private static final Object subLock = new Object();

    private static void add() throws InterruptedException {
        synchronized (addLock) {
            int current = value;
            Thread.sleep(1);
            value = current + 1;
        }
    }

    private static void subtract() throws InterruptedException {
        synchronized (subLock) {
            int current = value;
            Thread.sleep(1);
            value = current - 1;
        }
    }

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        int adders = in.nextInt();
        int subtractors = in.nextInt();
        int n = in.nextInt();

        List<Thread> workers = new ArrayList<>();
        for (int i = 0; i < adders; i++) {
            workers.add(new Thread(() -> {
                try {
                    for (int j = 0; j < n; j++) add();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        for (int i = 0; i < subtractors; i++) {
            workers.add(new Thread(() -> {
                try {
                    for (int j = 0; j < n; j++) subtract();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        for (Thread w : workers) w.start();
        for (Thread w : workers) w.join();

        System.out.println("Value: " + value);
    }
}
$b$,
     'JAVA',
     $t$[
  {
    "input": "1 1 25\n",
    "expectedOutput": "Value: 0\n",
    "hidden": false
  },
  {
    "input": "3 2 20\n",
    "expectedOutput": "Value: 20\n",
    "hidden": false
  },
  {
    "input": "2 4 15\n",
    "expectedOutput": "Value: -30\n",
    "hidden": true
  },
  {
    "input": "4 1 20\n",
    "expectedOutput": "Value: 60\n",
    "hidden": true
  }
]$t$,
     $h$[
  "Every method is synchronized, so why is the answer still wrong? Ask: synchronized on WHAT?",
  "add() and subtract() lock two different objects, so an adder and a subtractor can run at the same time and overwrite each other.",
  "Threads only exclude each other when they lock the SAME monitor.",
  "Use one shared lock object for both add() and subtract()."
]$h$,
     'WRONG_LOCK_OBJECT', 'MEDIUM',
     $s$import java.util.*;

public class Main {
    private static int value = 0;
    private static final Object lock = new Object();

    private static void add() throws InterruptedException {
        synchronized (lock) {
            int current = value;
            Thread.sleep(1);
            value = current + 1;
        }
    }

    private static void subtract() throws InterruptedException {
        synchronized (lock) {
            int current = value;
            Thread.sleep(1);
            value = current - 1;
        }
    }

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        int adders = in.nextInt();
        int subtractors = in.nextInt();
        int n = in.nextInt();

        List<Thread> workers = new ArrayList<>();
        for (int i = 0; i < adders; i++) {
            workers.add(new Thread(() -> {
                try {
                    for (int j = 0; j < n; j++) add();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        for (int i = 0; i < subtractors; i++) {
            workers.add(new Thread(() -> {
                try {
                    for (int j = 0; j < n; j++) subtract();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        for (Thread w : workers) w.start();
        for (Thread w : workers) w.join();

        System.out.println("Value: " + value);
    }
}
$s$, now()),
    ('00000000-0000-0000-0000-00000d000004', '00000000-0000-0000-0000-000000001013', 'The Missing Notify', $d$A consumer waits until the producer publishes a value, but the program never finishes. Input: one integer v. Expected output: "Received: v". Find out why the waiting thread sleeps forever.$d$,
     $b$import java.util.*;

public class Main {
    private static final Object lock = new Object();
    private static int value;
    private static boolean ready = false;

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        int v = in.nextInt();

        Thread consumer = new Thread(() -> {
            synchronized (lock) {
                try {
                    while (!ready) {
                        lock.wait();
                    }
                    System.out.println("Received: " + value);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        });
        consumer.start();

        Thread.sleep(50);
        synchronized (lock) {
            value = v;
            ready = true;
        }
        consumer.join();
    }
}
$b$,
     'JAVA',
     $t$[
  {
    "input": "7\n",
    "expectedOutput": "Received: 7\n",
    "hidden": false
  },
  {
    "input": "42\n",
    "expectedOutput": "Received: 42\n",
    "hidden": false
  },
  {
    "input": "-1\n",
    "expectedOutput": "Received: -1\n",
    "hidden": true
  }
]$t$,
     $h$[
  "Where does the program stop making progress? Think about what the consumer thread is doing when main calls join().",
  "wait() releases the monitor and parks the thread until another thread wakes it. Setting ready = true does not wake anybody.",
  "Whoever changes the condition must signal the threads waiting on that monitor.",
  "Call lock.notifyAll() inside the synchronized block after setting ready = true."
]$h$,
     'MISSING_NOTIFY', 'MEDIUM',
     $s$import java.util.*;

public class Main {
    private static final Object lock = new Object();
    private static int value;
    private static boolean ready = false;

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        int v = in.nextInt();

        Thread consumer = new Thread(() -> {
            synchronized (lock) {
                try {
                    while (!ready) {
                        lock.wait();
                    }
                    System.out.println("Received: " + value);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        });
        consumer.start();

        Thread.sleep(50);
        synchronized (lock) {
            value = v;
            ready = true;
            lock.notifyAll();
        }
        consumer.join();
    }
}
$s$, now()),
    ('00000000-0000-0000-0000-00000d000005', '00000000-0000-0000-0000-000000001015', 'Opposite Lock Order', $d$Two threads each need both locks A and B to bump a shared total, but the program freezes. Input: n (iterations per thread). Expected output: "Total: <2n>". Find the circular wait and break it.$d$,
     $b$import java.util.*;

public class Main {
    private static final Object lockA = new Object();
    private static final Object lockB = new Object();
    private static int total = 0;

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        int n = in.nextInt();

        Thread first = new Thread(() -> {
            try {
                for (int i = 0; i < n; i++) {
                    synchronized (lockA) {
                        Thread.sleep(5);
                        synchronized (lockB) {
                            total++;
                        }
                    }
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        Thread second = new Thread(() -> {
            try {
                for (int i = 0; i < n; i++) {
                    synchronized (lockB) {
                        Thread.sleep(5);
                        synchronized (lockA) {
                            total++;
                        }
                    }
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        first.start();
        second.start();
        first.join();
        second.join();

        System.out.println("Total: " + total);
    }
}
$b$,
     'JAVA',
     $t$[
  {
    "input": "1\n",
    "expectedOutput": "Total: 2\n",
    "hidden": false
  },
  {
    "input": "3\n",
    "expectedOutput": "Total: 6\n",
    "hidden": false
  },
  {
    "input": "5\n",
    "expectedOutput": "Total: 10\n",
    "hidden": true
  },
  {
    "input": "10\n",
    "expectedOutput": "Total: 20\n",
    "hidden": true
  }
]$t$,
     $h$[
  "Take a thread dump idea: what is each thread holding, and what is it waiting for?",
  "The first thread holds A and wants B, while the second holds B and wants A. That is a circular wait.",
  "Deadlock needs a cycle. If every thread acquires locks in the same global order, no cycle can form.",
  "Make both threads lock lockA first and lockB second."
]$h$,
     'LOCK_ORDERING', 'HARD',
     $s$import java.util.*;

public class Main {
    private static final Object lockA = new Object();
    private static final Object lockB = new Object();
    private static int total = 0;

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        int n = in.nextInt();

        Thread first = new Thread(() -> {
            try {
                for (int i = 0; i < n; i++) {
                    synchronized (lockA) {
                        Thread.sleep(5);
                        synchronized (lockB) {
                            total++;
                        }
                    }
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        Thread second = new Thread(() -> {
            try {
                for (int i = 0; i < n; i++) {
                    synchronized (lockA) {
                        Thread.sleep(5);
                        synchronized (lockB) {
                            total++;
                        }
                    }
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        first.start();
        second.start();
        first.join();
        second.join();

        System.out.println("Total: " + total);
    }
}
$s$, now()),
    ('00000000-0000-0000-0000-00000d000006', '00000000-0000-0000-0000-000000001015', 'Joining While Holding the Lock', $d$The main thread starts a worker and waits for it, but both threads end up stuck. Input: one integer n. Expected output: "Result: <n*n>".$d$,
     $b$import java.util.*;

public class Main {
    private static final Object lock = new Object();
    private static long result = 0;

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        long n = in.nextLong();

        Thread worker = new Thread(() -> {
            synchronized (lock) {
                result = n * n;
            }
        });

        synchronized (lock) {
            worker.start();
            worker.join();
        }

        System.out.println("Result: " + result);
    }
}
$b$,
     'JAVA',
     $t$[
  {
    "input": "3\n",
    "expectedOutput": "Result: 9\n",
    "hidden": false
  },
  {
    "input": "12\n",
    "expectedOutput": "Result: 144\n",
    "hidden": false
  },
  {
    "input": "100\n",
    "expectedOutput": "Result: 10000\n",
    "hidden": true
  },
  {
    "input": "1\n",
    "expectedOutput": "Result: 1\n",
    "hidden": true
  }
]$t$,
     $h$[
  "Who owns the lock while main is inside join()? And what does the worker need before it can finish?",
  "main holds the monitor and waits for the worker; the worker waits for the monitor main is holding. Neither can proceed.",
  "Never block on another thread while holding a lock that thread needs.",
  "Call join() outside the synchronized block; take the lock only when you read the result."
]$h$,
     'JOIN_INSIDE_LOCK', 'HARD',
     $s$import java.util.*;

public class Main {
    private static final Object lock = new Object();
    private static long result = 0;

    public static void main(String[] args) throws Exception {
        Scanner in = new Scanner(System.in);
        long n = in.nextLong();

        Thread worker = new Thread(() -> {
            synchronized (lock) {
                result = n * n;
            }
        });

        worker.start();
        worker.join();

        synchronized (lock) {
            System.out.println("Result: " + result);
        }
    }
}
$s$, now())
ON CONFLICT DO NOTHING;
