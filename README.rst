
.. image:: https://travis-ci.org/JuliaLang/DataStructures.jl.svg?branch=master
   :target: https://travis-ci.org/JuliaLang/DataStructures.jl
   :alt: Build Status
.. image:: https://img.shields.io/coveralls/JuliaLang/DataStructures.jl.svg
   :target: https://coveralls.io/r/JuliaLang/DataStructures.jl
   :alt: Coverage Status
.. image:: http://pkg.julialang.org/badges/DataStructures_release.svg
   :target: http://pkg.julialang.org/?pkg=DataStructures&ver=release
   :alt: PkgEval.jl Status

====================
DataStructures.jl
====================

This package implements a variety of data structures, including

* Deque (based on block-list)
* Stack
* Queue
* Accumulators and Counters
* Disjoint Sets
* Binary Heap
* Mutable Binary Heap
* Ordered Dicts and Sets
* Dictionaries with Defaults
* Trie
* Linked List
* Sorted Dict, Sorted Multi-Dict and Sorted Set

------
Deque
------

The ``Deque`` type implements a double-ended queue using a list of blocks. This data structure supports constant-time insertion/removal of elements at both ends of a sequence.

Usage::

  a = Deque{Int}()
  isempty(a)          # test whether the dequeue is empty
  length(a)           # get the number of elements
  push!(a, 10)        # add an element to the back
  pop!(a)             # remove an element from the back
  unshift!(a, 20)     # add an element to the front
  shift!(a)           # remove an element from the front
  front(a)            # get the element at the front
  back(a)             # get the element at the back

*Note:* Julia's ``Vector`` type also provides this interface, and thus can be used as a deque. However, the ``Deque`` type in this package is implemented as a list of contiguous blocks (default size = 2K). As a deque grows, new blocks may be created and linked to existing blocks. This way avoids the copying when growing a vector.

Benchmark shows that the performance of ``Deque`` is comparable to ``Vector`` on ``push!``, and is noticeably faster on ``unshift!`` (by about 30% to 40%).


-----------------
Stack and Queue
-----------------

The ``Stack`` and ``Queue`` types are a light-weight wrapper of a deque type, which respectively provide interfaces for FILO and FIFO access.

Usage of Stack::

  s = Stack(Int)
  push!(s, x)
  x = top(s)
  x = pop!(s)

Usage of Queue::

  q = Queue(Int)
  enqueue!(q, x)
  x = front(q)
  x = back(q)
  x = dequeue!(q)

--------------------------
Accumulators and Counters
--------------------------

A accumulator, as defined below, is a data structure that maintains an accumulated number for each key. This is a counter when the accumulated values
reflect the counts::

  type Accumulator{K, V<:Number}
      map::Dict{K, V}
  end


There are different ways to construct an accumulator/counter::

  a = accumulator(K, V)    # construct an accumulator with key-type K and
                           # accumulated value type V

  a = accumulator(dict)    # construct an accumulator from a dictionary

  a = counter(K)           # construct a counter, i.e. an accumulator with
                           # key type K and value type Int

  a = counter(dict)        # construct a counter from a dictionary

  a = counter(seq)         # construct a counter by counting keys in a sequence


Usage of an accumulator/counter::

  # let a and a2 be accumulators/counters

  a[x]             # get the current value/count for x.
                   # if x was not added to a, it returns zero(V)

  push!(a, x)       # add the value/count for x by 1
  push!(a, x, v)    # add the value/count for x by v
  push!(a, a2)      # add all counts from a2 to a1

  pop!(a, x)       # remove a key x from a, and returns its current value

  merge(a, a2)     # return a new accumulator/counter that combines the
                   # values/counts in both a and a2


--------------
Disjoint Sets
--------------

Some algorithms, such as finding connected components in undirected graph and Kruskal's method of finding minimum spanning tree, require a data structure that can efficiently represent a collection of disjoint subsets.
A widely used data structure for this purpose is the *Disjoint set forest*.

Usage::

  a = IntDisjointSets(10)      # creates a forest comprised of 10 singletons
  union!(a, 3, 5)             # merges the sets that contain 3 and 5 into one
  in_same_set(a, x, y)        # determines whether x and y are in the same set
  elem = push!(a)             # adds a single element in a new set; returns the new element
                              # (this operation is often called MakeSet)


One may also use other element types::

  a = DisjointSets{String}(["a", "b", "c", "d"])
  union!(a, "a", "b")
  in_same_set(a, "c", "d")
  push!(a, "f")


Note that the internal implementation of ``IntDisjointSets`` is based on vectors, and is very efficient. ``DisjointSets{T}`` is a wrapper of ``IntDisjointSets``, which uses a dictionary to map input elements to an internal index.


------
Heaps
------

Heaps are data structures that efficiently maintain the minimum (or maximum) for a set of data that may dynamically change.

All heaps in this package are derived from ``AbstractHeap``, and provide the following interface::

  # Let h be a heap, i be a handle, and v be a value.

  length(h)         # returns the number of elements

  isempty(h)        # returns whether the heap is empty

  push!(h, v)       # add a value to the heap

  top(h)            # return the top value of a heap

  pop!(h)           # removes the top value, and returns it

