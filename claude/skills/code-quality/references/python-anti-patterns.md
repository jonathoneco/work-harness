---
meta:
  stack: ["python"]
  version: 1
  last_reviewed: 2026-03-25
---

# Python Anti-Patterns

These rules target mistakes that AI coding assistants repeatedly introduce in Python code. Every rule has a concrete BAD/GOOD example. Rules that overlap with the universal rules in `code-quality.md` are intentionally excluded -- these are Python-specific.

## Anti-pattern: Mutable Default Arguments
**Severity**: error

Using mutable objects (lists, dicts, sets) as default argument values causes the default to be shared across all calls, accumulating state between invocations.

**Why**: Python evaluates default arguments once at function definition time, not at each call. A default `[]` or `{}` is the same object for every invocation, so mutations persist and corrupt subsequent calls silently.

```python
# BAD
def add_item(item, items=[]):
    items.append(item)
    return items

add_item("a")  # ["a"]
add_item("b")  # ["a", "b"] -- leaked state from previous call
```

```python
# GOOD
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

## Anti-pattern: Bare Except Clause
**Severity**: error

Using `except:` or `except Exception:` without discrimination catches KeyboardInterrupt, SystemExit, and other signals that should propagate, making the program impossible to interrupt cleanly.

**Why**: Bare except catches everything including signals the OS sends to terminate the process. The program appears to hang or silently swallow Ctrl-C, and real errors are masked by the overly broad handler.

```python
# BAD
try:
    process_data(payload)
except:
    pass  # swallows KeyboardInterrupt, SystemExit, MemoryError
```

```python
# GOOD
try:
    process_data(payload)
except ValueError as e:
    logger.warning("Invalid payload: %s", e)
except ConnectionError as e:
    logger.error("Connection failed: %s", e)
    raise
```

## Anti-pattern: Unawaited Coroutine
**Severity**: error

Calling an async function without `await` returns a coroutine object instead of executing the function. The operation silently does nothing and Python emits only a runtime warning.

**Why**: The coroutine is created but never scheduled. Database writes, HTTP requests, and file operations silently never execute. The caller receives a coroutine object that passes truthiness checks, hiding the bug.

```python
# BAD
async def save_user(db, user):
    db.execute("INSERT INTO users ...", user.name)  # missing await -- never executes
    return user

async def send_notification(client, msg):
    client.post("/notify", json=msg)  # coroutine discarded silently
```

```python
# GOOD
async def save_user(db, user):
    await db.execute("INSERT INTO users ...", user.name)
    return user

async def send_notification(client, msg):
    await client.post("/notify", json=msg)
```

## Performance: String Concatenation in Loop
**Severity**: info

Building strings by concatenating with `+` or `+=` inside a loop creates a new string object on every iteration, resulting in O(n^2) time complexity for n concatenations.

**Why**: Python strings are immutable. Each `+=` allocates a new string and copies all previous content. For large loops this causes quadratic memory allocation and measurable slowdowns.

```python
# BAD
def build_report(rows):
    result = ""
    for row in rows:
        result += f"{row['name']}: {row['value']}\n"  # O(n^2)
    return result
```

```python
# GOOD
def build_report(rows):
    parts = []
    for row in rows:
        parts.append(f"{row['name']}: {row['value']}")
    return "\n".join(parts)
