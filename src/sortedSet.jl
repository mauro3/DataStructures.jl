## A SortedSet is a wrapper around balancedTree with
## methods similiar to those of the julia Set.


type SortedSet{K, Ord <: Ordering}
    bt::BalancedTree23{K,Nothing,Ord}
end


typealias SetSemiToken IntSemiToken

immutable SetToken{K,Ord <: Ordering} <: Token{SortedSet{K,Ord}, SetSemiToken}
    container::SortedSet{K,Ord}
    semitoken::SetSemiToken
end

assemble(m::SortedSet, s::SetSemiToken) = SetToken(m,s)


## This constructor takes a set ordering object which defaults
## to Forward

function SortedSet{K,Ord <: Ordering}(d::AbstractArray{K,1}, o::Ord=Forward)
    bt1 = BalancedTree23{K, Nothing, Ord}(o)
    for pr in d
        insert!(bt1, pr, nothing, false)
    end
    SortedSet(bt1)
end

stoken_construct{K, Ord <: Ordering}(m::SortedSet{K,Ord},int1::Int) = 
    SetToken{K,Ord}(m, SetSemiToken(int1))

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.
        
function find{K,Ord <: Ordering}(m::SortedSet{K,Ord}, k_)
    ll, exactfound = findkey(m.bt, convert(K,k_))
    stoken_construct(m, exactfound? ll : 2)
end

## This function inserts an item into the tree.
## It returns a bool and a token.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The token points to the newly inserted item.

function insert!{K, Ord <: Ordering}(m::SortedSet{K,Ord}, k_)
    b, i = insert!(m.bt, convert(K,k_), nothing, false)
    b, stoken_construct(m, i)
end

## push! is similar to insert but returns the set

function push!{K, Ord <: Ordering}(m::SortedSet{K,Ord}, k_)
    b, i = insert!(m.bt, convert(K,k_), nothing, false)
    m
end


## First and last return the first and last (key,data) pairs
## in the SortedDict.  It is an error to invoke them on an
## empty SortedDict.


function first(m::SortedSet)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    return m.bt.data[i].k
end

function last(m::SortedSet)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return m.bt.data[i].k
end

## Function deref(ii), where ii is a token, returns the
## k indexed by ii.