Mutable heaps (values can be changed after being pushed to a heap) are derived from
``AbstractMutableHeap <: AbstractHeap``, and additionally provides the following interface::

  i = push!(h, v)       # adds a value to the heap and and returns a handle to v

  update!(h, i, v)      # updates the value of an element (referred to by the handle i)


Currently, both min/max versions of binary heap (type ``BinaryHeap``) and mutable binary heap (type ``MutableBinaryHeap``) have been implemented.

Examples of constructing a heap::

  h = binary_minheap(Int)
  h = binary_maxheap(Int)            # create an empty min/max binary heap of integers

  h = binary_minheap([1,4,3,2])
  h = binary_maxheap([1,4,3,2])      # create a min/max heap from a vector

  h = mutable_binary_minheap(Int)
  h = mutable_binary_maxheap(Int)    # create an empty mutable min/max heap

  h = mutable_binary_minheap([1,4,3,2])
  h = mutable_binary_maxheap([1,4,3,2])    # create a mutable min/max heap from a vector


---------------------
Functions using heaps
---------------------

Heaps can be used to extract the largest or smallest elements of an array
without sorting the entire array first::

  nlargest(3, [0,21,-12,68,-25,14]) # => [68,21,14]
  nsmallest(3, [0,21,-12,68,-25,14]) # => [-25,-12,0]

``nlargest(n, a)`` is equivalent to ``sort(a, lt = >)[1:min(n, end)]``, and
``nsmallest(n, a)`` is equivalent to ``sort(a, lt = <)[1:min(n, end)]``.

-----------------------------
OrderedDicts and OrderedSets
-----------------------------

``OrderedDicts`` are simply dictionaries whose entries have a
particular order.  For ``OrderedDicts`` (and ``OrderedSets``), order
refers to *insertion order*, which allows deterministic iteration over
the dictionary or set::

  ```julia
  d = OrderedDict(Char,Int)
  for c in 'a':'e'
      d[c] = c-'a'+1
  end
  collect(d) # => [('a',1),('b',2),('c',3),('d',4),('e',5)]

  s = OrderedSet(π,e,γ,catalan,φ)
  collect(s) # => [π = 3.1415926535897...,
             #     e = 2.7182818284590...,
             #     γ = 0.5772156649015...,
  		   #     catalan = 0.9159655941772...,
  		   #	 φ = 1.6180339887498...]

All standard ``Associative`` and ``Dict`` functions are available for
``OrderedDicts``, and all ``Set`` operations are available for
OrderedSets.

Note that to create an OrderedSet of a particular type, you must
specify the type in curly-braces::

  # create an OrderedSet of Strings
  strs = OrderedSet{String}()


----------------------------------
DefaultDict and DefaultOrderedDict
----------------------------------

A DefaultDict allows specification of a default value to return when a requested key is not in a dictionary.

While the implementation is slightly different, a ``DefaultDict`` can be thought to provide a normal ``Dict``
with a default value.  A ``DefaultOrderedDict`` does the same for an ``OrderedDict``.

Constructors::

  DefaultDict(default, kv)                        # create a DefaultDict with a default value or function,
                                                  # optionally wrapping an existing dictionary
 										         # or array of key-value pairs

  DefaultDict(KeyType, ValueType, default)        # create a DefaultDict with Dict type (KeyType,ValueType)

  DefaultOrderedDict(default, kv)                 # create a DefaultOrderedDict with a default value or function,
                                                  # optionally wrapping an existing dictionary
  							  	                # or array of key-value pairs

  DefaultOrderedDict(KeyType, ValueType, default) # create a DefaultOrderedDict with Dict type (KeyType,ValueType)


Examples using ``DefaultDict``::

  dd = DefaultDict(1)               # create an (Any=>Any) DefaultDict with a default value of 1
  dd = DefaultDict(String, Int, 0)  # create a (String=>Int) DefaultDict with a default value of 0

  d = ['a'=>1, 'b'=>2]
  dd = DefaultDict(0, d)            # provide a default value to an existing dictionary
  dd['c'] == 0                      # true
  #d['c'] == 0                      # false

  dd = DefaultOrderedDict(time)     # call time() to provide the default value for an OrderedDict
  dd = DefaultDict(Dict)            # Create a dictionary of dictionaries
                                    # Dict() is called to provide the default value
  dd = DefaultDict(()->myfunc())    # call function myfunc to provide the default value

  # create a Dictionary of type String=>DefaultDict{String, Int}, where the default of the
  # inner set of DefaultDicts is zero
  dd = DefaultDict(String, DefaultDict, ()->DefaultDict(String,Int,0))
```

Note that in the last example, we need to use a function to create each new ``DefaultDict``.
If we forget, we will end up using the same ``DefaultDict`` for all default values::

  julia> dd = DefaultDict(String, DefaultDict, DefaultDict(String,Int,0));

  julia> dd["a"]
  DefaultDict{String,Int64,Int64,Dict{K,V}}()

  julia> dd["b"]["a"] = 1
  1

  julia> dd["a"]
  ["a"=>1]


----
Trie
----

An implementation of the `Trie` data structure. This is an associative structure, with `String` keys::

  t=Trie{Int}()
  t["Rob"]=42
  t["Roger"]=24
  haskey(t,"Rob") #true
  get(t,"Rob",nothing) #42
  keys(t) # "Rob", "Roger"