```

## Anti-pattern: Silent Exception Swallowing
**Severity**: error

Catching an exception and replacing it with a bare `pass` or a log-only handler when the caller needs to know the operation failed. The function returns a default value that looks like success.

**Why**: The caller cannot distinguish between "operation succeeded with empty result" and "operation failed." Data loss, incomplete processing, and corrupted state all hide behind a successful-looking return.

```python
# BAD
def get_config(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return {}  # caller thinks config is just empty
```

```python
# GOOD
def get_config(path):
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        raise ConfigError(f"Config file not found: {path}")
    except json.JSONDecodeError as e:
        raise ConfigError(f"Invalid JSON in {path}: {e}")
```

## Anti-pattern: Late Binding Closures in Loops
**Severity**: error

Creating closures (lambdas or inner functions) inside a loop that reference the loop variable. All closures share the same variable and see its final value, not the value at the time of creation.

**Why**: Python closures capture variables by reference, not by value. When the loop finishes, all closures reference the same variable which holds the last iteration's value. Every callback or handler does the same thing.

```python
# BAD
handlers = []
for i in range(5):
    handlers.append(lambda: print(i))

handlers[0]()  # prints 4, not 0
handlers[1]()  # prints 4, not 1
```

```python
# GOOD
handlers = []
for i in range(5):
    handlers.append(lambda i=i: print(i))  # default arg captures current value

handlers[0]()  # prints 0
handlers[1]()  # prints 1
```

## Anti-pattern: Type Checking with isinstance vs type
**Severity**: warn

Using `type(x) == SomeType` or `type(x) is SomeType` for type checks instead of `isinstance()`. Direct type comparison breaks for subclasses and violates the Liskov substitution principle.

**Why**: `type()` checks fail on subclass instances, so code that accepts a `dict` will reject an `OrderedDict` or a custom mapping subclass. `isinstance()` respects inheritance and works with ABCs and Protocols.

```python
# BAD
def process(value):
    if type(value) is dict:
        return handle_mapping(value)
    elif type(value) is list:
        return handle_sequence(value)
```

```python
# GOOD
from collections.abc import Mapping, Sequence

def process(value):
    if isinstance(value, Mapping):
        return handle_mapping(value)
    elif isinstance(value, Sequence):
        return handle_sequence(value)
```

## Best Practice: Use Context Managers for Resources
**Severity**: warn

Opening files, database connections, locks, or network sockets without a `with` statement risks resource leaks when exceptions occur between open and close.

**Why**: Without a context manager, an exception between resource acquisition and release skips the cleanup code. File descriptors leak, database connections exhaust the pool, and locks are never released -- all intermittent failures that are hard to reproduce.

```python
# BAD
def read_data(path):
    f = open(path)
    data = json.load(f)
    f.close()  # never reached if json.load raises
    return data
```

```python
# GOOD
def read_data(path):
    with open(path) as f:
        return json.load(f)
```

## Best Practice: Explicit is Better than Implicit Returns
**Severity**: info

Functions that return a value on some code paths but fall through with an implicit `None` on others create ambiguity about the function's contract and make bugs hard to trace.

**Why**: When a function sometimes returns a value and sometimes returns `None` implicitly, callers cannot tell if `None` means "not found" or "the code forgot to return." Explicit returns on all paths make the intent clear and type checkers can verify consistency.

```python
# BAD
def find_user(users, user_id):
    for user in users:
        if user["id"] == user_id:
            return user
    # implicit None return -- caller can't distinguish "not found" from bug
```

```python
# GOOD
def find_user(users, user_id):
    for user in users:
        if user["id"] == user_id:
            return user
    return None  # explicit: "not found" is an intentional result
```

## Idiomatic: Use Enumerate Instead of Range(len())
**Severity**: info

Using `range(len(collection))` to get indices while also accessing elements by index is non-idiomatic and error-prone. `enumerate()` provides both index and value directly.

**Why**: `range(len())` requires manual indexing which is a source of off-by-one errors and is harder to read. `enumerate()` is the idiomatic Python pattern -- linters flag the `range(len())` form and AI assistants should not generate it.

```python
# BAD
items = ["apple", "banana", "cherry"]
for i in range(len(items)):
    print(f"{i}: {items[i]}")
```

```python
# GOOD
items = ["apple", "banana", "cherry"]
for i, item in enumerate(items):
    print(f"{i}: {item}")
```

## Idiomatic: Use f-strings Over format() or %
**Severity**: info

Using `str.format()` or `%` string formatting when f-strings are available (Python 3.6+). f-strings are faster, more readable, and less error-prone than older formatting methods.

**Why**: f-strings are evaluated at runtime with the variables in scope, making them harder to mismatch. `%`-formatting silently produces wrong output on argument count mismatches, and `.format()` is verbose. f-strings are the modern Python standard.

```python
# BAD
name = "Alice"
age = 30
msg = "Hello, %s. You are %d years old." % (name, age)
msg2 = "Hello, {}. You are {} years old.".format(name, age)
```

```python
# GOOD
name = "Alice"
age = 30
msg = f"Hello, {name}. You are {age} years old."
```

## Idiomatic: Use Pathlib Over os.path
**Severity**: info

Using `os.path.join()`, `os.path.exists()`, and manual string manipulation for file paths instead of the `pathlib.Path` API. Pathlib provides an object-oriented, cross-platform path interface.

**Why**: `os.path` functions require passing strings through chains of calls that are hard to read and easy to get wrong. `pathlib.Path` offers method chaining, `/` operator for joining, and integrates with `open()` and most stdlib functions.

```python
# BAD
import os

config_path = os.path.join(os.path.dirname(__file__), "..", "config", "settings.json")
if os.path.exists(config_path):
    with open(config_path) as f:
        config = json.load(f)
```

```python
# GOOD
from pathlib import Path

config_path = Path(__file__).parent.parent / "config" / "settings.json"
if config_path.exists():
    config = json.loads(config_path.read_text())
```

## Performance: Avoid Global Variable Lookup in Hot Paths
**Severity**: warn

Referencing global or module-level variables inside tight loops forces a LEGB scope lookup on every iteration. Local variable access is significantly faster in CPython.

**Why**: CPython uses `LOAD_FAST` for locals (array index) but `LOAD_GLOBAL` for globals (dict lookup). In hot loops with millions of iterations, the difference is measurable. Assigning the global to a local before the loop eliminates repeated dictionary lookups.

```python
# BAD
import math

def compute_distances(points):
    results = []
    for p in points:
        results.append(math.sqrt(p[0] ** 2 + p[1] ** 2))  # global lookup each iteration
    return results
```

```python
# GOOD
import math

def compute_distances(points):
    sqrt = math.sqrt  # local binding -- LOAD_FAST in loop
    results = []
    for p in points:
        results.append(sqrt(p[0] ** 2 + p[1] ** 2))
    return results
```

## Security: Use secrets Module for Tokens, Not random
**Severity**: error

Using `random.random()`, `random.randint()`, or `random.choice()` to generate tokens, passwords, session IDs, or any security-sensitive value. The `random` module uses a predictable PRNG (Mersenne Twister) that is not cryptographically secure.

**Why**: An attacker who observes 624 consecutive outputs of Mersenne Twister can predict all future outputs and reconstruct past outputs. Session tokens, API keys, and password reset tokens generated with `random` can be predicted and forged.

```python
# BAD
import random
import string

def generate_token(length=32):
    chars = string.ascii_letters + string.digits
    return "".join(random.choice(chars) for _ in range(length))
```

```python
# GOOD
import secrets

def generate_token(length=32):
    return secrets.token_urlsafe(length)
```

## Security: Avoid eval() and exec() on User Input
**Severity**: error

Using `eval()`, `exec()`, or `compile()` on strings that include any user-controlled input. Even partial user input in an eval string enables arbitrary code execution.

**Why**: `eval()` and `exec()` execute arbitrary Python code. An attacker can escape string boundaries, import modules, and run system commands. No amount of input sanitization makes eval-on-user-input safe -- the attack surface is the entire Python language.

```python
# BAD
def calculate(expression):
    # user submits: "__import__('os').system('rm -rf /')"
    return eval(expression)

def apply_filter(data, filter_code):
    exec(filter_code)  # arbitrary code execution
```

```python
# GOOD
import ast
import operator

SAFE_OPS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
}

