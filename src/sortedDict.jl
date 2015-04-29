## A SortedDict is a wrapper around balancedTree with
## methods similiar to those of Julia container Dict.


type SortedDict{K, D, Ord <: Ordering} <: Associative{K,D}
    bt::BalancedTree23{K,D,Ord}
end

typealias SDSemiToken IntSemiToken

immutable SDToken{K,D,Ord <: Ordering} <: Token{SortedDict{K,D,Ord}, SDSemiToken}
    container::SortedDict{K,D,Ord}
    semitoken::SDSemiToken
end

assemble(m::SortedDict, s::SDSemiToken) = SDToken(m,s)


## This constructor takes an ordering object which defaults
## to Forward

function SortedDict{K,D, Ord <: Ordering}(d::Associative{K,D}, o::Ord=Forward)
    bt1 = BalancedTree23{K,D,Ord}(o)
    for pr in d
        insert!(bt1, pr[1], pr[2], false)
    end
    SortedDict(bt1)
end

## This function implements m[k]; it returns the
## data item associated with key k.

function getindex{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    !exactfound && throw(KeyError(k_))
    return m.bt.data[i].d
end


## This function implements m[k]=d; it sets the 
## data item associated with key k equal to d.

function setindex!{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, d_, k_)
    insert!(m.bt, convert(K,k_), convert(D,d_), false)
    m
end

## Functions setindex! and getindex for semitokens:

function getindex{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, i::SDSemiToken)
    addr = i.address
    has_data(SDToken{K,D,Ord}(m,i))
    return m.bt.data[addr].d
end

function setindex!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                        d_, 
                                        i::SDSemiToken)
    addr = i.address
    has_data(SDToken{K,D,Ord}(m,i))
    m.bt.data[addr] = KDRec{K,D}(m.bt.data[addr].parent,
                                 m.bt.data[addr].k, 
                                 convert(D,d_))
    m
end


sdtoken_construct{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord},int1::Int) = 
    SDToken{K,D,Ord}(m, SDSemiToken(int1))

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.
        
function find{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    ll, exactfound = findkey(m.bt, convert(K,k_))
    sdtoken_construct(m, exactfound? ll : 2)
end

## This function inserts an item into the tree.
## Unlike m[k]=d, it also returns a bool and a token.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The token points to the newly inserted item.

function insert!{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, d_)
    b, i = insert!(m.bt, convert(K,k_), convert(D,d_), false)
    b, sdtoken_construct(m, i)
end


## First and last return the first and last (key,data) pairs
## in the SortedDict.  It is an error to invoke them on an
## empty SortedDict.


function first(m::SortedDict)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    return m.bt.data[i].k, m.bt.data[i].d
end

function last(m::SortedDict)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return m.bt.data[i].k, m.bt.data[i].d
end

## Function deref(ii), where ii is a token, returns the
## (k,d) pair indexed by ii.

function deref{K, D, Ord <: Ordering}(ii::SDToken{K,D,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].k, 
           ii.container.bt.data[ii.semitoken.address].d
end

## Function deref_key(ii), where ii is a token, returns the
## key indexed by ii.

function deref_key{K, D, Ord <: Ordering}(ii::SDToken{K,D,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].k
end

## Function deref_value(ii), where ii is a token, returns the
## value indexed by ii.

function deref_value{K, D, Ord <: Ordering}(ii::SDToken{K,D,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].d
end

## This function takes a key and returns the token
## of the first item in the tree that is >= the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedfirst{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    sdtoken_construct(m, exactfound? i : nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the first item in the tree that is > the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedafter{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    sdtoken_construct(m, nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the last item in the tree that is <= the given
## key in the sorted order.  It returns the before-start marker
## if there is none.

function searchsortedlast{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    sdtoken_construct(m, i)
end


function in{K,D,Ord <: Ordering}(pr::(@compat Tuple{Any,Any}), m::SortedDict{K,D,Ord})
    i, exactfound = findkey(m.bt,convert(K,pr[1]))
    return exactfound && isequal(m.bt.data[i].d,convert(D,pr[2]))
end

eltype{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}) = (K,D)

orderobject(m::SortedDict) = m.bt.ord

function haskey{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    exactfound
end

function get{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, default_)
    i, exactfound = findkey(m.bt, convert(K,k_))
   return exactfound? m.bt.data[i].d : convert(D,default_)
end


function get!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, default_)
    k = convert(K,k_)
    i, exactfound = findkey(m.bt, k)
    if exactfound
        return m.bt.data[i].d
    else
        default = convert(D,default_)
        insert!(m.bt,k, default, false)
        return default
    end
end


function getkey{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, default_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    exactfound? m.bt.data[i].k : convert(K,default_)
end

## Function delete! deletes an item at a given 
## key

function delete!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    !exactfound && throw(KeyError(k_))
    delete!(m.bt, i)
    m
end

function pop!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    !exactfound && throw(KeyError(k_))
    d = m.bt.data[i].d
    delete!(m.bt, i)
    d
end


## Check if two SortedDicts are equal in the sense of containing
## the same (K,D) pairs.  This sense of equality does not mean
## that semitokens valid for one are also valid for the other.

function isequal(m1::SortedDict, m2::SortedDict)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2)) || !isequal(eltype(m1), eltype(m2))
        error("Cannot use isequal for two SortedDicts unless their element types and ordering objects are equal")
    end
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendtoken(m1)
            return p2 == pastendtoken(m2)
        end
        if p2 == pastendtoken(m2)
            return false
        end
        k1,d1 = deref(p1)
        k2,d2 = deref(p2)
        if !eq(ord,k1,k2) || !isequal(d1,d2)
            return false
        end
        p1 = advance(p1)
        p2 = advance(p2)
    end
end


function mergetwo!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                        m2::Associative{K,D})
    for (k,v) in m2
        m[convert(K,k)] = convert(D,v)
    end
end

function packcopy{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    w = SortedDict(Dict{K,D}(),orderobject(m))
    mergetwo!(w,m)
    w
end

function packdeepcopy{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    w = SortedDict(Dict{K,D}(),orderobject(m))
    for (k,v) in m
        newk = deepcopy(k)
        newv = deepcopy(v)
        w[newk] = newv
    end
    w
end


function merge!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                     others::Associative{K,D}...)
    for o in others
        mergetwo!(m,o)
    end
end

function merge{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                    others::Associative{K,D}...)
    result = packcopy(m)
    merge!(result, others...)
    result
end