Constructors::

  Trie(keys, values)                  # construct a Trie with the given keys and values
  Trie(keys)                          # construct a Trie{Nothing} with the given keys and with values = nothing
  Trie(kvs::AbstractVector{(K, V)})   # construct a Trie from the given vector of (key, value) pairs
  Trie(kvs::Associative{K, V})        # construct a Trie from the given associative structure

This package also provides an iterator ``path(t::Trie, str)`` for looping over all the nodes
encountered in searching for the given string ``str``.
This obviates much of the boilerplate code needed in writing many trie algorithms.
For example, to test whether a trie contains any prefix of a given string,
use::

  seen_prefix(t::Trie, str) = any(v -> v.is_key, path(t, str))

-----------
Linked List
-----------

A list of sequentially linked nodes. This allows efficient insertion of nodes to the front of the list::

  julia> l1 = nil()
  nil()

  julia> l2 = cons(1, l1)
  list(1)

  julia> l3 = list(2, 3)
  list(2, 3)

  julia> l4 = cat(l1, l2, l3)
  list(1, 2, 3)

  julia> l5 = map((x) -> x*2, l4)
  list(2, 4, 6)

  julia> for i in l5; print(i); end
  246

----------------------------------------
Overview of Sorted Containers
----------------------------------------

Three sorted containers are provided:
SortedDict, SortedMultiDict and SortedSet.
*SortedDict* is similar to the built-in Julia type ``Dict``
with the additional feature that the keys are stored in
sorted order and can be efficiently iterated in this order.
SortedDict is a subtype of Associative.  It is slower than ``Dict``
because looking up a key requires an O(log *n*) tree search rather than
an expected O(1) hash-table lookup time as with Dict.
SortedDict is
a parametrized type with three parameters, the key type ``K``, the
value type ``V``, and the ordering type ``O``.
SortedSet has
only keys; it is an alternative to the built-in
``Set`` container.  Internally,
SortedSet is implemented as a SortedDict in which the value type
is ``Nothing``.  
Finally, SortedMultiDict is similar to SortedDict except that each key
can be associated with multiple values.  The (key,value) pairs in
a SortedMultiDict are stored according to the sorted order for keys,
and (key,value) pairs with the same
key are stored in order of insertion. 

The containers internally use a 2-3 tree, which is a
kind of balanced tree and is described in many elementary data
structure textbooks.

The containers require two functions to compare keys: a *less-than* and
*equals* function.  With the
default ordering argument, the comparison
functions are ``isless(a,b)`` and ``isequal(a,b)`` where ``a`` and ``b``
are keys.
More details are provided below.

------------------------------
Tokens for Sorted Containers
------------------------------

The sorted container objects are accompanied by auxiliary objects
called *tokens*
defined as parameterized types ``SDToken``, ``SMDToken``, and ``SetToken``.
A token is an item that stores
the address of a single data item in the container and can be
dereferenced in time O(1).
This notion of token is similar to the concept of iterators used
by C++ standard containers.
Tokens can be explicitly advanced or regressed through the data in
the sorted order; they are implicitly advanced or regressed via
iteration loops defined below.
A token may take two 
special values:
the *before-start* value and the *past-end* value.  These
values act as lower and upper bounds
on the actual data.  The before-start token can be advanced,
while the past-end token can be regressed.  A dereferencing operation on either
leads to an error.  

A token has two parts: the first part refers to the container as a whole, and the
second part refers to the particular item.  The second part is called a
*semitoken*.  In some applications, one might need an auxiliary data structure
that contains thousands of tokens addressing the same container.  In this
case, it may be more efficient to store semitokens rather than tokens
and reconstruct the full tokens as needed.  In the current implementation,
semitokens are internally stored as integers. However, 
for the purpose of future compatibility,
the user should  not extract this internal representation;
these integers do not have any direct interpretation
in terms of the container.

----------------------------------
Constructors for Sorted Containers
----------------------------------

``SortedDict(d)``
  Argument ``d`` is an ordinary Julia dict (or any associative type)
  used to initialize the container, e.g.::

     c = SortedDict(Dict("New York" => 1788, "Illinois" => 1818))

  In this example the key-type is deduced to be ASCIIString, while the
  value-type is Int.

``SortedDict(d,o)``
  Argument ``d`` is an ordinary Julia dict (or any associative type)
  used to initialize the container and ``o`` is an optional ordering object
  used for ordering the keys.  The default value
  for ``o`` is ``Forward``.

``SortedDict(Dict{K,V}(),o)``
  Construct an empty SortedDict by explicitly specifying
  the parameters of the type.  Ordering argument ``o`` is
  optional and defaults to ``Forward``.

``SortedMultiDict(k,v,o)``
  Construct a SortedMultiDict using keys given by ``k``, values
  given by ``v`` and ordering object ``o``.  The ordering object
  defaults to ``Forward`` if not specified.  The two arguments
  ``k`` and ``v`` are 1-dimensional arrays of the same length in 
  which ``k`` holds keys and ``v`` holds the corresponding values.
  To construct an empty SortedMultiDict with given types ``K`` and
  ``V``, use
  ``SortedMultiDict(K[], V[], o)``.