def calculate(expression):
    tree = ast.parse(expression, mode="eval")
    return _eval_node(tree.body)

def _eval_node(node):
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
        return node.value
    if isinstance(node, ast.BinOp) and type(node.op) in SAFE_OPS:
        return SAFE_OPS[type(node.op)](_eval_node(node.left), _eval_node(node.right))
    raise ValueError(f"Unsupported expression: {ast.dump(node)}")
```

## Anti-pattern: Circular Import via Top-Level Import
**Severity**: warn

Placing imports at the top of a module that create circular dependencies between modules. Module A imports B at the top level, and B imports A at the top level, causing ImportError or partially initialized modules.

**Why**: Circular top-level imports cause one module to see an incomplete version of the other (attributes not yet defined). This produces AttributeError at runtime that only surfaces under specific import orderings, making it nondeterministic and hard to debug.

```python
# BAD
# models.py
from services import UserService  # circular: services.py imports models.py

class User:
    def get_service(self):
        return UserService(self)

# services.py
from models import User  # circular: models.py imports services.py

class UserService:
    def __init__(self, user: User):
        self.user = user
```

```python
# GOOD
# models.py
from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from services import UserService  # only imported for type checking

class User:
    def get_service(self) -> UserService:
        from services import UserService  # deferred import at runtime
        return UserService(self)
```

## Anti-pattern: Inconsistent Return Types
**Severity**: warn

A function that returns different types depending on the code path (e.g., sometimes a list, sometimes None, sometimes a string) without this being reflected in the type signature or documented contract.

**Why**: Callers must handle every possible return type, but without a clear union type annotation they guess wrong. Code that works in testing (where the happy path returns a list) crashes in production (where the error path returns None and the caller calls `.append()` on it).

```python
# BAD
def fetch_users(db, active_only=False):
    if not db.is_connected():
        return None  # sometimes None
    users = db.query("SELECT * FROM users")
    if active_only:
        return [u for u in users if u.active]  # sometimes list
    return users  # sometimes query result object
```

```python
# GOOD
from dataclasses import dataclass

@dataclass
class UserQueryResult:
    users: list[User]
    filtered: bool

def fetch_users(db, active_only=False) -> UserQueryResult:
    if not db.is_connected():
        raise DatabaseError("Not connected")
    users = list(db.query("SELECT * FROM users"))
    if active_only:
        users = [u for u in users if u.active]
    return UserQueryResult(users=users, filtered=active_only)
```

## Best Practice: Use dataclasses or TypedDict for Structured Data
**Severity**: info

Passing around plain dicts with implicit key conventions instead of dataclasses, TypedDict, NamedTuple, or Pydantic models for structured data. Plain dicts have no schema and no IDE support.

**Why**: Dict-based data structures have no compile-time checking, no autocompletion, and no documentation of required fields. Typos in key names silently produce KeyError at runtime. Structured types make the schema explicit and enable static analysis.

```python
# BAD
def create_user(name, email, role="viewer"):
    return {
        "name": name,
        "email": email,
        "role": role,
        "created_at": datetime.now(),
    }

user = create_user("Alice", "alice@example.com")
print(user["naem"])  # KeyError at runtime -- typo undetectable statically
```

```python
# GOOD
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class User:
    name: str
    email: str
    role: str = "viewer"
    created_at: datetime = field(default_factory=datetime.now)

user = User(name="Alice", email="alice@example.com")
print(user.name)  # IDE autocompletion, typos caught by type checker
```
