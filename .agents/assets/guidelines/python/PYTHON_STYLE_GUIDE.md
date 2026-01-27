# Google Developer Documentation Style Guide (for Codex reference)

This document captures core principles and conventions from the Google Developer Documentation Style Guide, plus added guidance for writing NumPy-style Python docstrings (numpydoc). It’s meant as a quick, practical reference.

Primary source: Google Developer Documentation Style Guide: https://developers.google.com/style

NumPy docstring source references:
- numpydoc Style guide: https://numpydoc.readthedocs.io/en/latest/format.html
- NumPy documentation how-to: https://numpy.org/doc/1.19/docs/howto_document.html

---

## 1. Purpose & scope (Google dev docs)

- Write for clarity and consistency for developers and technical readers.  
- Treat guidance as a baseline; follow project-specific rules when they exist.
- Guidelines are not laws. If a rule makes the doc worse, don’t follow it.

Decision precedence:
1) Project style  
2) Google dev docs style  
3) External references (dictionary/style manuals)

---

## 2. Voice & tone (Google dev docs)

- Prefer active voice.
- Be concise and direct.
- Use second person (“you”) when it makes instructions clearer.
- Avoid idioms and culture-specific jokes (yes, even the good ones).

---

## 3. Word choice & grammar (Google dev docs)

- Use simple, unambiguous terms.
- Be consistent with terminology, UI names, and command names.
- Use inclusive language (for example, singular “they” where appropriate).

---

## 4. Headings & structure (Google dev docs)

- Use sentence case headings.
- Headings should help navigation, not be clever.
- Avoid links in headings.

---

## 5. Formatting conventions (Google dev docs)

- Use ordered lists when sequence matters.
- Use descriptive link text (not raw URLs).
- Provide meaningful alt text for images.

---

## 6. NumPy-style docstrings for Python (numpydoc)

These rules apply when Codex writes or edits Python docstrings intended to follow the NumPy/SciPy ecosystem conventions. The goal is docstrings that render well with numpydoc and read well in terminals and editors.  
Source: numpydoc format guide. https://numpydoc.readthedocs.io/en/latest/format.html

### 6.1 Overall shape (functions and methods)

Use this section order (common pattern):

1. **Short summary** (one line)
2. **Extended summary** (optional, a short paragraph or two)
3. **Parameters**
4. **Returns** or **Yields**
5. **Other Parameters** (optional)
6. **Raises** (optional but recommended when relevant)
7. **See Also** (optional)
8. **Notes** (optional)
9. **References** (optional)
10. **Examples** (optional but valuable)

Generators should use **Yields** instead of **Returns**.  
Source: NumPy doc how-to. https://numpy.org/doc/1.19/docs/howto_document.html

### 6.2 Short summary rules

- One sentence, imperative is fine: “Compute X”, “Return Y”, “Draw Z”.
- No leading “This function…”, unless needed for clarity.
- Keep it short: users see this in help() and tooltips.

### 6.3 Section header formatting

Section headers are plain text followed by an underline of hyphens:

Parameters

No colon, no Markdown header syntax inside the docstring (triple-quotes hold plain text).

### 6.4 Parameters section

Format each parameter like:

name : type
Description…

Rules of thumb:
- Use **4-space indentation** for description lines.
- Types should be informative but not over-precise to the point of lying.
- Include “optional” for optional parameters.
- If there are allowed values, state them in the description, often as:
  - “{‘a’, ‘b’, ‘c’}” for a small enumerated set
  - “If X, then …” rules for behavior changes

Example:

axis : int or None, optional
Axis along which to compute. If None, compute over the flattened array.

### 6.5 Returns and Yields sections

Format:

Returns

out : ndarray
Description…

If a function returns a single value and naming it adds no value, you can omit the name:

Returns

ndarray
Description…

Use **Yields** for generators.  
Source: numpydoc format guide. https://numpydoc.readthedocs.io/en/latest/format.html

### 6.6 Other Parameters section

Use **Other Parameters** to keep the main Parameters list focused when there are rarely-used keyword args. If you introduce `**kwargs`, document the relevant keywords there too.  
Source example notes: https://numpydoc.readthedocs.io/en/latest/example.html

Example:

Other Parameters

only_seldom_used_keyword : int, optional
Infrequently used parameter described here to avoid clutter.
**kwargs : dict
Other infrequently used keyword arguments. Document supported keys here.

### 6.7 Raises section

List exceptions that are meaningfully part of the contract, not every possible runtime failure.

Raises

ValueError
If axis is out of range.
TypeError
If x is not array_like.

### 6.8 See Also section

Use for related APIs and close neighbors:

See Also

numpy.sum : Sum of array elements.
numpy.mean : Mean of array elements.

Keep it curated, not a dumping ground.

### 6.9 Notes section

Use Notes for:
- algorithm details
- performance caveats
- numerical stability
- edge-case behavior that would clutter the main description

Be specific. If you can’t be specific, it probably belongs nowhere.

### 6.10 Examples section

Prefer doctest-like examples with `>>>` prompts.

- Keep examples runnable when feasible.
- Show the common case first.
- Don’t assume hidden imports; include `import numpy as np` when relevant.

### 6.11 Class docstrings (numpydoc)

Class docstrings generally follow the same structure as functions, but typically include:

- Summary/Extended summary
- Parameters (for `__init__` constructor parameters)
- Attributes (for public data attributes)
- Methods (optional, if listing key methods is helpful)

Attributes section format:

Attributes

x : float
The X coordinate.
y : float
The Y coordinate.

Properties that have their own docstrings can be listed by name alone.  
Source: numpydoc class guidance. https://numpydoc.readthedocs.io/en/latest/format.html

### 6.12 Method docstrings vs function docstrings

If a method has an equivalent top-level function, put the detailed docs on the function and keep the method docstring brief, often just:
- a short summary
- a See Also pointing to the function
- Returns or Yields (as appropriate)

Do not include `self` in Parameters.  
Source: NumPy doc how-to. https://numpy.org/doc/1.19/docs/howto_document.html

### 6.13 What Codex should do when editing code

When generating or refactoring Python:

- If adding a new public function/method, add a NumPy-style docstring unless the project explicitly says otherwise.
- Keep docstrings correct with respect to:
  - parameter names and defaults
  - return types and shapes
  - exceptions actually raised by the public contract
- If changing signature or behavior, update docstring sections in the same change.
- Avoid “TODO: document” docstrings. Either document or omit until ready.

---

## 7. Quick docstring template (copy/paste)

```python
def func(x, y=None, *, axis=0):
    """
    One-line summary of what this does.

    Extended summary that explains the behavior, constraints, and any
    important context.

    Parameters
    ----------
    x : array_like
        Main input.
    y : array_like or None, optional
        Optional second input.
    axis : int, optional
        Axis along which to operate.

    Returns
    -------
    out : ndarray
        The result.

    Raises
    ------
    ValueError
        If `axis` is invalid.

    See Also
    --------
    related_func : Short description.

    Notes
    -----
    Any algorithm/performance/numerical details.

    Examples
    --------
    >>> import numpy as np
    >>> func(np.array([1, 2, 3]))
    array([ ... ])
    """
    ...