``SortedSet(k,o)``
  Construct a SortedSet using keys given by ``k``,
  and ordering object ``o``.  The ordering object
  defaults to ``Forward`` if not specified.  The argumen
  ``k``is a 1-dimensional array.  To create an empty set of type ``K``,
  use ``SortedSet(K[],o)``.

Note that the code snippets in this section are based on the Julia
version 0.4.0 Dict-constructor
syntax.  There are equivalent statements for 0.3.0.


---------------------------------
Complexity of Sorted Containers
---------------------------------

In the list of functions below, the running time of the various
operations is provided.  In these running times,
*n* denotes the current size 
(number of items) in the
container at the time of the function call, and *c* denotes the
time needed to compare two keys.

--------------------------------------
Navigating the Containers 
--------------------------------------
``m[k]``
  Argument ``m`` is a SortedDict and ``k`` is a key.  In an 
  expression, this retrieves the value associated with the key
  (or ``KeyError`` if none).  On the left-hand side of an
  assignment, this assigns or
  reassigns the value associated with the key.  (For assigning and reassigning,
  see also ``insert!`` below.)  Time: O(*c* log *n*)

``find(m,k)``
  Argument ``m`` is a SortedDict and argument ``k`` is a key.
  This function returns a token that refers to the item whose key
  is ``k``, or 
  past-end marker if ``k`` is absent. Time: O(*c* log *n*)


``deref(i)``
  Argument ``i``
  is a token.  This returns the (key,value) pair 
  pointed to by the token for SortedDict and SortedMultiDict.  
  For SortedSet this returns a key.  Time: O(1)


``deref_key(i)``
  Argument ``i`` is a token for SortedMultiDict or SortedDict.  
  This returns the key pointed
  to by the token.  This functionality is available as plain ``deref``
  for SortedSet.
  Time: O(1)

``deref_value(i)``
  Argument ``i`` is a token for SortedMultiDict or SortedDict.  
  This returns the value pointed
  to by the token.
  Time: O(1)

``startof(m)``
  Argument ``m`` is SortedDict, SortedMultiDict or SortedSet.  This function
  returns the token of the first item according
  to the sorted order in the container.  If the container is empty,
  it returns the past-end token. Time: O(log *n*)

``endof(m)``
  Argument ``m`` is a SortedDict, SortedMultiDict or SortedSet.  This function
  returns the token of the last item according
  to the sorted order in the container.  If the container is empty,
  it returns the before-start token.  Time: O(log *n*)

``first(m)``
  Argument ``m`` is a SortedDict, SortedMultiDict or SortedSet  This function
  returns the first item (a ``(k,v)`` pair for SortedDict and SortedMultiDict;
  a key for SortedSet)
  according
  to the sorted order in the container.  Thus, ``first(m)`` is
  equivalent to ``deref(startof(m))``.
  It is an error to call this
  function on an empty container. Time: O(log *n*)

``last(m)``
  Argument ``m`` is a SortedDict, SortedMultiDict or SortedSet.  This function
  returns the last item (a ``(k,v)`` pair for SortedDict and SortedMultiDict; 
  a key for SortedSet)
  according
  to the sorted order in the container.  Thus, ``last(m)`` is
  equivalent to ``deref(endof(m))``.
  It is an error to call this
  function on an empty container.  Time: O(log *n*)

``pastendtoken(m)``
  Argument ``m`` is a SortedDict, SortedMultiDict or SortedSet.  This
  function returns the past-end token.  Time: O(1)

``beforestarttoken(m)``
  Argument ``m`` is a SortedDict, SortedMultiDict or SortedSet.  This
  function returns the before-start token.  Time: O(1)

``advance(i)``
  Argument   ``i`` is a token.  This function returns the token of the
  next entry in the container according to the sort order of the
  keys.  After the last item, this routine returns the past-end
  token.  It is an error to invoke this function if ``i`` is the
  past-end token.  If ``i`` is the before-start token, then this
  routine returns the token of the first item in the sort order (i.e., the
  same token returned by the ``startof`` function).
  Time: O(log *n*)

``regress(i)``
  Argument 
  ``i`` is a token.  This function returns the token of the
  previous entry in the container according to the sort order of the
  keys.  If ``i`` indexes the first item, this routine returns the before-start
  token.  It is an error to invoke this function if ``i`` is the
  before-start token.  If ``i`` is the past-end token, then this
  routine returns the token of the last item in the sort order (i.e., the
  same token returned by the ``endof`` function).
  Time: O(log *n*)

``searchsortedfirst(m,k)``
  Argument ``m`` is a SortedDict, SortedMultiDict or SortedSet and
  ``k`` is an element of the key type.  This routine returns the token
  of the first item in the container whose key is greater than or equal to
  ``k``.  If there is no such key, then the past-end token
  is returned.
  Time: O(*c* log *n*)

``searchsortedlast(m,k)``
  Argument ``m`` is a SortedDict, SortedMultiDict or SortedSet and
  ``k`` is an element of the key type.  This routine returns the token
  of the last item in the container whose key is less than or equal to
  ``k``.  If there is no such key, then the before-start token
  is returned.
  Time: O(*c* log *n*)

