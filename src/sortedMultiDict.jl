# A SortedMultiDict is a wrapper around balancedTree.
## Unlike SortedDict, a key in SortedMultiDict can
## refer to multiple data entries.

type SortedMultiDict{K, D, Ord <: Ordering}
    bt::BalancedTree23{K,D,Ord}
end


typealias SMDSemiToken IntSemiToken

immutable SMDToken{K,D,Ord <: Ordering} <: Token{SortedDict{K,D,Ord}, SMDSemiToken}
    container::SortedMultiDict{K,D,Ord}
    semitoken::SMDSemiToken
end

assemble(m::SortedMultiDict, s::SMDSemiToken) = SMDToken(m,s)


## This constructor takes an ordering object which defaults
## to Forward

function SortedMultiDict{K,D, Ord <: Ordering}(kk::AbstractArray{K,1},
                                               dd::AbstractArray{D,1}, 
                                               o::Ord=Forward)
    bt1 = BalancedTree23{K,D,Ord}(o)
    if length(kk) != length(dd)
        throw(ArgumentError("SortedMultiDict K and D constructor array arguments must be the same length"))
    end
    for i = 1 : length(kk)
        insert!(bt1, kk[i], dd[i], true)
    end
    SortedMultiDict(bt1)
end


## Functions setindex! and getindex for semitokens:

function getindex{K, D, Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, i::SDSemiToken)
    addr = i.address
    has_data(SMDToken{K,D,Ord}(m,i))
    return m.bt.data[addr].d
end

function setindex!{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, 
                                        d_, 
                                        i::SDSemiToken)
    addr = i.address
    has_data(SMDToken{K,D,Ord}(m,i))
    m.bt.data[addr] = KDRec{K,D}(m.bt.data[addr].parent,
                                 m.bt.data[addr].k, 
                                 convert(D,d_))
    m
end


smdtoken_construct{K, D, Ord <: Ordering}(m::SortedMultiDict{K,D,Ord},int1::Int) = 
SMDToken{K,D,Ord}(m, SMDSemiToken(int1))

## This function inserts an item into the tree.
## It returns a token that
## points to the newly inserted item.

function insert!{K,D, Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, k_, d_)
    b, i = insert!(m.bt, convert(K,k_), convert(D,d_), true)
    smdtoken_construct(m, i)
end


## First and last return the first and last (key,data) pairs
## in the SortedMultiDict.  It is an error to invoke them on an
## empty SortedMultiDict.


function first(m::SortedMultiDict)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    return m.bt.data[i].k, m.bt.data[i].d
end

function last(m::SortedMultiDict)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return m.bt.data[i].k, m.bt.data[i].d
end

## Function deref(ii), where ii is a token, returns the
## (k,d) pair indexed by ii.

function deref{K, D, Ord <: Ordering}(ii::SMDToken{K,D,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].k, 
           ii.container.bt.data[ii.semitoken.address].d
end

## Function deref_key(ii), where ii is a token, returns the
## key indexed by ii.

function deref_key{K, D, Ord <: Ordering}(ii::SMDToken{K,D,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].k
end

## Function deref_value(ii), where ii is a token, returns the
## value indexed by ii.

function deref_value{K, D, Ord <: Ordering}(ii::SMDToken{K,D,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].d
end

## This function takes a key and returns the token
## of the first item in the tree that is >= the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedfirst{K, D, Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, k_)
    i = findkeyless(m.bt, convert(K,k_))
    smdtoken_construct(m, nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the first item in the tree that is > the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedafter{K, D, Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    smdtoken_construct(m, nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the last item in the tree that is <= the given
## key in the sorted order.  It returns the before-start marker
## if there is none.

function searchsortedlast{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    smdtoken_construct(m, i)
end

## This function takes a key k and returns a pair of tokens,
## one pointing to the first key that agrees with argument k
## and the other pointing one past the last key that agrees with k.
## If the key is not present, it returns a pair of past-end tokens.


function searchequalrange{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, k_)
    k = convert(K,k_)
    i1 = findkeyless(m.bt, k)
    i2, exactfound = findkey(m.bt, k)
    if exactfound
        i1a = nextloc0(m.bt, i1)
        i2a = nextloc0(m.bt, i2)
        return smdtoken_construct(m,i1a), smdtoken_construct(m,i2a)
    else
        return smdtoken_construct(m,2), smdtoken_construct(m,2)
    end
end


## (k,d) in m checks whether a key-data pair is in 
## a sorted multidict.  This requires a loop over
## all data items whose key is equal to k. 

function in{K,D,Ord <: Ordering}(pr::(@compat Tuple{Any,Any}), m::SortedMultiDict{K,D,Ord})
    k = convert(K, pr[1])
    i1 = findkeyless(m.bt, k)
    i2,exactfound = findkey(m.bt,k)
    !exactfound && return false
    ord = m.bt.ord
    while true
        i1 = nextloc0(m.bt, i1)
        i1 == i2 && return false
        @assert(eq(ord, m.bt.data[i1].k, k))
        m.bt.data[i1].d == pr[2] && return true
    end
end
 

eltype{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}) = (K,D)
orderobject(m::SortedMultiDict) = m.bt.ord

function haskey{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    exactfound
end



## Check if two SortedMultiDicts are equal in the sense of containing
## the same (K,D) pairs in the same order.  This sense of equality does not mean
## that semitokens valid for one are also valid for the other.

function isequal(m1::SortedMultiDict, m2::SortedMultiDict)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2)) || !isequal(eltype(m1), eltype(m2))
        throw(ArgumentError("Cannot use isequal for two SortedMultiDicts unless their element types and ordering objects are equal"))
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

typealias SDorAssociative Union(Associative, SortedMultiDict)

function mergetwo!{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, 
                                        m2::SDorAssociative)
    for (k,v) in m2
        insert!(m.bt, convert(K,k), convert(D,v), true)
    end
end

function packcopy{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord})
    w = SortedMultiDict((K)[], (D)[], orderobject(m))
    mergetwo!(w,m)
    w
end

function packdeepcopy{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord})
    w = SortedMultiDict((K)[], (D)[], orderobject(m))
    for (k,v) in m
        insert!(w.bt, deepcopy(k), deepcopy(v), true)
    end
    w
end


function merge!{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, 
                                     others::SDorAssociative...)
    for o in others
        mergetwo!(m,o)
    end
end

function merge{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, 
                                    others::SDorAssociative...)
    result = packcopy(m)
    merge!(result, others...)
    result
end

function Base.show{K,D,Ord <: Ordering}(io::IO, m::SortedMultiDict{K,D,Ord})
    print(io, "SortedMultiDict(")
    keys = K[]
    vals = D[]
    for (k,v) in m
        push!(keys, k)
        push!(vals, v)
    end
    print(io, keys)
    println(io, ",")
    print(io, vals)
    println(io, ",")
    print(io, orderobject(m))
    print(io, ")")
end
