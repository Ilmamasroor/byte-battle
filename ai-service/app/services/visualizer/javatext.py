"""Tiny, dependency-free Java text utilities: comment/string cleaning and a
brace/statement parser good enough for teaching snippets (not a full grammar)."""
import bisect
import re
from dataclasses import dataclass, field
from typing import List, Optional, Tuple

WORD_RE = re.compile(r"[A-Za-z_$][\w$]*")


def clean(src: str) -> str:
    """Blank out comments and string/char literal contents, preserving length
    and newlines so offsets and line numbers stay identical to the source."""
    out: List[str] = []
    i, n = 0, len(src)
    while i < n:
        if src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(re.sub(r"[^\n]", " ", src[i:j]))
            i = j
        elif src.startswith('"""', i):
            j = src.find('"""', i + 3)
            j = n if j < 0 else j + 3
            out.append('"""' + re.sub(r"[^\n]", " ", src[i + 3 : max(i + 3, j - 3)]) + ('"""' if j - i >= 6 else ""))
            i = j
        elif src[i] in "\"'":
            q = src[i]
            j = i + 1
            while j < n and src[j] != q and src[j] != "\n":
                j += 2 if src[j] == "\\" else 1
            j = min(j, n)
            body = src[i + 1 : j]
            out.append(q + " " * len(body) + (q if j < n and src[j] == q else ""))
            i = j + 1 if j < n and src[j] == q else j
        else:
            out.append(src[i])
            i += 1
    res = "".join(out)
    return res[:n].ljust(n)


class LineMap:
    def __init__(self, text: str) -> None:
        self.starts = [0] + [m.end() for m in re.finditer(r"\n", text)]

    def line(self, offset: int) -> int:
        return bisect.bisect_right(self.starts, max(0, offset))


def match_close(text: str, i: int) -> int:
    """Index of the bracket closing text[i] (any of ([{), or -1."""
    depth = 0
    for j in range(i, len(text)):
        ch = text[j]
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
            if depth == 0:
                return j
    return -1


def skip_ws(text: str, i: int, end: int) -> int:
    while i < end and text[i].isspace():
        i += 1
    return i


@dataclass
class Node:
    kind: str  # simple|block|if|for|while|do|try|switch|sync|decl
    text: str = ""
    start: int = 0
    end: int = 0
    body: List["Node"] = field(default_factory=list)
    orelse: Optional[List["Node"]] = None
    finally_body: Optional[List["Node"]] = None
    body_span: Optional[Tuple[int, int]] = None  # for 'decl'


def _expression_brace(head: str) -> bool:
    return bool("=" in head or "->" in head or re.search(r"\bnew\b", head) or re.search(r"\breturn\b", head))


def _scan_simple(text: str, i: int, end: int) -> Tuple[Node, int]:
    depth = 0
    j = i
    while j < end:
        ch = text[j]
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        elif ch == "{":
            k = match_close(text, j)
            if k < 0 or k >= end:
                k = end - 1
            if depth == 0 and not _expression_brace(text[i:j]):
                return Node("decl", text[i:j].strip(), i, k + 1, body_span=(j + 1, k)), k + 1
            j = k + 1
            continue
        elif ch == ";" and depth <= 0:
            return Node("simple", text[i:j].strip(), i, j + 1), j + 1
        j += 1
    return Node("simple", text[i:end].strip(), i, end), end


def _paren(text: str, p: int, end: int) -> Tuple[str, int]:
    q = match_close(text, p)
    if q < 0 or q >= end:
        q = end - 1
    return text[p + 1 : q], q + 1


def _body(text: str, i: int, end: int) -> Tuple[List[Node], int]:
    i = skip_ws(text, i, end)
    if i >= end:
        return [], end
    if text[i] == "{":
        k = match_close(text, i)
        if k < 0 or k >= end:
            k = end - 1
        return parse_statements(text, i + 1, k), k + 1
    node, j = parse_one(text, i, end)
    return ([node] if node else []), j


def parse_one(text: str, i: int, end: int) -> Tuple[Optional[Node], int]:
    c = text[i]
    if c == ";":
        return None, i + 1
    if c == "{":
        k = match_close(text, i)
        if k < 0 or k >= end:
            k = end - 1
        return Node("block", "", i, k + 1, body=parse_statements(text, i + 1, k)), k + 1
    m = WORD_RE.match(text, i)
    word = m.group(0) if m else ""
    p = skip_ws(text, m.end(), end) if m else i
    has_paren = p < end and text[p] == "("

    if word in ("if", "while", "for", "switch", "synchronized") and has_paren:
        head, after = _paren(text, p, end)
        if word == "if":
            body, k = _body(text, after, end)
            node = Node("if", head.strip(), i, k, body=body)
            k2 = skip_ws(text, k, end)
            if text.startswith("else", k2) and not (k2 + 4 < end and (text[k2 + 4].isalnum() or text[k2 + 4] == "_")):
                node.orelse, k = _body(text, k2 + 4, end)
                node.end = k
            return node, k
        if word in ("while", "for"):
            body, k = _body(text, after, end)
            return Node(word, head.strip(), i, k, body=body), k
        if word == "synchronized":
            body, k = _body(text, after, end)
            return Node("sync", head.strip(), i, k, body=body), k
        # switch
        body, k = _body(text, after, end)
        return Node("switch", head.strip(), i, k, body=body), k

    if word == "do":
        body, k = _body(text, m.end(), end)
        k2 = skip_ws(text, k, end)
        head = ""
        if text.startswith("while", k2):
            pp = skip_ws(text, k2 + 5, end)
            if pp < end and text[pp] == "(":
                head, k = _paren(text, pp, end)
                k = skip_ws(text, k, end)
                if k < end and text[k] == ";":
                    k += 1
        return Node("do", head.strip(), i, k, body=body), k

    if word == "try":
        k = m.end()
        kp = skip_ws(text, k, end)
        if kp < end and text[kp] == "(":
            _, k = _paren(text, kp, end)
        body, k = _body(text, k, end)
        node = Node("try", "", i, k, body=body)
        while True:
            k2 = skip_ws(text, k, end)
            if text.startswith("catch", k2):
                pp = skip_ws(text, k2 + 5, end)
                if pp < end and text[pp] == "(":
                    _, k3 = _paren(text, pp, end)
                    _, k = _body(text, k3, end)
                    continue
            if text.startswith("finally", k2):
                node.finally_body, k = _body(text, k2 + 7, end)
                continue
            break
        node.end = k
        return node, k

    return _scan_simple(text, i, end)


def parse_statements(text: str, i: int, end: int) -> List[Node]:
    nodes: List[Node] = []
    while True:
        i = skip_ws(text, i, end)
        if i >= end:
            break
        node, j = parse_one(text, i, end)
        if node is not None:
            nodes.append(node)
        i = max(j, i + 1)
    return nodes


def walk_nodes(nodes: List[Node]):
    """Yield every node depth-first (statement bodies only)."""
    for n in nodes:
        yield n
        yield from walk_nodes(n.body)
        if n.orelse:
            yield from walk_nodes(n.orelse)
        if n.finally_body:
            yield from walk_nodes(n.finally_body)


def split_top_level(text: str, sep: str = ",") -> List[str]:
    parts, depth, cur = [], 0, []
    for ch in text:
        if ch in "([{<" and ch != "<":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == sep and depth == 0:
            parts.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    parts.append("".join(cur))
    return [p.strip() for p in parts]