``searchsortedafter(m,k)``
  Argument ``m`` is a SortedDict, SortedMultiDict or SortedSet and
  ``k`` is an element of the key type.  This routine returns the token
  of the first item in the container whose key is greater than
  ``k``.  If there is no such key, then the past-end token
  is returned.
  Time: O(*c* log *n*)

``searchequalrange(m,k)``
   Argument ``m`` is a SortedMultiDict and ``k`` is an element of the
   key type.  This routine returns a pair of tokens; the first 
   of the pair is the token addressing the first item in the container
   with key ``k`` and the second is the token addressing one past the
   last item in the container with key ``k``.  If the two tokens returned
   are equal, this means that no items in the container matched key ``k``.
   Time: O(*c* log *n*)
   

--------------------------------------------
Inserting & Deleting in Sorted Containers
--------------------------------------------

``empty!(m)``
    Argument ``m`` is a SortedDict, SortedMultiDict or SortedSet.  This
    empties the container.  Time: O(1).

``insert!(m,k,v)``
  Argument ``m`` is a SortedDict or SortedMultiDict, ``k`` is a key and ``v``
  is the corresponding value.  This inserts the ``(k,v)`` pair into
  the container.  If the key is already present in a
  SortedDict or SortedSet, this overwrites
  the old value.  In the case of SortedMultiDict, no overwriting takes place
  (since SortedMultiDict allows the same key to associate with multiple values).
  In the case of SortedDict, the return
  value is a pair whose first entry is boolean and indicates whether
  the insertion was new (i.e., the key was not previously present) and
  the second entry is the token of the new entry.  In the case of SortedMultiDict,
  a token is returned (but no boolean).
  Time: O(*c* log *n*)

``insert!(m,k)``
  Argument ``m`` is a SortedSet and ``k`` is a key.
  This inserts the key into
  the container.  If the key is already present in a
  this overwrites
  the old value.  (This is not necessarily a no-op; see below for 
  remarks about the customizing the sort order.)
  The return
  value is a pair whose first entry is boolean and indicates whether
  the insertion was new (i.e., the key was not previously present) and
  the second entry is the token of the new entry. 
  Time: O(*c* log *n*)

``push!(m,k)``
  Argument ``m`` is a SortedSet and ``k`` is a key.
  This inserts the key into
  the container.  If the key is already present in a
  this overwrites
  the old value.  (This is not necessarily a no-op; see below for 
  remarks about the customizing the sort order.)
  The return
  value is ``m``.
  Time: O(*c* log *n*)


``delete!(i)``
  Argument ``i`` is a token.
  This operation deletes the item addressed by ``i``.
  It is an error to call
  this on an entry that has already been deleted or on the
  before-start or past-end tokens.  After this operation is 
  complete, ``i`` is an invalid token and cannot be used in
  any further operations.
  Time: O(log *n*)

``delete!(m,k)``
  Argument ``m`` is a SortedDict or SortedSet and
  ``k`` is a key.  This operation deletes the item
  whose key is ``k``.  It is a  ``KeyError``
  if ``k`` is not a key of an item in the container.
  After this operation is 
  complete, any token addressing the deleted item is invalid.
  Returns ``m``.
  Time: O(*c* log *n*)

``pop!(m,k)``
  Deletes the item with key ``k`` in SortedDict or SortedSet ``m`` 
  and returns
  the value that was associated with ``k`` in the
  case of SortedDict or ``k`` itself in the case of SortedSet.
  A ``KeyError`` results
  if ``k`` is not in ``m``.
  Time: O(*c* log *n*)

``pop!(m)``
  Deletes the item with first key in SortedSet ``m`` and
  returns the key.  A ``BoundsError`` results if ``m`` is empty.
  Time: O(*c* log *n*)

``m[st]``
  If ``st`` is a semitoken (extracted from a token for 
  SortedDict or SortedMultiDict ``m`` via the ``semi`` function
  below), then ``m[st]`` refers to
  the value field of the (key,value) pair that the full
  token refers to.  This expression may occur on either side of an
  assignment statement.  Time: O(1)


------------------------
Token Manipulation
------------------------

``semi(i)``
  Extracts a semitoken from a token.  The semitoken is wrapper around an integer
  (in the current implementation).  See the above discussion of semitokens.
  Time: O(1)

``container(i)``
  Extracts the container from a token.   See the above discussion.
  Time: O(1)

``assemble(m,s)``
  Here, ``m`` is a sorted container and ``s`` is a semitoken; this
  function reassembles the complete token. In other words, if ``i``
  is a valid token, then 
  ``assemble(container(i), semi(i))``
  yields ``i``.  The validity of the token returned 
  is not checked by this function.  Time: O(1)

``isless(i1,i2)``
  Here, ``i1`` and ``i2`` are tokens for the same container; this
  function determines whether the (k,v) pair addressed by
  ``i1`` precedes that of ``i2`` in the sorted order.  An error is
  thrown if ``i1`` and ``i2`` refer to different containers.
  This function compares the tokens by determining their relative
  position within the tree and without dereferencing them.  For 
  SortedDict it is mostly
  equivalent to ``lt(o, deref_key(i1), deref_key(i2))`` 
  except in the
  case that either ``i1`` or ``i2`` is the before-start or past-end token,
  in which case the latter will fail.  Which one is more efficient
  depends on the time-complexity of comparing two keys.
  Similarly, for SortedSet it is mostly equivalent to
  ``lt(o, deref(i1), deref(i2))`` .
  Time: O(log *n*)