function deref{K, Ord <: Ordering}(ii::SetToken{K,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].k
end


## This function takes a key and returns the token
## of the first item in the tree that is >= the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedfirst{K, Ord <: Ordering}(m::SortedSet{K,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    stoken_construct(m, exactfound? i : nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the first item in the tree that is > the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedafter{K, Ord <: Ordering}(m::SortedSet{K,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    stoken_construct(m, nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the last item in the tree that is <= the given
## key in the sorted order.  It returns the before-start marker
## if there is none.

function searchsortedlast{K,Ord <:Ordering}(m::SortedSet{K,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    stoken_construct(m, i)
end


function in{K,Ord <: Ordering}(k_, m::SortedSet{K,Ord})
    i, exactfound = findkey(m.bt, convert(K,k_))
    return exactfound
end

eltype{K,Ord <: Ordering}(m::SortedSet{K,Ord}) = K
orderobject(m::SortedSet) = m.bt.ord

haskey(m::SortedSet, k_) = in(k_, m)

function delete!{K,Ord <: Ordering}(m::SortedSet{K,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    !exactfound && throw(KeyError(k_))
    delete!(m.bt, i)
    m
end

function pop!{K,Ord <: Ordering}(m::SortedSet{K,Ord}, k_)
    k = convert(K,k_)
    i, exactfound = findkey(m.bt, k)
    !exactfound && throw(KeyError(k_))
    d = m.bt.data[i].d
    delete!(m.bt, i)
    k
end

function pop!(m::SortedSet)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    k = m.bt.data[i].k
    delete!(m.bt, i)
    k
end



## Check if two SortedSets are equal in the sense of containing
## the same K entries.  This sense of equality does not mean
## that semitokens valid for one are also valid for the other.

function isequal(m1::SortedSet, m2::SortedSet)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2)) || !isequal(eltype(m1), eltype(m2))
        throw(ArgumentError("Cannot use isequal for two SortedSets unless their element types and ordering objects are equal"))
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
        k1 = deref(p1)
        k2 = deref(p2)
        if !eq(ord,k1,k2)
            return false
        end
        p1 = advance(p1)
        p2 = advance(p2)
    end
end


function union!{K, Ord <: Ordering}(m1::SortedSet{K,Ord}, iterable_item)
    for k in iterable_item
        push!(m1,convert(K,k))
    end
    m1
end

function union(m1::SortedSet, others...)
    mr = packcopy(m1)
    for m2 in others
        union!(mr, m2)
    end
    mr
end

function intersect2{K, Ord <: Ordering}(m1::SortedSet{K, Ord}, m2::SortedSet{K, Ord})
    ord = orderobject(m1)
    mi = SortedSet(K[], ord)
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendtoken(m1) || p2 == pastendtoken(m2)
            return mi
        end
        k1 = deref(p1)
        k2 = deref(p2)
        if lt(ord,k1,k2)
            p1 = advance(p1)
        elseif lt(ord,k2,k1)
            p2 = advance(p2)
        else
            push!(mi,k1)
            p1 = advance(p1)
            p2 = advance(p2)
        end
    end
end

            
function intersect{K, Ord <: Ordering}(m1::SortedSet{K,Ord}, others::SortedSet{K,Ord}...)
    ord = orderobject(m1)
    for s2 in others
        if !isequal(ord, orderobject(s2))
            throw(ArgumentError("Cannot intersect two SortedSets unless their ordering objects are equal"))
        end
    end
    if length(others) == 0
        return m1
    else
        mi = intersect2(m1, others[1])
        for s2 = others[2:end]
            mi = intersect2(mi, s2)
        end
        return mi
    end
end
    

function symdiff{K, Ord <: Ordering}(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord})
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2))
        throw(ArgumentError("Cannot apply symdiff to two SortedSets unless their ordering objects are equal"))
    end
    mi = SortedSet(K[], ord)
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        m1end = p1 == pastendtoken(m1)
        m2end = p2 == pastendtoken(m2)
        if m1end && m2end
            return mi
        elseif m1end
            push!(mi, deref(p2))
            p2 = advance(p2)
        elseif m2end
            push!(mi, deref(p1))
            p1 = advance(p1)
        else
            k1 = deref(p1)
            k2 = deref(p2)
            if lt(ord,k1,k2)
                push!(mi, k1)
                p1 = advance(p1)
            elseif lt(ord,k2,k1)
                push!(mi, k2)
                p2 = advance(p2)
            else
                p1 = advance(p1)
                p2 = advance(p2)
            end
        end
    end
end
    
function setdiff{K, Ord <: Ordering}(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord})
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2))
        throw(ArgumentError("Cannot apply setdiff to two SortedSets unless their ordering objects are equal"))
    end
    mi = SortedSet(K[], ord)
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendtoken(m1)
            return mi
        elseif p2 == pastendtoken(m2)
            push!(mi, deref(p1))
            p1 = advance(p1)
        else
            k1 = deref(p1)
            k2 = deref(p2)
            if lt(ord,k1,k2)
                push!(mi, deref(p1))
                p1 = advance(p1)
            elseif lt(ord,k2,k1)
                p2 = advance(p2)
            else
                p1 = advance(p1)
                p2 = advance(p2)
            end
        end
    end
end

function setdiff!(m1::SortedSet, iterable)
    for p in iterable
        i = find(m1, p)
        if i != pastendtoken(m1)
            delete!(i)
        end
    end
end


    
function issubset(iterable, m2::SortedSet)
    for k in iterable
        if !in(k, m2)
            return false
        end
    end
    return true
end


function packcopy{K,Ord <: Ordering}(m::SortedSet{K,Ord})
    w = SortedSet(K[], orderobject(m))
    for k in m
        push!(w, k)
    end
    w
end

function packdeepcopy{K, Ord <: Ordering}(m::SortedSet{K,Ord})
    w = SortedSet(K[], orderobject(m))
    for k in m
        newk = deepcopy(k)
        push!(w, newk)
    end
    w
end



function Base.show{K,Ord <: Ordering}(io::IO, m::SortedSet{K,Ord})
    print(io, "SortedSet(")
    keys = K[]
    for k in m
        push!(keys, k)
    end
    print(io, keys)
    println(io, ",")
    print(io, orderobject(m))
    print(io, ")")
end