``isequal(i1,i2)``
  Here, ``i1`` and ``i2`` are tokens for the same container; this
  function determines whether they address the same item.
  An error is
  thrown if ``i1`` and ``i2`` refer to different containers.
  Time: O(l)

``status(i1)``
  This function returns 0 if the token ``i1`` is invalid (e.g., refers to a
  deleted item), 1 if the token is valid and points to data, 2 if the
  token is the before-start token and 3 if it is the past-end token.
  Time: O(1)


--------------------------------
Iteration Over Sorted Containers
--------------------------------

As is standard in Julia, iteration over the containers is
implemented via calls to three functions, ``start``,
``next`` and ``done``.  It is usual practice, however, to
call these functions implicitly with a for-loop rather than
explicitly, so they are presented here in for-loop notation.
Internally, all of these iterations are implemented with tokens
that are advanced via the ``advance`` operation.
Each iteration
of these loops requires O(log *n*) operations to advance the
token.   If one loops over an entire container, then the amortized
cost of advancing the token drops to O(1).

The following snippet loops over the entire container ``m``, where
``m`` is a SortedDict or SortedMultiDict::

  for (k,v) in m
     < body >
  end

In this loop, ``(k,v)`` takes on successive (key,value) pairs 
according to 
the sort order of the key.  
For SortedSet one uses::

  for k in m
     < body >
  end


There are two ways to iterate over a subrange of a container.
The first is the inclusive iteration for SortedDict and SortedMultiDict::

  for (k,v) in i1 : i2
    < body >
  end

Here, ``i1`` and ``i2`` are tokens that refer to the same container.
It is acceptable for ``i1`` to be the past-end token 
or ``i2`` to be the before-start token (in these cases, the body
is not executed).
If ``isless(i2,i1)`` then the body is not executed. 

One can also define a loop that excludes the final item::

  for (k,v) in excludelast(i1,i2)
    < body >
  end

In this case, all the data addressed by tokens from ``i1`` up to but excluding
``i2`` are executed.  The body is not executed at all if ``!isless(i1,i2)``.
In this setting, either or both can be the past-end token, and ``i2`` can
be the before-start token.

Both the ``excludelast`` and colon operators return objects that can be 
saved and used later for iteration.  At the time of construction of these object,
it is checked that the start and end tokens refer to the same container.
The validity of the tokens is not checked until the loop initiates.

For SortedSet the usage is::

  for k in i1 : i2
    < body >
  end

  for k in excludelast(i1,i2)
    < body >
  end


If ``m`` is a SortedDict or SortedMultiDict,
one can iterate over just keys or just values::

   for k in keys(m)
      < body >
   end

   for v in values(m)
      < body >
   end


Finally, one can retrieve tokens during any of these iterations.  In the case
of SortedDict and SortedMultiDict, one uses::

   for (t,(k,v)) in tokens(m)
       < body >
   end

   for (t,k) in tokens(keys(m))
       < body >
   end

   for (t,v) in tokens(values(m))
       < body >
   end

In each successive iteration, ``t`` is a token referring to the 
current ``(k,v)`` pair.  
In the case of SortedSet, the following iteration may be used::

   for (t,k) in tokens(m)
       < body >
   end

In place of ``m`` in the above ``keys``, ``values`` and
``tokens``, snippets,
one could also use ``i1:i2`` or ``excludelast(i1,i2)``.

Note that it is acceptable for the loop body in the above
``tokens`` code snippets to invoke
``delete!(t)``.  This is because the for-loop internal state variable
is already advanced to the next token at the beginning of the body, so
``t`` is not necessarily referred to in the loop body (unless the
user refers to it).


----------------
Other Functions
----------------

``isempty(m)``
  Returns ``true`` if the container is empty (no items).
  Time: O(1)

``length(m)``
  Returns the length, i.e., number of items, in the container.
  Time: O(1)

``in(p,m)``
  Returns true if ``p`` is in ``m``.  In the
  case that ``m`` is a SortedDict or SortedMultiDict,
  ``p`` is a (key,value) pair.  In the case that ``m``
  is a SortedSet, ``p`` should be a key.
  Time: O(*c* log *n*) for SortedDict and SortedSet.
  In the case of SortedMultiDict, the time is
  O(*cl* log *n*), where *l* stands for the number
  of entries that have the key of the given pair.
  (So therefore this call is inefficient if the same key
  addresses a large number of values, and an alternative
  should be considered.)

``eltype(m)``
  Returns the (key,value) type (a pair of types)
  for SortedDict and SortedMultiDict.
  Returns the key type for SortedSet.
  Time: O(1)

``orderobject(m)``
  Returns the order object used to construct the container.  Time: O(1)

``haskey(m,k)``
  Returns true if ``k`` is present for SortedDict, SortedMultiDict
  or SortedSet ``m``.  For SortedSet, ``haskey(m,k)`` is
  a synonym for ``in(k,m)``.
  Time: O(*c* log *n*)


``get(m,k,v)``
  Returns the value associated with key ``k`` where ``m`` is a SortedDict,
  or else returns ``v`` if ``k`` is not in ``m``.
  Time: O(*c* log *n*)

``get!(m,k,v)``
  Returns the value associated with key ``k`` where ``m`` is a SortedDict,
  or else returns ``v`` if ``k`` is not in ``m``, and in the latter case,
  inserts ``(k,v)`` into ``m``.
  Time: O(*c* log *n*)

``getkey(m,k,defaultk)``
  Returns key ``k`` where ``m`` is a SortedDict, if ``k`` is in ``m``
  else it returns ``defaultk``. 
  If the container uses in its ordering
  an ``eq`` method different from
  isequal (e.g., case-insensitive ASCII strings illustrated below), then the
  return value is the actual key stored in the SortedDict that is equivalent
  to ``k`` according to the ``eq`` method, which might not be equal to ``k``.
  Similarly, if the user performs an implicit conversion as part of the
  call (e.g., the container has keys that are floats, but the ``k`` argument
  to ``getkey`` is an Int), then the returned key is the actual stored
  key rather than ``k``.
  Time: O(*c* log *n*)


``isequal(m1,m2)``
  Checks if two containers are equal in the sense
  that they contain the same items; the keys are compared
  using the ``eq`` method, while the values are compared with
  the ``isequal`` function.   In the case of SortedMultiDict,
  equality requires that the values associated with a particular
  key have same order (that is, the same insertion order).
  Note that ``isequal`` in this sense
  does not imply any correspondence between semitokens for items
  in ``m1`` with those for ``m2``.  If the equality-testing method associated
  with the keys and values implies hash-equivalence in the
  case of SortedDict, then ``isequal`` of the 
  entire containers implies hash-equivalence of the containers.
  Time: O(*cn* + *n* log *n*)

``packcopy(m)``
  This returns a copy of ``m`` in which the data is
  packed.  When deletions take
  place, the previously allocated memory is not returned.
  This function can be used to reclaim memory after
  many deletions.  
  Time: O(*cn* log *n*)

``deepcopy(m)``
  This returns a copy of ``m`` in which the data is
  deep-copied, i.e., the keys and values are replicated
  if they are mutable types.  A semitoken for the original ``m``
  can be composed with the deep-copy output to make a valid 
  token for the copy because this operation preserves the
  relative positions of the data in memory.
  Time O(*maxn*), where *maxn* denotes the maximum size
  that ``m`` has attained in the past.

``packdeepcopy(m)``
  This returns a packed copy of ``m`` in which the keys
  and values are deep-copied.
  This function can be used to reclaim memory after
  many deletions.  
  Time: O(*cn* log *n*)


``merge(s, t...)``
  This returns a SortedDict or SortedMultiDict that results from merging
  SortedDicts or SortedMultiDicts``s``, ``t``, etc., which all must have the same
  key-value-ordering types.  In the case of keys duplicated among
  the arguments, the rightmost argument that owns the
  key gets its value stored for SortedDict. In the case of SortedMultiDict
  all the key-value pairs are stored, and for  keys shared between ``s`` and ``t`` the
  ordering is left-to-right.  This function is not available for SortedSet,
  but the ``union`` function (see below) provides equivalent functionality.
  Time:  O(*cN* log *N*), where *N* is the total size
  of all the arguments.

``merge!(s, t...)``
  This updates ``s`` by merging
  SortedDicts or SortedMultiDicts ``t``, etc. into ``s``.
  These must all must have the same
  key-value types.  In the case of keys duplicated among
  the arguments, the rightmost argument that owns the
  key gets its value stored for SortedDict.
  In the case of SortedMultiDict
  all the key-value pairs are stored, and for overlapping keys the
  ordering is left-to-right.  This function is not available for SortedSet,
  but the ``union!`` function (see below) provides equivalent functionality.
  Time:  O(*cN* log *N*), where *N* is the total size
  of all the arguments.

----------------------
Set operations
----------------------

The SortedSet container supports the following set operations.  Note that
in the case of intersect, symdiff and setdiff, the two SortedSets should
have the same key and ordering object.  If they have different key or ordering
types, no error
message is produced; instead, the built-in default versions of these functions
(that can be applied to ``Any`` iterables and that return arrays) are invoked.


``union!(m, iterable)``
  This function inserts each item from the second argument
  (which must iterable) into the SortedSet ``m``.  The items
  must be convertible to the key-type of ``m``.
  Time: O(*ci* log *n*) where *i* is the number of items
  in the iterable argument.

``union(m, iterable...)``
  This function creates a new SortedSet (the return argument) and
  inserts each item from ``m`` and each item from each iterable argument
  into the returned SortedSet.  Time:  O(*cn* log *n*) where *n* is the
  total number of items in all the arguments.
   
``intersect(m, others...)``
  Each argument is a SortedSet with the same key and order type.
  The return variable is a new SortedSet that is the intersection of
  all the sets that are input.  Time: O(*cn* log *n*), where *n* is the
  total number of items in all the arguments.

``symdiff(m1, m2)``
  The two argument are sorted sets with the same key and order type.  This operation
  computes the symmetric difference, i.e., a sorted set containing
  entries that are in one of
  ``m1``, ``m2`` but not both.  
  Time: O(*cn* log *n*), where *n* is the
  total size of the two containers.  

``setdiff(m1, m2)``
  The two arguments are sorted sets with the same key and order type.  This operation
  computes the difference, i.e., a sorted set containing entries that in
  are in ``m1`` but not ``m2``.  
  Time: O(*cn* log *n*), where *n* is the
  total size of the two containers.  

``setdiff!(m1, iterable)``
  This function deletes items in ``m1`` that appear in the second argument.
  The second argument must be iterable and its entries must be
  convertible to the key type of m1.
  Time: O(*cm* log *n*), where *n* is the size of ``m1`` and *m* is
  the number of items in ``iterable``.

``issubset(iterable, m1)``
  This function checks whether each item of the first argument
  is an element of the SortedSet ``m1``.  The entries must be
  convertible to the key-type of ``m1``.  Time: O(*cm* log *n*), where
  *n* is the sizes of ``m1`` and *m* is the number of items in ``iterable``.


----------------------
Ordering of keys
----------------------
As mentioned earlier, the default ordering of keys uses 
``isless`` and ``isequal`` functions.  If the default ordering is used,
it is a requirement of the container that ``isequal(a,b)`` is true if and
only if ``!isless(a,b)`` and ``!isless(b,a)`` are both true.  This relationship
between ``isequal`` and ``isless`` holds for common built-in types, but
it may not hold for all types, especially user-defined types.
If it does not hold for a certain type, then a custom ordering
argument must be defined as discussed in the next few paragraphs.

The name for the default ordering (i.e., using ``isless`` and
``isequal``) is ``Forward``.  Another possible
choice is ``Reverse``, which reverses the usual sorted order.  
This name must be
imported ``import Base.Reverse`` if it is used.

As an example of a custom ordering, suppose the keys
are of type ``ASCIIString``, and the user wishes to order the keys ignoring
case: *APPLE*, *berry* and *Cherry* would appear in that
order, and *APPLE* and *aPPlE* would be indistinguishable in this
ordering.

The simplest approach is to define an ordering object
of the form ``Lt(my_isless)``, where ``Lt`` is a built-in type
(see ``ordering.jl``) and ``my_isless`` is the user's comparison function.
In the above example, the ordering object would be::

     Lt((x,y) -> isless(lowercase(x),lowercase(y)))

The ordering object is the second argument to
the ``SortedDict`` and ``SortedSet``  constructors, or the
third argument to the ``SortedMultiDict`` constructor 
(see above for constructor syntax).

This approach suffers from a performance hit (10%-50% depending on the
container) because the compiler cannot inline or compute the
correct dispatch for the function in parentheses, so the dispatch
takes place at run-time.
A more complicated but higher-performance method to implement
a custom ordering is as follows.
First, the user creates a singleton type that is a subtype of
``Ordering`` as follows::

    immutable CaseInsensitive <: Ordering
    end

Next, the user defines a method named ``lt`` for less-than 
in this ordering::

    lt(::CaseInsensitive, a, b) = isless(lowercase(a), lowercase(b))

The first argument to ``lt`` is an object of the ``CaseInsensitive``
type (there is only one such object since it is a singleton type).
The container also needs an equal-to function; the default is::

    eq(o::Ordering, a, b) = !lt(o, a, b) && !lt(o, b, a)

For a further slight performance boost, the user can also customize 
this function with a more efficient
implementation.  In the above example, an appropriate customization would
be::

    eq(::CaseInsensitive, a, b) = isequal(lowercase(a), lowercase(b))

Finally, the user specifies the unique element of ``CaseInsensitive``, namely
the object ``CaseInsensitive()``, as the ordering object to the
``SortedDict`` constructor.

For the above code to work, the module must make the following declarations,
typically near the beginning::

    import Base.Ordering
    import Base.lt
    import DataStructures.eq

--------------------------------
Cautionary note on mutable keys
--------------------------------
As with ordinary Dicts, keys for the sorted containers
can be either mutable or immutable.  In the
case of mutable keys, it is important that the keys not be mutated
once they are in the container else the indexing structure will be 
corrupted. (The same restriction applies to Dict.)
For example, suppose a SortedDict ``m`` is defined in which the
keys are of type ``Array{Int,1}.``  (For this to be possible, the user
must provide an ``isless`` function or order object for ``Array{Int,1}`` since
none is built into Julia.)  Suppose the values of ``m`` are of type ``Int``.
Then the following sequence of statements leaves ``m`` in
a corrupted state::

   a = [1,2,3]
   m[a] = 19
   a[1] = 7


-----------------------------------
Performance of Sorted Containers
-----------------------------------

The sorted containers are currently not optimized for cache performance.
This will be addressed in the future.

There is a minor performance issue as follows:
the container may hold onto a small number of keys and values even after the
data records containing those keys and values have been deleted.  This
may cause a memory drain in the case of large keys and values.
It may also lead to a
delay
in the invocation of finalizers.
All keys and values are released completely by the ``empty!`` function.
